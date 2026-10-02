# Week 5 — Tasks 11–20

Completed on 2 October 2026. These tasks prepare data and an adjusted schema. The SQL has not been executed on a MySQL server; import and database validation are tasks 21–24.

## 11. Column mapping

| Input | Destination | Transformation / meaning |
|---|---|---|
| Source geography | city.name, city.country | Barcelona, Spain, established from source scope |
| Rent area code and name | neighborhood.neighborhood_id, name, city_id | Trim whitespace, normalize Unicode; internal IDs use the 73 neighborhood codes within this Barcelona-only import |
| Airbnb neighbourhood_cleansed | property.neighborhood_id | Match through neighborhood_mapping.csv |
| Airbnb host_id | host.source_host_id | Preserve 64-bit external ID; generate separate internal host_id |
| host_identity_verified | host.verified | t→1, f→0, blank→NULL; latest observation per host; unresolved same-date conflicts→NULL |
| property_type | property.property_type | Preserve full source category without forced lossy grouping |
| bedrooms | property.bedrooms | Integer, blank→NULL; zero bedrooms is valid |
| accommodates | property.capacity | Positive integer; denotes listed accommodation capacity |
| id | listing.source_listing_id | Preserve external ID; generate internal listing_id |
| Source platform | platform and listing.platform_id | Airbnb |
| room_type | listing.room_type | Entire home/apt→entire_home; Private room→private_room; Shared room→shared_room; Hotel room→hotel_room |
| license | listing.license_number | Trim outer whitespace, preserve full text, blank→NULL |
| minimum_nights | listing.minimum_nights | Positive integer; do not cap valid long minimum stays arbitrarily |
| last_scraped | listing_snapshot.snapshot_date | ISO date, preserve actual per-record date |
| price | listing_snapshot.nightly_price | Remove export dollar sign and grouping commas; Decimal rounded to cents, blank→NULL |
| availability_365 | listing_snapshot.available_days_next_365 | Integer 0–365; unavailable days do not imply bookings |
| number_of_reviews | listing_snapshot.reviews_count | Nonnegative integer |
| Rent year + standalone quarter | housing_market_observation.observation_date | Q1→Jan 1, Q2→Apr 1, Q3→Jul 1, Q4→Oct 1; a period label, not a daily observation |
| Rent columns C–F | housing_market_observation.avg_rent_per_m2 | Standalone quarterly contractual rent, EUR/m²/month, rounded to cents |

host_property links are generated from each listing's host and its modelled accommodation record. They describe a source association, not verified ownership.

External source IDs are retained in their owning entity. Source ID and internal ID are deliberately distinct. Internal neighborhood IDs are not census codes; neighborhood.census_code is left NULL.

## 12. Unavailable attributes and assumptions

- All 15,293 host_since values are blank. registration_date remains NULL; it is never replaced by a scrape or review date.
- host_type and country_origin are unknown. Do not infer nationality from host_location or classify professional hosts from listing count alone.
- Street address and purchase price per m² are unavailable. Both remain NULL.
- ownership_type and acquisition_date are unknown. The source host association does not establish legal ownership or agency.
- Listing first/last publication dates are unavailable. They remain NULL; first_review is not a publication date.
- active status is unknown. has_availability is not mapped to active, and zero available days does not mean inactive.
- Regulation tables remain empty: neither source establishes regulations. Sales prices, household counts, poverty, and long-term rental-unit totals remain NULL.
- One property record per listing is a provisional accommodation-unit model. Real physical homes may appear through multiple listings, so property counts cannot be reported as verified counts of distinct homes.
- Property descriptors/capacity are imported as observed once; future time-series work may require reconsidering which mutable attributes belong in snapshots.
- Other unused source columns remain in the untouched originals. No amenities lists, descriptions, or personal profile material are inserted into the normalized tables.

## 13. Neighborhood lookup

All 69 distinct Airbnb neighborhood names match the 73 official rent neighborhood names after Unicode normalization and trimming, plus two explicit aliases:

| Airbnb name | Official rent name |
|---|---|
| el Poble Sec | el Poble Sec - AEI Parc Montjuïc |
| la Marina del Prat Vermell | la Marina del Prat Vermell - AEI Zona Franca |

These aliases reconcile extended official labels to their corresponding neighborhood entries. They do not prove perfect equivalence of geographic boundaries between publishers. No fuzzy matching is used. Unknown names cause the script to stop rather than silently misassign records.

## 14–16. Missing values, duplicates, and formats

Airbnb blanks become NULL for optional attributes. Prices are missing in 1,938 records; bedrooms in 2,562. There are no duplicate listing IDs. Exact duplicate IDs would be removed; conflicting duplicates cause an error. Repeated host IDs are expected and become one host record; verification is resolved from the latest nonblank values at the latest host observation date.

