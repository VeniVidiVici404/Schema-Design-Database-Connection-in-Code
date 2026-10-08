USE airbnb_market_real;

-- =====================================================================
-- ADAPTED QUERY 1
-- Author: Matteo-RSV (Matteo)
-- Adapted from: original Query 1 (Manos)
-- Question: Which neighborhoods have the highest average nightly price,
--           and how many listings were observed?
-- Relevance: Shows where short-term rentals earn the most, which is where
--            the pressure on housing is likely to be highest.
-- What changed: The original filtered on active = TRUE, but activity is
--               unknown in the real data (0 rows). Now it counts all observed
--               listings and averages only the known prices.
-- =====================================================================

SELECT
    c.name AS city,
    n.name AS neighborhood,
    COUNT(*) AS observed_listings,
    COUNT(s.nightly_price) AS listings_with_price,
    ROUND(AVG(s.nightly_price),2) AS avg_nightly_price_eur,
    MIN(s.nightly_price) AS min_nightly_price_eur,
    MAX(s.nightly_price) AS max_nightly_price_eur

FROM listing l 
JOIN property p ON p.property_id = l.property_id

JOIN neighborhood n ON n.neighborhood_id = p.neighborhood_id 
JOIN city c ON c.city_id = n.city_id

JOIN listing_snapshot s ON s.listing_id = l.listing_id

WHERE s.snapshot_date = (SELECT MAX(s2.snapshot_date)
    FROM listing_snapshot s2
    WHERE s2.listing_id  =  l.listing_id)

GROUP BY c.city_id, c.name, n.neighborhood_id, n.name 
ORDER BY avg_nightly_price_eur DESC;

-- =====================================================================
-- ADAPTED QUERY 2
-- Author: Matteo-RSV (Matteo)
-- Adapted from: original Query 2 (Manos)
-- Question: Which hosts are linked to more than one accommodation record?
-- Relevance: Hosts with many listings act like businesses and can take many
--            homes out of the housing market.
-- What changed: The column is renamed because the data show associations,
--               not verified ownership.
-- =====================================================================

SELECT
    h.host_id,
    h.source_host_id,
    h.host_type,
    h.verified,
    COUNT(DISTINCT hp.property_id) AS associated_accommodation_records,
    COUNT(DISTINCT l.listing_id) AS total_listings

FROM host h 
JOIN host_property hp ON hp.host_id = h.host_id

LEFT JOIN listing l ON l.host_id = h.host_id

GROUP BY h.host_id, h.source_host_id, h.host_type, h.verified

HAVING COUNT(DISTINCT hp.property_id)>1 
ORDER BY associated_accommodation_records DESC, h.host_id;

-- =====================================================================
-- ADAPTED QUERY 3
-- Author: Matteo-RSV (Matteo)
-- Adapted from: original Query 3 (Manos)
-- Question: How does each listing rank on price inside its neighborhood?
-- Relevance: Shows the price spread inside a neighborhood and which listings
--            earn the most compared with local rents.
-- What changed: Only listings with a known price are ranked (13,355 rows).
--               The external listing ID is shown.
-- =====================================================================

SELECT
    c.name AS city,
    n.name AS neighborhood,
    l.source_listing_id,
    p.property_type,
    s.nightly_price,
    RANK() OVER (PARTITION BY n.neighborhood_id ORDER BY s.nightly_price DESC) AS price_rank_in_neighborhood

FROM listing l 
JOIN property p ON p.property_id = l.property_id

JOIN neighborhood n ON n.neighborhood_id = p.neighborhood_id 
JOIN city c ON c.city_id = n.city_id

JOIN listing_snapshot s ON s.listing_id = l.listing_id

WHERE s.nightly_price IS NOT NULL 
AND s.snapshot_date = (SELECT MAX(s2.snapshot_date)
    FROM listing_snapshot s2
    WHERE s2.listing_id  =  l.listing_id)

ORDER BY n.neighborhood_id, price_rank_in_neighborhood, l.source_listing_id;

-- =====================================================================
-- ADAPTED QUERY 4
-- Author: Matteo-RSV (Matteo)
-- Adapted from: original Query 4 (Manos)
-- Question: Did the price of a listing change between two observations?
-- Relevance: Needed to compare tourist prices with rent growth, which is
--            the core question of residents.
-- What changed: The fixed April 2024 join was removed. Returns 0 rows,
--               because each listing has only one snapshot. This is a data
--               limit, not an error.
-- =====================================================================

WITH listing_growth AS (
SELECT listing_id, snapshot_date, nightly_price,
LAG(nightly_price) OVER (PARTITION BY listing_id ORDER BY snapshot_date) AS previous_price
FROM listing_snapshot)

SELECT
    listing_id,
    snapshot_date,
    ROUND(100.0*(nightly_price-previous_price)/NULLIF(previous_price,0),2) AS observed_price_growth_pct

FROM listing_growth 
WHERE previous_price IS NOT NULL 
AND nightly_price IS NOT NULL

ORDER BY listing_id, snapshot_date;

