create database imdb;
use imdb;

SET GLOBAL net_read_timeout = 1000;
SET GLOBAL net_write_timeout = 1000;
SET GLOBAL wait_timeout = 1000;
SET GLOBAL interactive_timeout = 600;
SET GLOBAL max_allowed_packet = 67108864; -- 64MB


SHOW TABLE STATUS WHERE Name = 'movies_table';


ANALYZE TABLE movies_table;
ANALYZE TABLE ratings_table;
ANALYZE TABLE role_mapping_table;
ANALYZE TABLE names_table;
ANALYZE TABLE genres_table;

SHOW TABLE STATUS LIKE 'movies_table';

CREATE INDEX idx_movies_id_year ON movies_table (movie_id(20), year);
CREATE INDEX idx_movies_prodcompany_year ON movies_table(production_company(100), year);
CREATE INDEX idx_movies_country_year ON movies_table(country(100), year);
CREATE INDEX idx_ratings_movie_rating_votes ON ratings_table(movie_id(20), avg_rating, num_of_votes);
CREATE INDEX idx_names_id_birth ON names_table(name_id(20), birth_year);
CREATE INDEX idx_names_name ON names_table(name(100));
CREATE INDEX idx_roles_movie_category_name ON role_mapping_table(movie_id(20), category(20), name_id(20));
CREATE INDEX idx_roles_name_movie_category ON role_mapping_table(name_id(20), movie_id, category(20));
CREATE INDEX idx_genres_movie_genre ON genres_table(movie_id(20), genres(50));
CREATE INDEX idx_roles_nameid_category_movie ON role_mapping_table(name_id(20), category(20), movie_id(20));
CREATE INDEX idx_movies_id_language ON movies_table(movie_id(20), language(20));
CREATE INDEX idx_names_nameid_name ON names_table(name_id(20), name(100));



-- To reset password>> https://dev.mysql.com/doc/refman/8.0/en/resetting-permissions.html
/*
You want to launch a production house with a blockbuster movie. Don't delay and analyse the imdb data :)

To import the data create database imdb, use imdb and then use the following code in notebook:

import os
import time
import pandas as pd
from sqlalchemy import create_engine
from urllib.parse import quote_plus

# MySQL connection details
DB_USER = 'root'
DB_PASSWORD_RAW = 'Ajay@123'
DB_HOST = 'localhost'
DB_PORT = '3306'
DB_NAME = 'imdb'

# URL encode password
DB_PASSWORD = quote_plus(DB_PASSWORD_RAW)

# Create SQLAlchemy engine
engine = create_engine(f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}")

# Path to CSV folder
csv_folder = r'C:\Users\ajayk\Downloads\imdb_final_data'

start_time = time.time()
total_rows = 0

print(f"Starting import from: {csv_folder}\n")

for file in os.listdir(csv_folder):
    if file.endswith(".csv"):
        file_start = time.time()
        
        table_name = file.replace(".csv", "")
        file_path = os.path.join(csv_folder, file)

        print(f"Importing {file} into table {table_name}")

        try:
            df = pd.read_csv(file_path)
            df.to_sql(table_name, con=engine, if_exists='replace', index=False)
            duration = round(time.time() - file_start, 2)
            print(f"Uploaded {len(df)} rows to {table_name} in {duration} seconds\n")
            total_rows += len(df)
        except Exception as e:
            print(f"Failed to import {file}: {e}\n")

total_time = round(time.time() - start_time, 2)
print(f"Finished importing. Total rows: {total_rows} | Total time: {total_time} seconds")



*/



SELECT 
    *
FROM
    movies_table;

SELECT 
    *
FROM
    names_table;

SELECT 
    *
FROM
    ratings_table;

SELECT 
    *
FROM
    genres_table;

SELECT 
    *
FROM
    role_mapping_table;

-- To see columns
SHOW COLUMNS FROM genres_table;


-- Q1. Count number of rows in each table
-- Expected Output:
-- +------------------+------------+
-- | table_name       | row_count  |
-- +------------------+------------+
-- | movies_table     | 10000      |
-- | genres_table     | 9500       |
-- | ratings_table    | 10000      |
-- | names_table      | 8500       |
-- | role_mapping     | 16000      |
-- +------------------+------------+

SELECT 
    table_name, table_rows AS row_count
FROM
    information_schema.tables
WHERE
    table_schema = 'imdb';

-- Q2. Identify columns with NULLs in movies_table
-- Expected Output:
-- +-----------------------+
-- | column_with_nulls     |
-- +-----------------------+
-- | production_company     |
-- | gross_income_usd       |
-- +-----------------------+

SELECT 
    COLUMN_NAME AS column_with_nulls
FROM
    information_schema.columns
WHERE
    table_name = 'movies_table'
        AND table_schema = 'imdb'
        AND is_nullable = 'YES';


-- Q3. Movies released per year
-- Expected Output:
-- +------+------------------+
-- | year | number_of_movies |
-- +------+------------------+
-- | 2017 | 1300             |
-- | 2018 | 1700             |
-- +------+------------------+

SELECT 
    year, COUNT(*) AS number_of_movies
FROM
    movies_table
GROUP BY year
ORDER BY year;

-- Q4. Movies per month
-- Expected Output:
-- +------------+------------------+
-- | month_num  | number_of_movies |
-- +------------+------------------+
-- | 1          | 125              |
-- | 2          | 118              |
-- +------------+------------------+

SELECT 
    MONTH(STR_TO_DATE(date_published, '%Y-%m-%d')) AS month_num,
    COUNT(*) AS number_of_movies
FROM
    movies_table
WHERE
    STR_TO_DATE(date_published, '%Y-%m-%d') IS NOT NULL
GROUP BY month_num
ORDER BY month_num;



-- Q5. Movies from USA or India in 2019
-- Expected Output:
-- +---------+
-- | count   |
-- +---------+
-- | 1245    |
-- +---------+

SELECT 
    COUNT(*) AS count
FROM
    movies_table
WHERE
    country IN ('United States' , 'India')
        AND year = 2019;


-- Q6. Unique genres
-- Expected Output:
-- +---------+
-- | genre   |
-- +---------+
-- | Drama   |
-- | Comedy  |
-- +---------+

WITH RECURSIVE genre_split AS (
    SELECT
        movie_id,
        TRIM(SUBSTRING_INDEX(genres, ',', 1)) AS genre,
        SUBSTRING(genres, LENGTH(SUBSTRING_INDEX(genres, ',', 1)) + 2) AS remaining
    FROM genres_table

    UNION ALL

    SELECT
        movie_id,
        TRIM(SUBSTRING_INDEX(remaining, ',', 1)) AS genre,
        SUBSTRING(remaining, LENGTH(SUBSTRING_INDEX(remaining, ',', 1)) + 2)
    FROM genre_split
    WHERE remaining != ''
)

