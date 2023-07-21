--inspecting data
SELECT *
FROM weather;

-- Practice Questions:

-- 1. Select all rows FROM Dec 1st, 2000 to Dec 15th 2000 (inclusive)
SELECT *
FROM weather
WHERE date_weather >= '2000-12-01' AND date_weather <= '2000-12-15';

-- My result set looks good

-- 2. Get the average maximum temperature for every year FROM the year 2000 onward. Order the results by year (ascending)
WITH year_view AS (
	SELECT extract('year' FROM date_weather) AS year, *
	FROM weather)
SELECT year, avg(temp_max)
FROM year_view
GROUP BY year
HAVING year >= '2000'
ORDER BY year;

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

-- 3. Get the standard deviation of the maximum temperature per year, FROM 2000 onward. Order by year (ascending)
WITH year_view AS (
    SELECT EXTRACT('year' FROM date_weather) AS year, temp_max
    FROM weather
    WHERE date_weather >= '2000-01-01'
)
SELECT year, STDDEV(temp_max)
FROM year_view
GROUP BY year
ORDER BY year;

-- Looks good, easy reuse of previous query form. 

--4. What are the 10 hottest days on record? Take hottest to mean 'highest maximum temperature'.
SELECT *
FROM weather
ORDER BY temp_max DESC
LIMIT 10;



-- 5. In 2016, what fraction of days did it rain?
SELECT 
    COUNT(*) FILTER (WHERE did_rain = true)::decimal / COUNT(*) AS rain_fraction
FROM 
    weather
WHERE 
    EXTRACT('YEAR' FROM date_weather) = 2016;
-- result is correct. About 47% of days we see rain


-- 6. What is the 75th percentile for the amount of rain that fell on a day where there was some rain in 2016?
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


-- 8. Get the 10 years with the hottest average maximum temperature in July. Order FROM hottest to coolest
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


-- 9. Get the 10 years with the coldest average minimum temperature in December. Order FROM coolest to hottest
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

-- 11. Given the results of the previous queries, 
-- 	   would it be fair to use this data to claim that 2015 had the "hottest July on record"? Why or why not?

-- 2015 does have the hottest average July on record here, but not the hottest DAY in July on record, which instead belongs to 2009. 
-- So yes it is fair in the average case, but not if we want to get into hottest specific days. 


-- 12. Give the average inches of rain that fell per day for each month, where the average is taken over 2000 - 2010 (inclusive).
SELECT 
	EXTRACT('month' FROM date_weather) as month,
	AVG(inches_rain) as avg_inch_rain
FROM weather
WHERE date_weather >= '2000-01-01' and date_weather <= '2010-12-31'
GROUP BY month
ORDER BY month;


