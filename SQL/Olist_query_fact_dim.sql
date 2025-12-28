-- Create a schema

CREATE SCHEMA dw


-- FACT: order_payments

SELECT
  order_id,
  SUM(payment_value) AS total_paid,
  COUNT(*) AS payment_rows
INTO dw.fact_order_payments
FROM stg.payments
GROUP BY order_id


-- agg_order_items

SELECT
  order_id,
  COUNT(*) AS items_count,
  SUM(price) AS items_total_price,
  SUM(freight_value) AS items_total_freight
INTO dw.agg_order_items
FROM stg.order_items
GROUP BY order_id


-- FACT: Orders

SELECT
  o.order_id,
  o.customer_id,
  o.order_status,
  o.order_purchase_timestamp,
  o.order_delivered_customer_date,
  o.order_estimated_delivery_date,
  p.total_paid,
  p.payment_rows,
  i.items_count,
  i.items_total_price,
  i.items_total_freight,
  (i.items_total_price + i.items_total_freight) AS order_plus_freight,
  CASE WHEN o.order_status = 'delivered' THEN 1 ELSE 0 END AS is_delivered,
  CASE
    WHEN o.order_status = 'delivered'
     AND o.order_delivered_customer_date > o.order_estimated_delivery_date
    THEN 1 ELSE 0
  END AS is_delayed,
  CASE
    WHEN o.order_status = 'delivered'
     AND o.order_delivered_customer_date IS NOT NULL
    THEN DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)
    ELSE NULL
  END AS delivery_days
INTO dw.fact_orders
FROM stg.orders o
LEFT JOIN dw.fact_order_payments p
  ON o.order_id = p.order_id
LEFT JOIN dw.agg_order_items i
  ON o.order_id = i.order_id


-- Check if order_id is unique

SELECT
  COUNT(*) AS rows,
  COUNT(DISTINCT order_id) AS distinct_orders
FROM dw.fact_orders


-- DIM: Customers

SELECT
	customer_id,
	customer_unique_id,
	customer_city,
	customer_state,
	customer_zip_code_prefix
INTO dw.dim_customers
FROM stg.customers


-- DIM: products

SELECT
  product_id,
  product_category_name
INTO dw.dim_products
FROM stg.products


-- Fact: sales_items

SELECT
  oi.order_id,
  oi.order_item_id,
  o.customer_id,
  oi.product_id,
  oi.seller_id,
  CAST(o.order_purchase_timestamp AS DATE) AS purchase_date,
  oi.price,
  oi.freight_value,
  1 AS qty
INTO dw.fact_sales_item
FROM stg.order_items oi
JOIN stg.orders o
  ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'




