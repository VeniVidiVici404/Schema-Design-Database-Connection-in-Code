"""Run: python generate_import.py cleaned_folder output.sql"""
import csv,re,sys
from pathlib import Path

tables=['city','neighborhood','host','property','host_property','platform','listing','listing_snapshot','housing_market_observation']
numeric={'city_id','neighborhood_id','host_id','source_host_id','property_id','bedrooms','capacity','price_per_m2_purchased','platform_id','listing_id','source_listing_id','minimum_nights','snapshot_id','nightly_price','available_days_next_365','active','reviews_count','avg_rent_per_m2','verified'}

def value(key,item):
    if item=='': return 'NULL'
    if key in numeric:
        if not re.fullmatch(r'-?\d+(\.\d+)?',item): raise ValueError('Invalid numeric value')
        return item
    return "CONVERT(X'"+item.encode('utf-8').hex()+"' USING utf8mb4)"

folder=Path(sys.argv[1])
with Path(sys.argv[2]).open('w',encoding='utf-8') as f:
    f.write('USE airbnb_market_real;\nSTART TRANSACTION;\n')
    for table in tables:
        rows=list(csv.DictReader((folder/(table+'.csv')).open(encoding='utf-8',newline='')))
        fields=list(rows[0])
        for offset in range(0,len(rows),250):
            f.write('INSERT INTO `'+table+'` ('+','.join('`'+k+'`' for k in fields)+') VALUES\n')
            f.write(',\n'.join('('+','.join(value(k,row[k]) for k in fields)+')' for row in rows[offset:offset+250])+';\n')
    f.write('COMMIT;\n')
