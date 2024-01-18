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

select concat('1 : ', round(max_count.max::DECIMAL/min_count.min, 2)) as ratio
from max_count, min_count


-- 11. Fetch the top 5 athletes who have won the most gold medals.
with cn as 
(
    select team, name, count(medal) as count
    from olympic_history
    where medal = "Gold"
    group by name, team
    ORDER BY 3 desc
),
rn as
(
    select *, dense_rank() over(order by count desc) as rank
    from cn
)

select name, team, count
from rn 
where rank <= 5


-- 12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).

with cn as 
(
    select team, name, count(medal) as count
    from olympic_history
    where medal in ('Gold', 'Silver', 'Bronze')
    group by name, team
    ORDER BY 3 desc
),
rn as
(
    select *, dense_rank() over(order by count desc) as rank
    from cn
)

select name, team, count
from rn 
where rank <= 5


-- 13. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.

-- Using Join, CTE and Rank() window function
with cn as 
(
    select region, count(medal) as count
    from olympic_history o
    join region r
    on o.noc = r.noc
    where medal in ('Gold', 'Silver', 'Bronze')
    group by region
),

rn as
(
    select *, rank() over(order by count desc) as rank
    from cn
)

select * 
from rn
where rank <= 5


-- Using join and Limit Clause

/*select 
    region, count(medal) as count
from 
    olympic_history o
join 
    region r
on 
    o.noc = r.noc
where 
    medal in ('Gold', 'Silver', 'Bronze')
group by region
order by 2 desc
limit 5*/







-- Queries Using CROSSTAB functino 
CREATE EXTENSION TABLEFUNC;


-- 14. List down total gold, silver and broze medals won by each country.

--  row level count

select region as country, medal, count(medal)
from olympic_history o
join region r
on o.noc = r.noc 
where medal <> 'NA'
group by region, medal
order by 1

-- Column Level Count 

with g as
(
select region, count(medal) as Gold
from olympic_history o
join region r 
on o.noc = r.noc
where medal = 'Gold'
group by region
),

silver as 
(
select region, count(medal) as Silver
from olympic_history o
join region r 
on o.noc = r.noc
where medal = 'Silver'
group by region
),

bronze as
(
select region, count(medal) as Bronze
from olympic_history o
join region r 
on o.noc = r.noc
where medal = 'Bronze'
group by region
)

select g.*, silver.Silver, bronze.Bronze
from g
join silver 
on g.region = silver.region
join bronze
on g.region = bronze.region
order by 2 desc, 3 desc, 4 desc

-- Column Level Count using CROSSTAB()


select country, 
       coalesce(gold, 0) as gold,
       coalesce(silver, 0) as silver,
       coalesce(bronze, 0) as bronze
from crosstab
(
    'select region as country, medal, count(medal)
    from olympic_history o
    join region r
    on o.noc = r.noc 
    where medal <> ''NA''
    group by region, medal
    order by 1',
    'values (''Bronze''), (''Gold''), (''Silver'')'
)
as result (country varchar, bronze bigint, gold bigint, silver bigint)
order by 2 desc, 3 desc, 4 desc 


-- 15. List down total gold, silver and broze medals won by each country corresponding to each olympic games.


select games, 
       coalesce(gold, 0) as gold,
       coalesce(silver, 0) as silver,
       coalesce(bronze, 0) as bronze
from crosstab(
    'select concat(games, '' - '', region) as games, medal, count(medal)
    from olympic_history o
    join region r
    on o.noc = r.noc
    where medal <> ''NA''
    group by region, games, medal
    order by games, medal',
    'values (''Bronze''), (''Gold''), (''Silver'')'
)
as result (games text, bronze bigint, gold bigint, silver bigint)


