create database netflix1;
 use netflix1;
 drop table if exists netflix1;
 create table netflix1(
 title varchar(100),
 type varchar(6),
 genres varchar(34),
 releaseYear varchar(12),
 imdbId varchar(9),
 imdbAverageRating decimal,
 imdbNumVotes int,
 availableCountries varchar(522)
 );
 
 select * from netflix1;
 
--  Retrieve all records where the type is "movie".

select * from netflix1
where type="Movie";


-- Find all titles released in the year 2000.

SELECT title 
FROM netflix1 
WHERE releaseYear = 2000;

-- List distinct genres available in the dataset.

with genre as(
select indi_genre from netflix1,
JSON_TABLE(CONCAT('["', REPLACE(genres, ',', '","'), '"]'),
           "$[*]" COLUMNS (indi_genre VARCHAR(255) PATH "$")) AS jt
)

select distinct(indi_genre) as gen from genre
order by gen desc;

-- Count the number of movies and TV shows separately.

Select type,count(*) from netflix1
group by 1;

-- Display the first 10 titles alphabetically.

select title from netflix1
order by title asc
limit 10;
 
-- Find titles available in a specific country (e.g., "US") 
SELECT title 
FROM netflix1
WHERE availableCountries LIKE '%US%' COLLATE utf8mb4_general_ci;

-- Retrieve titles with how's IMDb ratings below 5.

Select 
title,imdbAverageRating from netflix1
where imdbAverageRating <5
order by imdbAverageRating desc;

-- Show the total number of records in the dataset.

Select 
count(*) from netflix1;

-- List titles released after 2010.
SELECT title, releaseYear
FROM netflix1
WHERE CAST(releaseYear AS UNSIGNED) > 2010
ORDER BY releaseYear DESC;

-- Select records where imdbNumVotes is greater than 1 million

select
* from netflix1
where imdbNumVotes > 1000000;

-- Find the average IMDb rating for movies and TV shows separately.

SELECT 
    AVG(imdbAverageRating), type
FROM
    netflix1
GROUP BY type;

-- Retrieve the top 5 highest-rated movies based on IMDb rating.

SELECT 
    *
FROM
    netflix1
WHERE
    type = 'Movie'
ORDER BY imdbAverageRating DESC
LIMIT 5;

-- List the genres with the most associated titles.

With genre as(
select title, ind_genre from netflix1,
json_table(concat('["', replace(genres,",",'","' ), '"]'),
"$[*]" columns (ind_genre varchar(255) path "$")) as jt
)

select 
distinct ind_genre, count(title) as title_count
from genre
group by 1
order by title_count desc;

-- Identify movies with one genre listed.
WITH genre AS (
    SELECT 
        title, 
        type, 
        ind_genre
    FROM netflix1,
    JSON_TABLE(
        CONCAT('["', REPLACE(genres, ",", '","'), '"]'),
        "$[*]" COLUMNS (ind_genre VARCHAR(255) PATH "$")
    ) AS jt
)
SELECT 
    ind_genre, 
    COUNT(ind_genre) AS genre_count
FROM genre
WHERE type = "Movie"
GROUP BY 1
HAVING genre_count = 1;

-- Find the oldest and newest titles in the dataset.

(SELECT title, releaseYear
FROM netflix1
ORDER BY releaseYear ASC
LIMIT 1)
UNION ALL
(SELECT title, releaseYear
FROM netflix1
ORDER BY releaseYear DESC
LIMIT 1);

-- Display titles that are available in at least 10 countries.

with country as(
select title, indi_country from netflix1,
json_table(concat('["',Replace(availableCountries,",",'","'),'"]'),
"$[*]" columns(indi_country varchar(255) path "$")) as jt
)

select
title,count(distinct indi_country) as country_count  from country
group by 1
having count(*) >=10
order by country_count desc;


-- Group titles by release year and count them.

SELECT 
    releaseYear, 
    COUNT(title) AS title_count
FROM netflix1
GROUP BY releaseYear;

-- Retrieve all records where the title starts with the letter "A".

select
* from netflix1
where title regexp '^[A]';

-- List movies with an IMDb rating higher than the average rating of all titles.

SELECT 
    *
FROM
    netflix1
WHERE
    imdbAverageRating > (SELECT 
            AVG(imdbAverageRating)
        FROM
            netflix1
        WHERE
            imdbAverageRating IS NOT NULL);
            
