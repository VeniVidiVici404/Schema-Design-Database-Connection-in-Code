# Normalization summary — updated Week 2 report

This preserves the original normalization discussion and adds the Week 5 assessment below. The assessment applies to the documented entity meanings, not only accidental patterns in the current sample.

## Original normalization discussion

# Normalization Summary

This project's schema was normalized starting from a single, denormalized
`AIRBNB_RAW_DATA` table containing listing, property, host, city, and
regulation information all mixed together.

## Problems in the unnormalized table
- Repeated values (e.g. city and host names) stored redundantly on every row.
- Update anomalies: changing one host's details required updating every row
  for that host.
- Insertion anomalies: a regulation couldn't be recorded without an
  associated listing already existing.
- Deletion anomalies: removing all of a host's listings could silently
  delete the only record that a given host existed.

## 1NF — Atomic values
Split the single flat table into separate entities (`CITY`, `HOST`,
`NEIGHBORHOOD`, etc.) so that every column holds a single, atomic value and
each real-world concept has its own table linked by keys, rather than
repeating text fields across rows.

## 2NF — Remove partial dependencies
Where a table had a composite key, we made sure every non-key column
depended on the *whole* key, not just part of it. For example, static
property attributes (`property_type`, `bedrooms`, `capacity`) were pulled
out of the time-series `LISTING_SNAPSHOT` table (keyed by
`listing_id + snapshot_date`) and moved into the `PROPERTY` table, since
they only depend on the property, not the specific snapshot date.

## 3NF — Remove transitive dependencies
We removed cases where a non-key attribute depended on another non-key
attribute rather than directly on the primary key. For example,
`city_name`/`country` were removed from `NEIGHBORHOOD` (they depend on
`city_id`, not directly on `neighborhood_id`) and kept only in the `CITY`
table, referenced via foreign key.

## Result
The final schema (implemented in [`../sql/01_schema.sql`](../sql/01_schema.sql))
has one clear "single source of truth" per entity, avoids redundant storage,
and prevents the update/insertion/deletion anomalies described above, while
still supporting the joins needed for market analysis queries.

See `erd.pdf` in this folder for the full diagram and the original
normalization walkthrough this summary is based on.


## Week 5: real-data reassessment (tasks 29–30)

For a functional dependency X → A, 3NF requires X to be a superkey or A to be a prime attribute. A surrogate primary key alone does not prove 3NF; dependencies among non-key attributes must also be considered.

| Table | Primary key / determinant | Attributes dependent on the key |
|---|---|---|
| city | city_id; also unique name + country | name, country |
| neighborhood | neighborhood_id; also city_id + name | city_id, name, optional census_code and coordinates |
| regulation | regulation_id | city_id, type, effective dates, limit, registration flag, description |
| regulation_area | regulation_id + neighborhood_id | None; association keys only |
| host | host_id | external source ID, classification, verification, registration date, origin |
| property | property_id | neighborhood_id, observed accommodation type, bedrooms, capacity, address, purchase price |
| host_property | host_id + property_id | relationship role and acquisition/association date |
| platform | platform_id; also name | name, website_url |
| listing | listing_id | source ID, property_id, host_id, platform_id, room type, source license text, dates, minimum nights |
| listing_snapshot | snapshot_id; also listing_id + snapshot_date | nightly price, future availability, activity, reviews |
| housing_market_observation | observation_id; also neighborhood_id + observation_date | rent, gross household income, sale price and other area-period statistics |

Source host/listing IDs are unique among populated records. Because the columns are nullable, their SQL UNIQUE declarations are not universal relational candidate keys. Primary keys remain the authoritative identifiers. The external listing key is platform-scoped.

### 1NF

Each imported column holds one scalar value. Spreadsheet year/quarter columns are transformed into separate observation rows; cumulative values and aggregate rows are excluded. Host profile collections and amenity arrays are not imported. license_number preserves one uninterpreted source statement, sometimes long, rather than asserting one validated permit identifier. If individual permits are to be queried or validated, parse verified permits into a separate listing-permit association; this implementation does not claim that free-text permits are already structured permit entities.

### 2NF

For composite-key association tables, any relationship attributes depend on the pair of entities under the current model. Static host/property information is not copied into those association tables. Snapshot facts depend on listing and date; housing facts depend on neighborhood and quarter. No partial dependency requiring decomposition was identified under these meanings.

### 3NF

City descriptions remain in city; neighborhood descriptions remain in neighborhood; host attributes remain in host; platform descriptions remain in platform. Imported listings do not repeat these descriptions. Rent and income observations do not repeat district/city/neighborhood names or period labels as independent redundant attributes. Gross household income is stored at the neighborhood-year observation level, alongside other area-period facts; it is not copied into individual listing rows. No additional non-key determinant requiring decomposition was established by the source semantics. Missing data, repeated licenses, and unsupported categories are data-quality/domain issues, not automatically normal-form violations.

Conclusion: no new 1NF–3NF violation was identified for the normalized imported representation under the stated assumptions. No further table decomposition was required; changes concern domains, nullability, source identities, and positive-value checks for known rent and income. The income aggregation is performed before import, and the resulting value is stored once per neighborhood and reference year. This is a qualified assessment, not a proof that every future interpretation or source will preserve the same dependencies.

### Assumptions and remaining design questions

- One modelled property per source listing is not verified physical-property deduplication. If a physical home is identified across listings, reconcile identities without duplicating property attributes. Do not promote property_id → listing attributes merely because this sample is one-to-one; the schema intentionally permits multiple listings per property.
- host_property.acquisition_date is treated as relationship-specific. If it is later defined as a property-only date regardless of host, move it to property or a suitable acquisition entity; that interpretation would create a partial dependency.
- Text property descriptors overlap with room descriptions semantically, but no additional exact functional dependency is assumed without verification.
- All source_host_id values currently refer to Airbnb. Supporting other source platforms requires a source-scoped host identity mapping.
- Future collection may require historizing mutable host/listing/property attributes. Temporal modelling completeness is distinct from 3NF.
- Cross-city regulation-area consistency and listing/host-property consistency are integrity rules beyond normalization; foreign keys alone do not enforce all such business relationships.

The empty regulation tables cannot be empirically validated with these datasets. Their assessment relies on documented dependencies. Source assumptions are documented in 03_import_validation_queries.md and the tasks 11–20 mapping report.
