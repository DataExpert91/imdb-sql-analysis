-- 02_create_schema.sql
-- Clean, normalized schema built from the raw IMDb staging tables

USE imdb;

DROP TABLE IF EXISTS movie_genres;
DROP TABLE IF EXISTS ratings;
DROP TABLE IF EXISTS genres;
DROP TABLE IF EXISTS movies;

CREATE TABLE movies (
  movie_id         VARCHAR(20)  PRIMARY KEY,   -- IMDb tconst
  title            VARCHAR(500) NOT NULL,
  original_title   VARCHAR(500),
  release_year     SMALLINT,
  runtime_minutes  SMALLINT
);

CREATE TABLE genres (
  genre_id  INT AUTO_INCREMENT PRIMARY KEY,
  name      VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE movie_genres (
  movie_id  VARCHAR(20) NOT NULL,
  genre_id  INT         NOT NULL,
  PRIMARY KEY (movie_id, genre_id),
  FOREIGN KEY (movie_id) REFERENCES movies(movie_id),
  FOREIGN KEY (genre_id) REFERENCES genres(genre_id)
);

CREATE TABLE ratings (
  movie_id        VARCHAR(20) PRIMARY KEY,
  average_rating  DECIMAL(3,1) NOT NULL,
  num_votes       INT NOT NULL,
  FOREIGN KEY (movie_id) REFERENCES movies(movie_id)
);