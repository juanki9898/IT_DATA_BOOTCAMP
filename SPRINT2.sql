-- nivell 1 ex 2.1
SELECT DISTINCT company.country
FROM company
INNER JOIN transaction ON transaction.company_id = company.id AND transaction.declined = FALSE;

-- nivell 1 ex 2.2
SELECT COUNT( DISTINCT company.country)
FROM company
INNER JOIN transaction ON transaction.company_id = company.id AND transaction.declined = FALSE;

-- nivell 1 ex 2.3
SELECT company.company_name, AVG(transaction.amount) AS avg_transaction
FROM company
JOIN transaction ON transaction.company_id = company.id AND transaction.declined = FALSE
GROUP BY company.company_name
ORDER BY avg_transaction DESC
LIMIT 1;

-- nivell 1 ex 3.1
SELECT * 
FROM transaction
WHERE declined = FALSE 
AND company_id IN (
    SELECT id 
    FROM company 
    WHERE country = 'Germany'
);
-- nivell 1 ex 3.2
SELECT DISTINCT company_name 
FROM company 
WHERE id IN (
    SELECT company_id 
    FROM transaction 
    WHERE amount > (SELECT AVG(amount) FROM transaction WHERE declined = FALSE) AND declined = FALSE
);

-- nivell 1 ex 3.3
SELECT DISTINCT * FROM company WHERE id NOT IN(SELECT company_id FROM transaction);

-- nivell 2 ex 1.1

SELECT DATE(timestamp) as date, sum(amount) as total
FROM transaction
WHERE declined = FALSE
GROUP BY date
ORDER BY total DESC
LIMIT 5;

-- nivell 2 ex 1.2

SELECT country, AVG(transaction.amount) AS avg_transaction
FROM company
JOIN transaction ON transaction.company_id = company.id AND transaction.declined = FALSE
GROUP BY country
ORDER BY avg_transaction DESC;

-- nivell 2 ex 1.3
-- OPCION JOIN
SELECT *
FROM transaction
JOIN company ON transaction.company_id = company.id AND transaction.declined = FALSE
WHERE company.country = (SELECT country FROM company WHERE company_name='Non Institute') AND company_name != 'Non Institute';

-- OPCION SUBQUERY

SELECT *
FROM transaction
WHERE company_id IN( 
	SELECT id 
    FROM company 
    WHERE country = ((SELECT country FROM company WHERE company_name='Non Institute')) AND company_name != 'Non Institute');
    

-- nivell 3 ex 1.1
SELECT DISTINCT company_name, phone, country, date(transaction.timestamp), transaction.amount
FROM company 
INNER JOIN transaction ON 
transaction.company_id = company.id AND transaction.declined = FALSE 
	AND (date(transaction.timestamp) = '2021-04-29' OR date(transaction.timestamp) = '2021-07-20' OR 
	date(transaction.timestamp)='2022-03-13') AND (amount>100 AND amount<200)
ORDER BY amount DESC;

-- nivell 3 ex 1.2
SELECT DISTINCT company_name, count(transaction.id) as qt, (count(transaction.id) > 4) as condicio
FROM company 
INNER JOIN transaction ON 
transaction.company_id = company.id AND transaction.declined = FALSE
GROUP BY company_name
ORDER BY qt DESC;