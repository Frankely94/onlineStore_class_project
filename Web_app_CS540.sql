drop database web_csc540;
create database  web_CSC540;
use web_CSC540;


/***********Table 1 Login and registration page *************/

drop table if exists accounts;
CREATE TABLE accounts (
id int AUTO_INCREMENT PRIMARY KEY,
username varchar(200),
password  varchar(200),
email varchar(250),
phone varchar(15),
street varchar(300),
city varchar(100),
state varchar(100),
country varchar(100),
userType varchar(100));

Insert into accounts VALUES (1,'admin',1234, 'fr@hotmail.com','345-567-7890','98 Norman St', 'Birdgeport', 'CT','US','admin' );
Insert into accounts VALUES (null,'jon','jon','j@hotmail.com', '345-567-9078','123 goat st', 'Orange', 'CT','US','user' );
Insert into accounts VALUES (null,'pit','pit','pt@hotmail.com', '345-567-0987','123 glen st', 'Milford', 'CT','US','user' );
select * from accounts;

/* *Table 2 for Broker and Inventory Managment */
drop table InventoryProductCatgeory;
create table InventoryProductCatgeory(
  InvProdid int auto_increment primary key,
  InvProdcategory varchar(100)
  );
    INSERT INTO InventoryProductCatgeory (InvProdcategory) VALUES 
('Electronics'),
('Fashion'),
('Home Decor'),
('Health and Beauty'),
('Sports and Outdoors');

select * from InventoryProductCatgeory;

/* *Table 3 for inventory Storage */

drop table Inventoryproduct;
truncate table Inventoryproduct;
create table Inventoryproduct(
  productid int auto_increment primary key,
  InvProdid int,
  productname varchar(100),
  price decimal(8,2),
  quantity int,
  foreign key (InvProdid) references InventoryProductCatgeory(InvProdid)
  );
   INSERT INTO Inventoryproduct (InvProdid, productname, price, quantity) VALUES 
(1, 'TechGenius Laptop', 1299.99, 15),
(1, 'SmartPlus Smartphone', 899.50, 20),
(2, 'CasualComfort T-Shirt', 19.99, 100),
(2, 'DenimDynasty Jeans', 39.95, 50),
(3, 'GreenGrip Garden Hose', 29.99, 75),
(3, 'NatureEase Plant Pot', 9.50, 120),
(4, 'SilkShine Shampoo', 5.99, 200),
(4, 'GlowFresh Face Cream', 12.75, 80),
(5, 'FlexiFlow Yoga Mat', 20.00, 30),
(5, 'StrideMax Running Shoes', 79.99, 25);

select * from Inventoryproduct;
delete i from Inventoryproduct as i join InventoryProductCatgeory as n on i.InvProdid = n.InvProdid
where i.InvProdid = 5;


  

#################### View for consolidated report in inventoryReport screen ####################
SELECT
    ipc.InvProdcategory AS category,
    ipc.invprodid,
    COALESCE(SUM(quantity), 0) AS totalquantity
FROM
    InventoryProductCatgeory ipc ;



select category,totalquantity from Inventorydetails;
DROP VIEW IF EXISTS Inventorydetails; 
CREATE VIEW Inventorydetails AS
SELECT
    ipc.InvProdcategory AS category,
    ipc.invprodid,
    COALESCE(SUM(quantity), 0) AS totalquantity
FROM
    InventoryProductCatgeory ipc
LEFT JOIN
    Inventoryproduct ip ON ipc.invprodid = ip.invprodid
GROUP BY
    ipc.invprodid, ipc.InvProdcategory
ORDER BY
    COALESCE(SUM(quantity), 0) ASC;
 
select count(invprodid) as cnt from InventoryProductCatgeory where InvProdcategory='gar';
#################### View for current detail report in inventory report screen ####################

drop view getDetailedData;

CREATE VIEW getDetailedData AS
    SELECT ip.productid as pid , ip.productname as pname , ip.quantity as qn,
    ip.price as pr, ipc.InvProdcategory as pg
    FROM Inventoryproduct ip
    JOIN InventoryProductCatgeory ipc ON ip.invprodid = ipc.invprodid;
    SELECT pname,qn,pr,pg FROM getDetailedData WHERE pg = 'fashion';


