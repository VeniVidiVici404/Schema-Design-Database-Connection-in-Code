# Week 5 — Tasks 21–28: import and query assessment

## Execution status

There is no MySQL client/server in the execution environment. Therefore, the MySQL schema, import and validation scripts are prepared but have not been executed against MySQL. A separate SQLite reference database was created, populated and tested. Its schema is a portability translation of the supplied MySQL schema; it is not a substitute for verifying MySQL-specific types, collations, ENUMs and behavior on your laptop.

The portable database is included as reference_database/airbnb_market_real.sqlite. It contains all prepared normalized records. Query CSVs and validation.json are actual executed SQLite results, not invented MySQL outputs. SQL files target MySQL.

## 21–24. Import and validation

The MySQL workflow creates airbnb_market_real, then inserts parent tables before dependent tables. The import uses explicit columns, internal keys and SQL NULL values, within a transaction; foreign-key checks remain enabled. Text is encoded as UTF-8 hexadecimal SQL literals to preserve apostrophes, Unicode and backslashes safely. Insert statements are batched in 250-row groups.

One previously overlooked source record lacks minimum_nights. A real NOT NULL import failure in the reference database exposed this mismatch. The final schema makes minimum_nights nullable; known values still must be at least one. This is an additional justified change to the tasks 11–20 schema. A positive-known-rent CHECK was added after the zero-cell assessment. The final schema in this package supersedes the earlier real-data schema for the import.

Import totals: 1 city, 73 neighborhoods, 4,595 hosts, 15,293 accommodation records, 15,293 host associations, 1 platform, 15,293 listings, 15,293 snapshots, 365 housing observations, and no regulations or regulation areas.

All 24 recorded reference checks passed. These include counts, referential integrity, numeric bounds and six deliberately invalid updates rolled back after verifying rejection: negative price, availability 366, capacity zero, orphan neighborhood reference, duplicate platform/listing identity, and zero known rent. SQLite PRAGMA integrity_check returned ok and foreign_key_check returned no rows. These rejection checks do not establish MySQL's enforcement behavior.

No data were discarded to bypass constraints. Unknown values remain NULL, including 1 minimum stay, 1,938 prices, 2,562 bedroom counts, 21 rents, and activity flags. There are 15,293 unique source listing IDs and 344 positive rent observations.

## 25–27. Original and adapted queries

| Query | Original rows | Adapted rows | Interpretation and change |
|---|---:|---:|---|
| 1: neighborhood prices | 0 | 69 | Original filters active=TRUE, but activity is unknown. Adapted query describes observed listings, reports priced counts, and averages known prices. |
| 2: host portfolios | 1,607 | 1,607 | Source associations are available. Rename properties_owned to associated_accommodation_records; do not claim ownership or distinct physical homes. |
| 3: neighborhood ranking | 15,293 | 13,355 | Original includes missing prices. Adapted query ranks only known prices and shows external listing IDs. |
| 4: price growth and rent comparison | 0 | 0 | One observation per listing prevents price growth estimation. Remove the fixed April 2024 join. The adapted diagnostic measures consecutive observed price changes when data exist; the rent-growth comparison is deferred, not claimed complete. |
| 5: regulation assessment | 0 | 0 | Regulations are not populated. Adapted query checks both regulation dates against the snapshot date and labels its measure unavailable days, not booked nights or proven violations. |

Query 4 needs additional snapshots of the same listing IDs, then justified temporal alignment with rent quarters. Query 5 needs verified regulatory records and reliable occupancy evidence for any actual compliance claim. Their empty outputs represent insufficient evidence, not a broken database.

For query 1, the la Sagrada Família price mean was checked independently from the original CSV: EUR 267.08, matching the database result. Every listing has exactly one snapshot. Adapted query 3 returns exactly the 13,355 records with known prices. Query 2 identifies 1,607 hosts with more than one modelled accommodation association.

## 28. Query combining both sources

Query 6 returns 243 neighborhood–listing-date groups, with listing counts, known-price counts, average nightly listing price, rent quarter and rent per m²/month. Grouping by actual listing observation date makes timing visible. A LEFT JOIN retains listing groups when rent is unknown.

The latest available rent period is Q1 2026 for every neighborhood; June/July listing dates are later. Query 6 retains a Q1 NULL rent rather than silently falling back to an older nonmissing figure. These are contextual comparisons with different units and periods. The output cannot demonstrate a causal effect of Airbnb on rents or directly compare revenue profitability.

## Files and reproducibility

- 01_real_data_schema.sql: final MySQL schema.
- 02_import_real_data.sql: ready-to-run normalized data inserts.
- 03_original_queries.sql: original advanced queries with only the target database name changed.
- 04_adapted_queries.sql: six revised/new queries.
- 05_validation.sql: MySQL diagnostics and expected counts.
- results/: executed reference-query CSVs and validation evidence.

The Week 3 CRUD script contains writes/deletes and hard-coded mock IDs. It was not run against real records. Its read-only examples should be adapted separately; this report's five-query comparison covers the advanced analytical examples.
