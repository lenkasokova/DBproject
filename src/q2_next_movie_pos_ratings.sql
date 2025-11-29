-- interactions (only positives)
DROP MATERIALIZED VIEW IF EXISTS interactions_pos CASCADE;
CREATE MATERIALIZED VIEW interactions_pos AS
SELECT user_id, movie_id, rated_at, rating, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY rated_at, movie_id) AS rn
FROM ratings
WHERE rating >= 3.5;

CREATE UNIQUE INDEX IF NOT EXISTS interactions_pos_user_rn_uidx
  ON interactions_pos(user_id, rn);
CREATE INDEX IF NOT EXISTS interactions_pos_user_movie_idx
  ON interactions_pos(user_id, movie_id);
CREATE INDEX IF NOT EXISTS interactions_pos_movie_idx
  ON interactions_pos(movie_id);
CREATE INDEX IF NOT EXISTS interactions_pos_user_movie_idx ON interactions_pos(user_id, movie_id);

-- Compute next-movie recommendations for each user based on the user's last two watched movies
DROP MATERIALIZED VIEW IF EXISTS mv_user_pos_recommendations;
CREATE MATERIALIZED VIEW mv_user_pos_recommendations AS
WITH last_k AS (
  SELECT user_id, movie_id AS i,
         ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY rn DESC) AS rpos
  FROM interactions_pos
),
seed AS (
  SELECT user_id, i
  FROM last_k
  WHERE rpos <= 2
),
scores AS (
  SELECT s.user_id, cp.j AS candidate_movie_id, SUM(cp.p_ij) AS score
  FROM seed s
  JOIN item_condprob_next cp ON cp.i = s.i
  GROUP BY s.user_id, cp.j
),
filtered AS (
  -- remove candidates the user already saw
  SELECT sc.user_id, sc.candidate_movie_id, sc.score
  FROM scores sc
  LEFT JOIN interactions_pos seen
    ON seen.user_id = sc.user_id
   AND seen.movie_id = sc.candidate_movie_id
  WHERE seen.movie_id IS NULL
),
ranked AS (
  SELECT
    user_id, candidate_movie_id, score,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY score DESC, candidate_movie_id) AS rank
  FROM filtered
)
SELECT * FROM ranked
WHERE rank <= 10;

CREATE INDEX IF NOT EXISTS mv_user_pos_recommendations_user_idx
  ON mv_user_pos_recommendations(user_id, rank);

-- For each user, show the top 10 next-movie recommendations from positive recommendation with title and release year
SELECT
  r.user_id,
  r.candidate_movie_id AS movie_id,
  mv.title             AS movie_title,
  mv.release_year,
  r.score,
  r.rank
FROM mv_user_pos_recommendations r
JOIN movies mv ON mv.movie_id = r.candidate_movie_id
ORDER BY r.user_id, r.rank;

