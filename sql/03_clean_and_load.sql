-- 03_clean_and_load.sql
-- Cleans raw IMDb data and fills the normalized tables

USE imdb;

-- Make the script re-runnable
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE ratings;
TRUNCATE TABLE movie_genres;
TRUNCATE TABLE genres;
TRUNCATE TABLE movies;
SET FOREIGN_KEY_CHECKS = 1;

-- 1) Movies: only feature films, no adult titles, valid release year (1888..2026).
--    Runtime outside 1..600 minutes is treated as bad data and set to NULL.
INSERT INTO movies (movie_id, title, original_title, release_year, runtime_minutes)
SELECT
  tconst,
  LEFT(COALESCE(primaryTitle, originalTitle, 'Unknown'), 500),
  LEFT(originalTitle, 500),
  CAST(startYear AS UNSIGNED),
  CASE
    WHEN runtimeMinutes REGEXP '^[0-9]+$'
     AND CAST(runtimeMinutes AS UNSIGNED) BETWEEN 1 AND 600
    THEN CAST(runtimeMinutes AS UNSIGNED)
  END
FROM stg_title_basics
WHERE titleType = 'movie'
  AND isAdult = '0'
  AND startYear REGEXP '^[0-9]{4}$'
  AND CAST(startYear AS UNSIGNED) BETWEEN 1888 AND 2026;

-- 2) Genres: IMDb stores up to 3 genres as "Action,Drama,Thriller".
--    Split the string into one row per (movie, genre).
DROP TABLE IF EXISTS tmp_movie_genre;
CREATE TABLE tmp_movie_genre AS
SELECT s.tconst AS movie_id, SUBSTRING_INDEX(s.genres, ',', 1) AS genre
FROM stg_title_basics s JOIN movies m ON m.movie_id = s.tconst
WHERE s.genres IS NOT NULL
UNION ALL
SELECT s.tconst, SUBSTRING_INDEX(SUBSTRING_INDEX(s.genres, ',', 2), ',', -1)
FROM stg_title_basics s JOIN movies m ON m.movie_id = s.tconst
WHERE s.genres LIKE '%,%'
UNION ALL
SELECT s.tconst, SUBSTRING_INDEX(s.genres, ',', -1)
FROM stg_title_basics s JOIN movies m ON m.movie_id = s.tconst
WHERE s.genres LIKE '%,%,%';

INSERT INTO genres (name)
SELECT DISTINCT genre FROM tmp_movie_genre;

INSERT INTO movie_genres (movie_id, genre_id)
SELECT DISTINCT t.movie_id, g.genre_id
FROM tmp_movie_genre t
JOIN genres g ON g.name = t.genre;

DROP TABLE tmp_movie_genre;

-- 3) Ratings: only for the movies we kept
INSERT INTO ratings (movie_id, average_rating, num_votes)
SELECT r.tconst, CAST(r.averageRating AS DECIMAL(3,1)), CAST(r.numVotes AS UNSIGNED)
FROM stg_title_ratings r
JOIN movies m ON m.movie_id = r.tconst
WHERE r.averageRating IS NOT NULL AND r.numVotes IS NOT NULL;

-- 4) Data quality summary: raw vs clean
SELECT
  (SELECT COUNT(*) FROM stg_title_basics)                          AS raw_titles,
  (SELECT COUNT(*) FROM stg_title_basics WHERE titleType='movie')  AS raw_movies,
  (SELECT COUNT(*) FROM movies)                                    AS clean_movies,
  (SELECT COUNT(*) FROM movies WHERE runtime_minutes IS NULL)      AS movies_without_runtime,
  (SELECT COUNT(*) FROM ratings)                                   AS rated_movies,
  (SELECT COUNT(*) FROM genres)                                    AS genres,
  (SELECT COUNT(*) FROM movie_genres)                              AS movie_genre_links;