SELECT DISTINCT genre
FROM genre_split
WHERE genre IS NOT NULL
ORDER BY genre;



-- Q7. Genre with most movies
-- Expected Output:
-- +---------+---------------+
-- | genre   | movie_count   |
-- +---------+---------------+
-- | Drama   | 3050          |
-- +---------+---------------+

WITH RECURSIVE genre_split AS (
    SELECT
        movie_id,
        TRIM(SUBSTRING_INDEX(genres, ',', 1)) AS genre,
        SUBSTRING(genres, LENGTH(SUBSTRING_INDEX(genres, ',', 1)) + 2) AS remaining
    FROM genres_table

    UNION ALL

    SELECT
        movie_id,
        TRIM(SUBSTRING_INDEX(remaining, ',', 1)) AS genre,
        SUBSTRING(remaining, LENGTH(SUBSTRING_INDEX(remaining, ',', 1)) + 2)
    FROM genre_split
    WHERE remaining != ''
)

SELECT genre, COUNT(DISTINCT movie_id) AS movie_count
FROM genre_split
WHERE genre IS NOT NULL
GROUP BY genre
ORDER BY movie_count DESC
LIMIT 1;




-- Q8. Movies with only one genre
-- Expected Output:
-- +----------+
-- | count    |
-- +----------+
-- | 3125     |
-- +----------+

SELECT 
    COUNT(*) AS count
FROM
    genres_table
WHERE
    genres NOT LIKE '%,%';


-- Q9. Average movie duration per genre
-- Expected Output:
-- +---------+------------------+
-- | genre   | avg_duration     |
-- +---------+------------------+
-- | Drama   | 107.2            |
-- | Action  | 112.8            |
-- +---------+------------------+

WITH numbers AS (
    SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
),
genre_duration AS (
    SELECT
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(g.genres, ',', n.n), ',', -1)) AS genre,
        m.duration_in_mins
    FROM genres_table g
    JOIN movies_table m ON g.movie_id = m.movie_id
    JOIN numbers n ON n.n <= 1 + LENGTH(g.genres) - LENGTH(REPLACE(g.genres, ',', ''))
)
SELECT genre, ROUND(AVG(duration_in_mins), 1) AS avg_duration
FROM genre_duration
WHERE genre IS NOT NULL
GROUP BY genre
ORDER BY avg_duration DESC;




-- Q10. Rank of 'thriller' genre by movie count, you can use rank function
-- Expected Output:
-- +----------+-------------+-------------+
-- | genre    | movie_count | genre_rank  |
-- +----------+-------------+-------------+
-- | Thriller | 2050        | 3           |
-- +----------+-------------+-------------+

WITH genre_movie_counts AS (
    SELECT
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(g.genres, ',', n.n), ',', -1)) AS genre,
        COUNT(m.movie_id) AS movie_count
    FROM movies_table m
    JOIN genres_table g ON m.movie_id = g.movie_id
    JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8) n
    WHERE n.n <= LENGTH(g.genres) - LENGTH(REPLACE(g.genres, ',', '')) + 1
    GROUP BY genre
)
SELECT
    genre,
    movie_count,
    RANK() OVER (ORDER BY movie_count DESC) AS genre_rank
FROM genre_movie_counts
WHERE genre = 'Thriller';


-- Q11. Min/Max from ratings_table
-- Expected Output:
-- +----------------+----------------+----------------+----------------+
-- | min_avg_rating | max_avg_rating | min_votes      | max_votes      |
-- +----------------+----------------+----------------+----------------+
-- | 0.0            | 9.8            | 100            | 98000          |
-- +----------------+----------------+----------------+----------------+

SELECT 
    MIN(avg_rating) AS min_avg_rating,
    MAX(avg_rating) AS max_avg_rating,
    MIN(num_of_votes) AS min_votes,
    MAX(num_of_votes) AS max_votes
FROM
    ratings_table;


-- Q12. Top 10 movies by avg rating
-- Expected Output:
-- +---------------------+-------------+-------------+
-- | movie_name          | avg_rating  | movie_rank  |
-- +---------------------+-------------+-------------+
-- | The Dark Knight     | 9.8         | 1           |
-- | Parasite            | 9.6         | 2           |
-- +---------------------+-------------+-------------+

SELECT
    m.movie_name,
    r.avg_rating,
    RANK() OVER (ORDER BY r.avg_rating DESC) AS movie_rank
FROM movies_table m
JOIN ratings_table r ON m.movie_id = r.movie_id
ORDER BY movie_rank
LIMIT 10;


-- Q13. Movie counts by average rating
-- Expected Output:
-- +---------------+--------------+
-- | median_rating | movie_count |
-- +---------------+--------------+
-- | 7             | 3000         |
-- | 6             | 2500         |
-- +---------------+--------------+
SELECT 
    r.avg_rating, COUNT(*) AS movie_count
FROM
    ratings_table r
GROUP BY r.avg_rating
ORDER BY movie_count DESC;



-- Q14. Production house with max hit movies (>8 avg rating)
-- Expected Output:
-- +------------------------+--------------+------------------+
-- | production_company     | movie_count  | prod_company_rank|
-- +------------------------+--------------+------------------+
-- | Dream Warrior Pictures| 9            | 1                |
-- +------------------------+--------------+------------------+

SELECT
    m.production_company,
    COUNT(m.movie_id) AS movie_count,
    RANK() OVER (ORDER BY COUNT(m.movie_id) DESC) AS prod_company_rank
FROM movies_table m
JOIN ratings_table r ON m.movie_id = r.movie_id
WHERE r.avg_rating > 8
GROUP BY m.production_company
ORDER BY movie_count DESC
LIMIT 2;



-- Q15. March 2017 USA genre-wise movies with >100 votes
-- Expected Output:
-- +----------+--------------+
-- | genre    | movie_count  |
-- +----------+--------------+
-- | Action   | 15           |
-- +----------+--------------+

SELECT 
    g.genres AS genre, COUNT(DISTINCT m.movie_id) AS movie_count
FROM
    movies_table m
        JOIN
    ratings_table r ON m.movie_id = r.movie_id
        JOIN
    genres_table g ON m.movie_id = g.movie_id
WHERE
    m.country = 'USA'
        AND STR_TO_DATE(m.date_published, '%Y-%m-%d') BETWEEN '2017-03-01' AND '2017-03-31'
        AND r.num_of_votes > 100
GROUP BY g.genres
ORDER BY movie_count DESC;



-- Q16. Genre-wise movies starting with 'The' and avg_rating > 8
-- Expected Output:
-- +------------------+-------------+--------+
-- | movie_name       | avg_rating  | genre  |
-- +------------------+-------------+--------+
-- | The Pianist      | 8.7         | Drama  |
-- +------------------+-------------+--------+

SELECT 
    m.movie_name, r.avg_rating, g.genres
FROM
    movies_table m
        JOIN
    ratings_table r ON m.movie_id = r.movie_id
        JOIN
    genres_table g ON m.movie_id = g.movie_id
