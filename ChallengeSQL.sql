-- Database: store_db

-- DROP DATABASE IF EXISTS store_db;

-- Database: store_db

--DROP DATABASE IF EXISTS store_db;
-- CREATE TABLE customers (
--     customer_id SERIAL PRIMARY KEY,
-- 	first_name VARCHAR(100),
-- 	last_name VARCHAR(100),
-- 	email VARCHAR(100),
-- 	phone_number VARCHAR(20)
-- );


-- CREATE TABLE orders (
--     order_id SERIAL PRIMARY KEY,
--     customer_id INT  REFERENCES customers(customer_id),--(clé étrangère)
--     order_date DATE,
--     total_amount DECIMAL(10, 2)
-- );

-- CREATE TABLE products (
-- 	product_id SERIAL PRIMARY KEY,
-- 	name VARCHAR(100), 
-- 	price DECIMAL(10, 2), 
-- 	category VARCHAR(100)
-- );

-- CREATE TABLE order_items (
--     item_id SERIAL PRIMARY KEY,
--     order_id INT REFERENCES orders(order_id),--(clé étrangère)
--     product_id INT REFERENCES products(product_id),--(clé étrangère)
--     quantity INT
-- );
-- INSERT INTO customers (first_name, last_name, email, phone_number)
-- VALUES
-- ('Ahmed', 'Bennani', 'ahmed.bennani@email.com', '0611568491'),
-- ('Sara', 'El Amrani', 'sara.amrani@email.com', '0678315591'),
-- ('Youssef', 'Kamal', 'youssef.kamal@email.com', '0650123365'),
-- ('Amine', 'Ali', 'amine.ali@email.com', '0612305687'),
-- ('ikram', 'nawi', 'likram.nawi@email.com', '0610562784')

-- INSERT INTO products  (name, price,category)
-- VALUES
-- ('Ordinateur Portable', 8500.00, 'Informatique'),
-- ('Souris Sans Fil', 120.00, 'Accessoires'),
-- ('Casque Audio', 300.00, 'Audio'),
-- ('Écran 24 pouces', 1100.00, 'Informatique'),
-- ('Clavier mécanique Logitech', 450.00, 'Accessoires');
-- SELECT*FROM products
-- SELECT * FROM customers;
-- INSERT INTO orders (customer_id,order_date,total_amount)
-- VALUES
-- (1, '2025-07-01', 8500.00),
-- (1, '2025-07-05', 300.00),
-- (2, '2025-07-02', 1500.00),
-- (3, '2025-07-03', 120.00),
-- (4, '2025-07-04', 950.00),
-- (5, '2025-07-05', 2300.00);
-- SELECT * FROM orders;
-- INSERT INTO order_items (order_id,product_id, quantity)
-- VALUES
-- (1, 1, 1),
-- (2, 3, 1),
-- (3, 4, 1),
-- (3, 5, 1),
-- (4, 2, 1),
-- (5, 5, 2),
-- (5, 3, 1),
-- (6, 1, 1),
-- (6, 4, 1);
-- SELECT * FROM order_items;
-- SELECT * FROM customers
-- SELECT * FROM orders where order_date > '2024-01-01'
-- SELECT DISTINCT
--     c.first_name,
--     c.last_name,
--     c.email
-- FROM customers c
-- JOIN orders o ON c.customer_id = o.customer_id;
-- SELECT * FROM customers where first_name='Sara'
-- SELECT * FROM orders where total_amount=120
-- SELECT *FROM customers WHERE last_name LIKE 'A%'
-- UPDATE customers SET phone_number = 0622351451;
-- UPDATE orders SET total_amount=total_amount*1.10;
-- Update customers SET email='kamal.youssef@email.com' WHERE email='youssef.kamal@email.com'
-- DELETE FROM orders WHERE order_date <'2023-07-01'

-- ALTER TABLE orders
-- DROP CONSTRAINT IF EXISTS orders_customer_id_fkey;

-- ALTER TABLE orders
-- ADD CONSTRAINT orders_customer_id_fkey
-- FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
-- ON DELETE CASCADE;
--3
-- ALTER TABLE order_items
-- DROP CONSTRAINT IF EXISTS order_items_order_id_fkey;

-- ALTER TABLE order_items
-- ADD CONSTRAINT order_items_order_id_fkey
-- FOREIGN KEY (order_id) REFERENCES orders(order_id)
-- ON DELETE CASCADE


-- DELETE FROM orders WHERE customer_id=3




	