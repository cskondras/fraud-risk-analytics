-- Fraud Risk Analytics
-- Exploratory analysis of the synthetic payments dataset.

-- 1. Overall dataset summary
SELECT
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT customer_id) AS active_customers,
    COUNT(DISTINCT device_id) AS active_devices,
    MIN(transaction_at) AS first_transaction,
    MAX(transaction_at) AS last_transaction,
    ROUND(SUM(amount_eur), 2) AS total_transaction_value,
    ROUND(AVG(amount_eur), 2) AS avg_transaction_value
FROM transactions;


-- 2. Transaction activity by type
SELECT
    transaction_type,
    COUNT(*) AS transaction_count,
    ROUND(SUM(amount_eur), 2) AS total_value_eur,
    ROUND(AVG(amount_eur), 2) AS avg_value_eur
FROM transactions
GROUP BY transaction_type
ORDER BY transaction_count DESC;