WHERE
    m.movie_name LIKE 'The%'
        AND r.avg_rating > 8
ORDER BY g.genres;


-- Q17. Movies released between 1-Apr-2018 and 1-Apr-2019 with average rating = 8
-- Expected Output:
-- +----------+
-- | count    |
-- +----------+
-- | 42       |
-- +----------+

WITH movie_ratings AS (
    SELECT
        r.avg_rating,
        m.movie_id
    FROM movies_table m
    JOIN ratings_table r ON m.movie_id = r.movie_id
    WHERE m.date_published BETWEEN '2018-04-01' AND '2019-04-01'
)
SELECT COUNT(*) AS count
FROM movie_ratings
WHERE avg_rating = 8;


-- Q18. German vs Italian movie votes
-- Expected Output:
-- +----------+----------+------------------+
-- | country1 | country2 | more_votes       |
-- +----------+----------+------------------+
-- | German   | Italian  | German           |
-- +----------+----------+------------------+

SELECT 
    'German' AS country1,
    'Italian' AS country2,
    CASE
        WHEN
            SUM(CASE
                WHEN m.country = 'Germany' THEN r.num_of_votes
                ELSE 0
            END) > SUM(CASE
                WHEN m.country = 'Italy' THEN r.num_of_votes
                ELSE 0
            END)
        THEN
            'German'
        ELSE 'Italian'
    END AS more_votes
FROM
    movies_table m
        JOIN
    ratings_table r ON m.movie_id = r.movie_id
WHERE
    m.country IN ('Germany' , 'Italy');


-- Q19. Columns with nulls in names_table
-- Expected Output:
-- +--------------+---------------+----------------+------------------------+
-- | name_nulls   | birth_years   | death_years    | known_for_movies_nulls|
-- +--------------+---------------+----------------+------------------------+
-- | 0            | 213           | 1350           | 3212                   |
-- +--------------+---------------+----------------+------------------------+

SELECT 
    COUNT(CASE
        WHEN name IS NULL THEN 1
    END) AS name_nulls,
    COUNT(CASE
        WHEN birth_year IS NULL THEN 1
    END) AS birth_years,
    COUNT(CASE
        WHEN death_year IS NULL THEN 1
    END) AS death_years,
    COUNT(CASE
        WHEN known_for_movies IS NULL THEN 1
    END) AS known_for_movies_nulls
FROM
    names_table;


-- Q20. Top 3 directors in top 3 genres with avg_rating > 8
-- Expected Output:
-- +------------------+--------------+
-- | director_name    | movie_count  |
-- +------------------+--------------+
-- | James Cameron    | 5            |
-- +------------------+--------------+

WITH genre_counts AS (
    SELECT
        g.genres,
        COUNT(*) AS genre_count
    FROM genres_table g
    JOIN ratings_table r ON g.movie_id = r.movie_id
    WHERE r.avg_rating > 8
    GROUP BY g.genres
    ORDER BY genre_count DESC
    LIMIT 3
),
top_directors AS (
    SELECT
        nm.name AS director_name,
        g.genres,
        COUNT(*) AS movie_count
    FROM movies_table m
    JOIN ratings_table r ON m.movie_id = r.movie_id
    JOIN genres_table g ON m.movie_id = g.movie_id
    JOIN role_mapping_table rm ON m.movie_id = rm.movie_id
    JOIN names_table nm ON rm.name_id = nm.name_id
    WHERE rm.category = 'director'
      AND r.avg_rating > 8
      AND g.genres IN (SELECT genres FROM genre_counts)
    GROUP BY nm.name, g.genres
)
SELECT
    director_name,
    SUM(movie_count) AS movie_count
FROM top_directors
GROUP BY director_name
ORDER BY movie_count DESC
LIMIT 3;



-- Q21. Top 2 actors with average rating >= 8
-- Expected Output:
-- +------------------+--------------+
-- | actor_name       | movie_count  |
-- +------------------+--------------+
-- | Mohanlal         | 7            |
-- +------------------+--------------+

SELECT 
    n.name AS actor_name,
    COUNT(DISTINCT rm.movie_id) AS movie_count
FROM
    role_mapping_table rm
        JOIN
    names_table n ON rm.name_id = n.name_id
        JOIN
    ratings_table r ON rm.movie_id = r.movie_id
WHERE
    rm.category = 'actor'
        AND r.avg_rating >= 8
GROUP BY n.name
ORDER BY movie_count DESC
LIMIT 2;




-- Q22. List all movies that have more than 3 genres.
-- Expected Output:
-- +-----------+----------------+--------------+
-- | movie_id  | movie_name     | genres_count |
-- +-----------+----------------+--------------+
-- | m001      | Inception      | 4            |
-- | m002      | Pulp Fiction   | 5            |
-- +-----------+----------------+--------------+

SELECT 
    g.movie_id,
    m.movie_name,
    LENGTH(g.genres) - LENGTH(REPLACE(g.genres, ',', '')) + 1 AS genres_count
FROM
    genres_table g
        JOIN
    movies_table m ON g.movie_id = m.movie_id
WHERE
    g.genres IS NOT NULL
HAVING genres_count > 3;




-- Q23. Find the top 5 actors (category = 'actor') who have acted in the most number of English movies.
-- Expected Output:
-- +--------+---------------------+--------------+
-- | name_id| name                | movie_count  |
-- +--------+---------------------+--------------+
-- | n0123  | Tom Hanks           | 25           |
-- | n0456  | Leonardo DiCaprio  | 23           |
-- +--------+---------------------+--------------+

WITH english_movies AS (
    SELECT movie_id 
    FROM movies_table 
    WHERE language = 'English'
    LIMIT 10000  -- Adjust limit for testing
),
actor_roles AS (
    SELECT rm.name_id, rm.movie_id
    FROM role_mapping_table rm
    WHERE rm.category = 'actor'
    LIMIT 10000  -- Adjust limit for testing
),
actor_english_movies AS (
    SELECT ar.name_id
    FROM actor_roles ar
    JOIN english_movies em ON ar.movie_id = em.movie_id
)
SELECT 
    aem.name_id,
    n.name,
    COUNT(*) AS movie_count
FROM actor_english_movies aem
JOIN names_table n ON aem.name_id = n.name_id
GROUP BY aem.name_id, n.name
ORDER BY movie_count DESC
LIMIT 5;




-- Q24. Show all movies released in the same year as “Inception” but have a higher average rating.
-- Expected Output:
-- +-----------------------+------+-------------+
-- | movie_name            | year | avg_rating |
-- +-----------------------+------+-------------+
-- | The Social Network    | 2010 | 8.5        |
-- +-----------------------+------+-------------+

SELECT 
    m.movie_name, m.year, r.avg_rating
FROM
    movies_table m
        JOIN
    ratings_table r ON m.movie_id = r.movie_id
