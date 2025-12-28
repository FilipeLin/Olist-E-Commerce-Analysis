-- 1. Format data type for each column

SELECT
  TRY_CAST(price AS DECIMAL(10,2)) AS price
FROM stg.order_items

-- Check to verify NULL values

SELECT price
FROM stg.order_items
WHERE TRY_CAST(price AS DECIMAL(10,2)) IS NULL
  AND price IS NOT NULL

-- Alter column type permanently (order_items)

ALTER TABLE stg.order_items
ALTER COLUMN price DECIMAL(10,2)

ALTER TABLE stg.order_items
ALTER COLUMN freight_value DECIMAL(10,2)

ALTER TABLE stg.order_items
ALTER COLUMN shipping_limit_date DATETIME2


-- Alter column type permanently (geolocation)

ALTER TABLE stg.geolocation
ALTER COLUMN geolocation_lat DECIMAL(9,6)

ALTER TABLE stg.geolocation
ALTER COLUMN geolocation_lng DECIMAL(9,6)


-- Alter column type permanently (orders)

ALTER TABLE stg.orders
ALTER COLUMN order_purchase_timestamp DATETIME2

ALTER TABLE stg.orders
ALTER COLUMN order_approved_at DATETIME2

ALTER TABLE stg.orders
ALTER COLUMN order_delivered_carrier_date DATETIME2

ALTER TABLE stg.orders
ALTER COLUMN order_delivered_customer_date DATETIME2

ALTER TABLE stg.orders
ALTER COLUMN order_estimated_delivery_date DATETIME2


-- Alter column type permanently (payments)

ALTER TABLE stg.payments
ALTER COLUMN payment_value DECIMAL(10,2)



-- 2. Remove "" from some values in stg.order_items

-- Check for values with ""

SELECT TOP 1000 product_id
FROM stg.order_items
WHERE product_id LIKE '"%'

SELECT TOP 1000 seller_id
FROM stg.order_items
WHERE seller_id LIKE '"%'

-- Updanting the values

UPDATE stg.order_items
SET product_id = REPLACE(product_id, '"', '')
WHERE product_id LIKE '"%'

UPDATE stg.order_items
SET seller_id = REPLACE(seller_id, '"', '')
WHERE seller_id LIKE '"%'

UPDATE stg.order_items
SET order_id = REPLACE(order_id, '"', '')
WHERE order_id LIKE '"%'

-- Verify the changes

SELECT COUNT(*) AS Quotes
FROM stg.order_items
WHERE product_id LIKE '"%' OR seller_id LIKE '"%' OR order_id LIKE '"%'



-- Remove "" from some values in stg.customers

UPDATE stg.customers
SET customer_id = REPLACE(customer_id, '"', '')
WHERE customer_id LIKE '"%'

UPDATE stg.customers
SET customer_unique_id = REPLACE(customer_unique_id, '"', '')
WHERE customer_unique_id LIKE '"%'

UPDATE stg.customers
SET customer_zip_code_prefix = REPLACE(customer_zip_code_prefix, '"', '')
WHERE customer_zip_code_prefix LIKE '"%'


-- Remove "" from some values in stg.customers

UPDATE stg.geolocation
SET geolocation_zip_code_prefix = REPLACE(geolocation_zip_code_prefix, '"', '')
WHERE geolocation_zip_code_prefix LIKE '"%'


-- Remove "" from some values in stg.orders

UPDATE stg.orders
SET order_id = REPLACE(order_id, '"', '')
WHERE order_id LIKE '"%'

UPDATE stg.orders
SET customer_id = REPLACE(customer_id, '"', '')
WHERE customer_id LIKE '"%'


-- Remove "" from some values in stg.payments

UPDATE stg.payments
SET order_id = REPLACE(order_id, '"', '')
WHERE order_id LIKE '"%'


-- Remove "" from some values in stg.products

UPDATE stg.products
SET product_id = REPLACE(product_id, '"', '')
WHERE product_id LIKE '"%'


