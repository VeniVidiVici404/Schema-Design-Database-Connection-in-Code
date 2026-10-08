-- =====================================================================
-- Original Week 3 queries (historical, kept for comparison)
-- File: sql/queries/original_queries.sql
-- Written by: Manos (VeniVidiVici404). The SQL is unchanged.
-- These queries were written for the mock data. On the real Barcelona data
-- some of them return no rows. The reasons are explained in
-- docs/import_validation_queries.md, and the adapted versions are in
-- sql/queries/adapted_queries.sql.
-- Run after the real schema and the import (see README, section 5b).
-- =====================================================================
USE airbnb_market_real;


-- =====================================================================
-- ORIGINAL QUERY 1 (original, Week 3)
-- Author: VeniVidiVici404 (Manos)
-- Question: Which neighborhoods have the highest average nightly price,
--           and how many active listings do they have?
-- Relevance: Shows where short-term rentals earn the most. A high price
--            gives owners a reason to rent to tourists instead of residents.
-- On the real data: 0 rows, because activity is unknown (see adapted Query 1).
-- =====================================================================
SELECT
    c.name                              AS city,
    n.name                               AS neighborhood,
    COUNT(DISTINCT l.listing_id)         AS active_listings,
    ROUND(AVG(latest.nightly_price), 2)  AS avg_nightly_price,
    ROUND(MIN(latest.nightly_price), 2)  AS min_nightly_price,
    ROUND(MAX(latest.nightly_price), 2)  AS max_nightly_price
FROM neighborhood n
JOIN city c            ON c.city_id = n.city_id
JOIN property p         ON p.neighborhood_id = n.neighborhood_id
JOIN listing l           ON l.property_id = p.property_id
JOIN listing_snapshot latest
     ON latest.listing_id = l.listing_id
    AND latest.snapshot_date = (
        SELECT MAX(ls2.snapshot_date)
        FROM listing_snapshot ls2
        WHERE ls2.listing_id = l.listing_id
    )
WHERE latest.active = TRUE
GROUP BY c.name, n.name
ORDER BY avg_nightly_price DESC;

-- =====================================================================
-- ORIGINAL QUERY 2 (original, Week 3)
-- Author: VeniVidiVici404 (Manos)
-- Question: Which hosts manage more than one property, and how many
--           listings do they have in total?
-- Relevance: Hosts with many properties work like businesses. They can
--            remove many homes from the housing market at once.
-- =====================================================================
SELECT
    h.host_id,
    h.host_type,
    h.verified,
    COUNT(DISTINCT hp.property_id) AS properties_owned,
    COUNT(DISTINCT l.listing_id)   AS total_listings
FROM host h
JOIN host_property hp ON hp.host_id = h.host_id
LEFT JOIN listing l    ON l.host_id = h.host_id
GROUP BY h.host_id, h.host_type, h.verified
HAVING COUNT(DISTINCT hp.property_id) > 1
ORDER BY properties_owned DESC, total_listings DESC;


-- =====================================================================
-- ORIGINAL QUERY 3 (original, Week 3)
-- Author: VeniVidiVici404 (Manos)
-- Question: How does each listing rank on price inside its own neighborhood?
-- Relevance: Shows the price spread in a neighborhood. The top-ranked
--            listings are the ones that earn the most compared to local rents.
-- =====================================================================
SELECT
    n.name                    AS neighborhood,
    l.listing_id,
    p.property_type,
    latest.nightly_price,
    RANK() OVER (
        PARTITION BY n.neighborhood_id
        ORDER BY latest.nightly_price DESC
    ) AS price_rank_in_neighborhood
FROM listing l
JOIN property p ON p.property_id = l.property_id
JOIN neighborhood n ON n.neighborhood_id = p.neighborhood_id
JOIN listing_snapshot latest
     ON latest.listing_id = l.listing_id
    AND latest.snapshot_date = (
        SELECT MAX(ls2.snapshot_date)
        FROM listing_snapshot ls2
        WHERE ls2.listing_id = l.listing_id
    )
ORDER BY n.name, price_rank_in_neighborhood;


-- =====================================================================
-- ORIGINAL QUERY 4 (original, Week 3)
-- Author: VeniVidiVici404 (Manos)
-- Question: Do listing prices grow faster or slower than the long-term
--           rent in the same neighborhood?
-- Relevance: This is the core worry of residents: do tourist prices and
--            rents rise together?
-- On the real data: 0 rows, because each listing has only one snapshot (see adapted Query 4).
-- =====================================================================
WITH listing_growth AS (
    SELECT
        ls.listing_id,
        ls.snapshot_date,
        ls.nightly_price,
        LAG(ls.nightly_price) OVER (
            PARTITION BY ls.listing_id ORDER BY ls.snapshot_date
        ) AS previous_price
    FROM listing_snapshot ls
),
rent_growth AS (
    SELECT
        hmo.neighborhood_id,
        hmo.observation_date,
        hmo.avg_rent_per_m2,
        LAG(hmo.avg_rent_per_m2) OVER (
            PARTITION BY hmo.neighborhood_id ORDER BY hmo.observation_date
        ) AS previous_rent
    FROM housing_market_observation hmo
)
SELECT
    n.name                                                         AS neighborhood,
    l.listing_id,
    lg.snapshot_date,
    ROUND(100 * (lg.nightly_price - lg.previous_price) / lg.previous_price, 2)  AS listing_price_growth_pct,
    ROUND(100 * (rg.avg_rent_per_m2 - rg.previous_rent) / rg.previous_rent, 2)  AS neighborhood_rent_growth_pct
FROM listing_growth lg
JOIN listing l          ON l.listing_id = lg.listing_id
JOIN property p          ON p.property_id = l.property_id
JOIN neighborhood n       ON n.neighborhood_id = p.neighborhood_id
JOIN rent_growth rg       ON rg.neighborhood_id = n.neighborhood_id
                          AND rg.observation_date = '2024-04-01'
WHERE lg.previous_price IS NOT NULL
ORDER BY neighborhood, l.listing_id, lg.snapshot_date;


-- =====================================================================
-- ORIGINAL QUERY 5 (original, Week 3)
-- Author: VeniVidiVici404 (Manos)
-- Question: In neighborhoods under a regulation, how many listings go
--           over the allowed number of nights per year?
-- Relevance: Shows if rules on tourist rentals are followed. This is what
--            a city needs to protect housing for residents.
-- On the real data: 0 rows, because no regulation data is loaded (see adapted Query 5).
-- =====================================================================
SELECT
    n.name                     AS neighborhood,
    r.regulation_type,
    r.annual_night_limit,
    COUNT(DISTINCT l.listing_id) AS total_listings,
    SUM(
        CASE
            WHEN r.annual_night_limit IS NOT NULL
             AND (365 - latest.available_days_next_365) > r.annual_night_limit
            THEN 1 ELSE 0
        END
    ) AS listings_over_limit
FROM regulation r
JOIN regulation_area ra ON ra.regulation_id = r.regulation_id
JOIN neighborhood n      ON n.neighborhood_id = ra.neighborhood_id
JOIN property p           ON p.neighborhood_id = n.neighborhood_id
JOIN listing l             ON l.property_id = p.property_id
JOIN listing_snapshot latest
     ON latest.listing_id = l.listing_id
    AND latest.snapshot_date = (
        SELECT MAX(ls2.snapshot_date)
        FROM listing_snapshot ls2
        WHERE ls2.listing_id = l.listing_id
    )
WHERE r.effective_to IS NULL OR r.effective_to >= CURDATE()
GROUP BY n.name, r.regulation_type, r.annual_night_limit
ORDER BY listings_over_limit DESC;