WHERE
    m.year = (SELECT 
            year
        FROM
            movies_table
        WHERE
            movie_name = 'Inception')
        AND r.avg_rating > (SELECT 
            r.avg_rating
        FROM
            movies_table m
                JOIN
            ratings_table r ON m.movie_id = r.movie_id
        WHERE
            m.movie_name = 'Inception')



-- Q25. Find all movies that are in both the “Action” and “Adventure” genres.
-- Expected Output:
-- +-----------+---------------------+
-- | movie_id  | movie_name          |
-- +-----------+---------------------+
-- | m011      | Avengers: Endgame   |
-- +-----------+---------------------+

SELECT 
    m.movie_id, m.movie_name
FROM
    movies_table m
        JOIN
    genres_table g1 ON m.movie_id = g1.movie_id
        AND g1.genres LIKE '%Action%'
        JOIN
    genres_table g2 ON m.movie_id = g2.movie_id
        AND g2.genres LIKE '%Adventure%'. For each year, list the movie with the highest average rating.
-- Expected Output:
-- +------+--------------------+-------------+
-- | year | movie_name         | avg_rating |
-- +------+--------------------+-------------+
-- | 2010 | Inception          | 8.8        |
-- | 2011 | The Help           | 8.2        |
-- +------+--------------------+-------------+

WITH RankedMovies AS (
    SELECT 
        m.year,
        m.movie_name,
        r.avg_rating,
        ROW_NUMBER() OVER (PARTITION BY m.year ORDER BY r.avg_rating DESC) AS rn
    FROM movies_table m
    JOIN ratings_table r ON m.movie_id = r.movie_id
)
SELECT year, movie_name, avg_rating
FROM RankedMovies
WHERE rn = 1;




-- Q27. Show all movies where the number of votes is at least twice the average number of votes across all movies.
-- Expected Output:
-- +----------------+--------------+
-- | movie_name     | num_of_votes |
-- +----------------+--------------+
-- | Interstellar   | 2000000      |
-- +----------------+--------------+

SELECT m.movie_name, r.num_of_votes
FROM ratings_table r
JOIN movies_table m ON r.movie_id = m.movie_id
WHERE r.num_of_votes >= 2 * (
    SELECT AVG(num_of_votes) FROM ratings_table
);




-- Q28. List all directors (category = 'director') who have directed movies in more than 3 different languages.
-- Expected Output:
-- +--------+------------------+------------------+
-- | name_id| name             | languages_count  |
-- +--------+------------------+------------------+
-- | n789   | Bong Joon-ho     | 4                |
-- +--------+------------------+------------------+

SELECT n.name_id, n.name, COUNT(DISTINCT m.language) AS languages_count
FROM role_mapping_table rm
JOIN names_table n ON rm.name_id = n.name_id
JOIN movies_table m ON rm.movie_id = m.movie_id
WHERE rm.category = 'director'
GROUP BY n.name_id, n.name
HAVING COUNT(DISTINCT m.language) > 3;



-- Q29. Find the top 5 most voted adult movies.
-- Expected Output:
-- +-------------------+--------------+-------------+
-- | movie_name        | num_of_votes | avg_rating |
-- +-------------------+--------------+-------------+
-- | Eyes Wide Shut    | 500000       | 7.4        |
-- +-------------------+--------------+-------------+

SELECT m.movie_name, r.num_of_votes, r.avg_rating
FROM movies_table m
JOIN ratings_table r ON m.movie_id = r.movie_id
WHERE m.is_adult = '1'
ORDER BY r.num_of_votes DESC
LIMIT 5;




-- Q30. For each country, show the number of movies and the average rating of those movies.
-- Expected Output:
-- +--------+--------------+-------------+
-- | country| movie_count  | avg_rating |
-- +--------+--------------+-------------+
-- | USA    | 1200         | 7.1        |
-- | India  | 800          | 6.8        |
-- +--------+--------------+-------------+

SELECT m.country, COUNT(*) AS movie_count, ROUND(AVG(r.avg_rating), 2) AS avg_rating
FROM movies_table m
JOIN ratings_table r ON m.movie_id = r.movie_id
GROUP BY m.country;


-- Q31. Show movies where the production company has made more than 5 movies.
-- Expected Output:
-- +--------------------+----------------------+--------------+
-- | production_company | movie_name           | total_movies |
-- +--------------------+----------------------+--------------+
-- | Warner Bros        | The Dark Knight      | 7            |
-- +--------------------+----------------------+--------------+

SELECT 
    m.production_company, 
    m.movie_name, 
    total_movies
FROM 
    movies_table m
JOIN (
    SELECT production_company, COUNT(*) AS total_movies
    FROM movies_table
    GROUP BY production_company
    HAVING COUNT(*) > 5
) AS production_count
ON m.production_company = production_count.production_company;




-- Q32. Find the most recent movie for each production company.
-- Expected Output:
-- +------------------------+----------------+------+
-- | production_company     | movie_name     | year |
-- +------------------------+----------------+------+
-- | Universal Pictures     | Nope           | 2022 |

SELECT production_company, movie_name, year
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY production_company ORDER BY year DESC) AS rn
    FROM movies_table
    WHERE production_company IS NOT NULL
) t
WHERE rn = 1;

-- +------------------------+----------------+------+

-- Q33. List actors who have worked with at least 5 different production companies.
-- Expected Output:
-- +-------------+--------------------------+
-- | name        | production_company_count |
-- +-------------+--------------------------+
-- | Matt Damon  | 6                        |
-- +-------------+--------------------------+
SELECT n.name, COUNT(DISTINCT m.production_company) AS production_company_count
FROM role_mapping_table rm
JOIN names_table n ON rm.name_id = n.name_id
JOIN movies_table m ON rm.movie_id = m.movie_id
WHERE rm.category = 'actor' AND m.production_company IS NOT NULL
GROUP BY n.name
HAVING COUNT(DISTINCT m.production_company) >= 5;


-- Q34. List all movies where the gross income is NULL but rating is above 8.
-- Expected Output:
-- +------------+-------------+
-- | movie_name | avg_rating |
-- +------------+-------------+
-- | Parasite   | 8.6        |
-- +------------+-------------+

SELECT m.movie_name, r.avg_rating
FROM movies_table m
JOIN ratings_table r ON m.movie_id = r.movie_id
WHERE m.gross_income_usd IS NULL AND r.avg_rating > 8;



-- Q35. Show top 10 movies with the highest gross income per minute of duration.
-- Expected Output:
-- +-------------+------------------+--------------------+------------------+
-- | movie_name  | gross_income_usd | duration_in_mins   | income_per_min   |
-- +-------------+------------------+--------------------+------------------+
-- | Avatar      | 2800000000       | 160                | 17500000         |
-- +-------------+------------------+--------------------+------------------+