-- Rank movies by IMDb rating and retrieve the top 10.

WITH imdb_rk AS (
    SELECT 
        title, 
        type, 
        imdbAverageRating,
        RANK() OVER (ORDER BY imdbAverageRating DESC) AS rk
    FROM netflix1
    WHERE type = 'Movie'
)
SELECT 
    title, 
    imdbAverageRating, 
    rk
FROM imdb_rk
ORDER BY rk
limit 10;

-- Identify countries that have access to the most titles.

WITH country AS (
    SELECT 
        title, 
        indi_country 
    FROM netflix1,
    JSON_TABLE(
        CONCAT('["', REPLACE(availableCountries, ",", '","'), '"]'),
        "$[*]" COLUMNS (indi_country VARCHAR(255) PATH "$")
    ) AS jt
)
SELECT 
    indi_country, 
    COUNT(DISTINCT title) AS title_count
FROM country
GROUP BY indi_country
ORDER BY title_count DESC;

-- Find the most common genre for movies.

WITH genre AS (
    SELECT 
        indi_genre 
    FROM netflix1,
    JSON_TABLE(
        CONCAT('["', REPLACE(genres, ",", '","'), '"]'),
        "$[*]" COLUMNS (indi_genre VARCHAR(255) PATH "$")
    ) AS jt
    WHERE type = 'Movie'
)
SELECT 
    indi_genre, 
    COUNT(*) AS genre_count
FROM genre
GROUP BY 1
ORDER BY genre_count DESC
LIMIT 1;


-- Create a pivot table showing average IMDb rating by release year.

SELECT 
    releaseYear,
    AVG(CASE WHEN type = 'Movie' THEN imdbAverageRating END) AS Movie_Rating
FROM netflix1
GROUP BY releaseYear
ORDER BY releaseYear;

-- Identify titles available in both "US" and "Canada".

WITH country_split AS (
    SELECT 
        title, 
        indi_country
    FROM netflix1,
    JSON_TABLE(
        CONCAT('["', REPLACE(availableCountries, ",", '","'), '"]'),
        "$[*]" COLUMNS (indi_country VARCHAR(255) PATH "$")
    ) AS jt
)
SELECT 
    title, 
    indi_country
FROM country_split
where indi_country in ("US","CA");

-- Find titles with the lowest IMDb votes and ratings.

(
    SELECT 
        title, 
        imdbAverageRating AS imdb_value, 
        'Rating' AS type
    FROM netflix1
    ORDER BY imdbAverageRating ASC
    LIMIT 1
)
UNION ALL
(
    SELECT 
        title, 
        imdbNumVotes AS imdb_value, 
        'Votes' AS type
    FROM netflix1
    ORDER BY imdbNumVotes ASC
    LIMIT 1
);

-- Retrieve the top 5 most-voted titles for each genre.

WITH s_genre AS (
    SELECT 
        title, 
        imdbNumVotes, 
        indi_genre 
    FROM netflix1,
    JSON_TABLE(
        CONCAT('["', REPLACE(genres, ",", '","'), '"]'),
        "$[*]" COLUMNS (indi_genre VARCHAR(255) PATH "$")
    ) AS jt
),
ranked_titles AS (
    SELECT 
        title, 
        indi_genre, 
        imdbNumVotes, 
        RANK() OVER (PARTITION BY indi_genre ORDER BY imdbNumVotes DESC) AS rank_by_votes
    FROM s_genre
)
SELECT 
    title, 
    indi_genre, 
    imdbNumVotes
FROM ranked_titles
WHERE rank_by_votes <= 5
ORDER BY indi_genre, rank_by_votes;

-- Determine the correlation between imdbNumVotes and imdbAverageRating.

SELECT 
    (COUNT(*) * SUM(imdbNumVotes * imdbAverageRating) - SUM(imdbNumVotes) * SUM(imdbAverageRating)) /
    (SQRT(
        (COUNT(*) * SUM(POW(imdbNumVotes, 2)) - POW(SUM(imdbNumVotes), 2)) *
        (COUNT(*) * SUM(POW(imdbAverageRating, 2)) - POW(SUM(imdbAverageRating), 2))
    )) AS correlation
FROM netflix1
WHERE imdbNumVotes IS NOT NULL AND imdbAverageRating IS NOT NULL;

 