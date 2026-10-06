CREATE DATABASE report; -- Create a data base for this project
USE report; -- activate it


-- Import all the csv files using table import wizard. Once all imported, run the below query to check all tables stored or not
SHOW TABLES; -- This will the tables stored in the database or not.
-- -------------------------------------------------------------------------------------------------------------
-- Now lets see all data.

SELECT * FROM products; -- product_id(pk), product_name, category, price, stock_quantity, reorder_level, supplier_id(fk for suppliers)
-- what is reorder_level ? = when the stock_quantity < reorder_level we need to reorder

-- lets change the data type correctly for the table
-- I observed that some columns type need to change
ALTER TABLE products
MODIFY product_name VARCHAR(200),
MODIFY category VARCHAR(200),
MODIFY price FLOAT;

DESCRIBE products; -- Ok now
-- -------------------------------------------------------------------------------------------------------------
SELECT * FROM reorders; -- reorder_id, product_id(FK for products), reorder_quantity, reorder_date, status
DESCRIBE reorders; -- reorder_date, status

ALTER TABLE reorders
MODIFY `reorder_date` DATE,
MODIFY `status` VARCHAR(20);
-- -------------------------------------------------------------------------------------------------------------
SELECT * FROM shipments; -- shipment_id, product_id, supplier_id, quantity_received, shipment_date
DESCRIBE shipments;

ALTER TABLE shipments
MODIFY `shipment_date` DATE;
-- -------------------------------------------------------------------------------------------------------------
SELECT * FROM stock_entries; -- entry_id, product_id, change_quantity, change_type, entry_date
DESCRIBE stock_entries; -- change_type, entry_date

ALTER TABLE stock_entries
MODIFY `change_type` VARCHAR(20),
MODIFY `entry_date` DATE;

-- -------------------------------------------------------------------------------------------------------------
SELECT * FROM suppliers; -- supplier_id, supplier_name, contact_name, email, phone, address
DESCRIBE suppliers;


-- This below code will show the CREATE TABLE query of the imported table
-- Also in this way we can check existing PK, FK and relations. Also we can check the constraints

SHOW CREATE TABLE suppliers; -- supplier_id = PK, products and shipments are FK
SHOW CREATE TABLE products; -- product_id. = PK, stock_entries,shipments and reorders FK
SHOW CREATE TABLE stock_entries; -- entry_id = PK
SHOW CREATE TABLE reorders; -- reorder_id = PK
SHOW CREATE TABLE shipments; -- shipment_id = PK 
-- -------------------------------------------------------------------------------------------------------------

-- -------------------------------------------------------------------------------------------------------------
-- Now step is to check PK and FK columns
-- As we dont have a schema yet, what we studied from data we will check data quality of potential PK and FK columns and and then we will alter them

-- Lets start from products
SELECT `product_id`,COUNT(*) FROM products GROUP BY `product_id`
HAVING COUNT(*) >1; -- o/p should be zero row, this will confirm distinct

SELECT `product_id` FROM products WHERE `product_id` IS NULL ; -- o/p should be zero row, this will confirm not null

-- Ok now lets check the respective FKs in child tables , is there any such data which will not in paranet table
-- as data we used is completely raw, we should check
SELECT DISTINCT `product_id` FROM shipments
WHERE `product_id` NOT IN (SELECT `product_id` FROM products);

SELECT DISTINCT `product_id` FROM stock_entries
WHERE `product_id` NOT IN (SELECT `product_id` FROM products);

SELECT DISTINCT `product_id` FROM reorders
WHERE `product_id` NOT IN (SELECT `product_id` FROM products);


-- Lets simillarly check for suppliers
SELECT `supplier_id`,COUNT(*) FROM suppliers GROUP BY `supplier_id`
HAVING COUNT(*) >1;

SELECT `supplier_id` FROM suppliers WHERE `supplier_id` IS NULL ;


SELECT DISTINCT `supplier_id` FROM products
WHERE `supplier_id` NOT IN (SELECT `supplier_id` FROM suppliers);

SELECT DISTINCT `supplier_id` FROM shipments
WHERE `supplier_id` NOT IN (SELECT `supplier_id` FROM suppliers);


-- Lets check for stock_entries
SELECT `entry_id`,COUNT(*) FROM stock_entries GROUP BY `entry_id`
HAVING COUNT(*) >1; -- o/p should be zero row, this will confirm distinct

