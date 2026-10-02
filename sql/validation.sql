USE airbnb_market_real;

-- Expected counts after base import and the 2023 income import:
-- 1,73,4595,15293,15293,1,15293,15293,438,0,0.
SELECT 'city' AS table_name, COUNT(*) AS row_count FROM city
UNION ALL
SELECT 'neighborhood', COUNT(*) FROM neighborhood
UNION ALL
SELECT 'host', COUNT(*) FROM host
UNION ALL
SELECT 'property', COUNT(*) FROM property
UNION ALL
SELECT 'host_property', COUNT(*) FROM host_property
UNION ALL
SELECT 'platform', COUNT(*) FROM platform
UNION ALL
SELECT 'listing', COUNT(*) FROM listing
UNION ALL
SELECT 'listing_snapshot', COUNT(*) FROM listing_snapshot
UNION ALL
SELECT 'housing_market_observation', COUNT(*) FROM housing_market_observation
UNION ALL
SELECT 'regulation', COUNT(*) FROM regulation
UNION ALL
SELECT 'regulation_area', COUNT(*) FROM regulation_area;

-- Every result below should be zero.
SELECT 'property_neighborhood_orphans' AS check_name, COUNT(*) AS violations
FROM property p LEFT JOIN neighborhood n ON n.neighborhood_id=p.neighborhood_id WHERE n.neighborhood_id IS NULL
UNION ALL
SELECT 'listing_property_orphans', COUNT(*) FROM listing l LEFT JOIN property p ON p.property_id=l.property_id WHERE p.property_id IS NULL
UNION ALL
SELECT 'listing_host_orphans', COUNT(*) FROM listing l LEFT JOIN host h ON h.host_id=l.host_id WHERE h.host_id IS NULL
UNION ALL
SELECT 'snapshot_listing_orphans', COUNT(*) FROM listing_snapshot s LEFT JOIN listing l ON l.listing_id=s.listing_id WHERE l.listing_id IS NULL
UNION ALL
SELECT 'housing_neighborhood_orphans', COUNT(*) FROM housing_market_observation h LEFT JOIN neighborhood n ON n.neighborhood_id=h.neighborhood_id WHERE n.neighborhood_id IS NULL
UNION ALL
SELECT 'invalid_capacity', COUNT(*) FROM property WHERE capacity<1
UNION ALL
SELECT 'invalid_price', COUNT(*) FROM listing_snapshot WHERE nightly_price<=0
UNION ALL
SELECT 'invalid_availability', COUNT(*) FROM listing_snapshot WHERE available_days_next_365 NOT BETWEEN 0 AND 365
UNION ALL
SELECT 'invalid_minimum_stay', COUNT(*) FROM listing WHERE minimum_nights<1
UNION ALL
SELECT 'invalid_rent', COUNT(*) FROM housing_market_observation WHERE avg_rent_per_m2<=0;

SELECT COUNT(DISTINCT source_listing_id) AS unique_source_listings FROM listing;
SELECT COUNT(*) AS unique_housing_observations FROM (
SELECT neighborhood_id,observation_date FROM housing_market_observation GROUP BY neighborhood_id,observation_date
) AS rent_keys;
SELECT COUNT(*) AS known_positive_rents FROM housing_market_observation WHERE avg_rent_per_m2>0;
SELECT COUNT(*) AS known_positive_prices FROM listing_snapshot WHERE nightly_price>0;
SELECT COUNT(*) AS missing_minimum_nights FROM listing WHERE minimum_nights IS NULL;

-- Show the constraints installed by MySQL; negative-insert enforcement must be checked on MySQL separately.
SELECT TABLE_NAME,CONSTRAINT_NAME,CONSTRAINT_TYPE
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA='airbnb_market_real'
ORDER BY TABLE_NAME,CONSTRAINT_TYPE;

-- Household-income observations: expect 73 unique neighborhoods and no invalid known values.
SELECT COUNT(*) AS total_housing_observations FROM housing_market_observation;
SELECT COUNT(*) AS income_observations_2023
FROM housing_market_observation
WHERE observation_date = '2023-01-01'
  AND avg_gross_household_income IS NOT NULL;
SELECT COUNT(*) AS invalid_household_income_values
FROM housing_market_observation
WHERE avg_gross_household_income IS NOT NULL
  AND avg_gross_household_income <= 0;
SELECT COUNT(*) AS duplicate_income_neighborhoods
FROM (
    SELECT neighborhood_id
    FROM housing_market_observation
    WHERE observation_date = '2023-01-01'
      AND avg_gross_household_income IS NOT NULL
    GROUP BY neighborhood_id
    HAVING COUNT(*) > 1
) AS duplicate_income_keys;
