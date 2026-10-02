# Week 5 — Dataset inspection (tasks 4–10)

Inspection date: 2 October 2026. The original computer download date was not independently verified; 2 October 2026 is the date the files were provided for inspection. No database schema, source data, or queries were changed.

## 4. Preserve original files

Both uploaded originals remain unchanged. Byte-identical working backup copies were created in an originals folder and verified with SHA-256. Keep the originals in your own databases folder; perform subsequent cleaning on separate working files. This report can be committed to GitHub without publishing the raw Airbnb data.

SHA-256 fingerprints:
- `listings.csv`: `1c035a1cbecd612da4e16325861a34cad1321e3014b9e39529d8910e9f85d5bd`
- `trimestral_bcn_lloguer_m2.xlsx`: `710f1bcdda778eed3ead4a829bbde32ce6c3922712f5cd1a41bbd54649189945`

## 5–7. Sources, licensing, and dates

### A. Inside Airbnb — Barcelona detailed listings

- Uploaded file: listings.csv, extracted from the detailed listings download.
- Publisher: Inside Airbnb.
- Source: https://insideairbnb.com/get-the-data/
- Download: https://data.insideairbnb.com/spain/catalonia/barcelona/2026-06-24/data/listings.csv.gz
- License: Creative Commons Attribution 4.0 International, https://creativecommons.org/licenses/by/4.0/ . Attribute Inside Airbnb and describe transformations.
- Source-labelled snapshot date: 24 June 2026. A separate publication date is not supplied in the inspected CSV; do not claim the snapshot date is a verified publication date.
- File scrape_id: 20260624162917.
- Actual last_scraped dates: 24 June (2,340 records), 25 June (10,695), 2 July (520), and 3 July 2026 (1,738).
- Access: public downloadable file, no registration or payment required.
- Community guidance: https://insideairbnb.com/data-policies/ . Download once; the publisher discourages republishing the raw data. Document download and import instructions instead.

### B. Generalitat de Catalunya — Barcelona contractual rent per m²

- Uploaded file: trimestral_bcn_lloguer_m2.xlsx.
- Publisher: Generalitat de Catalunya, housing statistics service; source statistics derived from rental deposits at INCASÒL.
- Source: https://habitatge.gencat.cat/ca/dades/indicadors_estadistiques/estadistiques_de_construccio_i_mercat_immobiliari/mercat_de_lloguer/lloguers-barcelona-per-districtes-i-barris/
- Download: https://habitatge.gencat.cat/web/.content/home/dades/estadistiques/01_Estadistiques_de_construccio_i_mercat_immobiliari/03_Mercat_de_lloguer/03_Lloguers_Barcelona_per_districtes_i_barris/trimestral_bcn_lloguer_m2.xlsx
- Reuse terms: https://web.gencat.cat/ca/avis-legal . The notice allows free reuse, modification, and combination under its open-information licensing framework, unless a specific work license overrides it. Cite the source and latest update; preserve the statistics' meaning. No workbook-specific license label was found. Do not label this workbook CC BY without further evidence.
- Source-page update: 13 July 2026; workbook modified metadata: 13 July 2026 at 07:46 (timezone unspecified). This confirms an update, not the original publication date.
- Workbook created metadata: 19 October 1999. This is template/file metadata, not a reliable publication date for these statistics.
- Access: public Excel download, no registration or payment required.

## 8. File structure and sample records

### Airbnb

15,293 records, 90 columns, 15,293 distinct nonblank listing IDs, 4,595 distinct host IDs, and 69 neighborhood names. Relevant columns include id, host_id, host_since, host_identity_verified, neighbourhood_cleansed, property_type, room_type, accommodates, bedrooms, price, minimum_nights, availability_365, number_of_reviews, license, and last_scraped. The complete header remains available in the original CSV.

| Listing ID | Neighborhood | Room type | Raw price | last_scraped |
|---|---|---|---|---|
| 18674 | la Sagrada Família | Entire home/apt | $409.00 | 2026-06-25 |
| 23197 | el Besòs i el Maresme | Entire home/apt | $388.00 | 2026-06-25 |
| 34981 | el Barri Gòtic | Entire home/apt | $397.13 | 2026-06-25 |

Price is blank in 1,938 records; bedrooms is blank in 2,562. All records have host_id and neighbourhood_cleansed. A dollar symbol appears in raw prices: verify currency using source documentation before attaching EUR or USD to imported values. Room types include 68 Hotel room records, a category absent from the current schema. These findings are for later cleaning; no replacements or exclusions were performed.

### Rent workbook

27 year sheets (2000–2026). Modern sheets are presentation tables, not ready-to-import flat tables. In the selected 2025/2026 sheets, row 6 holds quarter labels, column A holds area codes, and column B holds names. Rows 22–94 are 73 neighborhoods. Columns C–F hold standalone quarterly rents; H–K hold cumulative figures. Exclude cumulative figures, district totals, city totals, headings, and footnotes from neighborhood observations.

| Neighborhood code | Neighborhood | Q1 2025 rent, EUR/m²/month |
|---|---|---:|
| 1 | el Raval | 16.092835694756563 |
| 2 | el Barri Gòtic | 16.628656583756758 |
| 3 | la Barceloneta | 22.268580735235854 |

Names contain trailing whitespace. The source note states that areas with fewer than six registered contracts have figures withheld. A blank cell must not become zero. In 2026, only Q1 is populated; Q2–Q4 are blank. None of the selected 365 neighborhood-quarter values is missing.

## 9. Selected scope

Retain the full provided listing batch as one collection, preserving each record's actual last_scraped date. Do not fabricate multiple snapshots from its four scrape dates: each listing occurs only once.

Select all four quarters of 2025 and Q1 2026 rents for all 73 neighborhoods. This provides historical rent context and 365 usable observations. The latest available rent reference is Q1 2026, earlier than the June/July listing observations. Label that lag explicitly in comparisons; no same-quarter 2026 Q2 rent comparison is available in this file. Listing price growth cannot be measured with this single batch.

The datasets complement each other: individual short-term rental records versus aggregated long-term contractual rents. Neither contains the other's records or measurements. Geographic joins require a verified neighborhood mapping. Rent values are EUR/m²/month; nightly listing prices have different units and must not be directly subtracted or divided as if comparable.

## 10. Unique-record requirement

| Dataset scope | Unique key | Unique records | At least 50? |
|---|---|---:|---|
| All provided Airbnb listings | listing ID | 15,293 | Yes |
| 2025 Q1–Q4 rents | neighborhood code + year + quarter | 292 | Yes |
| 2026 Q1 rents | neighborhood code + year + quarter | 73 | Yes |
| Combined selected rent periods | neighborhood code + year + quarter | 365 | Yes |

Airbnb has no duplicate listing IDs. Selected rent neighborhood codes are unique within each year sheet; the 365 observation keys are distinct. Repeated rent values across different neighborhoods/quarters are not duplicate records. Counts must be rechecked after later cleaning and import.

## Next task

Task 11: map relevant source columns into the existing normalized tables, marking unavailable attributes. This inspection does not yet perform cleaning, import, constraint checks, query execution, or a 3NF reassessment.