SELECT `entry_id` FROM products WHERE `entry_id` IS NULL ; -- o/p should be zero row, this will confirm not null

-- lets check for shipments
SELECT `shipment_id`,COUNT(*) FROM shipments GROUP BY `shipment_id`
HAVING COUNT(*) >1; -- o/p should be zero row, this will confirm distinct

SELECT `shipment_id` FROM shipments WHERE `shipment_id` IS NULL ; -- o/p should be zero row, this will confirm not null

-- lets check reorders
SELECT `reorder_id`,COUNT(*) FROM reorders GROUP BY `reorder_id`
HAVING COUNT(*) >1; -- o/p should be zero row, this will confirm distinct

SELECT `reorder_id` FROM reorders WHERE `reorder_id` IS NULL ; -- o/p should be zero row, this will confirm not null

-- ------------------------------------------------------------------------------------------------------------------------
-- Now lets add PK and FK
-- ------------------------------------------------------------------------------------------------------------------------

ALTER TABLE suppliers
MODIFY `supplier_id` INT NOT NULL, -- as all we saw in above is default NULL constraints, so we need to change first then PK for all tables
ADD PRIMARY KEY (`supplier_id`);

ALTER TABLE products
MODIFY `product_id` INT NOT NULL,
ADD PRIMARY KEY (`product_id`);

ALTER TABLE stock_entries
MODIFY entry_id INT NOT NULL,
ADD PRIMARY KEY (entry_id);

ALTER TABLE reorders
MODIFY reorder_id INT NOT NULL,
ADD PRIMARY KEY (reorder_id);

ALTER TABLE shipments
MODIFY shipment_id INT NOT NULL,
ADD PRIMARY KEY (shipment_id);

-- Also we will add an AUTO increment to it
ALTER TABLE suppliers
MODIFY supplier_id INT NOT NULL AUTO_INCREMENT;

ALTER TABLE products
MODIFY product_id INT NOT NULL AUTO_INCREMENT;

ALTER TABLE stock_entries
MODIFY entry_id INT NOT NULL AUTO_INCREMENT;

ALTER TABLE reorders
MODIFY reorder_id INT NOT NULL AUTO_INCREMENT;

ALTER TABLE shipments
MODIFY shipment_id INT NOT NULL AUTO_INCREMENT;

-- Lets add the FK 
ALTER TABLE products
ADD CONSTRAINT fk_products_supplier
FOREIGN KEY (supplier_id)
REFERENCES suppliers(supplier_id); 

ALTER TABLE stock_entries
ADD CONSTRAINT fk_stock_entries_product
FOREIGN KEY (product_id)
REFERENCES products(product_id);

ALTER TABLE reorders
ADD CONSTRAINT fk_reorders_product
FOREIGN KEY (product_id)
REFERENCES products(product_id);

ALTER TABLE shipments
ADD CONSTRAINT fk_shipments_product
FOREIGN KEY (product_id)
REFERENCES products(product_id);

ALTER TABLE shipments
ADD CONSTRAINT fk_shipments_supplier
FOREIGN KEY (supplier_id)
REFERENCES suppliers(supplier_id);


ALTER TABLE products
MODIFY product_name VARCHAR(200) NOT NULL,
MODIFY category VARCHAR(100) NOT NULL,
MODIFY price FLOAT NOT NULL,
MODIFY stock_quantity INT NOT NULL,
MODIFY reorder_level INT NOT NULL;

ALTER TABLE stock_entries
MODIFY change_quantity INT NOT NULL,
MODIFY change_type VARCHAR(20) NOT NULL,
MODIFY entry_date DATE NOT NULL;

ALTER TABLE reorders
MODIFY reorder_quantity INT NOT NULL,
MODIFY reorder_date DATE NOT NULL,
MODIFY status VARCHAR(20) NOT NULL;

ALTER TABLE shipments
MODIFY quantity_received INT NOT NULL,
MODIFY shipment_date DATE NOT NULL;


-- ------------------------------------------------------------------------------------------------------------------------
-- Now adding some constraints as per business rule
-- ------------------------------------------------------------------------------------------------------------------------

