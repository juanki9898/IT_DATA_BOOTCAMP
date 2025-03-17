-- SPRINT 4
CREATE DATABASE IF NOT EXISTS transactionsCSV;
USE transactionsCSV;
    
-- id,user_id,iban,pan,pin,cvv,track1,track2,expiring_date
CREATE TABLE IF NOT EXISTS credit_card (
        id VARCHAR(20) PRIMARY KEY,
        user_id INT,
        iban VARCHAR(50),
        pan VARCHAR(20), 
        pin VARCHAR(4),
        cvv VARCHAR(3),
        track1 VARCHAR(60),
        track2 VARCHAR(60),
        expiring_date VARCHAR(20)
    );
    
    -- company_id,company_name,phone,email,country,website
    CREATE TABLE IF NOT EXISTS company(
        company_id VARCHAR(20) PRIMARY KEY,
        company_name VARCHAR(255),
        phone VARCHAR(15), 
        email VARCHAR(100),
        country VARCHAR(100),
        website VARCHAR(300)
    );
    
-- id,name,surname,phone,email,birth_date,country,city,postal_code,address
CREATE TABLE IF NOT EXISTS user (
        id INT PRIMARY KEY,
        name VARCHAR(100),
        surname VARCHAR(100),
        phone VARCHAR(150),
        email VARCHAR(150),
        birth_date VARCHAR(100),
        country VARCHAR(150),
        city VARCHAR(150),
        postal_code VARCHAR(100),
        address VARCHAR(255)      
    );
    
    -- id,product_name,price,colour,weight,warehouse_id
    CREATE TABLE IF NOT EXISTS product (
        id INT AUTO_INCREMENT PRIMARY KEY,
        product_name VARCHAR(50),
        price VARCHAR(30), 
		colour VARCHAR(20),
        weight decimal(10,2),
        warehouse_id VARCHAR(20)
    );
    
-- id;card_id;business_id;timestamp;amount;declined;product_ids;user_id;lat;longitude
    CREATE TABLE IF NOT EXISTS transaction (
        id VARCHAR(255) PRIMARY KEY,
        card_id VARCHAR(20),
        business_id VARCHAR(20), 
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		amount decimal(10,2),
        declined tinyint,
        products_ids VARCHAR(255),
        user_id INT,
        lat float,
        longitude float,
		FOREIGN KEY (card_id) REFERENCES credit_card(id),
		FOREIGN KEY (business_id) REFERENCES company(company_id),
		FOREIGN KEY (user_id) REFERENCES user(id)
    );
    
-- Rellenar las tablas
SET GLOBAL local_infile=1;

LOAD DATA LOCAL INFILE 'C:/Users/juanc/Documents/SPRINT4/companies.csv' INTO TABLE transactionscsv.company
FIELDS TERMINATED BY ','
ENCLOSED BY ''
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/juanc/Documents/SPRINT4/credit_cards.csv' INTO TABLE transactionscsv.credit_card
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/juanc/Documents/SPRINT4/users_ca.csv' INTO TABLE transactionscsv.user
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/juanc/Documents/SPRINT4/users_uk.csv' INTO TABLE transactionscsv.user
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/juanc/Documents/SPRINT4/users_usa.csv' INTO TABLE transactionscsv.user
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/juanc/Documents/SPRINT4/products.csv' INTO TABLE transactionscsv.product
FIELDS TERMINATED BY ','
ENCLOSED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/juanc/Documents/SPRINT4/transactions.csv' INTO TABLE transactionscsv.transaction
FIELDS TERMINATED BY ';'
ENCLOSED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

SET GLOBAL local_infile=0;

-- Eliminamos el $ que se encuentra en la primera posición del string de price
SET SQL_SAFE_UPDATES = 0;
UPDATE product 
SET price= SUBSTR(price,2);

-- Cambiamos el tipo de la columna price de varchar a decimal
ALTER TABLE product
MODIFY COLUMN price decimal(10,2);
-- cerrar safe updates

