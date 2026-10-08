# Airbnb Housing Market Analysis — Database Project

**Course:** Databases KEN2110 — Data Modelling  
**Team:** Manos Chaloftidis, Matteo Restivo, Alexandre Kupfermunz  

## 1. Project overview

This repository implements the relational database for our Airbnb housing 
market analysis project. It models short-term rental listings, the hosts and 
properties behind them, the platforms they're published on, and the local 
housing-market context (rents, sale prices, and regulations) they operate in.

The design started from an ERD (see `docs/erd.pdf`) and was normalized 
through 1NF → 2NF → 3NF (see `docs/normalization.md`) before being implemented 
as a MySQL schema. In Week 4, we delivered a 5-minute stakeholder pitch presentation 
translating these schema insights for municipal housing authorities. In Week 5, 
we integrated two complementary real-world datasets from Barcelona to stress-test 
our schema, normalization, and constraints with real market data.

## 2. Stakeholder video presentation (Week 4)

[![Stakeholder Video Presentation](https://raw.githubusercontent.com/VeniVidiVici404/Schema-Design-Database-Connection-in-Code/main/Databases%20Project%20Pitch.jpg)](https://raw.githubusercontent.com/VeniVidiVici404/Schema-Design-Database-Connection-in-Code/main/Database%20Project%20Pitch.mp4)

> **[Watch the Project Pitch Video (MP4)](Database%20Project%20Pitch.mp4)**  
> *When homes become holiday rentals: What our database can tell cities about short-term rentals and housing.*  
> Click the thumbnail above or the direct link to play the video.

## 3. Repository structure

```
.
├── README.md
├── requirements.txt                       Python packages (openpyxl)
├── .gitignore
├── media/
│   ├── pitch_video.mp4                    Week 4 stakeholder video
│   └── pitch_thumbnail.png                Thumbnail used in this README
├── data/
│   ├── raw/
│   │   └── 2023_atles_renda_bruta_llar.csv    Income source (CC BY 4.0)
│   │                                          Airbnb and rent files are downloaded
│   │                                          here by scripts/download_raw_data.py
│   └── cleaned/                           Output of the cleaning scripts
│       ├── city.csv, neighborhood.csv, host.csv, property.csv,
│       │   host_property.csv, platform.csv, listing.csv,
│       │   listing_snapshot.csv, housing_market_observation.csv
│       ├── neighborhood_mapping.csv
│       ├── neighborhood_income_2023.csv
│       └── cleaning_summary.json
├── docs/
│   ├── erd.pdf                            Entity relationship diagram
│   ├── dataset_inspection.md              Sources, licenses, dates
│   ├── mapping_and_cleaning.md            Column mapping, cleaning, schema changes
│   ├── income_dataset_addendum.md         Third dataset (income)
│   ├── normalization.md                   1NF, 2NF, 3NF checks
│   ├── import_validation_queries.md       Import checks, original vs adapted queries
│   ├── mysql_validation.md                Results of the MySQL run
│   ├── queries.md                         Query catalogue (author, question, relevance)
│   └── sql_review.md                      SQL review notes
├── results/
│   ├── validation.json                    Check results (SQLite reference)
│   └── income_airbnb_comparison.csv       Output of adapted query 7
├── scripts/
│   ├── download_raw_data.py               Downloads the Airbnb and rent files
│   ├── clean_real_data.py                 Cleans raw data into data/cleaned/
│   ├── prepare_income_data.py             Aggregates income to 73 neighborhoods
│   ├── generate_import.py                 Builds the big INSERT file from data/cleaned/
│   └── build_real_data.sh                 Runs all four scripts in order
└── sql/
    ├── mock/                              Weeks 1 to 4 (database airbnb_market)
    │   ├── 01_schema.sql
    │   ├── 02_mock_data.sql
    │   ├── 03_crud_operations.sql
    │   └── 04_advanced_queries.sql
    ├── real/                              Weeks 5 and 6 (database airbnb_market_real)
    │   ├── 01_real_data_schema.sql
    │   ├── 02_import_real_data.sql        Generated file, not in git
    │   ├── 03_import_income_data.sql
    │   ├── 04_validation.sql
    │   └── 05_constraint_tests.sql
    └── queries/
        ├── original_queries.sql           Week 3 queries, unchanged
        ├── adapted_queries.sql            Queries adapted to the real data
        └── team_queries.sql               New queries, one author per query
```

## 4. Entity overview

| Table | Description |
|---|---|
| `city` | A city in the dataset (e.g. Barcelona, Berlin, Lisbon) |
| `neighborhood` | A neighborhood within a city |
| `regulation` | A short-term-rental regulation adopted by a city |
| `regulation_area` | Junction table: which neighborhoods a regulation covers (M:N) |
| `host` | A person/company that hosts short-term rentals |
| `property` | A physical unit located in a neighborhood |
| `host_property` | Junction table: which hosts own/manage which properties (M:N) |
| `platform` | A booking platform (Airbnb, Booking.com, Vrbo) |
| `listing` | A property marketed by a host on a platform |
| `listing_snapshot` | Time-series price/availability data for a listing |
| `housing_market_observation` | Time-series macro housing stats per neighborhood |

Full column definitions, data types, and constraints are in
[`sql/01_schema.sql`](sql/01_schema.sql).

## 5. How to run this project

**Requirements:** MySQL 8.0+ (Community Server, MySQL Workbench, or any 
MySQL-compatible client such as DBeaver).

1. Clone the repository:
   ```bash
   git clone <this-repo-url>
   cd <repo-folder>
   ```

2. Run the scripts **in order** against your MySQL server:
   ```bash
   mysql -u <your_user> -p < sql/01_schema.sql
   mysql -u <your_user> -p < sql/02_mock_data.sql
   mysql -u <your_user> -p < sql/03_crud_operations.sql
   mysql -u <your_user> -p < sql/04_advanced_queries.sql
   mysql -u <your_user> -p < sql/05_real_data.sql
   ```
   Or open each file in MySQL Workbench and execute it top to bottom.

   `01_schema.sql` creates its own database (`airbnb_market`), so no manual 
   `CREATE DATABASE` step is needed first.

3. To inspect real-world integration results, execute the verification queries
   at the bottom of `sql/05_real_data.sql`.

We did not include a full binary database dump for this assignment, as instructed; 
the scripts above are completely self-contained and reproduce the database from scratch.

## 6. What each SQL file demonstrates

- **`01_schema.sql`** — full DDL: primary keys, foreign keys (with 
`ON UPDATE`/`ON DELETE` rules), `UNIQUE`, `NOT NULL`, `CHECK` constraints, 
`ENUM` types for controlled vocabularies, and indexes to support the joins 
used later.
- **`02_mock_data.sql`** — realistic mock data across 3 cities, 7 
neighborhoods, 4 regulations, 8 hosts, 12 properties, 3 platforms, 
12 listings, and monthly price/availability snapshots.
- **`03_crud_operations.sql`** — annotated examples of `INSERT`, `SELECT` 
(including joins and correlated subqueries), `UPDATE`, and `DELETE`, 
including a demonstration of cascading vs. restricted deletes.
- **`04_advanced_queries.sql`** — 5 advanced queries demonstrating joins, subqueries, CTEs, and window functions (`RANK()`, `LAG()`).
- **`05_real_data.sql`** — Week 5 real-world data integration:
  - Applies required schema adjustments (`BIGINT UNSIGNED` identifiers, expanded `ENUM` sets, nullable scrape fields, and socioeconomic income metrics).
  - Inserts canonical dimensions for Barcelona, platforms, and 73 administrative neighborhoods.
  - Integrates 65 clean Airbnb listings, hosts, proxy properties, and snapshots (Source A).
  - Ingests 2023 gross household income benchmarks for all 73 Barcelona neighborhoods (Source B).
  - Executes automated constraint verification checks and cross-dataset analytical queries.

## 7. Team workflow / collaboration

- All team members have **write access** to this repository.
- We work on feature branches (e.g. `schema-update`, `add-queries`, `real-data-integration`) and open **Pull Requests** into `main` for review — no direct pushes to `main`.
- Each PR requires at least one approval from another team member before merging, ensuring all members read and understand every change to the schema and queries.
- Commit messages describe *what* changed and *why* (e.g. "Adjust host_id to BIGINT and add real data batch inserts").
