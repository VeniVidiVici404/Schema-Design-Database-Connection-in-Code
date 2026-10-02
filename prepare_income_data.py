"""Aggregate 2023 census-section income values to Barcelona neighborhoods.

Usage:
python prepare_income_data.py source.csv neighborhood.csv output.csv output.sql
"""
import csv
import re
import sys
from collections import defaultdict
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

source_path, neighborhood_path, output_csv, output_sql = map(Path, sys.argv[1:])

with neighborhood_path.open(encoding="utf-8-sig", newline="") as stream:
    neighborhoods = list(csv.DictReader(stream))
name_to_id = {row["name"].strip(): int(row["neighborhood_id"]) for row in neighborhoods}

aliases = {
    "Sant Gervasi- Galvany": "Sant Gervasi - Galvany",
    "Sant Gervasi- la Bonanova": "Sant Gervasi - la Bonanova",
    "Sants-Badal": "Sants - Badal",
    "el Poble Sec": "el Poble Sec - AEI Parc Montjuïc",
    "la Marina del Prat Vermell": "la Marina del Prat Vermell - AEI Zona Franca",
}

values = defaultdict(list)
section_keys = set()
source_rows = 0
with source_path.open(encoding="utf-8-sig", newline="") as stream:
    for row in csv.DictReader(stream):
        source_rows += 1
        if row["Any"].strip() != "2023":
            raise ValueError(f"Unexpected source year: {row['Any']}")
        key = (row["Codi_Districte"].strip(), row["Codi_Barri"].strip(), row["Seccio_Censal"].strip())
        if key in section_keys:
            raise ValueError(f"Duplicate census-section key: {key}")
        section_keys.add(key)
        source_name = row["Nom_Barri"].strip()
        neighborhood_name = aliases.get(source_name, source_name)
        if neighborhood_name not in name_to_id:
            raise ValueError(f"Unmatched neighborhood: {source_name}")
        amount = Decimal(row["Import_Renda_Bruta_€"].strip())
        if amount <= 0:
            raise ValueError(f"Non-positive income value in {key}")
        values[(name_to_id[neighborhood_name], neighborhood_name)].append(amount)

if source_rows != 1068 or len(section_keys) != 1068:
    raise ValueError(f"Expected 1,068 unique census sections; got {source_rows} rows and {len(section_keys)} keys")
if len(values) != 73:
    raise ValueError(f"Expected 73 neighborhoods; got {len(values)}")

records = []
for (neighborhood_id, name), amounts in sorted(values.items()):
    mean = (sum(amounts) / len(amounts)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
    records.append({
        "neighborhood_id": neighborhood_id,
        "neighborhood_name": name,
        "observation_date": "2023-01-01",
        "census_sections_aggregated": len(amounts),
        "avg_gross_household_income": str(mean),
    })

with output_csv.open("w", encoding="utf-8", newline="") as stream:
    writer = csv.DictWriter(stream, fieldnames=list(records[0]))
    writer.writeheader()
    writer.writerows(records)

def sql_text(value):
    return "CONVERT(X'" + value.encode("utf-8").hex() + "' USING utf8mb4)"

with output_sql.open("w", encoding="utf-8", newline="") as stream:
    stream.write("-- Household income aggregated from 2023 census sections.\n")
    stream.write("-- Run once after 02_import_real_data.sql on a fresh database.\n")
    stream.write("USE airbnb_market_real;\nSTART TRANSACTION;\n")
    stream.write("INSERT INTO housing_market_observation\n")
    stream.write("    (neighborhood_id, observation_date, avg_gross_household_income) VALUES\n")
    values_sql = []
    for record in records:
        values_sql.append(
            f"({record['neighborhood_id']}, '2023-01-01', {record['avg_gross_household_income']})"
        )
    stream.write(",\n".join(values_sql) + ";\nCOMMIT;\n")

print(f"Read {source_rows} unique census sections; wrote {len(records)} neighborhood observations.")
print("Income measure is the simple arithmetic mean of the source section-level household estimates.")
