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
