"""Count the rows returned by each query in a SQL file (MySQL).
Run from the repo root: python scripts/count_query_rows.py sql/queries/adapted_queries.sql
"""
import subprocess
import sys


def strip_comments(text):
    kept_lines = []
    for line in text.splitlines():
        if line.strip().startswith("--"):
            continue
        kept_lines.append(line)
    return "\n".join(kept_lines)


def main():
    path = sys.argv[1]
    with open(path, encoding="utf-8") as stream:
        text = strip_comments(stream.read())

    statements = text.split(";")
    number = 0
    for statement in statements:
        statement = statement.strip()
        if statement == "":
            continue
        if statement.upper().startswith("USE "):
            continue
        number = number + 1
        sql = "USE airbnb_market_real; SELECT COUNT(*) FROM (" + statement + ") AS q;"
        result = subprocess.run(["mysql", "-u", "root", "-N", "-e", sql],
                                capture_output=True, text=True)
        if result.returncode != 0:
            print("Query", number, "ERROR:", result.stderr.strip())
        else:
            print("Query", number, "rows:", result.stdout.strip())


main()
