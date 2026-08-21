/*
SQL PROJECT: FINANCIAL TRANSACTION ANALYSIS
Tool: PostgreSQL / pgAdmin 4

This project looks at:
- Customers
- Cards
- Transactions
- Errors
- Online transactions
- Joins between the tables
*/


-- Creating the users table
CREATE TABLE users_data (
id INTEGER,
current_age INTEGER,
retirement_age INTEGER,
birth_year INTEGER,
birth_month INTEGER,
gender TEXT,
address TEXT,
latitude NUMERIC,
longitude NUMERIC,
per_capital_income TEXT,
yearly_income TEXT,
total_debt TEXT,
credit_score INTEGER,
num_credit_cards INTEGER
);


-- Creating the cards table
CREATE TABLE cards_data (
id INTEGER,
client_id INTEGER,
card_brand TEXT,
card_type TEXT,
card_number TEXT,
expires TEXT,
cvv TEXT,
has_chip TEXT,
num_cards_issued INTEGER,
credit_limit TEXT,
account_open_date TEXT,
year_pin_last_changed INTEGER,
card_on_dark_web TEXT
);


-- Creating the transactions table
-- Amount is TEXT because the original data has a $ sign
CREATE TABLE transactions_data (
id INTEGER,
date TIMESTAMP,
client_id INTEGER,
card_id INTEGER,
amount TEXT,
use_chip TEXT,
merchant_id BIGINT,
merchant_city TEXT,
merchant_state TEXT,
zip TEXT,
mcc INTEGER,
errors TEXT
);


-- Imported the CSV files into PostgreSQL using pgAdmin 4


/* =========================
CUSTOMER DATA CLEANING
========================= */


-- Checking if there are duplicate customer IDs
SELECT id,COUNT(*) AS number_of_records
FROM users_data
GROUP BY id
HAVING COUNT(*)>1;

-- Output: No duplicate customer IDs


-- Checking for missing values
SELECT COUNT(*) FILTER (WHERE id IS NULL) AS missing_id,
COUNT(*) FILTER (WHERE current_age IS NULL) AS missing_age,
COUNT(*) FILTER (WHERE gender IS NULL) AS missing_gender,
COUNT(*) FILTER (WHERE per_capital_income IS NULL) AS missing_per_capital_income,
COUNT(*) FILTER (WHERE yearly_income IS NULL) AS missing_yearly_income,
COUNT(*) FILTER (WHERE total_debt IS NULL) AS missing_total_debt,
COUNT(*) FILTER (WHERE credit_score IS NULL) AS missing_credit_score
FROM users_data;

-- Output: No missing values in the customer columns that I checked


-- Creating a clean version so that I do not change the original data
-- Removing the $ sign and changing money columns to NUMERIC
CREATE TABLE clean_users_data AS
SELECT id AS customer_id,
current_age,
retirement_age,
birth_year,
birth_month,
gender,
address,
latitude,
longitude,
REPLACE(per_capital_income,'$','')::NUMERIC AS per_capita_income,
REPLACE(yearly_income,'$','')::NUMERIC AS yearly_income,
REPLACE(total_debt,'$','')::NUMERIC AS total_debt,
credit_score,
num_credit_cards
FROM users_data;


-- Checking the number of customers
SELECT COUNT(*) AS total_customers
FROM clean_users_data;

-- Output: 2000 customers


-- Checking that all customer IDs are still unique
SELECT COUNT(*) AS total_rows,
COUNT(DISTINCT customer_id) AS unique_customers
FROM clean_users_data;

-- Output: 2000 rows and 2000 unique customers


-- Adding the primary key
ALTER TABLE clean_users_data
ADD PRIMARY KEY (customer_id);


/* =========================
CUSTOMER EDA
========================= */


-- Checking the age range and average age
SELECT MIN(current_age) AS minimum_age,
MAX(current_age) AS maximum_age,
ROUND(AVG(current_age),2) AS average_age
FROM clean_users_data;

