# MySQL validation

Run date: 2026-10-08
MySQL server version (SELECT VERSION();): 26.7.0
Client: mysql command line (Homebrew, macOS, arm64)

| Step | File | Result |
|---|---|---|
| 1 | sql/real/01_real_data_schema.sql | ok, 11 tables created |
| 2 | sql/real/02_import_real_data.sql | ok, row counts match docs |
| 3 | sql/real/03_import_income_data.sql | ok, 73 income rows |
| 4 | sql/real/04_validation.sql | all violation counts = 0 |
| 5 | sql/real/05_constraint_tests.sql | 7 of 7 tests rejected, see below |
| 6 | sql/queries/adapted_queries.sql | Q1 69, Q2 1607, Q3 13355, Q4 0, Q5 0, Q6 243, Q7 69 |

## Row counts after import

city 1, neighborhood 73, host 4,595, property 15,293, host_property 15,293,
platform 1, listing 15,293, listing_snapshot 15,293,
housing_market_observation 438 (365 rent rows + 73 income rows),
regulation 0, regulation_area 0.

## Constraint tests (negative inserts)

| Test | What we tried | MySQL result |
|---|---|---|
| T1 | negative nightly price | ERROR 3819, chk_snapshot_price |
| T2 | availability 366 | ERROR 3819, chk_snapshot_availability |
| T3 | capacity 0 | ERROR 3819, chk_property_capacity |
| T4 | neighborhood that does not exist | ERROR 1452, fk_property_neighborhood |
| T5 | duplicate platform and source listing id | ERROR 1062, uq_listing_source |
| T6 | rent 0 | ERROR 3819, chk_rent_positive |
| T7 | income 0 | ERROR 3819, chk_income_positive |

The tests run inside a transaction that is rolled back.
listing_snapshot still has 15,293 rows afterwards.

## Problem found only in MySQL

MySQL needs a space after the comment marker. The comment `--C1` in
01_real_data_schema.sql caused ERROR 1064. SQLite accepted it.
We fixed it to `-- CHANGED C1`.

## Differences between SQLite and MySQL

The row counts of all 7 adapted queries are identical in MySQL and SQLite.
The only difference found was the comment syntax in 01_real_data_schema.sql (see above).

Raw outputs: results/mysql_validation_output.txt and results/mysql_constraint_tests_output.txt
