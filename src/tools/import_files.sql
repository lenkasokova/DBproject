COPY public.users(user_id)
FROM '/absolute_path/data/ml-25m-normalized/users.csv'
WITH (FORMAT csv, HEADER true);

COPY public.movies(movie_id, title, release_year)
FROM '/absolute_path/data/ml-25m-normalized/movies.csv'
WITH (FORMAT csv, HEADER true);

COPY public.genres(genre_id, genre_name)
FROM '/absolute_path/data/ml-25m-normalized/genres.csv'
WITH (FORMAT csv, HEADER true);

COPY public.movie_genres(movie_id, genre_id)
FROM '/absolute_path/data/ml-25m-normalized/movie_genres.csv'
WITH (FORMAT csv, HEADER true);

COPY public.movie_links(movie_id, imdb_id, tmdb_id)
FROM '/absolute_path/data/ml-25m-normalized/movie_links.csv'
WITH (FORMAT csv, HEADER true);

COPY public.genome_tags(tag_id, tag_name)
FROM '/absolute_path/data/ml-25m-normalized/genome_tags.csv'
WITH (FORMAT csv, HEADER true);

COPY public.genome_scores(movie_id, tag_id, relevance)
FROM '/absolute_path/data/ml-25m-normalized/genome_scores.csv'
WITH (FORMAT csv, HEADER true);

DROP TABLE IF EXISTS public.ratings_raw;
CREATE TABLE public.ratings_raw (
  "userId"    int,
  "movieId"   int,
  rating      numeric(2,1),
  "timestamp" bigint
);

COPY public.ratings_raw("userId","movieId",rating,"timestamp")
FROM '/absolute_path/data/ml-25m-normalized/ratings.csv'
WITH (FORMAT csv, HEADER true);

INSERT INTO public.ratings(user_id, movie_id, rating, rated_at)
SELECT
  "userId",
  "movieId",
  rating,
  to_timestamp("timestamp")
FROM public.ratings_raw;

DROP TABLE IF EXISTS public.user_tags_raw;
CREATE TABLE public.user_tags_raw (
  "userId"    int,
  "movieId"   int,
  "tag"       text,
  "timestamp" bigint
);

COPY public.user_tags_raw("userId","movieId","tag","timestamp")
FROM '/absolute_path/data/ml-25m-normalized/user_tags.csv'
WITH (FORMAT csv, HEADER true);

INSERT INTO public.user_tags(user_id, movie_id, tag_text, tagged_at)
SELECT
  "userId",
  "movieId",
  "tag",
  to_timestamp("timestamp")
FROM public.user_tags_raw;

SELECT 'users' t, COUNT(*) n FROM public.users
UNION ALL SELECT 'movies', COUNT(*) FROM public.movies
UNION ALL SELECT 'genres', COUNT(*) FROM public.genres
UNION ALL SELECT 'movie_genres', COUNT(*) FROM public.movie_genres
UNION ALL SELECT 'movie_links', COUNT(*) FROM public.movie_links
UNION ALL SELECT 'genome_tags', COUNT(*) FROM public.genome_tags
UNION ALL SELECT 'genome_scores', COUNT(*) FROM public.genome_scores
UNION ALL SELECT 'ratings', COUNT(*) FROM public.ratings
UNION ALL SELECT 'user_tags', COUNT(*) FROM public.user_tags;
