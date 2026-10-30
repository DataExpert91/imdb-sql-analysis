-- 01_load_raw.sql
-- Loads raw IMDb TSV files into staging tables (everything as text; cleaning comes later)

USE imdb;

DROP TABLE IF EXISTS stg_title_basics;
CREATE TABLE stg_title_basics (
  tconst          VARCHAR(20),
  titleType       VARCHAR(30),
  primaryTitle    TEXT,
  originalTitle   TEXT,
  isAdult         VARCHAR(5),
  startYear       VARCHAR(10),
  endYear         VARCHAR(10),
  runtimeMinutes  VARCHAR(20),
  genres          VARCHAR(200)
);

DROP TABLE IF EXISTS stg_title_ratings;
CREATE TABLE stg_title_ratings (
  tconst          VARCHAR(20),
  averageRating   VARCHAR(10),
  numVotes        VARCHAR(20)
);

-- \N in the IMDb files means NULL; MySQL converts it automatically
LOAD DATA INFILE '/var/lib/mysql-files/title.basics.tsv'
INTO TABLE stg_title_basics
CHARACTER SET utf8mb4
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA INFILE '/var/lib/mysql-files/title.ratings.tsv'
INTO TABLE stg_title_ratings
CHARACTER SET utf8mb4
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Sanity check: row counts
SELECT 'stg_title_basics'  AS table_name, COUNT(*) AS row_count FROM stg_title_basics
UNION ALL
SELECT 'stg_title_ratings', COUNT(*) FROM stg_title_ratings;