\set ON_ERROR_STOP on
\timing on

-- point to your CSV dir
\set data_dir '/home/lenka/Documents/TU/DB/DBProject/data/ml-25m-normalized'
\echo Using CSV directory: :data_dir
\cd :data_dir

-- 1) parents
\echo Importing users...
\copy public.users(user_id) FROM 'users.csv' CSV HEADER;

\echo Importing movies...
\copy public.movies(movie_id, title, release_year) FROM 'movies.csv' CSV HEADER;

\echo Importing genres...
\copy public.genres(genre_id, genre_name) FROM 'genres.csv' CSV HEADER;

-- 2) links/lookups
\echo Importing movie_genres...
\copy public.movie_genres(movie_id, genre_id) FROM 'movie_genres.csv' CSV HEADER;

\echo Importing movie_links...
\copy public.movie_links(movie_id, imdb_id, tmdb_id) FROM 'movie_links.csv' CSV HEADER;

\echo Importing genome_tags...
\copy public.genome_tags(tag_id, tag_name) FROM 'genome_tags.csv' CSV HEADER;

\echo Importing genome_scores...
\copy public.genome_scores(movie_id, tag_id, relevance) FROM 'genome_scores.csv' CSV HEADER;

-- 3) ratings (epoch -> timestamp via staging)
\echo Preparing ratings staging...
DROP TABLE IF EXISTS public.ratings_raw;
CREATE TABLE public.ratings_raw(
  "userId" int, "movieId" int, rating numeric(2,1), "timestamp" bigint
);

\echo Importing ratings.csv...
\copy public.ratings_raw("userId","movieId",rating,"timestamp") FROM 'ratings.csv' CSV HEADER;

\echo Converting ratings...
INSERT INTO public.ratings(user_id, movie_id, rating, rated_at)
SELECT "userId","movieId",rating,to_timestamp("timestamp") FROM public.ratings_raw;

-- 4) user tags (epoch -> timestamp via staging)
\echo Preparing user_tags staging...
DROP TABLE IF EXISTS public.user_tags_raw;
CREATE TABLE public.user_tags_raw(
  "userId" int, "movieId" int, "tag" text, "timestamp" bigint
);

\echo Importing user_tags.csv...
\copy public.user_tags_raw("userId","movieId","tag","timestamp") FROM 'user_tags.csv' CSV HEADER;

\echo Converting user_tags...
INSERT INTO public.user_tags(user_id, movie_id, tag_text, tagged_at)
SELECT "userId","movieId","tag",to_timestamp("timestamp") FROM public.user_tags_raw;

-- sanity
\echo Counts:
SELECT 'users' t, COUNT(*) n FROM public.users UNION ALL
SELECT 'movies', COUNT(*) FROM public.movies UNION ALL
SELECT 'genres', COUNT(*) FROM public.genres UNION ALL
SELECT 'movie_genres', COUNT(*) FROM public.movie_genres UNION ALL
SELECT 'movie_links', COUNT(*) FROM public.movie_links UNION ALL
SELECT 'genome_tags', COUNT(*) FROM public.genome_tags UNION ALL
SELECT 'genome_scores', COUNT(*) FROM public.genome_scores UNION ALL
SELECT 'ratings', COUNT(*) FROM public.ratings UNION ALL
SELECT 'user_tags', COUNT(*) FROM public.user_tags;
