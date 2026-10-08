# Query catalogue

Societal problem: short-term rentals and the housing market in Barcelona.
All row counts come from MySQL (see docs/mysql_validation.md).
Each query has the same documentation (Author, Question, Relevance) in its SQL file.

## Original Week 3 queries (sql/queries/original_queries.sql)

| ID | Author | Question | Relevance to the problem | Rows |
|---|---|---|---|---|
| O1 | VeniVidiVici404 (Manos) | Which neighborhoods have the highest average nightly price and how many active listings? | A high price gives owners a reason to rent to tourists instead of residents | 0 (activity unknown) |
| O2 | VeniVidiVici404 (Manos) | Which hosts manage more than one property? | Hosts with many properties can remove many homes at once | 1607 |
| O3 | VeniVidiVici404 (Manos) | How does each listing rank on price in its neighborhood? | Shows the price spread and which listings earn the most | 15293 |
| O4 | VeniVidiVici404 (Manos) | Do listing prices grow faster than rent? | Core worry of residents | 0 (one snapshot) |
| O5 | VeniVidiVici404 (Manos) | How many listings go over the regulation night limit? | Shows if rules are followed | 0 (no regulation data) |

## Adapted queries for the real data (sql/queries/adapted_queries.sql)

| ID | Author | Question | Relevance to the problem | Rows |
|---|---|---|---|---|
| A1 | Matteo-RSV (Matteo) | Which neighborhoods have the highest average nightly price? | Where short-term rentals earn the most | 69 |
| A2 | Matteo-RSV (Matteo) | Which hosts are linked to more than one accommodation record? | Business-like hosts take many homes | 1607 |
| A3 | Matteo-RSV (Matteo) | How does each priced listing rank in its neighborhood? | Price spread inside a neighborhood | 13355 |
| A4 | Matteo-RSV (Matteo) | Did a listing price change between two observations? | Needed to compare with rent growth | 0 (one snapshot) |
| A5 | Matteo-RSV (Matteo) | How many listings have more unavailable days than the allowed nights? | Shows if rules could be checked | 0 (no regulation data) |
| A6 | Matteo-RSV (Matteo) | How do listing prices compare with the latest rent? | Short-term prices against rent for residents | 243 |
| A7 | Matteo-RSV (Matteo) | How do listing counts and prices relate to 2023 household income? | Who is affected by tourist rentals | 69 |

## New queries (sql/queries/team_queries.sql)

| ID | Author | Question | Relevance to the problem | Rows |
|---|---|---|---|---|
| T1 | AlexandreKupfermunz (Alexandre) | In which neighborhoods does a typical household spend the largest share of its income on rent? | Shows where housing is least affordable, which is where short-term rentals may add the most pressure | 68 |
| T2 | AlexandreKupfermunz (Alexandre) | In which neighborhoods are most listings whole homes? | A whole home rented to tourists is not available for residents | 15 |
| T3 | Matteo-RSV (Matteo) | How many listings are linked to hosts with few or many listings? | Shows how concentrated the listing supply is among hosts with several listings | 3 |
| T4 | Matteo-RSV (Matteo) | How does rent growth compare with Airbnb listing counts across neighborhoods? | Explores whether more tourist rentals go together with larger rent increases | 68 |
| T5 | VeniVidiVici404 (Manos) | In which neighborhoods do the most listings show no license number? | Shows where the city could check for possible illegal listings first | 15 |
| T6 | VeniVidiVici404 (Manos) | How many nights per month must a host rent out a whole home to earn the same as a long-term rent? | Shows how attractive tourist rentals are compared with renting to residents | 44 |

All six queries are descriptive. The limits of each query are written in its header in the SQL file.