-- Output: Minimum = 18, Maximum = 101, Average = about 45


-- Checking gender
SELECT gender,COUNT(*) AS number_of_customers
FROM clean_users_data
GROUP BY gender
ORDER BY number_of_customers DESC;

-- Output: Female = 1016, Male = 984


-- Checking credit score
SELECT MIN(credit_score) AS min_credit,
MAX(credit_score) AS max_credit,
ROUND(AVG(credit_score),2) AS avg_credit
FROM clean_users_data;

-- Output: Minimum = 480, Maximum = 850, Average = 709.73


-- Checking average income and debt
SELECT ROUND(AVG(yearly_income),0) AS avg_income,
ROUND(AVG(total_debt),0) AS avg_debt,
MAX(yearly_income) AS max_income,
MAX(total_debt) AS max_debt
FROM clean_users_data;

-- Output:
-- Average income = 45716
-- Average debt = 63710
-- Maximum income = 307018
-- Maximum debt = 516263


-- Grouping customers using credit score
SELECT CASE
WHEN credit_score>=750 THEN 'Excellent'
WHEN credit_score>=700 THEN 'Good'
WHEN credit_score>=650 THEN 'Fair'
ELSE 'Poor'
END AS credit_score_category,
COUNT(*) AS number_of_customers
FROM clean_users_data
GROUP BY credit_score_category
ORDER BY number_of_customers ASC;

-- Output:
-- Poor = 334
-- Fair = 492
-- Excellent = 534
-- Good = 640


-- Checking how many cards customers have
SELECT num_credit_cards,COUNT(*) AS number_of_customers
FROM clean_users_data
GROUP BY num_credit_cards
ORDER BY num_credit_cards;


/* =========================
CARD DATA CLEANING
========================= */


-- Creating a clean version of the cards table
-- Removing the $ sign from credit_limit
CREATE TABLE clean_cards_data AS
SELECT id AS card_id,
client_id AS customer_id,
card_brand,
card_type,
card_number,
expires,
cvv,
has_chip,
num_cards_issued,
REPLACE(credit_limit,'$','')::NUMERIC AS credit_limit,
account_open_date,
year_pin_last_changed,
card_on_dark_web
FROM cards_data;


-- Checking that card IDs are still unique
SELECT COUNT(*) AS total_rows,
COUNT(DISTINCT card_id) AS unique_cards
FROM clean_cards_data;

-- Output: 6146 rows and 6146 unique cards


-- Adding a primary key
ALTER TABLE clean_cards_data
ADD PRIMARY KEY (card_id);


/* =========================
CARD EDA
========================= */


-- Checking the most used card brand
SELECT card_brand,COUNT(*) AS number_of_cards
FROM clean_cards_data
GROUP BY card_brand
ORDER BY number_of_cards DESC;

-- Output:
-- Mastercard = 3209
-- Visa = 2326
-- Amex = 402
-- Discover = 209


-- Checking the most common card type
SELECT card_type,COUNT(*) AS number_of_cards
FROM clean_cards_data
GROUP BY card_type
ORDER BY number_of_cards DESC;

-- Output:
-- Debit = 3511
-- Credit = 2057
-- Debit (Prepaid) = 578


-- Checking credit limits by card type
SELECT card_type,
ROUND(AVG(credit_limit),2) AS average_credit_limit,
MIN(credit_limit) AS lowest_credit_limit,
MAX(credit_limit) AS highest_credit_limit
FROM clean_cards_data
GROUP BY card_type
ORDER BY average_credit_limit DESC;


-- Checking how many cards have a chip
SELECT has_chip,COUNT(*) AS number_of_cards
FROM clean_cards_data
GROUP BY has_chip
ORDER BY number_of_cards DESC;

-- Output: Yes = 5500, No = 646


-- Checking cards that were flagged on the dark web
SELECT card_on_dark_web,COUNT(*) AS number_of_cards
FROM clean_cards_data
GROUP BY card_on_dark_web
ORDER BY number_of_cards DESC;

