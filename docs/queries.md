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