Correction to the initial inspection: 365 numeric rent cells include **21 zero values**. They are not 365 usable positive measurements. There are **344 positive measurements**. Zero rents are treated conservatively as unknown and retained as NULL, not interpreted as free accommodation. The source mentions suppression for small contract counts, but does not explicitly define every zero as suppression; this interpretation remains a documented cleaning assumption. Original zero values remain recoverable from the workbook. Q2–Q4 2026 are absent and are not fabricated.

Dates are parsed as ISO calendar dates. Currency uses Decimal, not binary floating-point arithmetic. The publisher's dictionary states that the dollar sign is an export artifact and price is local currency: Barcelona prices are EUR. Property-type strings remain intact; room types map through the explicit four-category lookup. License text reaches 340 characters, so truncating to 50 would lose data. Repeated license strings are allowed and cannot identify a unique listing.

Rent extraction uses 2025 Q1–Q4 and 2026 Q1, neighborhood rows only, standalone quarterly columns only. It excludes city/district totals, headings, footnotes, and cumulative figures. Each resulting row has a unique neighborhood + quarter key. Identical measured values across different keys are not duplicates.

## 17–18. Schema changes

The adjusted schema is sql/01_real_data_schema.sql. It creates a separate airbnb_market_real database, leaving the original project's files and database intact. It intentionally fails if that database already exists; it contains no DROP DATABASE. Do not run the old mock-data or CRUD scripts against this real-data schema.

| Change | Reason |
|---|---|
| Add host.source_host_id BIGINT UNSIGNED UNIQUE | Preserve external host identity independently of internal IDs |
| Add listing.source_listing_id BIGINT UNSIGNED and UNIQUE(platform_id, source_listing_id) | External listing IDs may exceed signed INT; identity is platform-scoped |
| Nullable host classification, registration date, verification | Unknown information is not false or an invented category/date |
| property_type becomes VARCHAR(100) | Preserve the 50 observed source categories |
| Nullable bedrooms and street_address | Missing bedrooms/addresses must not be invented |
| Nullable ownership_type | Known source association, unknown legal role |
| Add hotel_room to room-type ENUM | Accommodate 68 source hotel-room records |
| license_number becomes TEXT; remove global uniqueness | Preserve long and repeated source text |
| Nullable listing publication dates | Scrape/review dates have different meanings |
| Nullable nightly_price and active | Keep missing prices and unknown activity without fabricated values |

Existing primary keys, foreign keys, snapshot/date uniqueness, capacity, price, minimum-stay and availability checks are retained. MySQL CHECK conditions permit NULL, so known invalid prices remain rejected while unknown prices are allowed. Schema execution and enforcement still need MySQL verification in subsequent tasks. The original 11-table architecture is preserved.

## 19. Reproducible cleaning

scripts/clean_real_data.py reads originals and writes normalized table CSVs plus a neighborhood lookup and JSON summary. It never writes to the inputs. openpyxl is used only to read the source workbook; no new Excel workbook is authored.

Fields with NULL are empty in output CSVs. A later import script must convert empty optional fields to SQL NULL, not empty strings or zero. Regeneration overwrites its output CSVs deterministically. An unexpected category, invalid integer, out-of-range price/availability, unmatched name, or conflicting listing duplicate stops processing.

## 20. Counts after cleaning

| Output table | Rows |
|---|---:|
| city | 1 |
| neighborhood | 73 |
| host | 4,595 |
| property | 15,293 |
| host_property | 15,293 |
| platform | 1 |
| listing | 15,293 |
| listing_snapshot | 15,293 |
| housing_market_observation | 365 |

Airbnb retains **15,293 distinct listing IDs**, including **13,355 with known prices**. Rent retains **365 distinct neighborhood–quarter observations**, of which **344 have positive known rents**. Both meet the 50-record requirement even when counting only known price/rent measurements. No listing records were discarded. There are no unresolved host-verification conflicts at the chosen latest observation dates.

The workflow was rerun into a separate output folder and all output file bytes compared successfully. Known-value ranges and source keys were checked during processing. This validates preparation, not a database import or SQL query execution.

## References

- Inside Airbnb data dictionary (price, source IDs, dates, availability definitions): https://docs.google.com/spreadsheets/d/1iWCNJcSutYqpULSQHlNyGInUvHg2BoUGoNRIGa6Szc4/edit
- Inside Airbnb assumptions (availability and location limitations): https://insideairbnb.com/data-assumptions/
- Source and licensing documentation: docs/01_dataset_inspection.md. Its zero-rent and currency statements are corrected by this report.
