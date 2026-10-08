# Week 5 addendum: 2023 household-income dataset

This addendum extends the existing Airbnb listings and Barcelona contractual-rent analysis with a third dataset. The earlier cleaning and query report remains the record for those two sources; this file records the extra source, its integration, and the effect on the final database. Use the revised schema and import order in the repository's README.

## Source and licence

The source is **Atles de distribució de la renda de les llars 2023**, distributed as `2023_atles_renda_bruta_llar.csv` by the Ajuntament de Barcelona's Open Data service. It reports average gross taxable household income in euros for census sections and is based on the INE household income atlas. The data reference year is 2023; the catalogue records the 2023 CSV distribution as created and updated on 22 October 2025. The catalogue lists **Creative Commons Attribution 4.0 International (CC BY 4.0)**. Cite the city and INE and retain the dataset title, year, and source URL when reusing the data.

- Dataset page and download: https://opendata-ajuntament.barcelona.cat/data/dataset/atles-renda-bruta-per-llar
- Catalogue record and distribution metadata: https://datos.gob.es/es/catalogo/l01080193-renda-tributaria-bruta-media-por-hogar-ano-de-la-ciudad-de-barcelona
- Licence: https://creativecommons.org/licenses/by/4.0/

## Cleaning and aggregation

The source contains **1,068 rows**, each identified by the composite key `(Codi_Districte, Codi_Barri, Seccio_Censal)`. `Seccio_Censal` alone repeats across neighborhoods, so it is not a unique key. All 1,068 composite keys and all income values were checked; there are 73 distinct Barcelona neighborhoods and no blank or non-positive income values.

The source's Catalan neighborhood labels were matched to the 73 canonical neighborhood records by exact name after trimming, plus five documented aliases for hyphen spacing and the two extended official labels:

| Source label | Canonical neighborhood |
|---|---|
| `Sant Gervasi- Galvany` | `Sant Gervasi - Galvany` |
| `Sant Gervasi- la Bonanova` | `Sant Gervasi - la Bonanova` |
| `Sants-Badal` | `Sants - Badal` |
| `el Poble Sec` | `el Poble Sec - AEI Parc Montjuïc` |
| `la Marina del Prat Vermell` | `la Marina del Prat Vermell - AEI Zona Franca` |

For each neighborhood, the script takes the simple arithmetic mean of the census-section gross household income values and rounds to cents. The stored value is therefore an **unweighted average of section-level estimates**, not a household-count-weighted neighborhood estimate. This limitation is important when comparing neighborhoods with different numbers or sizes of census sections. The 2023 annual reference period is stored as `2023-01-01` to satisfy the existing date-keyed observation design; it is not a claim that the measure was observed on that day.

The income measure is written to `housing_market_observation.avg_gross_household_income`. Rent observations retain NULL income values; the 73 income records retain NULL rent values. The existing `(neighborhood_id, observation_date)` uniqueness constraint remains valid because the income date does not overlap the 2025–2026 rent dates.

## Integration and validation

The updated schema adds a nullable `DECIMAL(12,2)` income column and a CHECK constraint that rejects non-positive known income while allowing NULL. The existing import remains unchanged; run `sql/real/03_import_income_data.sql` after importing the Airbnb and rent data. The supplied preparation script regenerates the 73-row CSV and SQL insert file from the original CSV and canonical neighborhood table.

| Integrated facts | Rows |
|---|---:|
| Airbnb listings | 15,293 unique source listing IDs |
| Positive known Airbnb prices | 13,355 |
| Rent observations | 365, including 21 zero source values represented as NULL; 344 positive rents |
| Household-income observations | 73 neighborhoods, all positive |
| Combined neighborhood observations | 438 |

The income import was checked in the portable SQLite reference database: all 73 rows matched one canonical neighborhood, all values were positive, and the existing foreign-key and uniqueness checks still passed. This is a portable-reference result, not evidence that MySQL has been run. MySQL import and CHECK enforcement still need to be verified on the project laptop.

The new adapted query reports neighborhood listing counts and mean known nightly prices alongside the 2023 income benchmark. It has **69 rows**, since 69 neighborhoods occur in the Airbnb data. It is descriptive only: income is from 2023 while listings were scraped in 2026, the measures have different units, and the dataset does not support causal conclusions.

## Normalization assessment

The new value is a neighborhood-level measure recorded by reference period. It depends on the neighborhood and its observation date, like the other measures in `housing_market_observation`; it does not depend on an unrelated non-key attribute. The nullable income column therefore introduces no new 1NF, 2NF, or 3NF violation under the report's stated functional dependencies. The averaging calculation is performed before import, so the normalized table stores one income value per neighborhood and annual period rather than census-section rows duplicated across Airbnb listings.

## Reproduction

From the repository root, after the source files are in the locations named below:

```bash
python scripts/prepare_income_data.py data/raw/2023_atles_renda_bruta_llar.csv data/cleaned/neighborhood.csv data/cleaned/neighborhood_income_2023.csv sql/real/03_import_income_data.sql
```

For MySQL, run the revised `sql/real/01_real_data_schema.sql`, `sql/real/02_import_real_data.sql`, and then `sql/real/03_import_income_data.sql`. Run `sql/real/04_validation.sql` and the seven adapted queries in `sql/queries/adapted_queries.sql`. The income import should only be run once per fresh database.
