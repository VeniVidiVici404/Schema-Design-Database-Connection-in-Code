USE airbnb_market_real;

-- =====================================================================
-- TEAM QUERY 3
-- Author: Matteo-RSV (Matteo)
-- Question: How many listings are linked to hosts with few or many listings?
-- Relevance: This shows how much of the listing supply is concentrated
--            among hosts with several listings. It helps us investigate
--            possible pressure on housing available to residents.
-- Limits: Counts refer only to listings in our Barcelona dataset.
--         Several listings do not prove professional status or ownership.
--         Listings are not necessarily separate homes, and the data does
--         not show whether they were previously rented to residents.
-- =====================================================================

-- First count the listings linked to each host.
WITH host_counts AS (
    SELECT host_id, COUNT(*) AS listing_count
    FROM listing
    GROUP BY host_id
)
SELECT
    CASE
        WHEN listing_count = 1 THEN '1 listing'
        WHEN listing_count BETWEEN 2 AND 4 THEN '2 to 4 listings'
        ELSE '5 or more listings'
    END AS host_group,
    COUNT(*) AS hosts,
    SUM(listing_count) AS listings,
    ROUND(100.0 * SUM(listing_count) / (SELECT COUNT(*) FROM listing), 1)
        AS share_of_all_listings_pct
FROM host_counts
GROUP BY host_group
ORDER BY MIN(listing_count);
