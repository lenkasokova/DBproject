# MovieLens Next-Movie Recommender

## Create schema
```bash
psql -U <user> -d movielens -f src/Schema.sql
```

## Import the CSV data
Edit `src/tools/import_files.sql` and set the CSV directory:

```bash
\set data_dir '/absolute/path/to/your/ml-25m-normalized'
```

then run:

```bash
psql -U <user> -d movielens -f src/tools/import_files.sql
```

## Edit data
To edit data in movie_links.csv run:

```bash
python data/strip_dot_zero.py /path/to/file.csv --inplace
```

```bash
python data/strip_dot_zero.py /path/to/file.csv -o /path/to/file_cleaned.csv
```

## Save results from queries
To save the results of queries, you can use the following commands in save_query:

```bash
psql -U <user> -d movielens -f src/tools/save_query.sql
```