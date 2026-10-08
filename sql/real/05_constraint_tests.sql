USE airbnb_market_real;
-- Run with: mysql --force -u root   mysql -u root < sql/real/04_validation.sql -p < sql/real/05_constraint_tests.sql
-- Everything is rolled back at the end, so no data is changed.
START TRANSACTION;

-- T1 negative price (expect error 3819, chk_snapshot_price)
INSERT INTO listing_snapshot (listing_id, snapshot_date, nightly_price) VALUES (1, '2030-01-01', -5);

-- T2 availability 366 (expect 3819, chk_snapshot_availability)
INSERT INTO listing_snapshot (listing_id, snapshot_date, available_days_next_365) VALUES (1, '2030-01-02', 366);

-- T3 capacity 0 (expect 3819, chk_property_capacity)
INSERT INTO property (neighborhood_id, property_type, capacity) VALUES (1, 'apartment', 0);

-- T4 neighborhood that does not exist (expect 1452, foreign key)
INSERT INTO property (neighborhood_id, property_type, capacity) VALUES (9999, 'apartment', 2);

-- T5 duplicate platform and source listing id (expect 1062, uq_listing_source)
INSERT INTO listing (source_listing_id, property_id, host_id, platform_id, room_type)
SELECT source_listing_id, property_id, host_id, platform_id, room_type FROM listing LIMIT 1;

-- T6 zero rent (expect 3819, chk_rent_positive)
INSERT INTO housing_market_observation (neighborhood_id, observation_date, avg_rent_per_m2) VALUES (1, '2031-01-01', 0);

-- T7 zero income (expect 3819, chk_income_positive)
INSERT INTO housing_market_observation (neighborhood_id, observation_date, avg_gross_household_income) VALUES (1, '2031-01-02', 0);

ROLLBACK;