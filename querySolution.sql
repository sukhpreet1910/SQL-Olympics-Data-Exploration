SELECT count(*)
from olympic_history

SELECT column_name
FROM information_schema.columns
WHERE table_name = 'olympic_history';

-- 1. How many olympics games have been held?

SELECT count(distinct games) as Game_Count
from olympic_history


-- 2. List down all Olympics games held so far.

SELECT year, season, city  
from olympic_history
order by year

-- 3. Mention the total no of nations who participated in each olympics game?

SELECT 
    games, count(distinct noc) as Nations_Participated 
from 
    olympic_history
GROUP BY 
    games
order by 
    count(DISTINCT noc)

-- 4. Which year saw the highest and lowest no of countries participating in olympics?


SELECT max(Nations_Participated) as Max_Participation, min(Nations_Participated) as Min_Participation
from 
    (SELECT games, count(distinct noc) as Nations_Participated 
    from olympic_history
    GROUP BY games
    order by count(DISTINCT noc)) sub

-- 5. Which nation has participated in all of the olympic games?

with countries AS
(
    SELECT games, region
    from olympic_history h
    join region r
    on h.noc = r.noc
    group by games, region 
    ORDER BY games 
),

country_count AS
(
    select count(games) as Total_Games, region as country
    from countries 
    group by region
    order by 1    
),

max_count AS
(
    SELECT count(distinct games) as Game_Count
    from olympic_history
)

SELECT country_count.country, Total_Games
from country_count
join max_count 
on country_count.Total_Games = max_count.Game_Count


-- 6.Identify the sport which was played in all summer olympics.

with summer_games AS
(
    SELECT count(DISTINCT games) as total_summer_games
    from olympic_history
    where season = 'Summer'
),

games_played_in_summer AS
(
    select DISTINCT games, sport
    from olympic_history
    where season = 'Summer'
),

games_count AS
(
    SELECT count(games) as games_played, sport 
    from games_played_in_summer
    GROUP BY sport
    order by count(games)
)

SELECT sport, games_played, total_summer_games 
from games_count
join summer_games
on games_count.games_played = summer_games.total_summer_games


-- 7. Which Sports were just played only once in the olympics?

with game_count AS
(
    SELECT sport, count(distinct games) as no_of_games
    from olympic_history
    group by sport
    order by 2
)

select  *
from game_count
where no_of_games = 1


-- 8. Fetch the total no of sports played in each olympic games.

select games, count(distinct sport )
from olympic_history
group by games
order by 2 desc


with t1 AS
(
    select distinct games, sport 
    from olympic_history
)

select games, count(1) 
from t1
group by games
order by 2


-- 9. Fetch details of the oldest athletes to win a gold medal.
with gold as 
(
    SELECT *
    from olympic_history
    where medal = 'Gold' and age <> 'NA'
    order by age desc
),
rank as 
(
    select *, rank() over(order by age desc) as rank
    from gold 
)

SELECT * 
from rank
where rank = 1


-- 10. Find the Ratio of male and female athletes participated in all olympic games.

with ratio as 
(
    SELECT sex, count(sex) count
    from olympic_history
    group by sex
),

/*rank as 
(
    select *, row_number() over(order by count) as rn
    from ratio
),*/

min_count as 
(
    SELECT min(count) as min 
    from ratio
    --where rn = 1
),

max_count as
(
    SELECT max(count) as max  
    from ratio 
   -- where rn = 2
)


select concat('1 : ', round(max_count.max::decimal/min_count.min, 2)) as ratio
from max_count, min_count
