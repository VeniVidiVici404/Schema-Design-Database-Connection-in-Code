"""Download the two raw Barcelona files into data/raw/.
Run from the repo root: python scripts/download_raw_data.py
"""
import gzip
import hashlib
import shutil
import urllib.request
from pathlib import Path

RAW_FOLDER = Path("data/raw")

AIRBNB_URL = "https://data.insideairbnb.com/spain/catalonia/barcelona/2026-06-24/data/listings.csv.gz"
RENT_URL = ("https://habitatge.gencat.cat/web/.content/home/dades/estadistiques/"
            "01_Estadistiques_de_construccio_i_mercat_immobiliari/03_Mercat_de_lloguer/"
            "03_Lloguers_Barcelona_per_districtes_i_barris/trimestral_bcn_lloguer_m2.xlsx")

# SHA-256 values from docs/dataset_inspection.md
AIRBNB_SHA256 = "1c035a1cbecd612da4e16325861a34cad1321e3014b9e39529d8910e9f85d5bd"
RENT_SHA256 = "710f1bcdda778eed3ead4a829bbde32ce6c3922712f5cd1a41bbd54649189945"


def sha256_of(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def check_hash(path, expected):
    actual = sha256_of(path)
    if actual == expected:
        print("Hash OK:", path.name)
    else:
        print("WARNING: " + path.name + " is different from the file we used.")
        print("The publisher may have updated it. Results can differ from docs/.")


def main():
    RAW_FOLDER.mkdir(parents=True, exist_ok=True)

    gz_path = RAW_FOLDER / "listings.csv.gz"
    csv_path = RAW_FOLDER / "listings.csv"
    if csv_path.exists():
        print("Already there:", csv_path)
    else:
        print("Downloading Airbnb listings...")
        urllib.request.urlretrieve(AIRBNB_URL, gz_path)
        with gzip.open(gz_path, "rb") as source:
            with csv_path.open("wb") as target:
                shutil.copyfileobj(source, target)
        gz_path.unlink()
    check_hash(csv_path, AIRBNB_SHA256)

    rent_path = RAW_FOLDER / "trimestral_bcn_lloguer_m2.xlsx"
    if rent_path.exists():
        print("Already there:", rent_path)
    else:
        print("Downloading rent workbook...")
        urllib.request.urlretrieve(RENT_URL, rent_path)
    check_hash(rent_path, RENT_SHA256)


if __name__ == "__main__":
    main()