-- In products price, stock_quantity and reorder_level all should be >=0
ALTER TABLE products
ADD CONSTRAINT chk_products_price
CHECK (price >= 0),
ADD CONSTRAINT chk_products_stock
CHECK (stock_quantity >= 0),
ADD CONSTRAINT chk_products_reorder
CHECK (reorder_level >= 0);

-- In reorders reorder_quantity > 0
ALTER TABLE reorders
ADD CONSTRAINT chk_reorder_quantity
CHECK (reorder_quantity > 0);

-- In shipments quantity_received > 0
ALTER TABLE shipments
ADD CONSTRAINT chk_shipment_quantity
CHECK (quantity_received > 0);

-- in stock entries when we mention 'sale' in change_type, quantity should be -ve
-- when we mention 'Restock' in change_type, quantity should be +ve
ALTER TABLE stock_entries
ADD CONSTRAINT chk_stock_movement
CHECK (
    (change_type = 'Sale' AND change_quantity < 0)
    OR
    (change_type = 'Restock' AND change_quantity >= 0)
);




-- ------------------------------------------------------------------------------------------------------------------------
-- KPIs
-- ------------------------------------------------------------------------------------------------------------------------
-- 1. Total Suppliers
SELECT COUNT(DISTINCT `supplier_name`) AS 'Total Suppliers' FROM suppliers;
-- 2. Total Products
SELECT COUNT(DISTINCT `product_name`)  AS 'Total Products' FROM products;
-- 3. Total categories dealing
SELECT COUNT(DISTINCT `category`)  AS 'Total Categories' FROM products;

-- 4. Total sales value in last 3 months
-- This means what ever the date range we have we will so Latest 3 months

WITH t1 AS (
SELECT 
`product_id`,ABS(`change_quantity`) AS 'qty', `entry_date`,
(SELECT DATE_SUB(MAX(`entry_date`),INTERVAL 3 MONTH) FROM stock_entries WHERE `change_type` = 'Sale') AS 'prev_3month'
FROM stock_entries WHERE `change_type` = 'Sale'
ORDER BY `entry_date` DESC)
SELECT 
ROUND(SUM(t1.`qty`* p.`price`),2) AS 'total_sales_last3months'
FROM t1 LEFT JOIN products AS p
ON t1.`product_id` = p.`product_id`
WHERE `entry_date` >=`prev_3month`;



-- 5. Total Restock value(Last 3 months)
WITH t1 AS (
SELECT 
`product_id`,`change_quantity`, `entry_date`,
(SELECT DATE_SUB(MAX(`entry_date`),INTERVAL 3 MONTH) FROM stock_entries) AS 'prev_3month'
FROM stock_entries WHERE `change_type` = 'Restock'
ORDER BY `entry_date` DESC)
SELECT 
ROUND(SUM(t1.`change_quantity`* p.`price`),2) AS 'total_restock_last3months'
FROM t1 LEFT JOIN products AS p
ON t1.`product_id` = p.`product_id`
WHERE `entry_date` >=`prev_3month`;


-- 6. Below Reorder and No pending Reorders
SELECT COUNT(`product_id`) AS 'Below Reorder and No pending Reorders' 
FROM products 
WHERE `stock_quantity`< `reorder_level`
AND 
`product_id` NOT IN (SELECT `product_id` FROM reorders WHERE `status` = 'Pending');
-- -------------------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------------------------------------------------------------------------


-- How much inventory is available in each product category, and how many products are below their reorder level?
-- we will see product counts, quantity, inventory value, products at or below reorder level
SELECT 
`category`, COUNT(`product_id`) AS 'total_product',SUM(`stock_quantity`) AS 'Total Inventory',
ROUND(SUM(`stock_quantity`*`price`),2) AS 'Total Inventory Value',
SUM(CASE WHEN `stock_quantity`<= `reorder_level` THEN 1 ELSE 0 END) AS 'No of products below or at reorder level',
SUM(CASE WHEN `stock_quantity`< `reorder_level` THEN 1 ELSE 0 END) AS 'No of products below reorder level'
FROM products
GROUP BY `category`
ORDER BY `Total Inventory Value` DESC;


