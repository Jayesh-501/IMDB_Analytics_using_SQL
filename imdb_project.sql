use imdb;

-- ======================================================
-- 🎬 IMDb Analytics Case Study - SQL Script
-- ======================================================
-- Schema (already created, assumed existing in DB)
-- Tables: movie, genre, director_mapping, role_mapping, names, ratings
-- ======================================================

-- 🔧 Helper: Derived movie_clean CTE to standardize year & gross income
-- Use this in queries as needed
-- gross_amount = numeric worldwide gross income
-- published_year = derived year
-- ======================================================

-- ======================================================
-- 1. Genre Performance
-- Top 5 movies with the highest average rating in each genre
-- ======================================================
WITH movie_clean AS (
  SELECT
    m.*,
    CAST(NULLIF(REGEXP_REPLACE(IFNULL(m.worlwide_gross_income,''),'[^0-9.]',''), '') AS DECIMAL(15,2)) AS gross_amount,
    COALESCE(YEAR(m.date_published), m.year) AS published_year
  FROM movie m
),
genre_ratings AS (
  SELECT
    g.genre,
    g.movie_id,
    m.title,
    m.published_year,
    r.avg_rating,
    r.total_votes
  FROM genre g
  JOIN ratings r ON g.movie_id = r.movie_id
  JOIN movie_clean m ON m.id = g.movie_id
  WHERE r.total_votes >= 1000
)
SELECT genre, movie_id, title, published_year, avg_rating, total_votes
FROM (
  SELECT gr.*,
         ROW_NUMBER() OVER (PARTITION BY gr.genre ORDER BY gr.avg_rating DESC, gr.total_votes DESC) AS rn
  FROM genre_ratings gr
) t
WHERE rn <= 5
ORDER BY genre, avg_rating DESC, total_votes DESC;

-- ======================================================
-- 2. Director Insights
-- Directors consistently producing highly-rated movies (avg rating > 8)
-- ======================================================
WITH director_movie_ratings AS (
  SELECT
    dm.name_id,
    dm.movie_id,
    r.avg_rating,
    r.total_votes
  FROM director_mapping dm
  JOIN ratings r ON dm.movie_id = r.movie_id
  WHERE r.total_votes >= 500
)
SELECT
  n.id AS director_id,
  n.name AS director_name,
  COUNT(DISTINCT dmr.movie_id) AS movie_count,
  AVG(dmr.avg_rating) AS avg_director_rating,
  MIN(dmr.avg_rating) AS min_movie_rating,
  MAX(dmr.avg_rating) AS max_movie_rating
FROM director_movie_ratings dmr
JOIN names n ON n.id = dmr.name_id
GROUP BY dmr.name_id
HAVING AVG(dmr.avg_rating) > 8
   AND COUNT(DISTINCT dmr.movie_id) >= 3
ORDER BY avg_director_rating DESC, movie_count DESC;

-- ======================================================
-- 3. Actor Popularity
-- Actors who most frequently appear in movies with ratings > 7.5
-- ======================================================
SELECT
  n.id AS actor_id,
  n.name AS actor_name,
  COUNT(*) AS high_rating_movie_count,
  AVG(r.avg_rating) AS avg_rating_in_these_movies
FROM role_mapping rm
JOIN ratings r ON rm.movie_id = r.movie_id
JOIN names n ON n.id = rm.name_id
WHERE rm.category IN ('actor','actress','cast','performer')
  AND r.avg_rating > 7.5
  AND r.total_votes >= 500
GROUP BY n.id, n.name
ORDER BY high_rating_movie_count DESC, avg_rating_in_these_movies DESC
LIMIT 50;

-- ======================================================
-- 4. Country & Language Analysis
-- Production volume and average rating across countries and languages
-- ======================================================
SELECT
  m.country,
  COUNT(*) AS movie_count,
  AVG(r.avg_rating) AS avg_rating,
  SUM(CAST(NULLIF(REGEXP_REPLACE(IFNULL(m.worlwide_gross_income,''),'[^0-9.]',''), '') AS DECIMAL(15,2))) AS total_gross,
  AVG(CAST(NULLIF(REGEXP_REPLACE(IFNULL(m.worlwide_gross_income,''),'[^0-9.]',''), '') AS DECIMAL(15,2))) AS avg_gross_per_movie
FROM movie m
JOIN ratings r ON m.id = r.movie_id
WHERE r.total_votes >= 100
GROUP BY m.country
ORDER BY movie_count DESC, avg_rating DESC;

-- ======================================================
-- 5. Revenue vs Ratings
-- Correlation between gross income and average rating
-- ======================================================
WITH mc AS (
  SELECT
    m.id,
    CAST(NULLIF(REGEXP_REPLACE(IFNULL(m.worlwide_gross_income,''),'[^0-9.]',''), '') AS DECIMAL(15,2)) AS gross_amount,
    r.avg_rating,
    r.total_votes
  FROM movie m
  JOIN ratings r ON m.id = r.movie_id
)
SELECT
  COUNT(*) AS n_movies,
  AVG(gross_amount) AS mean_gross,
  AVG(avg_rating) AS mean_rating,
  CASE
    WHEN STDDEV_POP(gross_amount) = 0 OR STDDEV_POP(avg_rating) = 0 THEN NULL
    ELSE COVAR_POP(gross_amount, avg_rating) / (STDDEV_POP(gross_amount) * STDDEV_POP(avg_rating))
  END AS pearson_correlation