SELECT m.movie_name, m.gross_income_usd, m.duration_in_mins,
       ROUND(m.gross_income_usd / m.duration_in_mins, 2) AS income_per_min
FROM movies_table m
WHERE m.gross_income_usd IS NOT NULL AND m.duration_in_mins > 0
ORDER BY income_per_min DESC
LIMIT 10;



-- Q36. List all actors who acted in movies released before they were born (fun easter egg check).
-- Expected Output:
-- +--------+-------------+-------------+------------+
-- | name_id| name        | birth_year  | movie_year|
-- +--------+-------------+-------------+------------+
-- | n9876  | Some Actor  | 1990        | 1988      |
-- +--------+-------------+-------------+------------+

SELECT 
    n.name_id, 
    n.name, 
    n.birth_year, 
    m.year AS movie_year
FROM (
    SELECT name_id, movie_id
    FROM role_mapping_table
    WHERE category = 'actor'
) AS filtered_rm
JOIN names_table n ON filtered_rm.name_id = n.name_id AND n.birth_year IS NOT NULL
JOIN movies_table m ON filtered_rm.movie_id = m.movie_id AND m.year < n.birth_year;




-- Q37. Show actors who have played in movies of more than 4 different genres.
-- Expected Output:
-- +-------------+--------------+
-- | name        | genres_count|
-- +-------------+--------------+
-- | Johnny Depp | 6            |
-- +-------------+--------------+


WITH actor_genres AS (
    SELECT rm.name_id, g.genres
    FROM role_mapping_table rm
    JOIN genres_table g ON rm.movie_id = g.movie_id
    WHERE rm.category = 'actor'
    LIMIT 10000  -- Limiting the number of rows for testing
)
SELECT n.name, COUNT(DISTINCT ag.genres) AS genres_count
FROM actor_genres ag
JOIN names_table n ON ag.name_id = n.name_id
GROUP BY ag.name_id, n.name
HAVING genres_count > 4;




-- Q38. Show top 5 movies where the description contains the word "robot" or "AI".
-- Expected Output:
-- +-------------+--------------------------------------+
-- | movie_name  | description_snippet                  |
-- +-------------+--------------------------------------+
-- | Ex Machina  | A young programmer...robot           |
-- +-------------+--------------------------------------+

SELECT movie_name, description AS description_snippet
FROM movies_table
WHERE LOWER(description) LIKE '%robot%' OR LOWER(description) LIKE '%ai%'
LIMIT 5;


-- Q39. List all movies that were not assigned any rating.
-- Expected Output:
-- +-----------+----------------+
-- | movie_id  | movie_name     |
-- +-----------+----------------+
-- | m876      | Indie Film     |
-- +-----------+----------------+

SELECT m.movie_id, m.movie_name
FROM movies_table m
LEFT JOIN ratings_table r ON m.movie_id = r.movie_id
WHERE r.movie_id IS NULL;


-- Q40. Find the average duration of movies by genre.
-- Expected Output:
-- +--------+--------------+
-- | genre  | avg_duration |
-- +--------+--------------+
-- | Drama  | 120          |
-- | Comedy | 95           |
-- +--------+--------------+

SELECT g.genres AS genre, ROUND(AVG(m.duration_in_mins), 0) AS avg_duration
FROM genres_table g
JOIN movies_table m ON g.movie_id = m.movie_id
GROUP BY g.genres;


-- Q41. Find top 5 actors with highest average movie rating.
-- Expected Output:
-- +-------------------+--------------------+
-- | name              | avg_movie_rating   |
-- +-------------------+--------------------+
-- | Christian Bale    | 8.4                |
-- +-------------------+--------------------+

SELECT 
    n.name,
    ROUND(AVG(r.avg_rating), 2) AS avg_movie_rating
FROM role_mapping_table rm
JOIN ratings_table r ON rm.movie_id = r.movie_id
JOIN names_table n ON rm.name_id = n.name_id
WHERE rm.category = 'actor'
GROUP BY rm.name_id, n.name
HAVING COUNT(r.movie_id) >= 1
ORDER BY avg_movie_rating DESC
LIMIT 5;




-- Q42. Find all movies where the number of genres is equal to the number of languages.
-- Expected Output:
-- +----------+------------+-------------+----------------+
-- | movie_id | movie_name | genre_count | language_count |
-- +----------+------------+-------------+----------------+
-- | m034     | MovieX     | 3           | 3              |
-- +----------+------------+-------------+----------------+

SELECT 
    m.movie_id,
    m.movie_name,
    g.genre_count,
    lang.language_count
FROM movies_table m
JOIN (
    SELECT movie_id, COUNT(*) AS genre_count
    FROM genres_table
    GROUP BY movie_id
) g ON m.movie_id = g.movie_id
JOIN (
    SELECT 
        movie_id,
        LENGTH(language) - LENGTH(REPLACE(language, ',', '')) + 1 AS language_count
    FROM movies_table
) lang ON m.movie_id = lang.movie_id
WHERE g.genre_count = lang.language_count;

    

-- Q43. Which actors have appeared in both adult and non-adult films?
-- Expected Output:
-- +--------+---------+
-- | name_id| name    |
-- +--------+---------+
-- | n444   | Actor A |
-- +--------+---------+


SELECT 
    rm.name_id,
    n.name
FROM (
    SELECT 
        rm.name_id,
        COUNT(DISTINCT m.is_adult) AS is_adult_count
    FROM role_mapping_table rm
    STRAIGHT_JOIN movies_table m 
        ON rm.movie_id = m.movie_id
    WHERE rm.category = 'actor' AND m.is_adult IN (0, 1)
    GROUP BY rm.name_id
    HAVING is_adult_count = 2
    LIMIT 100
) AS rm
JOIN names_table n ON rm.name_id = n.name_id;


    


-- Q44. Show production companies that produced only non-English films.
-- Expected Output:
-- +------------------+
-- | production_company |
-- +------------------+
-- | Studio Ghibli     |
-- +------------------+
SELECT 
    production_company
FROM 
    movies_table
WHERE 
    language != 'English'
GROUP BY 
    production_company
HAVING 
    COUNT(DISTINCT language) = 1;



-- Q45. List top 5 actors who have acted in the most number of different languages.
-- Expected Output:
-- +-------------+------------------+
-- | name        | language_count   |
-- +-------------+------------------+
-- | Jackie Chan | 7                |
-- +-------------+------------------+


SELECT 
    t.name_id,
    n.name,
    COUNT(DISTINCT m.language) AS language_count
FROM (
    SELECT rm.name_id, rm.movie_id
    FROM role_mapping_table rm
    WHERE rm.category = 'actor'
    LIMIT 100000  -- Adjust this limit based on performance
) AS t
JOIN movies_table m ON t.movie_id = m.movie_id AND m.language IS NOT NULL
JOIN names_table n ON t.name_id = n.name_id
GROUP BY t.name_id, n.name
ORDER BY language_count DESC
LIMIT 5;







