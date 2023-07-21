--inspecting data
select *
from weather;

--practicing date extraction
select extract('month' from date_weather) as month
from weather
limit 5;

select extract('day' from date_weather) as days
from weather;

select date_weather
from weather;
-- no time stamps here, just dates in sequential order starting at 1948-01-01

-- Practice Questions:

-- 1. Select all rows from Dec 1st, 2000 to Dec 15th 2000 (inclusive)
select *
from weather
where date_weather >= '2000-12-01' and date_weather <= '2000-12-15';

-- My result set looks good, except there are two of every row, maybe when I installed I somehow appended duplicates of all rows for this database?

-- row count = 51096
select count(*)
from weather;

-- count duplicates
select date_weather, count(*)
from weather
group by date_weather
having count(*) > 1;
-- count = 2 for all visible rows, 25548 total rows => I do in fact have duplicates of all rows in this data base
-- 
select count(*)
from(
	select date_weather
	from weather
	group by date_weather
	having count(*) > 1
) as duplicate_count; -- returns 25548

-- Working on removing the duplicate rows from this table, no need to backup as the data is already backed up on Github

-- Learning a bit about ctid system column
select ctid, *
from weather
limit 20; -- ctid column contains 2 len tuples. First value is the 'block number' second is the index of the tuple within that block

-- using common table expression with window function to group by identical rows, then using assigned row_num to delete duplicate rows. 
with dupes as (
	select ctid, row_number() over(
		partition by date_weather, inches_rain, temp_max, temp_min, did_rain
		order by ctid
	) as row_num
	from weather
)
delete from weather
where ctid in (
	select ctid from dupes where row_num > 1);
	
-- RETURNED MESSAGE: 

--DELETE 25548
--Query returned successfully in 139 msec.

--------------------------------------------

-- Practicing row_number() to build intuition
select *, row_number() over()
from weather;

select *, row_number() -- requires an over clause.. creates error
from weather;

select *, row_number() over() as row_num
from weather;

-- Back to the question set: 

-- 2. Get the average maximum temperature for every year from the year 2000 onward. Order the results by year (ascending)

select extract('year' from date_weather) as year, avg(temp_max)
from weather
group by date_weather
having date_weather >= '2000-01-01'
order by date_weather;


-- trying again
with year_view as(
	select extract('year' from date_weather) as year, *
	from weather)
select year, avg(temp_max)
from year_view
group by year
having year >= '2000'
order by year;

-- Good, this is the correct result set. 

-- A more efficient alternative: 
WITH year_view AS (
    SELECT EXTRACT('year' FROM date_weather) AS year, temp_max
    FROM weather
    WHERE date_weather >= '2000-01-01'
)
SELECT year, AVG(temp_max)
FROM year_view
GROUP BY year
ORDER BY year;

-- the result set here is the same, but we filter within the CTE, demanding less calculation be made, and memory used overall, thus improving efficiency

-- 3. Get the standard deviation of the maximum temperature per year, from 2000 onward. Order by year (ascending)

WITH year_view AS (
    SELECT EXTRACT('year' FROM date_weather) AS year, temp_max
    FROM weather
    WHERE date_weather >= '2000-01-01'
)
SELECT year, STDDEV(temp_max)
FROM year_view
GROUP BY year
ORDER BY year;

-- Looks good, easy reuse of previous query form. Odd that pgAdmin 4 doesn't highlight STDDEV() as a known term. 

--4. What are the 10 hottest days on record? Take hottest to mean 'highest maximum temperature'.

select *
from weather
order by temp_max desc 
limit 10;
-- good. 


-- 5. In 2016, what fraction of days did it rain?

-- started writing this, but realized my solution was likely too complicated to be good. Useing chatGPT for direction..
-- my plan was to make several CTEs than do a basic mathematical operation on two count() operations
with year_2016 as (
	select extract('year' from date_weather) as year, did_rain
	from weather
	where date_weather >= '2016-01-01' and date_weather <= '2016-12-31'
)
select count(did_rain)
from year_2016
where did_rain = 'true'


-- ChatGPT's answer: 
SELECT 
    COUNT(*) FILTER (WHERE did_rain = true)::decimal / COUNT(*) AS rain_fraction
FROM 
    weather
WHERE 
    EXTRACT('YEAR' FROM date_weather) = 2016;

-- result is correct. About 47% of days we see rain

-- testing answer without casting
SELECT 
    (COUNT(*) FILTER (WHERE did_rain = true) / COUNT(*)) AS rain_fraction
FROM 
    weather
WHERE 
    EXTRACT('YEAR' FROM date_weather) = 2016;
-- rounds to 0, so casting to decimal is necessary for fraction results, which is atypical for other languages I have used 


-- 6. What is the 75th percentile for the amount of rain that fell on a day where there was some rain in 2016?

