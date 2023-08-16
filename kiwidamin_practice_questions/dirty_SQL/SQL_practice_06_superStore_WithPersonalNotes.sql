SELECT * FROM orders LIMIT 20;
-- for some reason no rows show up
-- row_id, orderpriority, discount, unit_price, shipping_cost, cusstomer_id, customer_name, ship_mode, customer_segment, product_category, 
-- product_subcategory, product_container, product_name, product_base_margin, country, region, state, city, postal_code, order_date, ship_date
-- profit, quanitity_ordered_new, slaes, order_id

SELECT * FROM returns;
-- order_id, status


-- Need to verify no rows and not some other cause for no rows showing up in orders table

SELECT COUNT(*) FROM orders; -- 0 

-- going to drop table and remake it from the csv. Somehow installation went bad
DROP TABLE orders;

CREATE TABLE orders (
    row_id INTEGER,
    order_priority TEXT,
    discount REAL,
    unit_price REAL,
    shipping_cost REAL,
    customer_id INTEGER,
    customer_name TEXT,
    ship_mode TEXT,
    customer_segment TEXT,
    product_category TEXT,
    product_sub_category TEXT,
    product_container TEXT,
    product_name TEXT,
    product_base_margin REAL,
    country TEXT,
    region TEXT,
    state_or_province TEXT,
    city TEXT,
    postal_code INTEGER,
    order_date DATE,
    ship_date DATE,
    profit REAL,
    quantity_ordered_new INTEGER,
    sales REAL,
    order_id INTEGER
);

COPY orders 
FROM 'D:\\Programming\\Learn_PostgreSQL\\SQL_Practice\\07_normalize_superstore\\orders.csv' 
DELIMITER ',' 
CSV HEADER;

SELECT * FROM orders;
-- good. the table has data now with 1952 total rows. 


-- Questions: 

/*
There is only one exercise here: take the data in the orders table, and normalize it. That is, create other tables so that 
you are not repeating information. For example, you probably want to have customer data in a customer table, where each customer 
has a customer id as a primary key. The order table should contain the customer id, and no other information about the customer. 

There are several different approaches to this problem, so no solution is provided. Here are some things to think about:
*/
-- 1. Can your proposed solution deal with multiple addresses per customer?
-- 2. Can you tell which address each customer's order went to?
-- 3. When you have made all your tables, can you write a SELECT statement with JOINs that recreates the original table?


/* For this exercise I am going to use an entity relationship diagram. Need to find a resource to make one, then I need to 
study op on levels of normalization to determine what qualities my tables should posses before proposing a design. I should also
create more constraints like the 3 above which help guide the design. I believe normalization level 3 is the standard level for a "normalized" 
relational databse, so I will aim to achieve that here.
*/



-- I have made a diagram I believe will work. Now lets try and implement the scheme I have made. 

-- Starting with customer_address table

SELECT DISTINCT customer_id, country, region, state_or_province, city, postal_code
FROM orders
ORDER BY customer_id;


-- checking for duplicate customer_id s 
WITH cust_add AS(
	SELECT DISTINCT customer_id, country, region, state_or_province, city, postal_code
	FROM orders
	ORDER BY customer_id -- CTE returns 1130 rows when run independently 
)
SELECT DISTINCT COUNT(customer_id)
FROM cust_add; 
-- 1130 is the count, which is the original number of rows, no customers have multiple addresses, 
-- My scheme is however built to handle multiple addresses per customer if it occurrs. 

-- initializing table
CREATE TABLE customer_address (
	address_id INTEGER,
    customer_id INTEGER,
    country TEXT,
    region TEXT,
    state_or_province TEXT,
    city TEXT,
    postal_code INTEGER
);


-- populating table
INSERT INTO customer_address
WITH cust_add AS(
	SELECT DISTINCT customer_id, country, region, state_or_province, city, postal_code
	FROM orders
	ORDER BY customer_id
)
SELECT
	ROW_NUMBER() OVER(ORDER BY customer_id) As address_id,	
	customer_id, country, region, state_or_province, city, postal_code
FROM cust_add;

-- inspecting new table
SELECT * FROM customer_address;


-- Creating customers table

SELECT DISTINCT customer_id, customer_segment, customer_name
FROM orders
ORDER BY customer_id;


WITH precount AS(
	SELECT DISTINCT customer_id, customer_segment, customer_name
	FROM orders
	ORDER BY customer_id -- CTE returns 1191 rows
)
SELECT COUNT(customer_id)
FROM precount;
-- 1191, no customers with two segments, or multiple ids to names 

-- initializing customer table

CREATE TABLE customer (
	customer_id INTEGER,
	customer_name TEXT,
	customer_segment TEXT
);

-- populating table
INSERT INTO customer
SELECT DISTINCT 
	customer_id, customer_name, customer_segment -- important the order of cols queried here matches the order setup in the create statement
FROM orders
ORDER BY customer_id;

SELECT * FROM customer;
-- upon inspecting, I can see that if a customer has multiple 'segments' they belong to, (the same person makes orders under separate entities)
-- Then they will need to be treated as a different customer. I believe this is a good design though, as accounts should be kept separate 
-- even when dealing with the same actual person if they're operating as different legal entities. 