-- Q46. For each decade, show the movie with the highest number of votes.
-- Expected Output:
-- +--------+----------------+--------------+
-- | decade | movie_name     | num_of_votes |
-- +--------+----------------+--------------+
-- | 1990s  | The Matrix     | 1900000      |
-- +--------+----------------+--------------+

SELECT 
    CONCAT(FLOOR(m.year / 10) * 10, 's') AS decade, 
    m.movie_name, 
    r.num_of_votes
FROM 
    movies_table m
JOIN 
    ratings_table r ON m.movie_id = r.movie_id
WHERE 
    r.num_of_votes = (SELECT MAX(r1.num_of_votes) FROM ratings_table r1 JOIN movies_table m1 ON m1.movie_id = r1.movie_id WHERE FLOOR(m1.year / 10) * 10 = FLOOR(m.year / 10) * 10)
ORDER BY 
    decade;
    
    
 


-- Q47. Show actors who have never worked in movies with average rating below 6.
-- Expected Output:
-- +--------+---------+
-- | name_id| name    |
-- +--------+---------+
-- | n333   | Actor B |
-- +--------+---------+

SELECT 
    n.name_id, n.name
FROM
    (SELECT DISTINCT
        name_id
    FROM
        role_mapping_table
    WHERE
        category = 'actor'
    LIMIT 1000) AS rm
        JOIN
    names_table n ON rm.name_id = n.name_id
        JOIN
    role_mapping_table rm2 ON rm.name_id = rm2.name_id
        JOIN
    movies_table m ON rm2.movie_id = m.movie_id
        JOIN
    ratings_table r ON m.movie_id = r.movie_id
GROUP BY n.name_id , n.name
HAVING MIN(r.avg_rating) >= 6
LIMIT 100. Show all movies having the same name but different release years.
-- Expected Output:
-- +---------------+------+
-- | movie_name    | year |
-- +---------------+------+
-- | The Avengers  | 1998 |
-- | The Avengers  | 2012 |
-- +---------------+------+

SELECT 
    movie_name, 
    year
FROM 
    movies_table
GROUP BY 
    movie_name
HAVING 
    COUNT(DISTINCT year) > 1;


-- Q49. List actors who have acted in more than 3 movies with the same genre.
-- Expected Output:
-- +------------+--------+-------------+
-- | name       | genre  | movie_count |
-- +------------+--------+-------------+
-- | Brad Pitt  | Drama  | 4           |
-- +------------+--------+-------------+

SELECT 
    n.name, 
    g.genres AS genre, 
    COUNT(DISTINCT m.movie_id) AS movie_count
FROM 
    names_table n
JOIN 
    role_mapping_table rm ON n.name_id = rm.name_id
JOIN 
    movies_table m ON rm.movie_id = m.movie_id
JOIN 
    genres_table g ON m.movie_id = g.movie_id
GROUP BY 
    n.name, g.genres
HAVING 
    movie_count > 3;



-- Q50. For each genre, show the actor with the highest number of appearances.
-- Expected Output:
-- +--------+-------------+-------------+
-- | genre  | name        | appearances |
-- +--------+-------------+-------------+
-- | Action | Vin Diesel  | 12          |
-- +--------+-------------+-------------+

SELECT 
    g.genres AS genre, 
    n.name, 
    COUNT(rm.movie_id) AS appearances
FROM 
    genres_table g
JOIN 
    movies_table m ON g.movie_id = m.movie_id
JOIN 
    role_mapping_table rm ON m.movie_id = rm.movie_id
JOIN 
    names_table n ON rm.name_id = n.name_id
GROUP BY 
    g.genres, n.name
ORDER BY 
    genre, appearances DESC;
    



-- Q51. Show the movie(s) with the longest duration in each genre.
-- Expected Output:
-- +--------+-------------+--------------------+
-- | genre  | movie_name  | duration_in_mins   |
-- +--------+-------------+--------------------+
-- | Drama  | The Irishman| 209                |
-- +--------+-------------+--------------------+
WITH genre_max_duration AS (
    SELECT 
        g.genres AS genre,
        MAX(m.duration_in_mins) AS max_duration
    FROM 
        genres_table g
    JOIN 
        movies_table m ON g.movie_id = m.movie_id
    GROUP BY 
        g.genres
)
SELECT 
    g.genres AS genre,
    m.movie_name,
    m.duration_in_mins
FROM 
    genres_table g
JOIN 
    movies_table m ON g.movie_id = m.movie_id
JOIN 
    genre_max_duration gd ON g.genres = gd.genre AND m.duration_in_mins = gd.max_duration
ORDER BY 
    genre;




-- Q52. List all actors who have acted in movies from every genre present in the dataset.
-- Expected Output:
-- +------------+------------------+
-- | name_id    | name             |
-- +------------+------------------+
-- | n123456    | Versatile Actor  |
-- +------------+------------------+
-- First count total number of genres
WITH total_genres AS (
    SELECT COUNT(DISTINCT genres) AS genre_count FROM genres_table
),
actor_genre_coverage AS (
    SELECT 
        rm.name_id,
        n.name,
        COUNT(DISTINCT g.genres) AS genre_count
    FROM 
        role_mapping_table rm
    JOIN 
        genres_table g ON rm.movie_id = g.movie_id
    JOIN 
        names_table n ON rm.name_id = n.name_id
    WHERE 
        rm.category = 'actor'
    GROUP BY 
        rm.name_id, n.name
)
SELECT 
    agc.name_id,
    agc.name
FROM 
    actor_genre_coverage agc
JOIN 
    total_genres tg ON agc.genre_count = tg.genre_count;




-- Q53. Show all movies where the description is missing (NULL or empty).
-- Expected Output:
-- +-----------+------------------+
-- | movie_id  | movie_name       |
-- +-----------+------------------+
-- | m0012     | Unknown Mystery  |
-- +-----------+------------------+
SELECT 
    movie_id, 
    movie_name
FROM 
    movies_table
WHERE 
    description IS NULL 
    OR TRIM(description) = '';



-- Q54. List the total number of movies released per year.
-- Expected Output:
-- +------+------------------+
-- | year | movie_count      |
-- +------+------------------+
-- | 2020 | 120              |
-- | 2019 | 130              |
-- +------+------------------+

SELECT 
    year,
    COUNT(*) AS movie_count
FROM 
    movies_table
WHERE 
    year IS NOT NULL
GROUP BY 
    year
ORDER BY 
    year DESC;
    


-- Q55. Show all people who are credited both as actors and directors.
-- Expected Output:
-- +----------+------------------+
-- | name_id  | name             |
-- +----------+------------------+
-- | n222     | Ben Affleck      |
-- +----------+------------------+
SELECT 
    n.name_id, 
    n.name
FROM 
    names_table n
JOIN 
    role_mapping_table rm_actor ON n.name_id = rm_actor.name_id AND rm_actor.category = 'actor'
