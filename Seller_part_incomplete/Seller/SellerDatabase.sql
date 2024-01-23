-- Active: 1700962580807@@127.0.0.1@3306@SellerDatabase
USE SellerDatabase;

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    name VARCHAR(255),
    description VARCHAR(255),
    price DECIMAL(10, 2)
);

INSERT INTO products (product_id, name, description, price)
VALUES
    (1, 'Blanket', 'Small Blanket', 19.99),
    (2, 'Sneakers', 'Basketball sneakers', 29.99),
    (3, 'Pillow', 'Soft Pillow', 12.99),
    (4, 'T-shirt', 'Cotton T-shirt', 15.99),
    (5, 'Backpack', 'Waterproof Backpack', 39.99),
    (6, 'Smartphone', 'Latest model smartphone', 599.99),
    (7, 'Laptop', 'High-performance laptop', 899.99),
    (8, 'Coffee Maker', 'Drip coffee maker', 49.99),
    (9, 'Vacuum Cleaner', 'Robotic vacuum cleaner', 249.99),
    (10, 'Digital Camera', 'Mirrorless digital camera', 799.99),
    (11, 'Desk Chair', 'Ergonomic desk chair', 199.99),
    (12, 'Toaster', '2-slice toaster', 29.99),
    (13, 'Blender', 'Countertop blender', 79.99),
    (14, 'Fitness Tracker', 'Fitness and activity tracker', 49.99),
    (15, 'Outdoor Grill', 'Gas outdoor grill', 349.99),
    (16, 'Microwave Oven', 'Countertop microwave oven', 89.99),
    (17, 'Digital Watch', 'Smart digital watch', 129.99),
    (18, 'Kitchen Mixer', 'Stand mixer for baking', 219.99),
    (19, 'Bluetooth Speaker', 'Portable Bluetooth speaker', 69.99),
    (20, 'Tablet', 'Tablet with touchscreen', 299.99),
    (21, 'Air Purifier', 'HEPA air purifier', 149.99),
    (22, 'Electric Toothbrush', 'Rechargeable electric toothbrush', 49.99),
    (23, 'Power Drill', 'Cordless power drill', 129.99),
    (24, 'Rice Cooker', 'Automatic rice cooker', 59.99),
    (25, 'Desk Lamp', 'LED desk lamp', 29.99),
    (26, 'Gaming Console', 'Latest gaming console', 399.99),
    (27, 'Hair Dryer', 'Ionic hair dryer', 39.99),
    (28, 'Coffee Grinder', 'Electric coffee grinder', 19.99),
    (29, 'Handheld Vacuum', 'Cordless handheld vacuum', 79.99),
    (30, 'Portable Charger', 'Power bank for devices', 24.99),
    (31, 'Tire', 'Snow Tire', 99.99),
    (32, 'Face Wash', 'Tula', 39.99),
    (33, 'Mug', 'Cold Mug', 29.99),
    (34, 'Monitor', 'Gaming Monitor', 189.99);



    USE SellerDatabase;

CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255),
    email VARCHAR(255),
    total_purchases DECIMAL(10, 2)
);


INSERT INTO customers (name, email, total_purchases)
VALUES
    ('Alice Smith', 'alice@example.com', 250.00),
    ('Bob Johnson', 'bob@example.com', 150.00);

INSERT INTO customers (name, email, total_purchases)
VALUES
    ('Charlie Brown', 'charlie.brown@example.com', 300.00),
    ('Diana Prince', 'diana.prince@example.com', 450.00),
    ('Ethan Hunt', 'ethan.hunt@example.com', 500.00),
    ('Fiona Gallagher', 'fiona.gallagher@example.com', 350.00),
    ('George Bluth', 'george.bluth@example.com', 200.00),
    ('Hannah Abbott', 'hannah.abbott@example.com', 280.00),
    ('Ian Malcolm', 'ian.malcolm@example.com', 320.00),
    ('Julia Green', 'julia.green@example.com', 400.00),
    ('Kyle Broflovski', 'kyle.broflovski@example.com', 380.00),
    ('Laura Palmer', 'laura.palmer@example.com', 420.00);


SELECT AVG(total_purchases) AS average_purchase_value FROM customers;

SELECT SUM(total_purchases) AS total_revenue FROM customers;

SELECT MIN(price) AS min_price, MAX(price) AS max_price, AVG(price) AS avg_price FROM products;

SELECT COUNT(*) AS total_customers FROM customers;

-- Most expensive product
SELECT name, price FROM products ORDER BY price DESC LIMIT 1;

-- Least expensive product
SELECT name, price FROM products ORDER BY price ASC LIMIT 1;


CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT,
    product_id INT,
    order_status VARCHAR(255),
    order_date DATETIME,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);


INSERT INTO orders (customer_id, product_id, order_status, order_date) 
VALUES 
    (1, 5, 'Shipped', '2023-01-10 10:00:00'),
    (2, 3, 'Processing', '2023-01-12 15:30:00'),
    (3, 10, 'Delivered', '2023-01-15 09:30:00'),
    (4, 16, 'Cancelled', '2023-01-16 14:00:00');



SELECT
    CONSTRAINT_NAME 
FROM
    INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE
    TABLE_SCHEMA = 'SellerDatabase' AND
    TABLE_NAME = 'orders' AND
    COLUMN_NAME = 'product_id';


ALTER TABLE orders DROP FOREIGN KEY orders_ibfk_2;


ALTER TABLE products MODIFY COLUMN product_id INT AUTO_INCREMENT;


ALTER TABLE orders ADD CONSTRAINT orders_ibfk_2 FOREIGN KEY (product_id) REFERENCES products(product_id);


SELECT SUM(p.price) AS total_monthly_sales
FROM orders o
INNER JOIN products p ON o.product_id = p.product_id
WHERE YEAR(o.order_date) = YEAR(CURRENT_DATE()) AND MONTH(o.order_date) = MONTH(CURRENT_DATE());


SELECT SUM(p.price) AS total_weekly_sales
FROM orders o
INNER JOIN products p ON o.product_id = p.product_id
WHERE YEARWEEK(o.order_date, 1) = YEARWEEK(CURRENT_DATE(), 1);


SELECT SUM(p.price) AS total_24h_sales
FROM orders o
INNER JOIN products p ON o.product_id = p.product_id
WHERE o.order_date >= NOW() - INTERVAL 1 DAY;