-- new orders table needs to be made next it will be named orders_n for orders_normalized or new. (whatever suites your fancy)

CREATE TABLE orders_n (
	order_id INTEGER,
	customer_id INTEGER,
	address_id INTEGER,
	order_date DATE,
	ship_date DATE
)

INSERT INTO orders_n
WITH distinctOrder AS(
	SELECT DISTINCT order_id, customer_id, order_date, ship_date
	FROM orders
)
SELECT o.order_id, o.customer_id, ca.address_id, o.order_date, o.ship_date
FROM distinctOrder o
JOIN customer_address ca ON ca.customer_id = o.customer_id
ORDER BY o.order_id;
-- since there are not multiple addresses in the table currently, this query works as our new table, though if we already had customers with
-- multiple addresses, it would be more difficult to get the table right. 

SELECT * FROM orders_n;

-- orders_n actually is incomplete right now, need to include the returns data within for my ERD to be properly implemented

-- drop table, then reinitialize and populate
DROP TABLE orders_n;

CREATE TABLE orders_n (
	order_id INTEGER,
	customer_id INTEGER,
	address_id INTEGER,
	order_date DATE,
	ship_date DATE,
	return_status TEXT
)

INSERT INTO orders_n
WITH distinctOrder AS(
	SELECT DISTINCT order_id, customer_id, order_date, ship_date -- ensuring no duplicate orders
	FROM orders
)
SELECT o.order_id, o.customer_id, ca.address_id, o.order_date, o.ship_date, r.status
FROM distinctOrder o
JOIN customer_address ca ON ca.customer_id = o.customer_id
LEFT JOIN returns r ON r.order_id = o.order_id
ORDER BY o.order_id;


SELECT * FROM orders_n; -- null entries for orders not returned

-- Looks good, onto the products table

SELECT * FROM orders;

CREATE TABLE products(
	product_name TEXT,
	product_category TEXT,
	product_sub_category TEXT,
	product_container TEXT,
	price REAL,
	product_base_margin REAL
)


INSERT INTO products(
SELECT DISTINCT product_name, product_category, product_sub_category, product_container, unit_price, product_base_margin
FROM orders
);

SELECT * FROM products;


----------------------------------------------------------------------------
-- learning how to query for column properties
SELECT 
    column_name, 
    data_type, 
    column_default,
    is_nullable,
    character_maximum_length
FROM 
    information_schema.columns 
WHERE 
    table_name = 'orders'
    AND table_schema = 'public'  -- usually 'public' if you didn't specify a different schema
ORDER BY 
    ordinal_position;


SELECT *
FROM 
    information_schema.columns 
WHERE 
    table_name = 'orders'
    AND table_schema = 'public'  -- usually 'public' if you didn't specify a different schema
ORDER BY 
    ordinal_position;
	
	
SELECT *
FROM 
    information_schema.table_constraints;

SELECT *
FROM 
    information_schema.key_column_usage;
----------------------------------------------------------------------------

-- next session, finish creating the last table needed, and then set integrity constraints.. use chatgpt to help with constraints and the process
-- also aim to understand a bit about indexing (how can this improve performance?)
-- test queries should be made against a normalized database to ensure it actually does what it was designed to do (duh, but takes effort and time)

-- initializing order_sales table
CREATE TABLE order_sales(
	sale_id INTEGER,
	order_id INTEGER,
	product_name TEXT,
	discount REAL,
	quantity INTEGER,
	shipping_cost REAL,
	ship_mode TEXT
)

INSERT INTO order_sales(
	WITH distinct_orders AS(
		SELECT DISTINCT order_id, product_name, discount, quantity_ordered_new, shipping_cost, ship_mode
		FROM orders
	)
	SELECT
		ROW_NUMBER() OVER(ORDER BY order_id) as sale_id,
		order_id, 
		product_name,
		discount,
		quantity_ordered_new,
		shipping_cost,
		ship_mode
	FROM distinct_orders 
);
-- scrolling through I can see there are clearly duplicate order_ids and product_names here, thus the need for sale_id is clear

-- inspect new table: 
SELECT * FROM order_sales;


-- TEST: remake original table from new tables only 
-- going to create a view and compare the two views for size and column types


SELECT DISTINCT
	c.customer_id, c.customer_segment, c.customer_name,
	ca.country, ca.region, ca.state_or_province, ca.city, ca.postal_code,
	orn.order_id, orn.order_date, orn.ship_date, 
	os.product_name, os.discount, os.quantity, os.shipping_cost, os.ship_mode,
	prd.product_category, prd.product_sub_category, prd.product_container, prd.price, prd.product_base_margin
FROM customer c
JOIN customer_address ca ON ca.customer_id = c.customer_id
JOIN orders_n orn ON orn.customer_id = c.customer_id
JOIN order_sales os ON os.order_id = orn.order_id
JOIN products prd ON prd.product_name = os.product_name
ORDER BY customer_id;
-- 3351 rows all distinct

select * from orders order by customer_id;
-- 1952 rows .. meaning in a join of ours we are creating novel rows somewhere

-- counting cols
SELECT COUNT(column_name) 
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'orders'; --25

SELECT COUNT(column_name) 
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = ''; 