JOIN 
    role_mapping_table rm_director ON n.name_id = rm_director.name_id AND rm_director.category = 'director'
GROUP BY 
    n.name_id, n.name;

-- Q56. Find top 3 countries by average gross income of their movies.
-- Expected Output:
-- +---------+--------------------+
-- | country | avg_gross_income   |
-- +---------+--------------------+
-- | USA     | 150000000          |
-- +---------+--------------------+

SELECT country, 
       ROUND(AVG(gross_income_usd)) AS avg_gross_income
FROM movies_table
WHERE gross_income_usd IS NOT NULL
GROUP BY country
ORDER BY avg_gross_income DESC
LIMIT 3;


-- Q57. Show the number of movies in each language where the average rating is above 7.
-- Expected Output:
-- +----------+--------------+
-- | language | movie_count  |
-- +----------+--------------+
-- | English  | 500          |
-- | Korean   | 45           |
-- +----------+--------------+


SELECT m.language, COUNT(*) AS movie_count
FROM movies_table m
JOIN ratings_table r ON m.movie_id = r.movie_id
WHERE r.avg_rating > 7
GROUP BY m.language;

-- Q58. List actors who acted in movies from at least 3 different decades.
-- Expected Output:
-- +----------+-------------------+-------------------+
-- | name_id  | name              | decades_appeared  |
-- +----------+-------------------+-------------------+
-- | n456     | Tom Cruise        | 1980s, 1990s, 2000s|
-- +----------+-------------------+-------------------+

SELECT rm.name_id, n.name,
       GROUP_CONCAT(DISTINCT CONCAT(FLOOR(m.year / 10) * 10, 's') ORDER BY m.year) AS decades_appeared
FROM role_mapping_table rm
JOIN movies_table m ON rm.movie_id = m.movie_id
JOIN names_table n ON rm.name_id = n.name_id
WHERE rm.category = 'actor'
GROUP BY rm.name_id, n.name
HAVING COUNT(DISTINCT FLOOR(m.year / 10)) >= 3;


-- Q59. Show all movies that have won at least one award (assuming "description" contains keywords like 'won' or 'award').
-- Expected Output:
-- +------------------+-----------------------------------------+
-- | movie_name       | description_snippet                     |
-- +------------------+-----------------------------------------+
-- | Slumdog Millionaire | ...won 8 Academy Awards...           |
-- +------------------+-----------------------------------------+

SELECT movie_name, description AS description_snippet
FROM movies_table
WHERE LOWER(description) LIKE '%award%' OR LOWER(description) LIKE '%won%';


-- Q60. Find the most frequent genre combination (e.g., "Action, Adventure, Sci-Fi").
-- Expected Output:
-- +-----------------------------+--------+
-- | genre_combination           | count  |
-- +-----------------------------+--------+
-- | Action, Adventure, Sci-Fi   | 18     |
-- +-----------------------------+--------+

SELECT genres, COUNT(*) AS count
FROM genres_table
GROUP BY genres
ORDER BY count DESC
LIMIT 1;


-- Q61. For each actor, show their highest-rated movie and its rating.
-- Expected Output:
-- +----------+-------------------+--------------+-------------+
-- | name_id  | name              | movie_name   | avg_rating  |
-- +----------+-------------------+--------------+-------------+
-- | n001     | Leonardo DiCaprio | Inception    | 8.8         |
-- +----------+-------------------+--------------+-------------+
WITH actor_movies AS (
  SELECT rm.name_id, n.name, m.movie_id, m.movie_name, r.avg_rating
  FROM role_mapping_table rm
  JOIN names_table n ON rm.name_id = n.name_id
  JOIN movies_table m ON rm.movie_id = m.movie_id
  JOIN ratings_table r ON m.movie_id = r.movie_id
  WHERE rm.category = 'actor'
),
ranked_movies AS (
  SELECT *, 
         RANK() OVER (PARTITION BY name_id ORDER BY avg_rating DESC) AS rnk
  FROM actor_movies
)
SELECT name_id, name, movie_name, avg_rating
FROM ranked_movies
WHERE rnk = 1;


-- Q62. Find the top 3 actors by total number of votes across all their movies.
-- Expected Output:
-- +----------+------------------+----------------+
-- | name_id  | name             | total_votes    |
-- +----------+------------------+----------------+
-- | n101     | Robert Downey Jr.| 11,000,000     |
-- +----------+------------------+----------------+
SELECT rm.name_id, n.name, SUM(r.num_of_votes) AS total_votes
FROM role_mapping_table rm
JOIN names_table n ON rm.name_id = n.name_id
JOIN ratings_table r ON rm.movie_id = r.movie_id
WHERE rm.category = 'actor'
GROUP BY rm.name_id, n.name
ORDER BY total_votes DESC
LIMIT 3;


-- Q63. Show the ranking of each movie within its release year based on average rating.
-- Expected Output:
-- +-----------+--------------+------+-------------+--------+
-- | movie_id  | movie_name   | year | avg_rating | rank   |
-- +-----------+--------------+------+-------------+--------+
-- | m001      | Inception    | 2010 | 8.8         | 1      |
-- +-----------+--------------+------+-------------+--------+
SELECT m.movie_id, m.movie_name, m.year, r.avg_rating,
       RANK() OVER (PARTITION BY m.year ORDER BY r.avg_rating DESC) AS rank_
FROM movies_table m
JOIN ratings_table r ON m.movie_id = r.movie_id;


-- Q64. For each actor, show the moving average of movie ratings over the years.
-- Expected Output:
-- +-----------+------------------+------+-------------+-------------------+
-- | name_id   | name             | year | movie_rating | moving_avg_rating |
-- +-----------+------------------+------+--------------+-------------------+
-- | n456      | Actor A          | 2015 | 7.2          | 7.2               |
-- | n456      | Actor A          | 2016 | 7.8          | 7.5               |
-- | n456      | Actor A          | 2017 | 8.0          | 7.67              |
-- +-----------+------------------+------+--------------+-------------------+