-- Remove "" from some values in stg.sellers

UPDATE stg.sellers
SET seller_zip_code_prefix = REPLACE(seller_zip_code_prefix, '"', '')
WHERE seller_zip_code_prefix LIKE '"%'

UPDATE stg.sellers
SET seller_id = REPLACE(seller_id, '"', '')
WHERE seller_id LIKE '"%'



-- 3. Data quality check

-- Verify if price and freight values are equal or lower than 0

SELECT price
FROM stg.order_items
WHERE price <= 0


SELECT freight_value
FROM stg.order_items
WHERE freight_value < 0


-- Validate consistency of order_status values

SELECT order_status,
	COUNT(order_status) AS Total
FROM stg.orders
GROUP BY order_status


-- Check if there is payment_value equal to zero

SELECT *
FROM stg.payments
WHERE payment_value = 0


-- Check if payment equal item price

SELECT p.order_id,
	order_status,
	payment_value,
	price
FROM stg.payments p
LEFT JOIN stg.orders o
ON p.order_id = o.order_id
LEFT JOIN stg.order_items i
ON p.order_id = i.order_id
WHERE payment_value > 0


-- Check for orders overpaid compared to item price

WITH pay AS (
  SELECT
    order_id,
    COUNT(*) AS payment_rows,
    SUM(payment_value) AS total_paid
  FROM stg.payments
  WHERE payment_value > 0
  GROUP BY order_id
),
items AS (
  SELECT
    order_id,
    COUNT(*) AS item_rows,
    SUM(price) AS items_total_price,
    SUM(freight_value) AS items_total_freight
  FROM stg.order_items
  GROUP BY order_id
)
SELECT
  p.order_id,
  p.payment_rows,
  p.total_paid,
  i.item_rows,
  i.items_total_price,
  i.items_total_freight,
  (i.items_total_price + i.items_total_freight) AS order_total_items_plus_freight,
  (p.total_paid - (i.items_total_price + i.items_total_freight)) AS diff_paid_vs_items
FROM pay p
JOIN items i
  ON p.order_id = i.order_id
WHERE p.payment_rows = 1 and (p.total_paid - (i.items_total_price + i.items_total_freight)) > 0
ORDER BY ABS(p.total_paid - (i.items_total_price + i.items_total_freight)) DESC


-- Check for orders with more than one payment_row and compare diff_paid_vs_items

WITH pay AS (
  SELECT
    order_id,
    COUNT(*) AS payment_rows,
    SUM(payment_value) AS total_paid
  FROM stg.payments
  WHERE payment_value > 0
  GROUP BY order_id
),
items AS (
  SELECT
    order_id,
    COUNT(*) AS item_rows,
    SUM(price) AS items_total_price,
    SUM(freight_value) AS items_total_freight
  FROM stg.order_items
  GROUP BY order_id
)
SELECT
  p.order_id,
  p.payment_rows,
  p.total_paid,
  i.item_rows,
  i.items_total_price,
  i.items_total_freight,
  (i.items_total_price + i.items_total_freight) AS order_total_items_plus_freight,
  (p.total_paid - (i.items_total_price + i.items_total_freight)) AS diff_paid_vs_items
FROM pay p
JOIN items i
  ON p.order_id = i.order_id
WHERE p.payment_rows > 1
ORDER BY ABS(p.total_paid - (i.items_total_price + i.items_total_freight)) DESC


-- Time consistency 

SELECT COUNT(*) AS invalid_date
FROM stg.orders
WHERE order_delivered_customer_date < order_purchase_timestamp


-- Explore the cause behind the invalid_date

SELECT 
	order_status
FROM stg.orders
WHERE order_delivered_customer_date < order_purchase_timestamp and order_status = 'delivered'

SELECT 
	order_status
FROM stg.orders
WHERE order_delivered_customer_date < order_purchase_timestamp 


-- Check if there is order duplicates

SELECT order_id, COUNT(*)
FROM stg.orders
GROUP BY order_id
HAVING COUNT(*) > 1

