-- 16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.
 

 with cte as
 (
 select 
    substring(games_country, 1, position(' - ' in games_country)) as Games,
    substring(games_country, position(' - ' in games_country) + 3) as country,
    coalesce(gold, 0) as gold,
    coalesce(silver, 0) as silver,
    coalesce(bronze, 0) as bronze
 from crosstab
 (
    'select concat(games, '' - '', region) as games_country, medal, count(medal)
    from olympic_history o
    join region r
    on o.noc = r.noc
    where medal <> ''NA''
    group by games, region, medal
    order by games',
    'values (''Bronze''), (''Gold''), (''Silver'')'
 )
 as result (games_country text, bronze bigint, gold bigint, silver bigint)
 )

 select 
    distinct games, 
    concat(
        first_value(country) over(partition by games order by gold desc) , ' - ',
        first_value(gold) over(partition by games order by gold desc)
    ) as Gold,

    concat(
        first_value(country) over(partition by games order by silver desc) , ' - ',
        first_value(silver) over(partition by games order by silver desc)
    ) as Silver,

    concat(
        first_value(country) over(partition by games order by bronze desc) , ' - ',
        first_value(bronze) over(partition by games order by bronze desc)
    ) as Bronze

 from cte 
 order  by games




-- 17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.

with part as
(
select 
    substring(games_country, 1, position(' - ' in games_country) - 1) as games,
    substring(games_country, position(' - ' in games_country) + 3) as country,
    coalesce(gold, 0) as gold,
    coalesce(silver, 0) as silver,
    coalesce(bronze, 0) as bronze

from crosstab
(
    'select 
        concat(games, '' - '', region) as games_country,
        medal, 
        count(medal)
    from olympic_history o
    join region r
    on o.noc = r.noc
    where medal <> ''NA'' a
    group by games, region, medal
    order by games',
    'values (''Bronze''), (''Gold''), (''Silver'')'
)
as result(games_country text, bronze bigint, gold bigint, silver bigint)
),

total as
(
    select games, region as country, count(1) as total_medals
    from olympic_history o
    join region r 
    on o.noc = r.noc
    where medal <> 'NA'
    group by games, region
    order by 1, 2
)


select distinct p.games,
    concat(
        first_value(p.country) over(partition by p.games order by gold desc),
        ' - ',
        first_value(p.gold) over(partition by p.games order by gold desc)
        ) as gold,

    concat(
        first_value(p.country) over(partition by p.games order by silver desc),
        ' - ',
        first_value(silver) over(partition by p.games order by silver desc)
        ) as silver,

    concat(
        first_value(p.country) over(partition by p.games order by bronze desc),
        ' - ',
        first_value(bronze) over(partition by p.games order by bronze desc)
        ) as bronze
    ,concat(
        first_value(t.country) over(partition by t.games order by t.total_medals desc nulls last),
        ' - ',
        first_value(t.total_medals) over(partition by t.games order by t.total_medals desc nulls last)
    ) as max
from part p
join total t
on  p.country = t.country and  p.games = t.games
where p.gold = 
order by games;



-- 18. Which countries have never won gold medal but have won silver/bronze medals?

select *
from
(
    select 
        country,
        coalesce(gold, 0) as gold,
        coalesce(silver, 0) as silver,
        coalesce(bronze, 0) as bronze


    from crosstab(
        'select region as country, medal, count(1)
        from olympic_history o
        join region r
        on o.noc = r.noc 
        where medal <> ''NA''
        group by region, medal
        order by region, medal',
        'values (''Bronze''), (''Gold''), (''Silver'')'
    )
    as result(country varchar, bronze bigint, gold bigint, silver bigint)
)z
where gold = 0 and (silver > 0 or bronze > 0)
order by gold desc nulls last, silver desc nulls last, bronze desc nulls last;















-- 19. In which Sport/event, India has won highest medals.

with count as 
(
    select region as country, sport, count(medal) as medals
    from olympic_history o
    join region r
    on o.noc = r.noc
    where medal <> 'NA' and region = 'India'
    GROUP BY region, sport
),

rank as
(
    select *, dense_rank() over(order by medals desc) as Rank
    from count
)

select country, sport, medals
from rank 
where rank = 1


-- or 


select region as country, sport, count(medal) as medals
from olympic_history o
join region r
on o.noc = r.noc
where medal <> 'NA' and region = 'India'
GROUP BY region, sport
order by 3 DESC
limit 1


-- 20. Break down all olympic games where india won medal for Hockey and how many medals in each olympic games.

SELECT team, sport, games, count(medal) as medals
from olympic_history o
where medal <> 'NA' and team = 'India' and sport = 'Hockey'
group by team, sport, games
order by games