-- Output: No cards were flagged


/* =========================
CUSTOMER AND CARD JOINS
========================= */


-- Joining customers and cards
SELECT u.customer_id,u.current_age,c.card_id,c.card_brand,c.card_type,c.credit_limit
FROM clean_users_data u
JOIN clean_cards_data c
ON u.customer_id=c.customer_id
LIMIT 15;


-- Checking if the number of cards in users_data matches cards_data
SELECT u.customer_id,
u.num_credit_cards AS reported_cards,
COUNT(c.card_id) AS actual_cards
FROM clean_users_data u
JOIN clean_cards_data c
ON u.customer_id=c.customer_id
GROUP BY u.customer_id,u.num_credit_cards
HAVING u.num_credit_cards<>COUNT(c.card_id);

-- Output: 0 rows
-- The number of cards matched for every customer


-- Checking how many debit and credit cards each customer has
SELECT u.customer_id,
COUNT(c.card_id) AS total_cards,
SUM(CASE WHEN c.card_type='Debit' THEN 1 ELSE 0 END) AS debit_cards,
SUM(CASE WHEN c.card_type='Credit' THEN 1 ELSE 0 END) AS credit_cards
FROM clean_users_data u
LEFT JOIN clean_cards_data c
ON u.customer_id=c.customer_id
GROUP BY u.customer_id
ORDER BY total_cards DESC;

-- Output: The highest number of cards for one customer was 9


/* =========================
TRANSACTION DATA CLEANING
========================= */


-- Checking missing values in transactions
SELECT COUNT(*) FILTER (WHERE id IS NULL) AS missing_transaction_id,
COUNT(*) FILTER (WHERE date IS NULL) AS missing_date,
COUNT(*) FILTER (WHERE client_id IS NULL) AS missing_customer_id,
COUNT(*) FILTER (WHERE card_id IS NULL) AS missing_card_id,
COUNT(*) FILTER (WHERE amount IS NULL) AS missing_amount,
COUNT(*) FILTER (WHERE merchant_id IS NULL) AS missing_merchant_id,
COUNT(*) FILTER (WHERE merchant_city IS NULL) AS missing_merchant_city,
COUNT(*) FILTER (WHERE merchant_state IS NULL) AS missing_merchant_state,
COUNT(*) FILTER (WHERE mcc IS NULL) AS missing_mcc,
COUNT(*) FILTER (WHERE errors IS NULL) AS missing_errors
FROM transactions_data;

-- Output:
-- Merchant_state had missing values
-- Errors also had many missing values


-- Checking how many rows are missing both merchant_state and errors
SELECT COUNT(*) AS missing_merchant_and_errors
FROM transactions_data
WHERE merchant_state IS NULL
AND errors IS NULL;

-- Output: 1528138


-- Checking which transaction method had missing merchant_state
SELECT use_chip,COUNT(*) AS transactions_missing_state
FROM transactions_data
WHERE merchant_state IS NULL
GROUP BY use_chip
ORDER BY transactions_missing_state DESC;

-- Output: Most were online transactions


-- Checking if all online transactions are missing merchant_state
SELECT COUNT(*) AS online_transactions_with_state
FROM transactions_data
WHERE use_chip='Online Transaction'
AND merchant_state IS NOT NULL;

-- Output: 0
-- All online transactions were missing merchant_state


-- Creating a clean transaction table
-- Removing $ from amount and changing amount to NUMERIC
CREATE TABLE clean_transactions_data AS
SELECT id AS transaction_id,
date,
client_id AS customer_id,
card_id,
REPLACE(amount,'$','')::NUMERIC AS amount,
use_chip,
merchant_id,
merchant_city,
CASE
WHEN use_chip='Online Transaction' AND merchant_state IS NULL THEN 'Online / N/A'
ELSE merchant_state
END AS merchant_state,
zip,
mcc,
errors
FROM transactions_data;


