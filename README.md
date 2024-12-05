# Netflix Movies & Tv-shows Data Analysis Using SQL
![Netflix Logo](https://raw.githubusercontent.com/adnanalam8360/Netflix/refs/heads/main/Netflix-logo.webp)

## Overview
This project focuses on analyzing a comprehensive dataset of Netflix movies and TV shows using SQL. The analysis covers various aspects such as title metadata, genres, IMDb ratings, votes, and availability across different countries. It demonstrates how SQL can be leveraged to extract meaningful insights from structured data, making it a valuable resource for understanding trends, patterns, and audience preferences on Netflix.

### Database Design and Querying:
Setting up a database (netflix1) to organize and store data efficiently.
Using advanced SQL queries to retrieve and manipulate data.

### Basic Retrieval:

Retrieve all records where the type is "Movie."

select * from netflix1
where type="Movie";

Find titles released in a specific year (e.g., 2000).
Genre Exploration:

SELECT title 
FROM netflix1 
WHERE releaseYear = 2000;

List all distinct genres available in the dataset.

with genre as(
select indi_genre from netflix1,
JSON_TABLE(CONCAT('["', REPLACE(genres, ',', '","'), '"]'),
           "$[*]" COLUMNS (indi_genre VARCHAR(255) PATH "$")) AS jt
)

select distinct(indi_genre) as gen from genre
order by gen desc;

Count the number of movies and TV shows separately.

Select type,count(*) from netflix1
group by 1;

Display the first 10 titles alphabetically.

select title from netflix1
order by title asc
limit 10;


Retrieve all records where the title starts with a specific letter (e.g., "A").

select
* from netflix1
where title regexp '^[A]';


### Country-Based Queries:

Find titles available in a specific country (e.g., "US").

SELECT title 
FROM netflix1
WHERE availableCountries LIKE '%US%' COLLATE utf8mb4_general_ci;


Identify titles available in both "US" and "Canada."

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
where indi_country in ("US","CA")
Having Count(Distinct indi_country) = 2

Display titles available in at least 10 countries.

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

Identify countries with access to the most titles.

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

### IMDb Rating and Votes Analysis:

Retrieve titles with IMDb ratings below 5.

Select 
title,imdbAverageRating from netflix1
where imdbAverageRating <5
order by imdbAverageRating desc;

List movies with an IMDb rating higher than the average rating of all titles.

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

Find titles with the lowest IMDb votes and ratings.

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

Retrieve the top 5 highest-rated movies.

SELECT 
    *
FROM
    netflix1
WHERE
    type = 'Movie'
ORDER BY imdbAverageRating DESC
LIMIT 5;

Retrieve the top 5 most-voted titles for each genre.

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

Determine the correlation between IMDb votes and ratings.

SELECT 
    (COUNT(*) * SUM(imdbNumVotes * imdbAverageRating) - SUM(imdbNumVotes) * SUM(imdbAverageRating)) /
    (SQRT(
        (COUNT(*) * SUM(POW(imdbNumVotes, 2)) - POW(SUM(imdbNumVotes), 2)) *
        (COUNT(*) * SUM(POW(imdbAverageRating, 2)) - POW(SUM(imdbAverageRating), 2))
    )) AS correlation
FROM netflix1
WHERE imdbNumVotes IS NOT NULL AND imdbAverageRating IS NOT NULL;


### Year-Based Queries:

List titles released after 2010.

SELECT title, releaseYear
FROM netflix1
WHERE CAST(releaseYear AS UNSIGNED) > 2010
ORDER BY releaseYear DESC;

Group titles by release year and count them.

SELECT 
    releaseYear, 
    COUNT(title) AS title_count
FROM netflix1
GROUP BY releaseYear;

Find the oldest and newest titles in the dataset.

(SELECT title, releaseYear
FROM netflix1
ORDER BY releaseYear ASC
LIMIT 1)
UNION ALL
(SELECT title, releaseYear
FROM netflix1
ORDER BY releaseYear DESC
LIMIT 1);


### Pivot and Rankings:

Create a pivot table showing the average IMDb rating by release year.

SELECT 
    releaseYear,
    AVG(CASE WHEN type = 'Movie' THEN imdbAverageRating END) AS Movie_Rating
FROM netflix1
GROUP BY releaseYear
ORDER BY releaseYear;

Rank movies by IMDb ratings and retrieve the top 10.

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

### Advanced Genre Analysis:

Identify movies associated with only one genre.

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

Extract and rank individual genres for movies using JSON data.

WITH s_genre AS (
    SELECT 
        title, 
        indi_genre 
    FROM netflix1,
    JSON_TABLE(
        CONCAT('["', REPLACE(genres, ",", '","'), '"]'),
        "$[*]" COLUMNS (indi_genre VARCHAR(255) PATH "$")
    ) AS jt
)
SELECT 
    indi_genre, 
    COUNT(title) AS genre_count
FROM s_genre
GROUP BY indi_genre
ORDER BY genre_count DESC;

# Summary
This project combines technical SQL skills with analytical thinking, providing a structured approach to understanding Netflix's extensive content library. It is an excellent demonstration of the use of SQL for real-world data analysis scenarios.