-- Cambiamos la fecha de VARCHAR a DATE modificando el tipo de la columna birth_date
UPDATE user 
SET birth_date = STR_TO_DATE(birth_date, '%b %d, %Y');

-- Cambiamos la fecha de caducidad de VARCHAR a DATE modificando el tipo de la columna birth_date
UPDATE credit_card 
SET expiring_date = STR_TO_DATE(expiring_date, '%m/%d/%y');

ALTER TABLE credit_card MODIFY COLUMN expiring_date DATE;

CREATE TABLE IF NOT EXISTS transaction_product (
	product_id INT NOT NULL,
	transaction_id VARCHAR(255) NOT NULL,
	PRIMARY KEY (product_id, transaction_id),
	FOREIGN KEY (product_id) REFERENCES product(id),
	FOREIGN KEY (transaction_id) REFERENCES transaction(id)
);

-- EXPLICACION teniendo en cuenta no declined, utilizamos FIND_IN_SET como condicion para asociar cada product_id con su transaction_id
INSERT INTO transaction_product (product_id, transaction_id) 
SELECT product.id as product_id, transaction.id as transaction_id
FROM product
JOIN transaction on FIND_IN_SET(product.id, REPLACE (products_ids, " ", ""))>0
WHERE declined=0;

-- Ejercicio 1 nivel 1 contando transacciones declined como no declined
SELECT user.id,name,surname,phone,email,birth_date,country,city,postal_code,address, count(user.id) as contador_transacciones
FROM user
JOIN transaction ON user_id=user.id
GROUP BY user.id, name, surname, phone, email, birth_date, country,city, postal_code, address
HAVING contador_transacciones > 30;

-- Ejercicio 1 nivel 1 contando solo transacciones no declined
SELECT user.id,name,surname,phone,email,birth_date,country,city,postal_code,address, count(user.id) as contador_transacciones
FROM user
JOIN transaction ON user_id=user.id
WHERE declined = 0
GROUP BY user.id, name, surname, phone, email, birth_date, country,city, postal_code, address
HAVING contador_transacciones > 30;

-- Ejercicio 2 nivel 2
-- Seleccionamos el iban, nombre de la compañia y la media de las transacciones de la empresa Donec Ltd 
-- haciendo JOIN de las tablas transaction, company y credit_card, teniendo en cuenta declined y no declined
SELECT iban, company_name, round(AVG(amount),2) as mitjana
FROM transaction
JOIN company on business_id = company.company_id
JOIN credit_card on card_id=credit_card.id
WHERE company_name='Donec Ltd'
GROUP BY iban, company_name;

-- Ejercicio 1 nivel 2
-- Creamos una vista status_card, utilizando RANK para obtener las ultimas transacciones de forma descendiente
-- filtramos por las 3 ultimas, agrupamos por card_id y comprobamos que el estado de declined suma 3 para saber si las 3 ultimas han sido declined
-- y asignamos "Desactivated" o "Active" a cada tarjeta si se cumple la condición
CREATE VIEW status_card AS
SELECT 
		card_id, 
        IF(SUM(declined)=3, "Desactivated", "Active") AS card_status
FROM (SELECT 	
		card_id, 
		timestamp, 
		declined,
        RANK() OVER (PARTITION BY card_id ORDER BY timestamp DESC) AS ultimas
		FROM transaction) AS inter
WHERE ultimas <= 3
GROUP BY card_id;

-- Realizamos la cuenta de las Active, en este caso todas las cards estan activas
SELECT COUNT("Active") 
FROM status_card;


-- Ejercicio 2 nivel 3. Dir el nombre de cops que s'ha venut cada producte
-- Con todos los products id, incluso los productos de 0 veces

SELECT DISTINCT product.id, product_name, COUNT(product_id) AS veces
FROM product
LEFT JOIN transaction_product ON product_id=product.id
GROUP BY product.id;
