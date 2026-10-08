USE airbnb_market_real;

-- =====================================================================
-- Q8
-- Author: <Alexandre Kupfermunz>
-- Question: In which neighborhoods does a typical household spend the
--           largest share of its income on rent?
-- Relevance: Rising rents push residents out. Comparing rent with income
--            shows where housing is least affordable, which is where
--            short-term rentals may add the most pressure.
-- Limits: Income is 2023, rent is Q1 2026. The 60 m2 flat is our own
--         assumption. This is descriptive, not causal.
-- =====================================================================
SELECT
    n.name AS neighborhood,
    inc.avg_gross_household_income AS avg_household_income_eur_2023,
    rent.avg_rent_per_m2 AS rent_eur_per_m2_month_q1_2026,
    ROUND(100.0 * (rent.avg_rent_per_m2 * 60 * 12) / inc.avg_gross_household_income, 1) AS rent_burden_pct_for_60m2
FROM neighborhood n
JOIN housing_market_observation inc
     ON inc.neighborhood_id = n.neighborhood_id
    AND inc.observation_date = '2023-01-01'
    AND inc.avg_gross_household_income IS NOT NULL
JOIN housing_market_observation rent
     ON rent.neighborhood_id = n.neighborhood_id
    AND rent.observation_date = '2026-01-01'
    AND rent.avg_rent_per_m2 IS NOT NULL
ORDER BY rent_burden_pct_for_60m2 DESC;

-- =====================================================================
-- Q9
-- Author: <Alexandre Kupfermunz>
-- Question: In which neighborhoods are most listings whole homes
--           (not rooms)?
-- Relevance: A whole home rented to tourists is a home that is not
--            available for residents. A high share of entire homes
--            points to more pressure on housing supply.
-- Limits: Inside Airbnb does not say if a home was a resident's home
--         before. Only neighborhoods with 30 or more listings are shown.
-- =====================================================================
SELECT
    n.name AS neighborhood,
    COUNT(*) AS total_listings,
    SUM(CASE WHEN l.room_type = 'entire_home' THEN 1 ELSE 0 END) AS entire_home_listings,
    ROUND(100.0 * SUM(CASE WHEN l.room_type = 'entire_home' THEN 1 ELSE 0 END) / COUNT(*), 1) AS entire_home_share_pct
FROM listing l
JOIN property p ON p.property_id = l.property_id
JOIN neighborhood n ON n.neighborhood_id = p.neighborhood_id
GROUP BY n.neighborhood_id, n.name
HAVING COUNT(*) >= 30
ORDER BY entire_home_share_pct DESC, total_listings DESC
LIMIT 15;