############## Table 4 storing the tracked inventory data (for inser and update) ##############
drop table trackInventoryData;
create table trackInventoryData (
productid int,
productname varchar(200),
product_category varchar(100),
quantity int,
price decimal(8,2),
updatedDate timestamp
);


############### Table 5 storing the deleted data  ##############

drop table trackInventoryDeletedData;
create table trackInventoryDeletedData (
productid int,
productname varchar(200),
product_category varchar(100),
quantity int,
price decimal(8,2),
updatedDate timestamp
);

#################### Trigger for updating the inventory Data ####################

DROP TRIGGER IF EXISTS track_INVdata;
DELIMITER //
CREATE TRIGGER track_INVdata
After UPDATE ON Inventoryproduct
FOR EACH ROW
BEGIN
    DECLARE pc VARCHAR(100);
    SET pc = (SELECT InvProdcategory FROM InventoryProductCatgeory WHERE invprodid = new.InvProdId);

    INSERT INTO trackInventoryData (productid, productname, product_category, quantity, price, updatedDate)
    VALUES (new.productid, new.productname, pc, new.quantity, new.price, CURRENT_TIMESTAMP());
END //
DELIMITER ;




#################### Trigger for insert the inventory Data ####################

DROP TRIGGER IF EXISTS track_INVadddata;
DELIMITER //
CREATE TRIGGER track_INVadddata
After insert ON Inventoryproduct
FOR EACH ROW
BEGIN
    DECLARE pc VARCHAR(100);
    SET pc = (SELECT InvProdcategory FROM InventoryProductCatgeory WHERE invprodid = new.InvProdId);

    INSERT INTO trackInventoryData (productid, productname, product_category, quantity, price, updatedDate)
    VALUES (new.productid, new.productname, pc, new.quantity, new.price, CURRENT_TIMESTAMP());
END //
DELIMITER ;


#################### Trigger for after deletion on inveotory Product Table ####################

DROP TRIGGER IF EXISTS track_INVdeletedata;
DELIMITER //
CREATE TRIGGER track_INVdeletedata
After delete ON Inventoryproduct
FOR EACH ROW
BEGIN
    DECLARE pc VARCHAR(100);
    SET pc = (SELECT InvProdcategory FROM InventoryProductCatgeory WHERE invprodid = old.InvProdId);

    INSERT INTO trackInventoryDeletedData (productid, productname, product_category, quantity, price, updatedDate)
    VALUES (old.productid, old.productname, pc, old.quantity, old.price, CURRENT_TIMESTAMP());
END //
DELIMITER ;


drop table Customer_product;
 create table Customer_product(
  productid int primary key,
  productname varchar(300),
  product_category varchar(200),
  quantity int,
  price decimal(8,2),
  isAvailable char
 );

 


INSERT INTO  Customer_product(productid,productname,product_category, quantity,price,isAvailable) VALUES 
(1, 'TechGenius Laptop','Electronics',15, 1299.99, 'Y'),
(2, 'SmartPlus Smartphone','Electronics', 20, 899.50, 'Y'),
(3, 'CasualComfort T-Shirt','Fashion',100,  19.99, 'Y'),
(4, 'DenimDynasty Jeans','Fashion',50,  39.95, 'Y'),
(5, 'GreenGrip Garden Hose','Home Decor', 75, 29.99, 'Y'),
(6, 'NatureEase Plant Pot','Home Decor',120, 9.50, 'Y'),
(7, 'SilkShine Shampoo', 'Health and Beauty', 200,5.99, 'Y'),
(8,'GlowFresh Face Cream','Health and Beauty', 80, 12.75, 'Y'),
(9,'FlexiFlow Yoga Mat','Sports and Outdoors',30,  20.00, 'Y'),
(10, 'StrideMax Running Shoes','Sports and Outdoors',25, 79.99, 'Y');



select * from Customer_product;


