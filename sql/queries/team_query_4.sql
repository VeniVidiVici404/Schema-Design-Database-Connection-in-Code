USE airbnb_market_real;

-- =====================================================================
-- TEAM QUERY 4
-- Author: Matteo-RSV (Matteo)
-- Question: How does rent growth compare with Airbnb listing counts
--           across Barcelona neighborhoods?
-- Relevance: Comparing listing counts with rent changes helps us explore
--            whether more tourist rentals go together with larger rent
--            increases, which matters for housing affordability.
-- Limits: This is a comparison table, not a statistical correlation test.
--         It cannot show that Airbnb caused rent increases. We compare
--         Q1 2025 and Q1 2026 rents with a June-July 2026 listing snapshot.
--         Counts are not adjusted for neighborhood size. Neighborhoods
--         without valid rents for both periods are excluded.
-- =====================================================================

SELECT
    n.name AS neighborhood,
    COUNT(DISTINCT l.listing_id) AS airbnb_listings,
    r25.avg_rent_per_m2 AS rent_q1_2025,
    r26.avg_rent_per_m2 AS rent_q1_2026,
    ROUND(100.0 * (r26.avg_rent_per_m2 - r25.avg_rent_per_m2)
        / r25.avg_rent_per_m2, 2) AS rent_change_pct
FROM neighborhood n
JOIN housing_market_observation r25
    ON r25.neighborhood_id = n.neighborhood_id
    AND r25.observation_date = '2025-01-01'
JOIN housing_market_observation r26
    ON r26.neighborhood_id = n.neighborhood_id
    AND r26.observation_date = '2026-01-01'
-- Keep neighborhoods with valid rents even if they have no listings.
LEFT JOIN property p ON p.neighborhood_id = n.neighborhood_id
LEFT JOIN listing l ON l.property_id = p.property_id
WHERE r25.avg_rent_per_m2 > 0
    AND r26.avg_rent_per_m2 > 0
GROUP BY n.neighborhood_id, n.name,
    r25.avg_rent_per_m2, r26.avg_rent_per_m2
ORDER BY airbnb_listings DESC, n.name;