FROM mc
WHERE gross_amount IS NOT NULL
  AND avg_rating IS NOT NULL
  AND total_votes >= 1000;

-- ======================================================
-- 6. Trends Over Time
-- Yearly movie count, average rating, and gross income
-- ======================================================
SELECT
  COALESCE(YEAR(m.date_published), m.year) AS year,
  COUNT(*) AS movies_released,
  AVG(r.avg_rating) AS avg_rating,
  SUM(CAST(NULLIF(REGEXP_REPLACE(IFNULL(m.worlwide_gross_income,''),'[^0-9.]',''), '') AS DECIMAL(15,2))) AS total_gross
FROM movie m
JOIN ratings r ON m.id = r.movie_id
WHERE COALESCE(YEAR(m.date_published), m.year) IS NOT NULL
GROUP BY year
ORDER BY year;

-- ======================================================
-- 7. Market Expansion Recommendations
-- 7a. Genres growing in popularity
-- ======================================================
WITH genre_year AS (
  SELECT g.genre, COALESCE(YEAR(m.date_published), m.year) AS year
  FROM genre g
  JOIN movie m ON g.movie_id = m.id
  WHERE COALESCE(YEAR(m.date_published), m.year) IS NOT NULL
),
max_year AS (SELECT MAX(COALESCE(YEAR(date_published), year)) AS max_y FROM movie),
counts AS (
  SELECT
    gy.genre,
    SUM(CASE WHEN gy.year BETWEEN (max_y-2) AND max_y THEN 1 ELSE 0 END) AS recent_count,
    SUM(CASE WHEN gy.year BETWEEN (max_y-5) AND (max_y-3) THEN 1 ELSE 0 END) AS prior_count
  FROM genre_year gy
  CROSS JOIN max_year
  GROUP BY gy.genre
)
SELECT
  genre,
  recent_count,
  prior_count,
  (recent_count - prior_count) AS count_change,
  ROUND(CASE WHEN prior_count = 0 THEN NULL ELSE (recent_count - prior_count)/prior_count*100 END, 2) AS pct_change
FROM counts
ORDER BY count_change DESC;

-- 7b. Countries producing most profitable / highest avg gross
SELECT
  m.country,
  COUNT(*) AS movie_count,
  AVG(r.avg_rating) AS avg_rating,
  SUM(CAST(NULLIF(REGEXP_REPLACE(IFNULL(m.worlwide_gross_income,''),'[^0-9.]',''), '') AS DECIMAL(15,2))) AS total_gross,
  AVG(CAST(NULLIF(REGEXP_REPLACE(IFNULL(m.worlwide_gross_income,''),'[^0-9.]',''), '') AS DECIMAL(15,2))) AS avg_gross_per_movie
FROM movie m
JOIN ratings r ON m.id = r.movie_id
WHERE r.total_votes >= 200
GROUP BY m.country
ORDER BY avg_gross_per_movie DESC
LIMIT 20;

-- ======================================================
-- 8. Recommendation System
-- Similar movies based on same genre, director, or actors
-- ======================================================
SET @target_movie_id = 'M123';

WITH target_genres AS (
  SELECT genre FROM genre WHERE movie_id = @target_movie_id
),
target_directors AS (
  SELECT name_id FROM director_mapping WHERE movie_id = @target_movie_id
),
target_actors AS (
  SELECT name_id FROM role_mapping WHERE movie_id = @target_movie_id
    AND (category IN ('actor','actress','cast','performer') OR category IS NULL)
)
SELECT
  cand.movie_id,
  mv.title,
  SUM(cand.score) AS total_score,
  r.avg_rating,
  r.total_votes
FROM (
  SELECT dm.movie_id, 3 AS score
  FROM director_mapping dm
  WHERE dm.name_id IN (SELECT name_id FROM target_directors)
    AND dm.movie_id <> @target_movie_id

  UNION ALL
  SELECT rm.movie_id, 2 AS score
  FROM role_mapping rm
  WHERE rm.name_id IN (SELECT name_id FROM target_actors)
    AND rm.movie_id <> @target_movie_id

  UNION ALL
  SELECT g.movie_id, 1 AS score
  FROM genre g
  WHERE g.genre IN (SELECT genre FROM target_genres)
    AND g.movie_id <> @target_movie_id
) cand
JOIN movie mv ON mv.id = cand.movie_id
LEFT JOIN ratings r ON r.movie_id = cand.movie_id
GROUP BY cand.movie_id, mv.title, r.avg_rating, r.total_votes
ORDER BY total_score DESC, r.avg_rating DESC, r.total_votes DESC
LIMIT 20;

-- ======================================================
-- END OF SCRIPT
-- ======================================================
