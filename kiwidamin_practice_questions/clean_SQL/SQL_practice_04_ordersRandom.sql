-- Data is randomly generated, thus, prices may seem unreasonable

-- Inspecting tables, listing cols: 

SELECT * FROM customer;
-- customer_id, name, email, address, state
SELECT * FROM customer_order;
-- order_id, customer_id, date_ordered, date_delivered
-- "We assume that all items in the same order are delivered on the same day."

SELECT * FROM order_product;
-- order_ide, product_id, qty
SELECT * FROM product;
-- product_id, product_name, price
--  "We assume that the price does not change for a particular product."

SELECT * FROM pg_catalog.pg_tables;
-- this lists the tables of the current database, 
--	but also includes a lot of other information like data structures which seem internal to postgreSQL itself


-- Questions: 

-- 1. List the 10 most expensive products for sale, and their prices
SELECT *
FROM product
ORDER BY price DESC
LIMIT 10;


-- 2. Which states have more than 5 customers? Use the state column on the customer table. 
--		Count each customer on the table, regardless of whether they have ever bought anything.
WITH count_customers AS(
	SELECT state, COUNT(customer_id) as num_customers
	FROM customer
	GROUP BY state 
)
SELECT *
FROM count_customers
WHERE num_customers > 5
ORDER BY num_customers DESC;


-- 3. Get the 17 customers that have made the largest number of orders. Include the name, address, state, and number of orders made.
WITH customers_orders AS(
	SELECT co.*, c.name, c. address, c.state
	FROM customer_order co
	JOIN customer c ON c.customer_id = co.customer_id
)
SELECT name, address, state, COUNT(order_id) as num_orders
FROM customers_orders
GROUP BY customer_id, name, address, state
ORDER BY num_orders DESC
LIMIT 17;



-- 4. Get all orders by customer 1026. Include the amount spent in each order, the order id, and the total number of distinct products purchased.
CREATE VIEW customer_orders_products AS
SELECT co.*, op.product_id, op.qty, p.product_name, p.price, (p.price * op.qty) AS total_spent
FROM customer_order co
JOIN order_product op ON op.order_id = co.order_id
JOIN product p ON p.product_id = op.product_id;

-- inspect VIEW: 
SELECT * FROM customer_orders_products;

-- RESOLVING WITH THE VIEW 
SELECT order_id, SUM(total_spent) as total_order_cost, COUNT(DISTINCT product_id) as num_unique_products
FROM customer_orders_products
WHERE customer_id = 1026
GROUP BY order_id; 
-- Correct. 


-- 5. Get the 10 customers that have spent the most. Give the customer_id and amount spent
SELECT customer_id, SUM(total_spent) as grand_total_spent
FROM customer_orders_products
GROUP BY customer_id
ORDER BY grand_total_spent DESC
LIMIT 10;


-- 6. Repeat the previous question, but include the customer's name, address, and state, 
--		in addition to the customer id and total amount spent
WITH gTotalPerCustomer AS(
	SELECT customer_id, SUM(total_spent) as grand_total_spent
	FROM customer_orders_products
	GROUP BY customer_id
	ORDER BY grand_total_spent DESC
	LIMIT 10
)
SELECT gt.*, c.name, c.address, c.state 
FROM gTotalPerCustomer gt
JOIN customer c ON c.customer_id = gt.customer_id
ORDER BY grand_total_spent DESC;



-- 7. Find the 10 customers that spent the most in 2017. Give the name and amount spent. 
--		Take the date to be the order date (not the delivery date)
WITH top_2017_customers AS(
	SELECT customer_id, SUM(total_spent) as amount_spent
	FROM customer_orders_products
	WHERE EXTRACT('year' from date_ordered) = 2017
	GROUP BY customer_id
	ORDER BY amount_spent DESC
	LIMIT 10
)
SELECT c.name, tc.customer_id, tc.amount_spent
FROM top_2017_customers tc
JOIN customer c ON c.customer_id = tc.customer_id
ORDER BY tc.amount_spent DESC; 


-- 8. Which three products have we sold the most of? i.e. the greatest number of units?
SELECT product_id, SUM(qty) as units_sold
FROM order_product
GROUP BY product_id
ORDER BY units_sold DESC
LIMIT 3; 


-- 9. What is the average number of days between order and delivery?
SELECT AVG(date_delivered - date_ordered) as avg_delivery_time 
FROM customer_order;
-- answer in days hours minutes seconds

SELECT AVG(EXTRACT(EPOCH FROM (date_delivered - date_ordered))/86400) as avg_delivery_time
FROM customer_order;
-- answer in fractional days


-- 10. What is the average number of days between order and delivery for each year? Take the year from the order date.
SELECT 
	EXTRACT('year' from date_ordered) as year,
	AVG(date_delivered - date_ordered) as avg_delivery_time
FROM customer_order
GROUP BY year;
-- answer in days hours minutes seconds

SELECT 
	EXTRACT('year' from date_ordered) as year,
	AVG(EXTRACT(EPOCH FROM (date_delivered - date_ordered))/86400) as avg_delivery_time
FROM customer_order
GROUP BY year;
-- answer in fractional days

