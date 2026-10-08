# SQL review before upload

The schema, income import, and query logic were reviewed for the stated MySQL 8 target. No definite syntax issue was found by static inspection. The scripts were executed on MySQL on 8 October 2026. See docs/mysql_validation.md for the results.

All seven adapted queries were executed against the combined SQLite reference database. Queries 1–6 return the same rows as before the income addition; query 7 returns 69 neighborhood comparisons with the 2023 income measure. Query row counts are recorded in `results/validation.json`; the aggregate income comparison is in `results/income_airbnb_comparison.csv`. Standard joins, aggregation, correlated subqueries, CASE, CTEs, and window functions are retained because the Week 3 project already uses these techniques.

The original-query file is deliberately historical; its known logical limitations are preserved for before/after comparison. Do not describe it as the corrected production query file.

The 73-row income import is generated from the open-data CSV by `scripts/prepare_income_data.py`. The 8.4 MB Airbnb/rent bulk import is generated serialization, not hand-written student SQL; follow the repository's existing plan to regenerate it from the cleaned CSVs instead of uploading it.

Known limits remain: listing activity is unknown; there is one snapshot per listing; regulation data are absent; one minimum-stay value, 1,938 listing prices, 2,562 bedroom counts, and 21 rent values are unknown. Household income is an unweighted mean of census-section estimates for 2023; it is compared descriptively with listing prices observed in 2026. These limits do not support causal claims. MySQL behavior still requires a local run.
