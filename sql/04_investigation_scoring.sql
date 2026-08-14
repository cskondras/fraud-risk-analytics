-- Fraud Risk Analytics
-- Multi-signal investigation prioritization.
--
-- A risk signal is not treated as proof of fraud.
-- The purpose of this query is to prioritize customers
-- for further investigation based on multiple indicators.


WITH transaction_velocity AS (
    SELECT
        customer_id,
        transaction_at,

        COUNT(*) OVER (
            PARTITION BY customer_id
            ORDER BY transaction_at
            RANGE BETWEEN INTERVAL '10 minutes' PRECEDING
                      AND CURRENT ROW
        ) AS transactions_10min

    FROM transactions
),

velocity_summary AS (
    SELECT
        customer_id,
        MAX(transactions_10min) AS max_transactions_10min

    FROM transaction_velocity

    GROUP BY customer_id

    HAVING MAX(transactions_10min) >= 8
),


rapid_cashout_cases AS (
    SELECT
        d.customer_id,

        ROUND(
            EXTRACT(EPOCH FROM (w.transaction_at - d.transaction_at)) / 60,
            2
        ) AS minutes_to_withdrawal,

        ROUND(
            100.0 * w.amount_eur / d.amount_eur,
            2
        ) AS cashout_pct

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
),

rapid_cashout_summary AS (
    SELECT
        customer_id,
        COUNT(*) AS rapid_cashout_events,
        MIN(minutes_to_withdrawal) AS fastest_cashout_minutes,
        MAX(cashout_pct) AS max_cashout_pct

    FROM rapid_cashout_cases

    GROUP BY customer_id
),


geo_summary AS (
    SELECT
        t.customer_id,

        COUNT(*) FILTER (
            WHERE t.ip_country_code <> c.country_code
        ) AS mismatch_transactions,

        ROUND(
            100.0 * COUNT(*) FILTER (
                WHERE t.ip_country_code <> c.country_code
            ) / COUNT(*),
            2
        ) AS mismatch_rate_pct

    FROM transactions t

    JOIN customers c
        ON t.customer_id = c.customer_id

    GROUP BY t.customer_id
),


shared_device_counts AS (
    SELECT
        device_id,
        COUNT(DISTINCT customer_id) AS linked_customers

    FROM account_devices

    GROUP BY device_id

    HAVING COUNT(DISTINCT customer_id) > 1
),

shared_device_summary AS (
    SELECT
        ad.customer_id,
        COUNT(DISTINCT ad.device_id) AS shared_devices,
        MAX(sdc.linked_customers) AS max_accounts_on_device

    FROM account_devices ad

    JOIN shared_device_counts sdc
        ON ad.device_id = sdc.device_id

    GROUP BY ad.customer_id
),


candidate_customers AS (
    SELECT customer_id
    FROM velocity_summary

    UNION

    SELECT customer_id
    FROM rapid_cashout_summary

    UNION

    SELECT customer_id
    FROM geo_summary
    WHERE mismatch_rate_pct >= 20

    UNION

    SELECT customer_id
    FROM shared_device_summary
),


risk_features AS (
    SELECT
        cc.customer_id,
        c.country_code AS home_country,

        COALESCE(v.max_transactions_10min, 0)
            AS max_transactions_10min,

        COALESCE(r.rapid_cashout_events, 0)
            AS rapid_cashout_events,

        COALESCE(r.fastest_cashout_minutes, 0)
            AS fastest_cashout_minutes,

        COALESCE(r.max_cashout_pct, 0)
            AS max_cashout_pct,

        COALESCE(g.mismatch_transactions, 0)
            AS mismatch_transactions,

        COALESCE(g.mismatch_rate_pct, 0)
            AS mismatch_rate_pct,

        COALESCE(s.shared_devices, 0)
            AS shared_devices,

        COALESCE(s.max_accounts_on_device, 1)
            AS max_accounts_on_device,

        CASE
            WHEN v.customer_id IS NOT NULL THEN 1
            ELSE 0
        END AS velocity_flag,

        CASE
            WHEN r.customer_id IS NOT NULL THEN 1
            ELSE 0
        END AS rapid_cashout_flag,

        CASE
            WHEN COALESCE(g.mismatch_rate_pct, 0) >= 20 THEN 1
            ELSE 0
        END AS geo_anomaly_flag,

        CASE
            WHEN s.customer_id IS NOT NULL THEN 1
            ELSE 0
        END AS shared_device_flag

    FROM candidate_customers cc

    JOIN customers c
        ON cc.customer_id = c.customer_id

    LEFT JOIN velocity_summary v
        ON cc.customer_id = v.customer_id

    LEFT JOIN rapid_cashout_summary r
        ON cc.customer_id = r.customer_id

    LEFT JOIN geo_summary g
        ON cc.customer_id = g.customer_id

    LEFT JOIN shared_device_summary s
        ON cc.customer_id = s.customer_id
),


scored_customers AS (
    SELECT
        *,
        velocity_flag
        + rapid_cashout_flag
        + geo_anomaly_flag
        + shared_device_flag
            AS risk_signal_count

    FROM risk_features
)


SELECT
    *,
    CASE
        WHEN risk_signal_count >= 3 THEN 'high_priority'
        WHEN risk_signal_count = 2 THEN 'medium_priority'
        ELSE 'review'
    END AS investigation_priority

FROM scored_customers

ORDER BY
    risk_signal_count DESC,
    rapid_cashout_events DESC,
    max_transactions_10min DESC,
    mismatch_rate_pct DESC;
