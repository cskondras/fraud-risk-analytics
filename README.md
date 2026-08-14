# Fraud Risk Analytics

SQL-based analysis of synthetic payment transactions to identify fraud risk indicators and prioritize customer cases for investigation.

## Dataset

- 5,000 customers
- 6,692 devices
- 99,499 transactions

## Analysis

The project explores four risk indicators:

- Shared devices across multiple accounts
- Geographic transaction mismatches
- High transaction velocity
- Rapid post-deposit cash-out

The final SQL analysis combines these signals into a customer-level investigation priority.

## SQL Skills

PostgreSQL · JOINs · CTEs · Window Functions · Self-Joins · Aggregations · CASE · FILTER · COALESCE

## Files

- `01_schema.sql` — database schema
- `02_exploratory_analysis.sql` — transaction overview
- `03_risk_indicators.sql` — individual risk signals
- `04_investigation_scoring.sql` — multi-signal prioritization

> All data is synthetic and used only for portfolio and learning purposes.
