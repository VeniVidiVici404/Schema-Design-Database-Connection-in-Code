#!/usr/bin/env bash
# Run from the repo root: bash scripts/build_real_data.sh
set -e

python scripts/download_raw_data.py
python scripts/clean_real_data.py data/raw/listings.csv data/raw/trimestral_bcn_lloguer_m2.xlsx data/cleaned
python scripts/generate_import.py data/cleaned sql/real/02_import_real_data.sql
python scripts/prepare_income_data.py data/raw/2023_atles_renda_bruta_llar.csv data/cleaned/neighborhood.csv data/cleaned/neighborhood_income_2023.csv sql/real/03_import_income_data.sql

echo "Done. Now run the MySQL commands from the README, section 5."