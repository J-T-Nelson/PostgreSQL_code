SELECT * FROM orders LIMIT 20;
-- row_id, orderpriority, discount, unit_price, shipping_cost, cusstomer_id, customer_name, ship_mode, customer_segment, product_category, 
-- product_subcategory, product_container, product_name, product_base_margin, country, region, state, city, postal_code, order_date, ship_date
-- profit, quanitity_ordered_new, slaes, order_id

SELECT * FROM returns;
-- order_id, status


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


-- Creating customer table
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
-- since there are not multiple addresses in the table currently, this query works as our new table, though if we already had customers with
-- multiple addresses, it would be more difficult to get the table right. 

SELECT * FROM orders_n; -- null entries for orders not returned

-- Looks good, onto the products table

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

SELECT * FROM order_sales;

-- No testing on this exercise as of now, perhaps I will return to get more practice in the future, 
--	though for now I will leave the normalization of this table at a complete but untested stage