############################## Trigger for updating customer product table from inventory Product table when there is a change #############
DROP TRIGGER IF EXISTS prodUpdate;
DELIMITER //
CREATE TRIGGER prodUpdate
After UPDATE ON Inventoryproduct
FOR EACH ROW
BEGIN
    DECLARE pc VARCHAR(100);
     Declare updatedPrice decimal(8,2);
     Declare flag char;
    SET pc = (SELECT InvProdcategory FROM InventoryProductCatgeory WHERE invprodid = new.InvProdId);
    SET updatedPrice=new.price*1.10;
    if (new.quantity >0) then 
    set flag ='Y'; 
    else set flag ='N' ;
    end if;
    Update Customer_product set productname=new.productname,
    product_category=PC,quantity=new.quantity,price=updatedPrice, isAvailable=flag
    where productid=new.productid;

END //
DELIMITER ;


############################## Trigger for inserting into customer product table from inventory Product table when there is a change #############
DROP TRIGGER IF EXISTS prodInsert;
DELIMITER //
CREATE TRIGGER prodInsert
After insert ON Inventoryproduct
FOR EACH ROW
BEGIN
    DECLARE pc VARCHAR(100);
    Declare updatedPrice decimal(8,2);
	Declare flag char;
    SET pc = (SELECT InvProdcategory FROM InventoryProductCatgeory WHERE invprodid = new.InvProdId);
      SET updatedPrice=new.price*1.10;
	if (new.quantity >0) then 
    set flag ='Y'; 
    else set flag ='N' ;
    end if;
    INSERT INTO Customer_product (productid, productname, product_category, quantity, price,isAvailable)
    VALUES (new.productid, new.productname, pc, new.quantity, updatedPrice,flag);
    
END //
DELIMITER ;

############################## Trigger for deleting customer product table from inventory Product table when there is a change #############
DROP TRIGGER IF EXISTS ProdDelete;
DELIMITER //
CREATE TRIGGER ProdDelete
After delete ON Inventoryproduct
FOR EACH ROW
BEGIN
      Delete from Customer_product where productid= old.productid;
END //
DELIMITER ;

############################## Trigger for decrementing quantity in Inventory product after customer placed #############
drop trigger if exists DecrementInventoryQuantity;
DELIMITER //
CREATE TRIGGER DecrementInventoryQuantity
After Insert ON orders
FOR EACH ROW
BEGIN
    #IF NEW.placeOrder = 'yes' THEN
        update Inventoryproduct set quantity= quantity -1 where productname =new.product;
    #END IF;
END //
DELIMITER ;

######################## customer and seller activity queries########################

/********* All total number and profit result procedure**********/
Drop procedure if exists GetBrokerResult;
DELIMITER //
CREATE PROCEDURE GetBrokerResult()
BEGIN
 select count(id) as total_count from accounts where userType="user";
select count(id) as total_count from accounts where userType="seller";
select count(main) as totalsales from Orders;
select sum(price) as totalprice from Orders;
END //
DELIMITER ;
call GetBrokerResult();

/*********** get customer, customer email, seller and seller email for dropdowns*********/
select  username, email from accounts where userType='user';
select  username, email from accounts where userType='seller';

/*********** get customer Detailed list StoredProcedure*********/
Drop procedure if exists GetcustomerViewResult;
DELIMITER //
CREATE PROCEDURE GetcustomerViewResult(id int)
BEGIN
  select sum(price) as tp,count(main) as tq from orders where userid =id;
  select product,price,updatedDate from orders where userid =id ;
END //
DELIMITER ;
call GetcustomerViewResult(1);

########################################### customer Tables : this tables track TRANSATION, CART, ##################################

