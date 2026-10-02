# SQL review before upload

The schema and query logic were reviewed for the stated MySQL 8 target. No definite syntax error was identified by static inspection. No MySQL server is available here, so this is not a completed MySQL execution check.

The adapted-query file was reformatted with separate SELECT expressions and JOIN clauses, consistent whitespace, and brief comments about the important assumptions. All six reformatted queries were executed against the reference database; their complete results matched the previous CSVs exactly. Standard joins, aggregation, correlated subqueries, CASE, CTE and window functions are retained because the existing Week 3 project already uses those techniques. No extra abstraction or unnecessary clever syntax was introduced.

The original-query file is deliberately historical; its known logical limitations are preserved for before/after comparison. Do not describe it as the corrected production query file.

The import file's hexadecimal UTF-8 literals are generated serialization, not hand-written student SQL. Upload generate_import.py and instructions instead of the bulk import file if following the current repository plan.

Known limits: activity unknown; one snapshot per listing; regulation data absent; one missing minimum stay; 21 unknown rent values; different price/rent units and reference periods. The documentation must retain these facts. Coding style is readable at course level, but it is not evidence of human authorship. Understand and explain the code and acknowledge assistance as your course requires.
