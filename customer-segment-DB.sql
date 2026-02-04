---Step 1: Creating a data table and uploading data.

CREATE TABLE transactions (
    invoice_no VARCHAR(20),
    stock_code VARCHAR(20),
    description TEXT,
    quantity INT,
    invoice_date TEXT,   
    unit_price DECIMAL(10,2),
    customer_id INT,
    country VARCHAR(50)
);


ALTER TABLE transactions
ADD COLUMN invoice_ts TIMESTAMP;

UPDATE transactions
SET invoice_ts = TO_TIMESTAMP(invoice_date, 'DD/MM/YYYY HH24:MI');


---Step 2:  Create Clean Transactions Table

CREATE TABLE clean_transactions AS
SELECT *
FROM transactions
WHERE customer_id IS NOT NULL
  AND invoice_no NOT LIKE 'C%'
  AND quantity > 0
  AND unit_price > 0;

select * from transactions 


---Step 3: Compute Base RFM Metrics

--- Compute recency, frequency, and monetary values for each customer.

WITH rfm_base AS (
    SELECT
        customer_id,
        MAX(invoice_date) AS last_purchase_date,
        COUNT(DISTINCT invoice_no) AS frequency,
        SUM(quantity * unit_price) AS monetary
    FROM clean_transactions
    GROUP BY customer_id
)

SELECT * FROM rfm_base;

---Step 4: Calculate Recency (Days Since Last Purchase)

WITH last_purchase AS (
    SELECT
        customer_id,
        MAX(TO_TIMESTAMP(invoice_date, 'DD/MM/YYYY HH24:MI')) AS last_purchase_date
    FROM clean_transactions
    GROUP BY customer_id
)
SELECT
    customer_id,
    CURRENT_DATE - last_purchase_date::DATE AS recency_days
FROM last_purchase;



--- Step 5: Full RFM Calculation (Recency + Frequency + Monetary)

WITH rfm_base AS (
    SELECT
        customer_id,
        MAX(TO_TIMESTAMP(invoice_date, 'DD/MM/YYYY HH24:MI')) AS last_purchase_date,
        COUNT(DISTINCT invoice_no) AS frequency,
        SUM(quantity * unit_price) AS monetary
    FROM clean_transactions
    GROUP BY customer_id
),
rfm_metrics AS (
    SELECT
        customer_id,
        CURRENT_DATE - last_purchase_date::DATE AS recency,
        frequency,
        monetary
    FROM rfm_base
)
SELECT * FROM rfm_metrics;

  ---- Step 6: RFM Scoring (1–5 Scale) --Assign scores to each customer for recency, frequency, and monetary value.

WITH rfm_base AS (
    SELECT
        customer_id,
        MAX(TO_TIMESTAMP(invoice_date, 'DD/MM/YYYY HH24:MI')) AS last_purchase_date,
        COUNT(DISTINCT invoice_no) AS frequency,
        SUM(quantity * unit_price) AS monetary
    FROM clean_transactions
    GROUP BY customer_id
),
rfm_metrics AS (
    SELECT
        customer_id,
        CURRENT_DATE - last_purchase_date::DATE AS recency,
        frequency,
        monetary
    FROM rfm_base
),
rfm_scores AS (
    SELECT
        customer_id,
        NTILE(5) OVER (ORDER BY recency ASC)  AS r_score,
        NTILE(5) OVER (ORDER BY frequency DESC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary DESC)  AS m_score
    FROM rfm_metrics
)
SELECT * FROM rfm_scores;


--- Step 7: Customer Segmentation

--- Convert RFM scores into business-friendly segments.

WITH rfm_base AS (
    SELECT
        customer_id,
        MAX(TO_TIMESTAMP(invoice_date, 'DD/MM/YYYY HH24:MI')) AS last_purchase_date,
        COUNT(DISTINCT invoice_no) AS frequency,
        SUM(quantity * unit_price) AS monetary
    FROM clean_transactions
    GROUP BY customer_id
),
rfm_metrics AS (
    SELECT
        customer_id,
        CURRENT_DATE - last_purchase_date::DATE AS recency,
        frequency,
        monetary
    FROM rfm_base
),
rfm_scores AS (
    SELECT
        customer_id,
        NTILE(5) OVER (ORDER BY recency ASC)        AS r_score,
        NTILE(5) OVER (ORDER BY frequency DESC)     AS f_score,
        NTILE(5) OVER (ORDER BY monetary DESC)      AS m_score
    FROM rfm_metrics
)
SELECT
    customer_id,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_score,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'Potential Loyalist'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        ELSE 'Lost Customers'
    END AS customer_segment
	