drop table if exists cart;
CREATE TABLE cart (
  Id int NOT NULL AUTO_INCREMENT,
  user_id int not null,
  PRIMARY KEY (Id),
  foreign key (user_id) references accounts(Id)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


SELECT Id FROM cart WHERE user_id = (SELECT id FROM accounts WHERE username = 'admin');
insert into cart values (2,1);
INSERT INTO cart (user_Id) SELECT id FROM accounts WHERE username ='jon';
select * from cart;

drop table if exists cartproducts;
CREATE TABLE cartproducts (
  main_id int auto_increment, 
  cart_Id int NOT NULL,
  product_id int NOT NULL,
  foreign key (cart_id) references cart(Id),
  foreign key (product_id) references Customer_product(productid), 
  primary key(main_id)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


insert into cartproducts values (null,2,5);
DELETE FROM cartproducts WHERE cart_Id = 2 AND product_id =5 ;
INSERT INTO cartproducts (cart_Id,product_Id) VALUES (2,6);
select * from cartproducts ; 

SELECT product_id FROM cartproducts WHERE cart_Id = (SELECT Id FROM cart WHERE user_id = '1');

DROP TABLE IF EXISTS ShippingDetails;

CREATE TABLE ShippingDetails (
  Id int NOT NULL AUTO_INCREMENT,
  UserId int DEFAULT NULL,
  Full_Name varchar(255) DEFAULT NULL,
  Street_Address varchar(255) DEFAULT NULL,
  City varchar(255) DEFAULT NULL,
  State_Province varchar(255) DEFAULT NULL,
  Postal_Code varchar(255) DEFAULT NULL,
  Country varchar(255) DEFAULT NULL,
  PRIMARY KEY (Id),
  FOREIGN KEY (UserId) REFERENCES accounts(id)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

select * from ShippingDetails;


DROP TABLE IF EXISTS Orders;

CREATE TABLE Orders (
  main int not null auto_increment,
  order_Id int ,
  UserId int NOT NULL,
  product varchar(100),
  price decimal(10,2)  NULL,
  updatedDate timestamp,
  FOREIGN KEY (UserId) REFERENCES accounts (id),
  primary key(main)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
select * from Orders;

select userid, sum(price) from orders where UserId = 1;

select order_id,UserId,product,price as price_per_unit, count(*) as quantity_of_product_for_users from orders group by order_id,UserId,product,price;











drop procedure if exists GetTotal;
DELIMITER //
#################################store procedure
CREATE PROCEDURE GetTotal(IN username varchar(20))
BEGIN
	SELECT SUM(P.Price)
    FROM cartproducts as CP
    JOIN customer_product as P ON CP.product_Id = P.productid
    JOIN cart as C ON CP.cart_Id = C.Id
    JOIN accounts as U ON C.user_Id = U.Id
    WHERE U.username = username;
        
END
// DELIMITER ;

CALL GetTotal('admin');


SELECT P.productname
    FROM cartproducts as CP
    JOIN customer_product as P ON CP.product_Id = P.productid
    JOIN cart as C ON CP.cart_Id = C.Id
    JOIN accounts as U ON C.user_Id = U.Id
    WHERE U.username = username;
    
    
    /*insert into orders (order_Id, userid, product, price, updatedDate) 
	SELECT c.id, u.id, P.productname, P.price, CURRENT_TIMESTAMP()
    FROM cartproducts CP
    JOIN Customer_product P ON CP.product_id = P.productid
    JOIN cart C ON CP.cart_Id = C.Id
    JOIN accounts U ON C.user_id = U.id
    WHERE U.username = 'admin';*/
    
    insert into orders (order_Id, userid, product, price, updatedDate) 
	SELECT c.id, u.id, P.productname, P.price, CURRENT_TIMESTAMP()
    FROM cartproducts CP
    JOIN Customer_product P ON CP.product_id = P.productid
    JOIN cart C ON CP.cart_Id = C.Id
    JOIN accounts U ON C.user_id = U.id
    WHERE U.username = 'admin';
    
    insert into orders values(1,1,1,"xcv pants",10.50,CURDATE());
insert into orders values(2,1,1,"xcv pants",100.00,CURDATE());


################## UPDATE INVENTORY PRODUCT ################
drop trigger if exists after_orders_insert;
 
DELIMITER //
CREATE TRIGGER after_orders_insert
AFTER INSERT ON Orders
FOR EACH ROW
BEGIN
    DECLARE product_quantity INT;
 
    -- Get the quantity of the product from the inserted row
    SELECT COUNT(*) INTO product_quantity
    FROM Orders
    WHERE product = NEW.product;
 
    -- Subtract the quantity from the Inventoryproduct table
    UPDATE Inventoryproduct
    SET quantity = quantity - product_quantity
    WHERE productname = NEW.product;
END;
//
DELIMITER ;



############################## to subtract the product qunatiy end user place the order it #####################
 
CREATE TABLE OrderedProduct  (

  main int not null auto_increment,
  order_Id int ,
  UserId int NOT NULL,
  product varchar(100),
  price decimal(10,2)  NULL,
  updatedDate timestamp,
  primary key(main)
);

select * from OrderedProduct;
 drop procedure if exists ProcessOrders;
 
DELIMITER //

CREATE PROCEDURE ProcessOrders()
BEGIN
  DECLARE orderIdValue INT;
  DECLARE userIdValue INT;
  DECLARE productValue VARCHAR(100);
  DECLARE priceValue DECIMAL(10,2);
  DECLARE currentDate TIMESTAMP;
  DECLARE ordersCursor CURSOR FOR
    SELECT order_Id, UserId, product, price, updatedDate
    FROM Orders;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET @done = TRUE;
  START TRANSACTION;
  OPEN ordersCursor;
  ordersLoop: LOOP
     FETCH ordersCursor INTO orderIdValue, userIdValue, productValue, priceValue, currentDate;
    IF @done THEN
      LEAVE ordersLoop;
    END IF;
    INSERT INTO OrderedProduct (order_Id, UserId, product, price, updatedDate)
    VALUES (orderIdValue, userIdValue, productValue, priceValue, currentDate);
    UPDATE InventoryProduct
    SET quantity = quantity - 1
    WHERE productname = productValue;
  END LOOP;
  CLOSE ordersCursor;
  TRUNCATE TABLE Orders;
   COMMIT;
END // DELIMITER ;


################################### seller Database########################################
CREATE TABLE sellers (
    seller_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255),
    email VARCHAR(255)
);
INSERT INTO sellers (name, email) VALUES
('John Doe', 'john.doe@example.com'),
('Alice Johnson', 'alice.johnson@example.com'),
('Bob Smith', 'bob.smith@example.com'),
('Cindy White', 'cindy.white@example.com'),
('Dave Brown', 'dave.brown@example.com'),
('Emily Davis', 'emily.davis@example.com'),
('Frank Miller', 'frank.miller@example.com'),
('Grace Wilson', 'grace.wilson@example.com'),
('Henry Taylor', 'henry.taylor@example.com'),
('Irene Anderson', 'irene.anderson@example.com');

CREATE TABLE seller_product_category (
    id INT PRIMARY KEY AUTO_INCREMENT,
    seller_id INT,
    product_category VARCHAR(255),
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
);
INSERT INTO seller_product_category (seller_id, product_category) VALUES
(1, 'Electronics'),
(2, 'Home Appliances'),
(3, 'Sporting Goods'),
(4, 'Fashion'),
(5, 'Beauty Products'),
(6, 'Books'),
(7, 'Gardening Tools'),
(8, 'Kitchenware'),
(9, 'Pet Supplies'),
(10, 'Toys & Games');
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    name VARCHAR(255),
    description VARCHAR(255),
    price DECIMAL(10, 2)
);
INSERT INTO products (product_id, name, item_category, price)
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

ALTER TABLE products
ADD COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE products CHANGE description item_category VARCHAR(255);
ALTER TABLE products
ADD COLUMN seller_id INT;

ALTER TABLE products
ADD COLUMN quantity int;

ALTER TABLE products
ADD FOREIGN KEY (seller_id) REFERENCES sellers(seller_id);

UPDATE products SET quantity = 1 WHERE product_id IN (1, 2, 3);
UPDATE products SET quantity = 2 WHERE product_id IN (4, 5, 6);
-- and so on for other sellers and products
-- Continuing the updates for seller_id in products
UPDATE products SET seller_id = 1 WHERE product_id IN (1, 2, 3);
UPDATE products SET seller_id = 2 WHERE product_id IN (4, 5, 6);
-- and so on for other sellers and products
-- Continuing the updates for seller_id in products
UPDATE products SET seller_id = 3 WHERE product_id IN (7, 8, 9);
UPDATE products SET seller_id = 4 WHERE product_id IN (10, 11, 12);
UPDATE products SET seller_id = 5 WHERE product_id IN (13, 14, 15);
UPDATE products SET seller_id = 6 WHERE product_id IN (16, 17, 18);
UPDATE products SET seller_id = 7 WHERE product_id IN (19, 20, 21);
UPDATE products SET seller_id = 8 WHERE product_id IN (22, 23, 24);
UPDATE products SET seller_id = 9 WHERE product_id IN (25, 26, 27);
UPDATE products SET seller_id = 10 WHERE product_id IN (28, 29, 30);


SELECT p.product_id, p.name AS product_name, p.item_category, p.quantity, p.price, s.name AS seller_name, s.email AS seller_email, spc.product_category AS seller_product_category
FROM products p
JOIN sellers s ON p.seller_id = s.seller_id
JOIN seller_product_category spc ON s.seller_id = spc.seller_id;


SELECT p.product_id, p.name AS product_name, p.item_category, p.price, 
       s.name AS seller_name, s.email AS seller_email, 
       spc.product_category AS seller_product_category
FROM products p
JOIN sellers s ON p.seller_id = s.seller_id
JOIN seller_product_category spc ON s.seller_id = spc.seller_id;

create view sellerData as(
SELECT p.product_id, p.name AS product_name, p.item_category, p.quantity, p.price, s.name AS seller_name, s.email AS seller_email, spc.product_category AS seller_product_category
FROM products p
JOIN sellers s ON p.seller_id = s.seller_id
JOIN seller_product_category spc ON s.seller_id = spc.seller_id);

select seller_name,seller_email from sellerdata group by seller_name,seller_email;  # for taking seller name and email
with sellerTable(seller_name,seller_email) as(select seller_name,seller_email from sellerdata group by seller_name,seller_email)
select count(*) as totalSeller from sellerTable;
select sum(quantity) as tqs from sellerdata; #total no of products added by seller
select sum(quantity)  as stq from sellerdata where seller_name='John Doe'and seller_email='john.doe@example.com'; #total no of products added by seller
select sum(price) as tps from sellerdata;# overall profit quired
select sum(price)  as stp from sellerdata where seller_name='John Doe'and seller_email='john.doe@example.com'; #total price added by seller
select product_name,price,quantity,seller_product_category  as stp from sellerdata where seller_name='John Doe'and seller_email='john.doe@example.com';

######################## customer and seller activity queries########################

/********* All total number and profit result procedure**********/
Drop procedure if exists GetBrokerResult;
DELIMITER //
CREATE PROCEDURE GetBrokerResult()
BEGIN
 select count(id) as totalcustomer from accounts where userType="user"; #total no of user
#select count(id) as total_count from accounts where userType="seller";
with sellerTable(seller_name,seller_email) as(select seller_name,seller_email from sellerdata group by seller_name,seller_email)
select count(*) as totalSeller from sellerTable; #total no of seller
select count(main) as totalsales from Orderedproduct; # need to recheck with hugh and frank
select sum(price) as totalprice from Orderedproduct; # total profit from customer need to recheck with hugh and frank
select sum(price) as tps from sellerdata;# overall profit acquired from seller
END //
DELIMITER ;
call GetBrokerResult();

/*********** get customer, customer email, seller and seller email for dropdowns*********/
select  username, email from accounts where userType='user';
select seller_name,seller_email from sellerdata group by seller_name,seller_email;  
#select  username, email from accounts where userType='seller';

/*********** get Seller Detailed list StoredProcedure*********/
Drop procedure if exists GetSellerViewResult;
DELIMITER //
CREATE PROCEDURE GetSellerViewResult(sellername varchar(200),selleremail varchar(300))
BEGIN
  select sum(quantity)  as stq from sellerdata where 
seller_name=sellername and seller_email=selleremail; #total no of products added by seller
  select sum(price)  as stp from sellerdata where seller_name=sellername and seller_email=selleremail; #total price added by seller
  select product_name,price,quantity,seller_product_category  as stp from sellerdata 
  where seller_name=sellername and seller_email=selleremail;
END //
DELIMITER ;
call GetSellerViewResult('John Doe','john.doe@example.com');

/*********** get customer Detailed list StoredProcedure*********/
Drop procedure if exists GetcustomerViewResult;
DELIMITER //
CREATE PROCEDURE GetcustomerViewResult(id int)
BEGIN
  select sum(price) as tp,count(main) as tq from Orderedproduct where userid =id;
  select product,price,updatedDate from Orderedproduct where userid =id ;
END //
DELIMITER ;
call GetcustomerViewResult(1);




