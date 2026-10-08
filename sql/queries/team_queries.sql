USE airbnb_market_real;

-- =====================================================================
-- TEAM QUERY 1
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
-- TEAM QUERY 2
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


-- =====================================================================
-- TEAM QUERY 5
-- Author: VeniVidiVici404 (Manos)
-- Question: In which neighborhoods do the most listings show no license
--           number?
-- Relevance: In Barcelona, tourist rentals need a license. Listings
--            without one may be illegal and may take homes from residents.
--            This shows where the city could check first.
-- Limits: A blank field can also mean exempt, or missing data. It is a
--         warning sign, not proof of an illegal listing. Only
--         neighborhoods with 30 or more listings are meaningful, so we
--         filter on that.
-- =====================================================================
SELECT
    n.name AS neighborhood,
    COUNT(*) AS total_listings,
    SUM(CASE WHEN l.license_number IS NULL OR TRIM(l.license_number) = '' THEN 1 ELSE 0 END) AS listings_without_license,
    ROUND(100.0 * SUM(CASE WHEN l.license_number IS NULL OR TRIM(l.license_number) = '' THEN 1 ELSE 0 END) / COUNT(*), 1) AS share_without_license_pct
FROM listing l
JOIN property p ON p.property_id = l.property_id
JOIN neighborhood n ON n.neighborhood_id = p.neighborhood_id
GROUP BY n.neighborhood_id, n.name
HAVING COUNT(*) >= 30
ORDER BY share_without_license_pct DESC, total_listings DESC
LIMIT 15;

-- =====================================================================
-- TEAM QUERY 6
-- Author: VeniVidiVici404 (Manos)
-- Question: How many nights per month must a host rent out a whole home
--           to earn the same as a long-term rent?
-- Relevance: If a host needs only a few nights to match the monthly rent,
--            renting to tourists is more attractive than renting to
--            residents. This is a possible reason why homes leave the
--            long-term market.
-- Limits: Nightly prices are asking prices, not paid prices. We do not
--         know the real occupancy. The 60 m2 flat is our own assumption.
--         Costs, taxes and fees are not included. Rent is Q1 2026 and
--         listings are June to July 2026.
-- =====================================================================
SELECT
    n.name AS neighborhood,
    COUNT(*) AS priced_entire_home_listings,
    ROUND(AVG(s.nightly_price), 2) AS avg_nightly_price_eur,
    r.avg_rent_per_m2 AS rent_eur_per_m2_month_q1_2026,
    ROUND(r.avg_rent_per_m2 * 60, 2) AS est_monthly_rent_60m2_eur,
    ROUND(r.avg_rent_per_m2 * 60 / AVG(s.nightly_price), 1) AS breakeven_nights_per_month
FROM listing l
JOIN property p ON p.property_id = l.property_id
JOIN neighborhood n ON n.neighborhood_id = p.neighborhood_id
JOIN listing_snapshot s ON s.listing_id = l.listing_id
JOIN housing_market_observation r
     ON r.neighborhood_id = n.neighborhood_id
    AND r.observation_date = '2026-01-01'
    AND r.avg_rent_per_m2 IS NOT NULL
WHERE l.room_type = 'entire_home'
  AND s.nightly_price IS NOT NULL
GROUP BY n.neighborhood_id, n.name, r.avg_rent_per_m2
HAVING COUNT(*) >= 20
ORDER BY breakeven_nights_per_month ASC;
EOF