WITH actor_ratings AS (
  SELECT rm.name_id, n.name, m.year, r.avg_rating
  FROM role_mapping_table rm
  JOIN names_table n ON rm.name_id = n.name_id
  JOIN movies_table m ON rm.movie_id = m.movie_id
  JOIN ratings_table r ON m.movie_id = r.movie_id
  WHERE rm.category = 'actor'
),
actor_ratings_ranked AS (
  SELECT *, 
         ROW_NUMBER() OVER (PARTITION BY name_id ORDER BY year) AS row_num
  FROM actor_ratings
)
SELECT name_id, name, year, avg_rating AS movie_rating,
       ROUND(AVG(avg_rating) OVER (PARTITION BY name_id ORDER BY year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS moving_avg_rating
FROM actor_ratings_ranked;




-- Q65. Show pairs of actors who have co-acted in more than 3 movies together.
-- Expected Output:
-- +------------+------------------+------------+-------------------+ movie_count
-- | actor1_id  | actor1_name      | actor2_id  | actor2_name       | movie_count
-- +------------+------------------+------------+-------------------+--------------
-- | n001       | Brad Pitt        | n002       | George Clooney    | 5
-- +------------+------------------+------------+-------------------+--------------

SELECT a1.name_id AS actor1_id, n1.name AS actor1_name,
       a2.name_id AS actor2_id, n2.name AS actor2_name,
       COUNT(*) AS movie_count
FROM role_mapping_table a1
JOIN role_mapping_table a2 ON a1.movie_id = a2.movie_id 
                           AND a1.name_id < a2.name_id
                           AND a1.category = 'actor'
                           AND a2.category = 'actor'
JOIN names_table n1 ON a1.name_id = n1.name_id
JOIN names_table n2 ON a2.name_id = n2.name_id
GROUP BY actor1_id, actor2_id
HAVING movie_count > 3;


-- Q66. For each movie, show how many days it took to reach its peak vote count (assuming we had daily vote history).
-- [Hypothetical if a `vote_history` table existed]
-- Expected Output:
-- +-----------+--------------+------------------+
-- | movie_id  | movie_name   | days_to_peak     |
-- +-----------+--------------+------------------+
-- | m002      | Joker        | 12               |
-- +-----------+--------------+------------------+
SELECT vh.movie_id, m.movie_name,
       DATEDIFF(MAX(vh.vote_date), MIN(vh.vote_date)) AS days_to_peak
FROM vote_history vh
JOIN movies_table m ON vh.movie_id = m.movie_id
WHERE (vh.movie_id, vh.vote_count) IN (
  SELECT movie_id, MAX(vote_count)
  FROM vote_history
  GROUP BY movie_id
)
GROUP BY vh.movie_id, m.movie_name;


-- Q67. Show a running total of movies produced each year.
-- Expected Output:
-- +------+--------------+-------------------+
-- | year | movie_count  | cumulative_total  |
-- +------+--------------+-------------------+
-- | 2010 | 100          | 100               |
-- | 2011 | 110          | 210               |
-- +------+--------------+-------------------+

WITH yearly_counts AS (
  SELECT year, COUNT(*) AS movie_count
  FROM movies_table
  GROUP BY year
)
SELECT year, movie_count,
       SUM(movie_count) OVER (ORDER BY year) AS cumulative_total
FROM yearly_counts;



-- Q68. For each genre, show the movie with the largest increase in rating compared to the previous year’s top movie.
-- Expected Output:
-- +--------+--------------+--------+--------------+
-- | genre  | movie_name   | year   | rating_diff  |
-- +--------+--------------+--------+--------------+
-- | Drama  | Movie X      | 2020   | 1.3          |
-- +--------+--------------+--------+--------------+

WITH top_movies_by_year AS (
    SELECT
        g.genres AS genre,
        m.movie_name,
        m.year,
        r.avg_rating,
        RANK() OVER (PARTITION BY g.genres, m.year ORDER BY r.avg_rating DESC) AS movie_rank  -- Renamed 'rank' to 'movie_rank'
    FROM
        movies_table m
    JOIN
        genres_table g ON m.movie_id = g.movie_id
    JOIN
        ratings_table r ON m.movie_id = r.movie_id
    WHERE
        g.genres IS NOT NULL
),
top_movies_with_previous_year AS (
    SELECT
        tm1.genre,
        tm1.movie_name,
        tm1.year,
        tm1.avg_rating AS current_year_rating,
        tm2.avg_rating AS previous_year_rating,
        (tm1.avg_rating - tm2.avg_rating) AS rating_diff
    FROM
        top_movies_by_year tm1
    JOIN
        top_movies_by_year tm2 ON tm1.genre = tm2.genre AND tm1.year = tm2.year + 1
    WHERE
        tm1.movie_rank = 1 AND tm2.movie_rank = 1
)
SELECT
    genre,
    movie_name,
    year,
    rating_diff
FROM
    top_movies_with_previous_year
ORDER BY
    genre, rating_diff DESC;




-- Q69. Identify “one-hit wonders” — directors with only one movie in the database, but avg_rating >= 8.5.
-- Expected Output:
-- +-----------+-------------------+--------------+-------------+
-- | name_id   | name              | movie_name   | avg_rating  |
-- +-----------+-------------------+--------------+-------------+
-- | n555      | New Director      | Masterpiece  | 8.9         |
-- +-----------+-------------------+--------------+-------------+
WITH director_movies AS (
    SELECT 
        rm.name_id,
        n.name,
        m.movie_name,
        r.avg_rating,
        COUNT(*) OVER (PARTITION BY rm.name_id) AS movie_count
    FROM 
        role_mapping_table rm
    JOIN 
        movies_table m ON rm.movie_id = m.movie_id
    JOIN 
        ratings_table r ON rm.movie_id = r.movie_id
    JOIN 
        names_table n ON rm.name_id = n.name_id
    WHERE 
        rm.category = 'director'
)
SELECT 
    dm.name_id,
    dm.name,
    dm.movie_name,
    dm.avg_rating
FROM 
    director_movies dm
WHERE 
    dm.movie_count = 1
    AND dm.avg_rating >= 8.5
ORDER BY 
    dm.avg_rating DESC;


-- Q70. List all trilogies or franchises (same movie name prefix) with consistent rating growth.
-- [Assuming name patterns like "Iron Man 1", "Iron Man 2", etc.]
-- Expected Output:
-- +--------------+-------------+--------------+--------------+
-- | franchise    | part        | movie_name   | avg_rating   |
-- +--------------+-------------+--------------+--------------+
-- | Iron Man     | 1           | Iron Man     | 7.2          |
-- | Iron Man     | 2           | Iron Man 2   | 7.4          |
-- | Iron Man     | 3           | Iron Man 3   | 7.6          |
-- +--------------+-------------+--------------+--------------+

WITH franchise_ratings AS (
    SELECT 
        m.movie_name,
        r.avg_rating,
        SUBSTRING_INDEX(m.movie_name, ' ', 1) AS franchise,
        CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(m.movie_name, ' ', -1), ' ', 1) AS UNSIGNED) AS part
    FROM 
        movies_table m
    JOIN 
        ratings_table r ON m.movie_id = r.movie_id
    WHERE 
        m.movie_name LIKE '% %'  -- Ensures the movie name contains a space (for franchise and part)
),
rating_growth AS (
    SELECT 
        franchise,
        part,
        movie_name,
        avg_rating,
        LEAD(avg_rating) OVER (PARTITION BY franchise ORDER BY part) AS next_avg_rating
    FROM 
        franchise_ratings
)
SELECT 
    franchise,
    part,
    movie_name,
    avg_rating
FROM 
    rating_growth
WHERE 
    next_avg_rating > avg_rating
ORDER BY 
    franchise, part;