-- =====================================================================
-- ADAPTED QUERY 5
-- Author: Matteo-RSV (Matteo)
-- Adapted from: original Query 5 (Manos)
-- Question: In neighborhoods under a regulation, how many listings have
--           more unavailable days than the allowed nights?
-- Relevance: Shows if rules on tourist rentals could be checked.
-- What changed: Dates of the regulation are checked. The measure is called
--               unavailable days, because they are not proven booked nights.
--               Returns 0 rows, because no regulation data are loaded.
-- =====================================================================

SELECT
    n.name AS neighborhood,
    r.regulation_id,
    r.regulation_type,
    r.annual_night_limit,
    COUNT(*) AS observed_listings,
    SUM(CASE WHEN r.annual_night_limit IS NOT NULL AND 365-s.available_days_next_365>r.annual_night_limit THEN 1 ELSE 0 END) AS unavailable_days_above_limit

FROM regulation r 
JOIN regulation_area ra ON ra.regulation_id = r.regulation_id

JOIN neighborhood n ON n.neighborhood_id = ra.neighborhood_id

JOIN property p ON p.neighborhood_id = n.neighborhood_id 
JOIN listing l ON l.property_id = p.property_id

JOIN listing_snapshot s ON s.listing_id = l.listing_id

WHERE s.snapshot_date = (SELECT MAX(s2.snapshot_date)
    FROM listing_snapshot s2
    WHERE s2.listing_id  =  l.listing_id)

AND r.effective_from<=s.snapshot_date 
AND (r.effective_to IS NULL OR r.effective_to>=s.snapshot_date)

GROUP BY n.neighborhood_id, n.name, r.regulation_id, r.regulation_type, r.annual_night_limit

ORDER BY unavailable_days_above_limit DESC;

-- =====================================================================
-- ADAPTED QUERY 6
-- Author: Matteo-RSV (Matteo)
-- Question: How do listing prices compare with the latest long-term rent
--           in each neighborhood?
-- Relevance: Combines the Airbnb data with the rent data. It shows where
--            short-term prices are high compared with the rent for residents.
-- Limits: Units differ (euro per night and euro per m2 per month), and rent is
--         Q1 2026 while listings are June to July 2026. Descriptive only.
-- =====================================================================

SELECT
    n.name AS neighborhood,
    s.snapshot_date AS listing_observed_date,
    h.observation_date AS rent_quarter_start,
    COUNT(*) AS observed_listings,
    COUNT(s.nightly_price) AS listings_with_price,
    ROUND(AVG(s.nightly_price),2) AS avg_nightly_price_eur,
    h.avg_rent_per_m2 AS residential_rent_eur_m2_month

FROM listing l 
JOIN property p ON p.property_id = l.property_id

JOIN neighborhood n ON n.neighborhood_id = p.neighborhood_id

JOIN listing_snapshot s ON s.listing_id = l.listing_id

LEFT JOIN housing_market_observation h ON h.neighborhood_id = n.neighborhood_id

AND h.observation_date = (SELECT MAX(h2.observation_date) FROM housing_market_observation h2
WHERE h2.neighborhood_id = n.neighborhood_id AND h2.observation_date<=s.snapshot_date)

WHERE s.snapshot_date = (SELECT MAX(s2.snapshot_date)
    FROM listing_snapshot s2
    WHERE s2.listing_id  =  l.listing_id)

GROUP BY n.neighborhood_id, n.name, s.snapshot_date, h.observation_date, h.avg_rent_per_m2

ORDER BY n.neighborhood_id, s.snapshot_date;

-- =====================================================================
-- ADAPTED QUERY 7
-- Author: Matteo-RSV (Matteo)
-- Question: How do listing counts and prices relate to the 2023 household
--           income of each neighborhood?
-- Relevance: Shows if tourist rentals are concentrated in richer or poorer
--            areas, which matters for who is affected by them.
-- Limits: Income is from 2023, listings from 2026. No causal claim.
-- =====================================================================
WITH listing_summary AS (
    SELECT
        p.neighborhood_id,
        COUNT(DISTINCT l.listing_id) AS observed_listings,
        COUNT(s.nightly_price) AS listings_with_price,
        ROUND(AVG(s.nightly_price), 2) AS avg_nightly_price_eur
    FROM listing l
    JOIN property p ON p.property_id = l.property_id
    JOIN listing_snapshot s ON s.listing_id = l.listing_id
    GROUP BY p.neighborhood_id
)
SELECT
    n.name AS neighborhood,
    i.observation_date AS income_reference_date,
    i.avg_gross_household_income AS avg_section_gross_household_income_eur,
    ls.observed_listings,
    ls.listings_with_price,
    ls.avg_nightly_price_eur
FROM housing_market_observation i
JOIN neighborhood n ON n.neighborhood_id = i.neighborhood_id
JOIN listing_summary ls ON ls.neighborhood_id = n.neighborhood_id
WHERE i.observation_date = '2023-01-01'
ORDER BY ls.avg_nightly_price_eur DESC, n.name;
