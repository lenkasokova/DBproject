DROP MATERIALIZED VIEW IF EXISTS interactions_all CASCADE;

-- Per-user, time-ordered interactions (from ratings)
CREATE MATERIALIZED VIEW interactions_all AS
SELECT
  user_id,
  movie_id,
  rated_at,
  rating,
  ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY rated_at, movie_id) AS rn
FROM ratings;

CREATE UNIQUE INDEX IF NOT EXISTS interactions_all_user_rn_uidx ON interactions_all(user_id, rn);
CREATE INDEX IF NOT EXISTS interactions_all_user_ts_idx ON interactions_all(user_id, rated_at, movie_id);
CREATE INDEX IF NOT EXISTS interactions_all_movie_idx ON interactions_all(movie_id);
CREATE INDEX IF NOT EXISTS interactions_all_user_movie_idx ON interactions_all(user_id, movie_id);

-- Consecutive pairs: for each user, pair movie i with the immediately next movie j
DROP MATERIALIZED VIEW IF EXISTS mv_user_pairs_next;
CREATE MATERIALIZED VIEW mv_user_pairs_next AS
SELECT
  a.user_id,
  a.movie_id AS i,
  b.movie_id AS j,
  a.rated_at AS i_time,
  b.rated_at AS j_time,
  a.rn       AS rn_i,
  b.rn       AS rn_j
FROM interactions_all a
JOIN interactions_all b
  ON b.user_id = a.user_id
 AND b.rn     = a.rn + 1;

-- co_cnt(i,j): counts times users watch j movie right after i
DROP MATERIALIZED VIEW IF EXISTS item_pair_counts;
CREATE MATERIALIZED VIEW item_pair_counts AS
SELECT i, j, COUNT(*) AS co_cnt
FROM mv_user_pairs_next
GROUP BY i, j;

CREATE INDEX IF NOT EXISTS item_pair_counts_i_idx ON item_pair_counts(i);
CREATE INDEX IF NOT EXISTS item_pair_counts_j_idx ON item_pair_counts(j);

-- out_cnt(i): number of transitions following movie i = sum_j(co_cnt(i, j))
DROP MATERIALIZED VIEW IF EXISTS item_outdeg_next;
CREATE MATERIALIZED VIEW item_outdeg_next AS
SELECT i AS movie_id, SUM(co_cnt) AS out_cnt
FROM item_pair_counts
GROUP BY i;

CREATE INDEX IF NOT EXISTS item_outdeg_next_mid_idx ON item_outdeg_next(movie_id);

-- Conditional probability P(j | i) = co_cnt(i, j) / out_cnt(i)
DROP MATERIALIZED VIEW IF EXISTS item_condprob_next;
CREATE MATERIALIZED VIEW item_condprob_next AS
SELECT
  p.i,
  p.j,
  (p.co_cnt::double precision) / NULLIF(o.out_cnt, 0) AS p_ij
FROM item_pair_counts p
JOIN item_outdeg_next o ON o.movie_id = p.i;

CREATE INDEX IF NOT EXISTS item_condprob_next_i_idx ON item_condprob_next(i);
CREATE INDEX IF NOT EXISTS item_condprob_next_j_idx ON item_condprob_next(j);

-- Compute next-movie recommendations for each user based on the user's last two watched movies
DROP MATERIALIZED VIEW IF EXISTS mv_user_recommendations;
CREATE MATERIALIZED VIEW mv_user_recommendations AS
WITH last_k AS (
  SELECT
    user_id,
    movie_id AS i,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY rn DESC) AS rpos
  FROM interactions_all
),
seed AS (
  SELECT user_id, i
  FROM last_k
  WHERE rpos <= 2  -- last 2 movies
),
scores AS (
  SELECT s.user_id, cp.j AS candidate_movie_id, SUM(cp.p_ij) AS score
  FROM seed s
  JOIN item_condprob_next cp ON cp.i = s.i
  GROUP BY s.user_id, cp.j
),
filtered AS (
  -- Remove candidates the user has already seen
  SELECT sc.user_id, sc.candidate_movie_id, sc.score
  FROM scores sc
  LEFT JOIN interactions_all seen
    ON seen.user_id  = sc.user_id
   AND seen.movie_id = sc.candidate_movie_id
  WHERE seen.movie_id IS NULL
),
-- Rank each result by score
ranked AS (
  SELECT
    user_id,
    candidate_movie_id,
    score,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY score DESC, candidate_movie_id) AS rank
  FROM filtered
)
SELECT * FROM ranked
WHERE rank <= 10;  -- keep only the top 10 results

CREATE INDEX IF NOT EXISTS mv_user_recommendations_user_idx
  ON mv_user_recommendations(user_id, rank);

-- For each user, show the top 10 next-movie recommendations with title and release year
SELECT
  r.user_id,
  r.candidate_movie_id AS movie_id,
  mv.title             AS movie_title,
  mv.release_year,
  r.score,
  r.rank
FROM mv_user_recommendations r
JOIN movies mv ON mv.movie_id = r.candidate_movie_id
ORDER BY r.user_id, r.rank;
