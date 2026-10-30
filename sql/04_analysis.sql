-- 04_analysis.sql
-- Analytical queries on the cleaned IMDb movie database
USE imdb;

-- Q1. Top 10 highest-rated movies with at least 100,000 votes (JOIN)
SELECT m.title, m.release_year, r.average_rating, r.num_votes
FROM movies m
JOIN ratings r ON r.movie_id = m.movie_id
WHERE r.num_votes >= 100000
ORDER BY r.average_rating DESC, r.num_votes DESC
LIMIT 10;

-- Q2. Which genres are rated highest? (GROUP BY + HAVING)
SELECT g.name AS genre,
       COUNT(*) AS rated_movies,
       ROUND(AVG(r.average_rating), 2) AS avg_rating
FROM genres g
JOIN movie_genres mg ON mg.genre_id = g.genre_id
JOIN ratings r ON r.movie_id = mg.movie_id
GROUP BY g.name
HAVING COUNT(*) >= 500
ORDER BY avg_rating DESC;

-- Q3. How have ratings changed by decade? (CTE)
WITH decade_stats AS (
  SELECT FLOOR(m.release_year / 10) * 10 AS decade,
         COUNT(*) AS movies,
         AVG(r.average_rating) AS avg_rating
  FROM movies m
  JOIN ratings r ON r.movie_id = m.movie_id
  WHERE r.num_votes >= 1000
  GROUP BY decade
)
SELECT decade, movies, ROUND(avg_rating, 2) AS avg_rating
FROM decade_stats
ORDER BY decade;

-- Q4. Best movie in every genre (window function ROW_NUMBER)
WITH ranked AS (
  SELECT g.name AS genre, m.title, m.release_year,
         r.average_rating, r.num_votes,
         ROW_NUMBER() OVER (
           PARTITION BY g.name
           ORDER BY r.average_rating DESC, r.num_votes DESC
         ) AS rn
  FROM movies m
  JOIN ratings r       ON r.movie_id = m.movie_id
  JOIN movie_genres mg ON mg.movie_id = m.movie_id
  JOIN genres g        ON g.genre_id = mg.genre_id
  WHERE r.num_votes >= 50000
)
SELECT genre, title, release_year, average_rating, num_votes
FROM ranked
WHERE rn = 1
ORDER BY average_rating DESC;

-- Q5. Do longer movies get better ratings? (CASE buckets)
SELECT CASE
         WHEN m.runtime_minutes < 90  THEN '1. under 90 min'
         WHEN m.runtime_minutes < 120 THEN '2. 90-119 min'
         WHEN m.runtime_minutes < 150 THEN '3. 120-149 min'
         ELSE '4. 150+ min'
       END AS runtime_bucket,
       COUNT(*) AS movies,
       ROUND(AVG(r.average_rating), 2) AS avg_rating
FROM movies m
JOIN ratings r ON r.movie_id = m.movie_id
WHERE m.runtime_minutes IS NOT NULL
  AND r.num_votes >= 1000
GROUP BY runtime_bucket
ORDER BY runtime_bucket;

-- Q6. Hidden gems: rated 8.0+ but with relatively few votes
SELECT m.title, m.release_year, r.average_rating, r.num_votes
FROM movies m
JOIN ratings r ON r.movie_id = m.movie_id
WHERE r.average_rating >= 8.0
  AND r.num_votes BETWEEN 5000 AND 25000
  AND m.release_year <= 2020
ORDER BY r.average_rating DESC, r.num_votes ASC
LIMIT 15;