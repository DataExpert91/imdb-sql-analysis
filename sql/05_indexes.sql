-- 05_indexes.sql
-- Query optimization: EXPLAIN before and after adding an index
USE imdb;

-- BEFORE: no index on release_year, MySQL has to scan the whole table
EXPLAIN
SELECT m.title, m.release_year, r.average_rating, r.num_votes
FROM movies m
JOIN ratings r ON r.movie_id = m.movie_id
WHERE m.release_year = 1994
  AND r.num_votes >= 100000;

-- Add the index
CREATE INDEX idx_movies_release_year ON movies (release_year);

-- AFTER: same query, now it can use the index
EXPLAIN
SELECT m.title, m.release_year, r.average_rating, r.num_votes
FROM movies m
JOIN ratings r ON r.movie_id = m.movie_id
WHERE m.release_year = 1994
  AND r.num_votes >= 100000;