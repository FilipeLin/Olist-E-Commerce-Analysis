-- Change dbo tables to stg

USE Olist

-- ORDERS

IF OBJECT_ID('stg.orders','U') IS NOT NULL DROP TABLE stg.orders;
IF OBJECT_ID('dbo.olist_orders_dataset','U') IS NOT NULL
BEGIN
    SELECT * INTO stg.orders
    FROM dbo.olist_orders_dataset
END


-- ORDER_ITEMS

IF OBJECT_ID('stg.order_items','U') IS NOT NULL DROP TABLE stg.order_items;
IF OBJECT_ID('dbo.olist_order_items_dataset','U') IS NOT NULL
BEGIN
    SELECT * INTO stg.order_items
    FROM dbo.olist_order_items_dataset
END


-- PAYMENTS

IF OBJECT_ID('stg.payments','U') IS NOT NULL DROP TABLE stg.payments;
IF OBJECT_ID('dbo.olist_order_payments_dataset','U') IS NOT NULL
BEGIN
    SELECT * INTO stg.payments
    FROM dbo.olist_order_payments_dataset
END


-- PRODUCTS

IF OBJECT_ID('stg.products','U') IS NOT NULL DROP TABLE stg.products;
IF OBJECT_ID('dbo.olist_products_dataset','U') IS NOT NULL
BEGIN
    SELECT * INTO stg.products
    FROM dbo.olist_products_dataset
END


-- SELLERS

IF OBJECT_ID('stg.sellers','U') IS NOT NULL DROP TABLE stg.sellers;
IF OBJECT_ID('dbo.olist_sellers_dataset','U') IS NOT NULL
BEGIN
    SELECT * INTO stg.sellers
    FROM dbo.olist_sellers_dataset
END


-- CUSTOMERS

IF OBJECT_ID('stg.customers','U') IS NOT NULL DROP TABLE stg.customers;
IF OBJECT_ID('dbo.olist_customers_dataset','U') IS NOT NULL
BEGIN
    SELECT * INTO stg.customers
    FROM dbo.olist_customers_dataset
END



-- GEOLOCATION

IF OBJECT_ID('stg.geolocation','U') IS NOT NULL DROP TABLE stg.geolocation;
IF OBJECT_ID('dbo.olist_geolocation_dataset','U') IS NOT NULL
BEGIN
    SELECT * INTO stg.geolocation
    FROM dbo.olist_geolocation_dataset
END


-- CHECK: linhas por tabela stg

SELECT 'stg.orders'       AS table_name, COUNT(*) AS rows_count FROM stg.orders
UNION ALL
SELECT 'stg.order_items'  AS table_name, COUNT(*) AS rows_count FROM stg.order_items
UNION ALL
SELECT 'stg.payments'     AS table_name, COUNT(*) AS rows_count FROM stg.payments
UNION ALL
SELECT 'stg.products'     AS table_name, COUNT(*) AS rows_count FROM stg.products
UNION ALL
SELECT 'stg.sellers'      AS table_name, COUNT(*) AS rows_count FROM stg.sellers
UNION ALL
SELECT 'stg.customers'    AS table_name, COUNT(*) AS rows_count FROM stg.customers
UNION ALL
SELECT 'stg.geolocation'  AS table_name, COUNT(*) AS rows_count FROM stg.geolocation
