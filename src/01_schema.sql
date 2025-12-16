DROP TABLE IF EXISTS movie_links CASCADE;
DROP TABLE IF EXISTS genome_scores CASCADE;
DROP TABLE IF EXISTS genome_tags CASCADE;
DROP TABLE IF EXISTS user_tags CASCADE;
DROP TABLE IF EXISTS ratings CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS movie_genres CASCADE;
DROP TABLE IF EXISTS genres CASCADE;
DROP TABLE IF EXISTS movies CASCADE;

CREATE TABLE movies (
    movie_id     INTEGER PRIMARY KEY,
    title        TEXT    NOT NULL,
    release_year INTEGER  
);

CREATE TABLE genres (
    genre_id   INTEGER PRIMARY KEY,
    genre_name TEXT NOT NULL UNIQUE
);

CREATE TABLE movie_genres (
    movie_id INTEGER NOT NULL REFERENCES movies(movie_id) ON DELETE CASCADE,
    genre_id INTEGER NOT NULL REFERENCES genres(genre_id),
    PRIMARY KEY (movie_id, genre_id)
);

CREATE TABLE users (
    user_id INTEGER PRIMARY KEY
);

CREATE TABLE ratings (
    rating_id SERIAL PRIMARY KEY,
    user_id   INTEGER REFERENCES users(user_id),
    movie_id  INTEGER REFERENCES movies(movie_id),
    rating    NUMERIC(2,1) NOT NULL,
    rated_at  TIMESTAMP    NOT NULL
);

CREATE TABLE user_tags (
    user_tag_id SERIAL PRIMARY KEY,
    user_id     INTEGER NOT NULL REFERENCES users(user_id)  ON DELETE CASCADE,
    movie_id    INTEGER NOT NULL REFERENCES movies(movie_id) ON DELETE CASCADE,
    tag_text    TEXT    NOT NULL,
    tagged_at   TIMESTAMP NOT NULL,
    UNIQUE (user_id, movie_id, tag_text, tagged_at)
);

CREATE TABLE genome_tags (
    tag_id   INTEGER PRIMARY KEY,
    tag_name TEXT NOT NULL
);

CREATE TABLE genome_scores (
    genome_score_id SERIAL PRIMARY KEY,
    movie_id        INTEGER NOT NULL REFERENCES movies(movie_id)    ON DELETE CASCADE,
    tag_id          INTEGER NOT NULL REFERENCES genome_tags(tag_id) ON DELETE CASCADE,
    relevance       REAL    NOT NULL CHECK (relevance >= 0 AND relevance <= 1),
    UNIQUE (movie_id, tag_id)
);

CREATE TABLE movie_links (
    movie_id INTEGER PRIMARY KEY REFERENCES movies(movie_id) ON DELETE CASCADE,
    imdb_id  INTEGER,
    tmdb_id  INTEGER,
    UNIQUE (imdb_id)
);