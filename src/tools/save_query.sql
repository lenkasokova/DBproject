\set ON_ERROR_STOP on
\timing on

\set data_dir 'absolute_path/data/results' -- change path
\echo Using CSV directory: :data_dir
\cd :data_dir

\echo Saving user_recommendations results ...
\copy (SELECT user_id, candidate_movie_id, score, rank FROM mv_user_recommendations ORDER BY user_id, rank) TO 'q1_user_recommendations.csv' CSV HEADER;

\echo Saving user_pos_recommendations results ...
\copy (SELECT user_id, candidate_movie_id, score, rank FROM mv_user_pos_recommendations ORDER BY user_id, rank) TO 'q2_user_pos_recommendations.csv' CSV HEADER;

-- add queries to save
\echo result saved