-- Checking that all transactions are still there and IDs are unique
SELECT COUNT(*) AS total_rows,
COUNT(DISTINCT transaction_id) AS unique_transactions
FROM clean_transactions_data;

-- Output:
-- Total rows = 13305915
-- Unique transactions = 13305915


-- Adding a primary key
ALTER TABLE clean_transactions_data
ADD PRIMARY KEY (transaction_id);


/* =========================
MERCHANT LOCATION CLEANING
========================= */


-- Changing Online / N/A to ONLINE to match merchant_city
UPDATE clean_transactions_data
SET merchant_state='ONLINE'
WHERE use_chip='Online Transaction'
AND merchant_state='Online / N/A';


-- Checking chip transactions with missing merchant_state
SELECT merchant_city,COUNT(*) AS number_of_transactions
FROM clean_transactions_data
WHERE use_chip='Chip Transaction'
AND merchant_state IS NULL
GROUP BY merchant_city
ORDER BY number_of_transactions DESC;

-- Output: merchant_city was ONLINE


-- Checking some of the actual rows
SELECT transaction_id,date,customer_id,card_id,merchant_city,merchant_state,zip,amount
FROM clean_transactions_data
WHERE use_chip='Chip Transaction'
AND merchant_state IS NULL
LIMIT 30;


-- Checking ZIP for online transactions
SELECT COUNT(*) AS total_online_transactions,
COUNT(*) FILTER (WHERE zip IS NULL) AS online_transactions_missing_zip,
COUNT(*) FILTER (WHERE zip IS NOT NULL) AS online_transactions_with_zip
FROM clean_transactions_data
WHERE use_chip='Online Transaction';

-- Output: All online transactions had NULL ZIP


-- Updating merchant_state for chip transactions where merchant_city is ONLINE
UPDATE clean_transactions_data
SET merchant_state='ONLINE'
WHERE use_chip='Chip Transaction'
AND merchant_city='ONLINE'
AND merchant_state IS NULL;


-- Updating ZIP to ONLINE when merchant_city is ONLINE
UPDATE clean_transactions_data
SET zip='ONLINE'
WHERE merchant_city='ONLINE'
AND zip IS NULL;


-- Checking if the updates worked
SELECT COUNT(*) FILTER (WHERE merchant_state IS NULL) AS missing_state,
COUNT(*) FILTER (WHERE zip IS NULL) AS missing_zip
FROM clean_transactions_data
WHERE merchant_city='ONLINE';

-- Output: 0 missing merchant_state and 0 missing ZIP


/* =========================
ERROR CLEANING
========================= */


-- Checking what is inside the errors column
SELECT errors,COUNT(*) AS number_of_transactions
FROM clean_transactions_data
GROUP BY errors
ORDER BY number_of_transactions DESC;


-- Changing NULL error values to No Error
UPDATE clean_transactions_data
SET errors='No Error'
WHERE errors IS NULL;


-- Checking if there are still NULL errors
SELECT COUNT(*) AS remaining_null_errors
FROM clean_transactions_data
WHERE errors IS NULL;

-- Output: 0


/* =========================
TRANSACTION EDA
========================= */


-- Checking total transactions, total value and average transaction amount
SELECT COUNT(*) AS total_transactions,
ROUND(SUM(amount),2) AS total_transaction_value,
ROUND(AVG(amount),2) AS average_transaction_amount
FROM clean_transactions_data;

-- Output:
-- Total transactions = 13305915
-- Total transaction value = 571835522.28
-- Average transaction amount = 42.98


-- Checking the lowest and highest transaction amount
SELECT MIN(amount) AS lowest_transaction_amount,
MAX(amount) AS highest_transaction_amount
FROM clean_transactions_data;

-- Output:
-- Lowest = -500
-- Highest = 6820.20


