-- Step 1: Get the genres for each movie that a user has rated
  WITH user_genre_history AS (
    SELECT
        r.user_id,
        mg.genre_id,
        COUNT(*) AS genre_count
    FROM
        ratings r
    JOIN
        movie_genres mg ON r.movie_id = mg.movie_id
    GROUP BY
        r.user_id, mg.genre_id
),
-- Step 2: Calculate the total genres watched by each user
total_watched_genres AS (
    SELECT
        user_id,
        SUM(genre_count) AS total_watched
    FROM
        user_genre_history
    GROUP BY
        user_id
)
-- Step 3: Calculate the probability of each genre for a user based on their history
SELECT
    ugh.user_id,
    g.genre_name,
    ugh.genre_count,
    (ugh.genre_count::FLOAT / twg.total_watched) AS genre_probability
FROM
    user_genre_history ugh
JOIN
    genres g ON ugh.genre_id = g.genre_id
JOIN
    total_watched_genres twg ON ugh.user_id = twg.user_id
ORDER BY
    ugh.user_id, genre_probability DESC;