-- Inventory health check
-- we will see product_id, product_name, category, stock_quantity, reorder_level
SELECT 
`product_id`, `product_name`, `category`, `stock_quantity`, `reorder_level`,
CASE 
WHEN `stock_quantity`<`reorder_level` THEN 'Critical Stock'
WHEN `stock_quantity`=`reorder_level` THEN 'Low Stock'
ELSE 'Good Stock'
END AS 'inventory health'
FROM products
ORDER BY CASE 
WHEN `stock_quantity`<`reorder_level` THEN 1
WHEN `stock_quantity`=`reorder_level` THEN 2
ELSE 3
END;


-- Now lets see how much products come under these 3 category

SELECT 
CASE 
WHEN `stock_quantity`<`reorder_level` THEN 'Critical Stock'
WHEN `stock_quantity`=`reorder_level` THEN 'Low Stock'
ELSE 'Good Stock'
END AS 'inventory health',
COUNT(`product_id`) AS 'total products'
FROM products
GROUP BY `inventory health`;
/*
-- Monthly sales trend
-- How much units sold, how much estimated value and what is the current status

SELECT 
DATE_FORMAT(se.`entry_date`,'%y-%m') AS 'year_month', ABS(SUM(se.`change_quantity`)) AS 'Total_quantity_sold',
ROUND(SUM(p.`price`),2) AS 'Total_sales_value'
FROM stock_entries AS se
LEFT JOIN 
products AS p
ON se.`product_id` = p.`product_id`
WHERE `change_type` = 'Sale'
GROUP BY DATE_FORMAT(`entry_date`,'%y-%m')
ORDER BY `year_month`;

-- Monthly restock trend
SELECT 
DATE_FORMAT(st.`entry_date`,'%y-%m') AS 'year_month',
SUM(st.`change_quantity`) AS 'Total_Restock',
ROUND(SUM(st.`change_quantity`*p.`price`),2) AS 'Total_restock_value'
FROM stock_entries  AS st
LEFT JOIN products AS p
ON st.`product_id` = p.`product_id`
WHERE `change_type` = 'Restock'
GROUP BY DATE_FORMAT(st.`entry_date`,'%y-%m'),CONCAT('Q-',QUARTER(st.`entry_date`))
ORDER BY `year_month`;
*/

-- MONTHLY SALES and Restock Comparision

SELECT 
DATE_FORMAT(st.`entry_date`,'%y-%m') AS 'year_month',
SUM(CASE WHEN `change_type` = 'Restock' THEN st.`change_quantity` ELSE 0 END) AS 'Total_Restock_quantity',
SUM(CASE WHEN `change_type` = 'Sale' THEN ABS(st.`change_quantity`) ELSE 0 END) AS 'Total_Sale_quantity',
ROUND(SUM(CASE WHEN `change_type` = 'Restock' THEN st.`change_quantity`*p.`price` ELSE 0 END ),2) AS 'Total_restock_value',
ROUND(SUM(CASE WHEN `change_type` = 'Sale' THEN ABS(st.`change_quantity`)*ABS(p.`price`) ELSE 0 END ),2) AS 'Total_sales_value',
ROUND(SUM(CASE WHEN `change_type` = 'Restock' THEN st.`change_quantity`* p.`price` ELSE 0 END ) 
- SUM(CASE WHEN `change_type` = 'Sale' THEN ABS(st.`change_quantity`)*ABS(p.`price`) ELSE 0 END ),2) AS 'Net stock movement'
FROM stock_entries  AS st
LEFT JOIN products AS p
ON st.`product_id` = p.`product_id`
GROUP BY DATE_FORMAT(st.`entry_date`,'%y-%m')
ORDER BY `year_month`;

-- Productwise performance
-- We will see whch product sold most in quantitywise and how much value it generate and also show the stock in current inventory and their current reorder level

SELECT 
p.`product_id`,p.`product_name`,
SUM(CASE WHEN `change_type` = 'Sale' THEN ABS(st.`change_quantity`) END) AS 'Total_Sale_quantity',
ROUND(SUM(CASE WHEN `change_type` = 'Sale' THEN ABS(st.`change_quantity`)*ABS(p.`price`)END ),2) AS 'Total_sales_value',
SUM(CASE WHEN `change_type` = 'Restock' THEN ABS(st.`change_quantity`) END) AS 'Total_Stock_quantity'
FROM stock_entries  AS st
LEFT JOIN products AS p
ON st.`product_id` = p.`product_id`
GROUP BY p.`product_id`,p.`product_name`
ORDER BY `Total_Sale_quantity` DESC;

