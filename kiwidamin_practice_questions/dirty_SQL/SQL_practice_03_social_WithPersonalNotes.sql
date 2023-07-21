SELECT * 
FROM follows;
-- user_id, follows, date_created

SELECT * 
FROM users;
-- user_id, first_name, last_name, house

-- 1. How many users are there in each house?
SELECT house, COUNT(user_id)
FROM users
GROUP BY house;


-- 2. List all following links that were created before September 1st, 1993
SELECT *
FROM follows
WHERE date_created < '1993-09-01';


-- 3. List all rows from the follows table, replacing both user_ids with first name. Hint: it may help to make this a VIEW
WITH tab1 AS(
	SELECT u.first_name as name_followed, f.* 
	FROM follows f
	LEFT JOIN users u ON u.user_id = f.user_id
)
SELECT t.*, u.first_name AS name_follower
FROM tab1 t
LEFT JOIN users u ON u.user_id = t.follows;

-- refining result
WITH tab1 AS(
	SELECT u.first_name as user_first, f.* 
	FROM follows f
	LEFT JOIN users u ON u.user_id = f.user_id
)
SELECT t.user_first, u.first_name AS follower_first, t. date_created
FROM tab1 t
LEFT JOIN users u ON u.user_id = t.follows;

-- VIEW ALTERNATIVE: 
CREATE VIEW follows_with_names AS
SELECT 
    u1.first_name as user_first, 
    u2.first_name as follower_first, 
    f.date_created
FROM 
    follows f
LEFT JOIN 
    users u1 ON u1.user_id = f.user_id
LEFT JOIN 
    users u2 ON u2.user_id = f.follows;

-- inspect view
SELECT *
FROM follows_with_names;



-- 4. List all the following links established before September 1st 1993, but this time use the users first names.
SELECT *
FROM follows_with_names
WHERE date_created < '1993-09-01';


-- 5. Give a count of how many people followed each user as of 1999-12-31. Give the result in term of "users full name, number of followers".
SELECT user_first, count(user_first) as num_followers
FROM follows_with_names
WHERE date_created <= '1999-12-31'
GROUP BY user_first;
-- not quite right yet, I also see there must be an issue with the result set posted on Github, as there are strictly incorrect values in the answer table posted

SELECT 
	u.first_name || ' ' || u.last_name as user_full_name, 
	COUNT(fw.follower_first) as num_followers
FROM users u
LEFT JOIN follows_with_names fw ON fw.user_first = u.first_name AND fw.date_created <= '1999-12-31'
--WHERE fw.date_created <= '1999-12-31' -- <- this WHERE clause filters out users with no follows by this time, which is an incomplete data set. 
GROUP BY user_full_name
ORDER BY num_followers DESC;


-- ANSWER
SELECT 
	u.first_name || ' ' || u.last_name as user_full_name, 
	COUNT(fw.follower_first) as num_followers
FROM users u
LEFT JOIN follows_with_names fw ON fw.user_first = u.first_name AND fw.date_created <= '1999-12-31' 
GROUP BY user_full_name
ORDER BY num_followers DESC;

-- 6. List the number of users each user follows
SELECT follower_first as user_first, count(user_first) as num_following
FROM follows_with_names
GROUP BY follower_first;
-- again my answer differs from the given answer, however, their answer disagrees with the table upon visual inspection. Strange. 


-- 7. List all rows from follows where someone from one house follows someone from a different house.
-- Note that how you interpret what the columns should be (first name, user id, full name) is left up to interpretation in this question. 
-- 	For example,the question doesn't explicitly ask for the houses of each person. 
-- 	Other answers formats would also be acceptable, as long as they represent the same relationships.

WITH houses_tab AS(
	SELECT 
		fw.user_first, u1.house as user_house, 
		fw.follower_first, u2.house as follower_house
	FROM follows_with_names fw
	LEFT JOIN users u1 ON u1.first_name = fw.user_first
	LEFT JOIN users u2 ON u2.first_name = fw.follower_first
)
SELECT *
FROM houses_tab
WHERE user_house != follower_house;
-- looks good 

-- attempting to use where in the original query without use CTE
SELECT 
	fw.user_first, u1.house as user_house, 
	fw.follower_first, u2.house as follower_house
FROM follows_with_names fw
LEFT JOIN users u1 ON u1.first_name = fw.user_first
LEFT JOIN users u2 ON u2.first_name = fw.follower_first
WHERE u1.house != u2.house; 
-- same outcome. I need to learn about the order of JOIN statements 

-- so joins happen at the FROM stage. Which is why WHERE statements can reference ALL columns coming from the tables being joined in!


-- 8. We define a friendship as a relationship between two users where both follow each other. 
--		The friendship is established when the later of the two links is established.

-- no actual question prompted here... presumably they want us to show which users are friends.. i.e. which users both follow each other. 
SELECT fw1.user_first, fw1.follower_first, fw1.date_created
FROM follows_with_names fw1
JOIN follows_with_names fw2 
ON fw1.user_first = fw2.follower_first AND fw1.follower_first = fw2.user_first;


WITH ordered_follows AS (
    SELECT 
        LEAST(fw1.user_first, fw1.follower_first) || '-' || GREATEST(fw1.user_first, fw1.follower_first) AS pair_identifier,
        fw1.date_created,
        ROW_NUMBER() OVER 
			(PARTITION BY LEAST(fw1.user_first, fw1.follower_first), GREATEST(fw1.user_first, fw1.follower_first) 
			 	ORDER BY fw1.date_created DESC) AS rn
    FROM follows_with_names fw1
    JOIN follows_with_names fw2 
    ON fw1.user_first = fw2.follower_first AND fw1.follower_first = fw2.user_first
)
SELECT pair_identifier, date_created
FROM ordered_follows
WHERE rn = 1;



-- 9. List all unrequited followings (i.e. where A follows B but B does not follow A)

-- To find unrequited follow relationships, we capture the relevant pairs with string concatenation, 
-- then use a window function to assign sizes to each unique pair. Then use those sizes to filter out pairs with group size > 1. 
-- When a group size is > 1, this means that both users follow each other. Unrequitted follows occur where the group size = 1. 
WITH follow_groups AS(
	SELECT 
		LEAST(user_first, follower_first) || '-' || GREATEST(user_first, follower_first) AS name_pairs,
		date_created,
		COUNT(*) OVER (PARTITION BY LEAST(user_first, follower_first) || '-' || GREATEST(user_first, follower_first)) AS group_size
	FROM follows_with_names
)
SELECT *
FROM follow_groups
WHERE group_size = 1; 
