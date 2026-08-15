# Fraud Risk Analytics

End-to-end fraud risk analytics project using **PostgreSQL, SQL and Power BI** to identify suspicious payment behavior and prioritize customer cases for investigation.

The analysis covers **99,499 synthetic payment transactions** and combines multiple behavioral risk indicators into a customer-level investigation queue.

## Power BI Dashboard

### Overview

![Fraud Risk Analytics Overview](screenshots/overview.png)

### Risk Investigation

![Fraud Risk Investigation Dashboard](screenshots/risk-investigation.png)

[Download the Power BI dashboard](powerbi/Fraud_Risk_Analytics.pbix)

## Key Findings

- **99,499** transactions analyzed
- **€7.72M** total transaction value
- **5,000** active customers
- **403** customers flagged for investigation
- **1** High Priority
- **30** Medium Priority
- **372** Review

Risk signals triggered:

- **237** Shared Device
- **73** Geo Anomaly
- **70** Rapid Cash-out
- **55** High Velocity

## Risk Indicators

The analysis focuses on four behavioral signals:

- **Shared Devices** — devices linked to multiple accounts
- **Geographic Anomalies** — IP country differs from customer country
- **High Transaction Velocity** — unusually high activity within short time windows
- **Rapid Cash-out** — large deposits followed shortly by significant withdrawals

These signals are combined into a customer-level investigation score and classified as **High Priority, Medium Priority or Review**.

## Technologies

**PostgreSQL · SQL · Power BI · DAX · Power Query**

SQL techniques:

`JOINs` · `CTEs` · `Window Functions` · `Self-Joins` · `Aggregations` · `CASE` · `FILTER` · `COALESCE`

## Project Structure

```text
fraud-risk-analytics/
├── README.md
├── sql/
│   ├── 01_schema.sql
│   ├── 02_exploratory_analysis.sql
│   ├── 03_risk_indicators.sql
│   └── 04_investigation_scoring.sql
├── powerbi/
│   └── Fraud_Risk_Analytics.pbix
└── screenshots/
    ├── overview.png
    └── risk-investigation.png