-- Slow moving product
-- Basically we will see which products sold quantity is less than or equal to 20% of stock quantity
-- That means it is blocking inventory
-- This is also call inventory turn over ratio = sold/stock
WITH prod_performance AS (
SELECT 
p.`product_id`,p.`product_name`,
SUM(CASE WHEN `change_type` = 'Sale' THEN ABS(st.`change_quantity`) END) AS 'Total_Sale_quantity',
SUM(CASE WHEN `change_type` = 'Restock' THEN ABS(st.`change_quantity`) END) AS 'Total_Stock_quantity'
FROM stock_entries  AS st
LEFT JOIN products AS p
ON st.`product_id` = p.`product_id`
GROUP BY p.`product_id`,p.`product_name`
ORDER BY `Total_Sale_quantity` DESC
) SELECT * FROM prod_performance WHERE (Total_Sale_quantity/Total_Stock_quantity) <= 0.20 
ORDER BY (Total_Sale_quantity/Total_Stock_quantity) ASC;





-- show suplier details table  - in that supplier name, contact name, phone , email
SELECT 
`supplier_name`,`contact_name`,`email`,`phone` 
FROM suppliers;

-- show product with supplier and stock
-- columns need = product_name, supplier_name, stock_quantity, reorder_level

SELECT 
p.`product_name`,
p.`stock_quantity`,p.`reorder_level`,s.`supplier_name`,
(p.`reorder_level`-p.`stock_quantity`)*1.10 AS 'quantity need to reorder'
-- The above order qty in such a way that stock will 10% more than reorder level
FROM products AS p
LEFT JOIN
suppliers AS s
ON p.`supplier_id`= s.`supplier_id`
WHERE p.`stock_quantity`<p.`reorder_level`
ORDER BY `product_name`;



-- Product required to reorder
-- columns = product_name, stock_quantity, reorder_level
SELECT 
`product_name`,
`stock_quantity`,`reorder_level`
FROM products
WHERE `stock_quantity`<`reorder_level`
ORDER BY `product_name`;


-- Add new product = product_name, category(drop down), price, stock_quantity, reorder_level, supplier_id
 
SELECT * FROM products;
DESCRIBE products;

SELECT * FROM shipments ORDER BY shipment_id DESC;
DESCRIBE shipments;

SELECT * FROM stock_entries ORDER BY `entry_id` DESC;
DESCRIBE stock_entries;

SHOW TABLES;

DROP PROCEDURE addnewproduct;

DELIMITER $$
CREATE PROCEDURE addnewproduct (
IN pname VARCHAR(200),
IN pcategory VARCHAR(200),
IN pprice FLOAT,
IN pquantity INT,
IN preorder INT,
IN psupplier_id INT
)

BEGIN
DECLARE pid INT; -- as i have added auto increment so commenting this line
DECLARE shipid INT;
-- DECLARE entid INT;

-- Changes in products table
-- SET pid = (SELECT MAX(`product_id`) FROM products) + 1; -- as i have added auto increment so commenting this line
INSERT INTO products(`product_name`, `category`, `price`, `stock_quantity`, `reorder_level`, `supplier_id`)
VALUES(pname,pcategory,pprice,pquantity,preorder,psupplier_id);

SET pid  = (SELECT MAX(`product_id`) FROM products);
-- Changes in shipment table
-- SET shipid = (SELECT MAX(`shipment_id`) FROM shipments) + 1;
INSERT INTO shipments ( `product_id`, `supplier_id`, `quantity_received`, `shipment_date`)
VALUES(pid,psupplier_id,pquantity,DATE(NOW()));

SET shipid = (SELECT MAX(`shipment_id`) FROM shipments);

-- Changes in stock_entries table
-- SET entid = (SELECT MAX(`entry_id`) FROM stock_entries) + 1;
INSERT INTO stock_entries ( `product_id`, `change_quantity`, `change_type`, `entry_date`)
VALUES(pid,pquantity,'Restock',DATE(NOW()));

END $$
DELIMITER ;



-- Product History
-- product_id,shipment_date,quantity, reorder_type
SELECT * FROM shipments; -- shipment_id, product_id, supplier_id, quantity_received, shipment_date
SELECT * FROM stock_entries; -- entry_id, product_id, change_quantity, change_type, entry_date