select date_weather, inches_rain, did_rain
from weather
where extract('year' from date_weather) = 2016 and did_rain = 'true'
order by inches_rain;

-- total rows = 172
-- to get 75th percentile, we need the row number that = 75th percentile delimeter == .75*172 = 129
select .75*172 as result;

-- 129th row == .33, which is the correct answer. 

-- There are other ways to answer this within postgreSQL.. lets see what they look like. 
SELECT 
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY inches_rain) AS rain_75th_percentile
FROM 
    weather
WHERE 
    EXTRACT('YEAR' FROM date_weather) = 2016 AND
    did_rain = true;

-- 7. What is the 75th percentile for the amount of rain that fell on any day in 2016?
SELECT PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY inches_rain) AS rain_75th_percentile
FROM weather
WHERE EXTRACT('YEAR' FROM date_weather) = 2016;
-- Outputs 0.150000... which is correct

-- curious to see if I can drop the WITHIN GROUP statement, as there is only 1 group here
-- ChatGPT says that the ORDER BY clause only works to change the order of the returned results, 
--  and thus is not effective for reordering a single group for ordered-set aggregate functions 
SELECT PERCENTILE_CONT(0.75) (order by inches_rain) AS rain_75th_percentile
FROM weather
WHERE EXTRACT('YEAR' FROM date_weather) = 2016; -- syntax is unsupported... 

-- 8. Get the 10 years with the hottest average maximum temperature in July. Order from hottest to coolest
select *
from weather
where extract('month' from date_weather) = '07'
order by temp_max desc
limit 10;

-- Decent first try, but I missed on doing the average of days in July. I got the hottest 10 days in july across all years
select extract('year' from date_weather), avg(temp_max) as avgTmpMax
from weather
where extract('month' from date_weather) = '07'
group by extract('year' from date_weather)
order by avgTmpMax desc
limit 10;

-- ChatGPTs answer... alias from select in group by.. but its functioning. 
SELECT 
    EXTRACT('year' FROM date_weather) AS year, 
    AVG(temp_max) AS avg_max_temp
FROM 
    weather
WHERE 
    EXTRACT('month' FROM date_weather) = 7
GROUP BY 
    year
ORDER BY 
    avg_max_temp DESC
LIMIT 10;

-- After fixing up my code, I recognize that a complicated query like this one does in fact look pretty strange without the standard formatting
--  Thus I want to start using better formatting where needed. 

-- 9. Get the 10 years with the coldest average minimum temperature in December. Order from coolest to hottest
SELECT 
    EXTRACT('year' FROM date_weather) AS year, 
    AVG(temp_min) AS avg_min_temp
FROM 
    weather
WHERE 
    EXTRACT('month' FROM date_weather) = 12
GROUP BY 
    year
ORDER BY 
    avg_min_temp
LIMIT 10;

-- Correct. Simple to recycle the code now. 

-- 10. Repeat the last question, but round the temperatures to 3 decimal places

SELECT 
    EXTRACT('year' FROM date_weather) AS year, 
    ROUND(AVG(temp_min)::decimal, 3) AS avg_min_temp
FROM 
    weather
WHERE 
    EXTRACT('month' FROM date_weather) = 12
GROUP BY 
    year
ORDER BY 
    avg_min_temp
LIMIT 10;
-- ROUND() doesn't accept double precison ints, and needs casting of the aggregate func to work properly. Error message made it easy to solve. 
-- correct. Though my method of solving is different from how kiwidamian solved... they state REAL type is not a subclass of NUMERIC in postgreSQL

SELECT 
    EXTRACT('year' FROM date_weather) AS year, 
    ROUND(AVG(temp_min::numeric), 3) AS avg_min_temp
FROM 
    weather
WHERE 
    EXTRACT('month' FROM date_weather) = 12
GROUP BY 
    year
ORDER BY 
    avg_min_temp
LIMIT 10;
-- This also works. Evidently, I could afford to know a bit more about types in postgreSQL, as this type based behavior is a bit strange on the surface


-- 11. Given the results of the previous queries, 
-- 	   would it be fair to use this data to claim that 2015 had the "hottest July on record"? Why or why not?

-- 2015 does have the hottest average July on record here, but not the hottest DAY in July on record, which instead belongs to 2009. 
-- So yes it is fair in the average case, but not if we want to get into hottest specific days. 


-- 12. Give the average inches of rain that fell per day for each month, where the average is taken over 2000 - 2010 (inclusive).

SELECT 
	EXTRACT('month' from date_weather) as month,
	AVG(inches_rain) as avg_inch_rain
FROM weather
WHERE date_weather >= '2000-01-01' and date_weather <= '2010-12-31'
GROUP BY month
ORDER BY month;
-- Correct answer, though my column alias could have been more descriptive. 

