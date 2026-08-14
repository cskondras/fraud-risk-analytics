-- Fraud Risk Analytics
-- Individual fraud and transaction-risk indicators.


-- 1. Shared devices across multiple customer accounts
SELECT
    device_id,
    COUNT(DISTINCT customer_id) AS linked_customers
FROM account_devices
GROUP BY device_id
HAVING COUNT(DISTINCT customer_id) > 1
ORDER BY linked_customers DESC, device_id;


-- 2. Geographic mismatch by customer
-- Compares the customer's registered country with the transaction IP country.
SELECT
    t.customer_id,
    c.country_code AS home_country,
    COUNT(*) AS total_transactions,

    COUNT(*) FILTER (
        WHERE t.ip_country_code <> c.country_code
    ) AS mismatch_transactions,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE t.ip_country_code <> c.country_code
        ) / COUNT(*),
        2
    ) AS mismatch_rate_pct,

    COUNT(DISTINCT t.ip_country_code) FILTER (
        WHERE t.ip_country_code <> c.country_code
    ) AS foreign_countries,

    ROUND(
        SUM(t.amount_eur) FILTER (
            WHERE t.ip_country_code <> c.country_code
        ),
        2
    ) AS mismatch_value_eur

FROM transactions t

JOIN customers c
    ON t.customer_id = c.customer_id

GROUP BY
    t.customer_id,
    c.country_code

HAVING COUNT(*) FILTER (
    WHERE t.ip_country_code <> c.country_code
) >= 3

ORDER BY
    mismatch_rate_pct DESC,
    mismatch_transactions DESC;


-- 3. High transaction velocity
-- Identifies customers reaching at least 8 transactions
-- within a rolling 10-minute window.
WITH transaction_velocity AS (
    SELECT
        customer_id,
        transaction_at,

        COUNT(*) OVER (
            PARTITION BY customer_id
            ORDER BY transaction_at
            RANGE BETWEEN INTERVAL '10 minutes' PRECEDING
                      AND CURRENT ROW
        ) AS transactions_10min,

        ROUND(
            SUM(amount_eur) OVER (
                PARTITION BY customer_id
                ORDER BY transaction_at
                RANGE BETWEEN INTERVAL '10 minutes' PRECEDING
                          AND CURRENT ROW
            ),
            2
        ) AS value_10min

    FROM transactions
)

SELECT
    customer_id,
    MAX(transactions_10min) AS max_transactions_10min,
    MAX(value_10min) AS max_value_10min
FROM transaction_velocity
GROUP BY customer_id
HAVING MAX(transactions_10min) >= 8
ORDER BY
    max_transactions_10min DESC,
    max_value_10min DESC;


-- 4. Rapid cash-out
-- Successful deposits of at least EUR 500 followed by a
-- successful withdrawal of at least 80% within 30 minutes.
WITH rapid_cashout_cases AS (
    SELECT
        d.customer_id,

        ROUND(
            EXTRACT(EPOCH FROM (w.transaction_at - d.transaction_at)) / 60,
            2
        ) AS minutes_to_withdrawal,

        ROUND(
            100.0 * w.amount_eur / d.amount_eur,
            2
        ) AS cashout_pct,

        d.amount_eur AS deposit_amount_eur,
        w.amount_eur AS withdrawal_amount_eur

    FROM transactions d

    JOIN transactions w
        ON d.customer_id = w.customer_id
        AND w.transaction_type = 'withdrawal'
        AND w.status = 'successful'
        AND w.transaction_at > d.transaction_at
        AND w.transaction_at <= d.transaction_at + INTERVAL '30 minutes'

    WHERE d.transaction_type = 'deposit'
      AND d.status = 'successful'
      AND d.amount_eur >= 500
      AND w.amount_eur >= d.amount_eur * 0.80
)

SELECT
    customer_id,
    COUNT(*) AS rapid_cashout_events,
    MIN(minutes_to_withdrawal) AS fastest_cashout_minutes,
    MAX(cashout_pct) AS max_cashout_pct,
    ROUND(SUM(deposit_amount_eur), 2) AS total_deposit_value,
    ROUND(SUM(withdrawal_amount_eur), 2) AS total_cashout_value
FROM rapid_cashout_cases
GROUP BY customer_id
ORDER BY
    rapid_cashout_events DESC,
    max_cashout_pct DESC;