-- When product name and inventory history
CREATE VIEW product_inventory_history AS (
SELECT s.`product_id` AS 'id',p.`product_name` AS 'Product Name',s.`entry_date` AS 'Record Date', s.`change_quantity` AS 'Change in quantity', s.`change_type` AS 'Status',
SUM(s.`change_quantity`)OVER(PARTITION BY s.`product_id` ORDER BY s.`product_id`, s.`entry_date` ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS 'Final inventory quantity'
FROM stock_entries AS s
LEFT JOIN products AS p
ON s.`product_id` = p.`product_id`
ORDER BY s.`product_id`, `Record Date` DESC);


SELECT * FROM product_inventory_history;

-- When product name and shipment Details

CREATE VIEW product_shipment_history AS(
SELECT 
s.`product_id` AS 'id',p.`product_name` AS 'Product Name',su.`supplier_name` AS 'Supplier',s.`shipment_date` AS 'Record shipped Date',
s.`quantity_received` AS 'Quantity Shipped', 'Shipped' AS 'Status' 
FROM shipments AS s
LEFT JOIN products AS p
ON s.`product_id` = p.`product_id`
LEFT JOIN
suppliers AS su
ON s.`supplier_id` = su.`supplier_id`
ORDER BY s.`product_id`, s.`shipment_date` DESC);

SELECT * FROM product_shipment_history;
-- ----------------------------------------------------------------------------------------
-- Place Reorder
-- current staus

DELIMITER $$

CREATE PROCEDURE place_order(IN pname VARCHAR(200), IN pquant INT)

BEGIN
-- DECLARE re_id INT;
DECLARE p_id INT;

-- SET re_id = (SELECT MAX(`reorder_id`)+1 FROM reorders);

SET p_id = (SELECT MAX(`product_id`) FROM products WHERE `product_name` = pname); -- duplicate product_name so max used

INSERT INTO reorders(`reorder_id`, `product_id`, `reorder_quantity`, `reorder_date`, `status`)
VALUES(re_id,p_id,pquant,DATE(NOW()),'Ordered');

END $$

DELIMITER ;

-- CALL place_order('Next Device',50);

SELECT 
p.`product_id`,p.`product_name`,p.`stock_quantity`,p.`reorder_level`,
CAST(CEIL(p.`reorder_level`*1.10 - p.`stock_quantity`) AS SIGNED) AS 'Quantity Need to reorder (recommended)'
FROM products AS p
WHERE p.`stock_quantity`<= p.`reorder_level`;

SELECT * FROM reorders;

-- ------------------------------------------------------------------------------------------------------------------------
-- When an order maked as received then all table data need to update
-- We have to select the ordered status and update them to received

-- Create a procedure for updating reorders which got received

DELIMITER $$
CREATE PROCEDURE order_received(
IN reorderid VARCHAR(200)
)
BEGIN
DECLARE pid_r INT;
DECLARE qty INT;
DECLARE supid_r INT;
-- DECLARE shipid_r INT;
-- DECLARE entryid_r INT;

START TRANSACTION;

-- Get data for input reorder_id
SELECT `product_id`, `reorder_quantity`
INTO pid_r, qty
FROM reorders
WHERE `reorder_id` =  reorderid;

-- get supplier id
SELECT `supplier_id`
INTO supid_r 
FROM products WHERE `product_id` = pid_r;

-- update reorder table
UPDATE reorders
SET `status` = 'Received'
WHERE `reorder_id` = reorderid;

-- update product table
UPDATE products
SET `stock_quantity` = `stock_quantity`+qty
WHERE `product_id` = pid_r;

-- update the stock table

-- SET entryid_r = (SELECT MAX(`entry_id`)+1 FROM stock_entries);

INSERT INTO stock_entries(`product_id`, `change_quantity`, `change_type`, `entry_date`)
VALUES(pid_r,qty,'Restock',DATE(NOW()));

-- INSERT record into shipment table
-- SET shipid_r = (SELECT MAX(`shipment_id`)+1 FROM shipments);

INSERT INTO shipments( `product_id`, `supplier_id`, `quantity_received`, `shipment_date`)
VALUES(pid_r,supid_r,qty,DATE(NOW()));

COMMIT;
END$$
DELIMITER ;