-- Checking positive, negative and zero transactions
SELECT CASE
WHEN amount<0 THEN 'Negative'
WHEN amount=0 THEN 'Zero'
ELSE 'Positive'
END AS amount_category,
COUNT(*) AS number_of_transactions
FROM clean_transactions_data
GROUP BY amount_category
ORDER BY number_of_transactions DESC;

-- Output:
-- Positive = 12635227
-- Negative = 660049
-- Zero = 10639


-- Checking transactions by transaction method
SELECT use_chip,
COUNT(*) AS number_of_transactions,
ROUND(SUM(amount),2) AS total_transaction_value,
ROUND(AVG(amount),2) AS average_transaction_amount
FROM clean_transactions_data
GROUP BY use_chip
ORDER BY total_transaction_value DESC;

-- Output: Most transactions were swipe transactions


-- Checking error rate by transaction method
SELECT use_chip,
COUNT(*) AS total_transactions,
SUM(CASE WHEN errors<>'No Error' THEN 1 ELSE 0 END) AS transactions_with_errors,
ROUND(100.0*SUM(CASE WHEN errors<>'No Error' THEN 1 ELSE 0 END)/COUNT(*),2) AS error_rate_percentage
FROM clean_transactions_data
GROUP BY use_chip
ORDER BY error_rate_percentage DESC;

-- Output:
-- Online = 2.28%
-- Chip = 1.51%
-- Swipe = 1.49%


/* =========================
JOINS BETWEEN ALL TABLES
========================= */


-- Joining transactions and cards
SELECT t.transaction_id,t.date,t.amount,c.card_brand,c.card_type,c.credit_limit
FROM clean_transactions_data t
JOIN clean_cards_data c
ON t.card_id=c.card_id
LIMIT 20;


-- Joining all three tables
SELECT t.transaction_id,t.date,t.amount,u.customer_id,u.current_age,u.gender,
u.credit_score,c.card_brand,c.card_type,c.credit_limit
FROM clean_transactions_data t
JOIN clean_cards_data c
ON t.card_id=c.card_id
JOIN clean_users_data u
ON t.customer_id=u.customer_id
LIMIT 20;


-- Checking which customers had the highest transaction value
SELECT u.customer_id,
COUNT(t.transaction_id) AS number_of_transactions,
ROUND(SUM(t.amount),2) AS total_transaction_value,
ROUND(AVG(t.amount),2) AS average_transaction_amount
FROM clean_users_data u
JOIN clean_transactions_data t
ON u.customer_id=t.customer_id
GROUP BY u.customer_id
ORDER BY total_transaction_value DESC
LIMIT 20;


-- Checking transaction behaviour by card type
SELECT c.card_type,
COUNT(t.transaction_id) AS number_of_transactions,
ROUND(SUM(t.amount),2) AS total_transaction_value,
ROUND(AVG(t.amount),2) AS average_transaction_amount
FROM clean_transactions_data t
JOIN clean_cards_data c
ON t.card_id=c.card_id
GROUP BY c.card_type
ORDER BY total_transaction_value DESC;

-- Output: Customers transacted more using credit cards


-- Checking which card type had the highest number of errors
SELECT c.card_type,
COUNT(*) AS total_transactions,
SUM(CASE WHEN t.errors<>'No Error' THEN 1 ELSE 0 END) AS transactions_with_errors
FROM clean_transactions_data t
JOIN clean_cards_data c
ON t.card_id=c.card_id
GROUP BY c.card_type
ORDER BY transactions_with_errors DESC;

-- Output: Debit cards had the highest number of errors


/* =========================
SIMPLE CTE
========================= */


-- Using a CTE to first count transactions for each customer
-- Then showing the top 10 customers with the most transactions
WITH customer_transactions AS (
SELECT customer_id,COUNT(*) AS total_transactions
FROM clean_transactions_data
GROUP BY customer_id
)
SELECT customer_id,total_transactions
FROM customer_transactions
ORDER BY total_transactions DESC
LIMIT 10;

-- Output: Top 10 customers with the highest number of transactions