FROM rfm_scores;

CREATE OR REPLACE VIEW vw_customer_rfm AS
WITH rfm_base AS (
    SELECT
        customer_id,
        MAX(TO_TIMESTAMP(invoice_date, 'DD/MM/YYYY HH24:MI')) AS last_purchase_date,
        COUNT(DISTINCT invoice_no) AS frequency,
        SUM(quantity * unit_price) AS monetary
    FROM clean_transactions
    GROUP BY customer_id
),
rfm_metrics AS (
    SELECT
        customer_id,
        CURRENT_DATE - last_purchase_date::DATE AS recency,
        frequency,
        monetary
    FROM rfm_base
),
rfm_scores AS (
    SELECT
        customer_id,
        recency,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency ASC)        AS r_score,
        NTILE(5) OVER (ORDER BY frequency DESC)     AS f_score,
        NTILE(5) OVER (ORDER BY monetary DESC)      AS m_score
    FROM rfm_metrics
)
SELECT
    customer_id,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_score,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'Potential Loyalist'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        ELSE 'Lost Customers'
    END AS customer_segment
FROM rfm_scores;


--- view
SELECT *
FROM vw_customer_rfm;


SELECT * FROM transactions


With invoices as SELECT * FROM clean_transactions;


WITH invoice_details AS (
    SELECT stock_code, description, 
           AVG(unit_price) AS avg_price
    FROM clean_transactions
    GROUP BY stock_code, description
)
SELECT *
FROM invoice_details
WHERE avg_price > 0.19;



WITH monthly_sales AS (
    SELECT 
        stock_code,
        description,
        SUM(quantity) AS total_quantity,
        SUM(quantity * unit_price) AS total_sales
    FROM clean_transactions
    GROUP BY 
        stock_code, 
        description
)
SELECT *
FROM monthly_sales
WHERE total_quantity > 30000
ORDER BY  total_sales DESC;


SELECT 
stock_code  
FROM clean_transactions


SELECT stock_code, COUNT(*)
FROM clean_transactions
GROUP BY stock_code
HAVING COUNT(*) > 1;


SELECT customer_id, COUNT(*)
FROM clean_transactions
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT invoice_no, COUNT(*)
FROM clean_transactions
GROUP BY invoice_no
HAVING COUNT(*) > 1;


SELECT stock_code, description, unit_price
FROM clean_transactions
WHERE unit_price > (
    SELECT AVG(unit_price)
    FROM clean_transactions
);


select 
quantity
FROM clean_transactions


SELECT stock_code
FROM clean_transactions
WHERE stock_code IN (
    SELECT stock_code
    FROM clean_transactions
    WHERE quantity > 20000
);


SELECT stock_code
FROM clean_transactions
WHERE stock_code IN (
    SELECT stock_code
    FROM clean_transactions
    WHERE quantity < 2000
);



SELECT stock_code
FROM clean_transactions
WHERE stock_code IN (
    '567505',
    '553900',
    '550911',
    '552449',
    '541430',
    '574740',
    '559707',
    '571034',
    '554132'
);



SELECT stock_code, description 
FROM clean_transactions
WHERE stock_code IN (
    '21883',
    '23161',
    '23201',
    '20676',
    '48194',
    '22703',
    '21499',
    '21883',
    '21789'
);



SELECT stock_code, description, unit_price
FROM clean_transactions
WHERE unit_price > (
    SELECT AVG(unit_price)
    FROM clean_transactions
);



SELECT stock_code, total_quantity 
FROM (
    SELECT stock_code, description,
           SUM(quantity) AS total_quantity,
           SUM(quantity * unit_price) AS total_sales
    FROM clean_transactions
    GROUP BY stock_code, description
) AS sales_summary
WHERE total_quantity > 500;





