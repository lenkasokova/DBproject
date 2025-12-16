
-- QUERY 4 

DROP MATERIALIZED VIEW IF EXISTS mv_cb_final_recommendations CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mv_cb_candidate_scores CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mv_user_tag_profile CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mv_user_likes CASCADE;

-- Use only movies the users really like, 4 or more stars
CREATE MATERIALIZED VIEW mv_user_likes AS
SELECT 
    user_id, 
    movie_id
FROM ratings
WHERE rating >= 4.0
  AND user_id <= 1000; 

CREATE INDEX idx_mv_ul_user ON mv_user_likes(user_id);
CREATE INDEX idx_mv_ul_movie ON mv_user_likes(movie_id);


-- Table with the movies and the tags but just the relevant ones 0.8+
CREATE MATERIALIZED VIEW mv_user_tag_profile AS
SELECT DISTINCT
    ul.user_id,
    gs.tag_id
FROM mv_user_likes ul
JOIN genome_scores gs ON ul.movie_id = gs.movie_id
WHERE gs.relevance > 0.8;

CREATE INDEX idx_mv_utp_tag ON mv_user_tag_profile(tag_id);
CREATE INDEX idx_mv_utp_user ON mv_user_tag_profile(user_id);

-- This table conects the user with the movies that has tags he likes
CREATE MATERIALIZED VIEW mv_cb_candidate_scores AS
SELECT 
    utp.user_id,
    gs.movie_id AS candidate_movie_id,
    SUM(gs.relevance) AS score
FROM mv_user_tag_profile utp
JOIN genome_scores gs ON utp.tag_id = gs.tag_id
WHERE gs.relevance > 0.8 
GROUP BY utp.user_id, gs.movie_id;

CREATE INDEX idx_mv_ccs_user_movie ON mv_cb_candidate_scores(user_id, candidate_movie_id);


-- Ranking and filtration of the movies that are recommended but he has already seen
CREATE MATERIALIZED VIEW mv_cb_final_recommendations AS
WITH filtered AS (
    SELECT 
        c.user_id,
        c.candidate_movie_id,
        c.score
    FROM mv_cb_candidate_scores c
    LEFT JOIN ratings seen 
           ON c.user_id = seen.user_id 
          AND c.candidate_movie_id = seen.movie_id
    WHERE seen.movie_id IS NULL 
),
ranked AS (
    SELECT 
        user_id,
        candidate_movie_id,
        score,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY score DESC) as rank
    FROM filtered
)
SELECT * FROM ranked
WHERE rank <= 10; 

CREATE INDEX idx_final_rec_user ON mv_cb_final_recommendations(user_id);

-- show the final result
SELECT 
    r.user_id,
	r.candidate_movie_id AS movie_id,
	m.title AS movie_title,
	m.release_year,
	r.score,
    r.rank
FROM mv_cb_final_recommendations r
JOIN movies m ON r.candidate_movie_id = m.movie_id
ORDER BY r.user_id, r.rank;