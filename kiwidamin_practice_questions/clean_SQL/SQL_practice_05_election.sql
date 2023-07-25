-- inspect tables 
SELECT * FROM candidate;
-- year, party, candidate
SELECT * FROM election;
-- state, democrate_votes, republican_votes, other_votes, year


-- Questions: 

-- it is suggested to make a 'tidy' data view for this dataset, specifically for the election table. Lets do that first

/* 
Data as is: 

state | democrat_votes | republican_votes | other_votes | year 
-------+----------------+------------------+-------------+------
 AL    |         275075 |           149231 |           0 | 1952
 AR    |         226300 |           177155 |           0 | 1952
 AZ    |         108528 |           152042 |           0 | 1952
 CA    |        2257646 |          3035587 |           0 | 1952
 
 Tidy data version:
 
  state | votes  |   party    | year 
-------+--------+------------+------
 AL    |      0 | other      | 1952
 AL    | 149231 | republican | 1952
 AL    | 275075 | democrat   | 1952
 AR    | 177155 | republican | 1952
 AR    | 226300 | democrat   | 1952
 AR    |      0 | other      | 1952
 AZ    | 152042 | republican | 1952
 */
 
-- need to order by 'state' then 'year', but first to mutate the party_votes cols into 'votes' and 'party' cols

CREATE VIEW tidy_election AS
(
  SELECT state, democrat_votes AS votes, 'democrat' AS party, year
  FROM election
  UNION ALL
  SELECT state, republican_votes, 'republican', year
  FROM election
  UNION ALL
  SELECT state, other_votes, 'other', year
  FROM election
)
ORDER BY year, state;

-- inspect view
SELECT * FROM tidy_election;
-- data looks good 


-- 1. How many candidates are in the candidate table for the 2000 election?
SELECT COUNT(candidate)
FROM candidate
WHERE year = 2000;

-- 2. How many candidates are in the candidate table for each election from 1984 to 2016?
SELECT year, COUNT(candidate)
FROM candidate
WHERE year >= 1984 and year <= 2016
GROUP BY year;

-- 3. For each election from 1984 to 2016, give the party that won the popular vote (i.e. the most votes, not the most electoral college seats)

SELECT  year, party, SUM(votes) AS total_votes
FROM tidy_election
WHERE year >= 1984 and year <= 2016
GROUP BY party, year
ORDER BY year,  total_votes DESC;
-- first attempt here, doesn't get exactly what they're looking for, as non-winners are included each year, however, the query still usefully addresses the question

WITH ranked_parties AS(
	SELECT  year, party, SUM(votes) as total_votes, 
			ROW_NUMBER() OVER(PARTITION BY year ORDER by SUM(votes) DESC) as rank_by_vote
	FROM tidy_election
	WHERE year >= 1984 and year <= 2016 
	GROUP BY party, year
	ORDER BY year,  total_votes DESC
)
SELECT year, party as winner
FROM ranked_parties
WHERE rank_by_vote = 1;
-- correct 


-- 4. Extension of previous question: for each election from 1984 to 2016, give the party that won the popular vote and the margin 
--		(i.e. the amount that the winning party got over the party that came in second place). 
--	  You can assume that the third party votes ("Other") are irrelevant, and just compare Democrats and Republicans.

-- creating view to ease this question
CREATE VIEW winners_1984_2016 AS(
WITH party_votes AS(
	SELECT 
		year, 
		sum(democrat_votes) as democrat_votes, 
		sum(republican_votes) as republican_votes, 
		sum(other_votes) as other_votes
	FROM election
	WHERE year between 1984 and 2016
	GROUP BY year
)
SELECT *,
	CASE
		WHEN democrat_votes >= republican_votes AND democrat_votes >= other_votes THEN 'democrat'
		WHEN republican_votes >= democrat_votes AND republican_votes >= other_votes THEN 'republican'
		ELSE 'other'
		END AS winner
FROM party_votes
ORDER BY year
)

-- inspect view .. only republican and democrat winners
SELECT * FROM winners_1984_2016;


SELECT *, 
	CASE
		WHEN winner = 'democrat' THEN democrat_votes - republican_votes
		ELSE republican_votes - democrat_votes
		END AS voting_margin
FROM winners_1984_2016;
-- answer is correct

-- 5. Which states have had fewer than 3 democratic victories 
-- 		(i.e. fewer than 3 elections where the democrats got the majority of the votes in that state) since 1952?

WITH state_wins AS(
	SELECT *, 
		CASE
			WHEN democrat_votes >= republican_votes AND democrat_votes >= other_votes THEN 'democrat'
			WHEN republican_votes >= democrat_votes AND republican_votes >= other_votes THEN 'republican'
			ELSE 'other'
			END AS state_victory
	FROM election
)
SELECT state, state_victory, COUNT(year) AS num_victories
FROM state_wins
GROUP BY state, state_victory
HAVING COUNT(year) < 3 AND state_victory = 'democrat';
-- correct answer, data starts at 1952, so no need to filter by year


-- 6. Which states have had fewer than 3 republican victories since 1952?
WITH state_wins AS(
	SELECT *, 
		CASE
			WHEN democrat_votes >= republican_votes AND democrat_votes >= other_votes THEN 'democrat'
			WHEN republican_votes >= democrat_votes AND republican_votes >= other_votes THEN 'republican'
			ELSE 'other'
			END AS state_victory
	FROM election
)
SELECT state, state_victory, COUNT(year) AS num_victories
FROM state_wins
GROUP BY state, state_victory
HAVING COUNT(year) < 3 AND state_victory = 'republican';
-- this is failing to grab the case where there is a '0' entry, but otherwise is correct 


SELECT state,
       COUNT(year) FILTER (WHERE republican_votes > democrat_votes AND republican_votes > other_votes) AS num_republican_victories
FROM election
GROUP BY state
HAVING COUNT(year) FILTER (WHERE republican_votes > democrat_votes AND republican_votes > other_votes) < 3;
-- correct


-- 7. We are interested in measuring the partisanship of the states. We will define a partisan state as one that is consistently won by 
--		a single party (either Democrat or Republican) since 1988. For example, since 1988 California has been won by the republicans once, 
--		and won by the democrats 7 times. Under this metric, California would be considered "partisan". 
--		(Note that if we include elections back to 1952, the republicans have won CA 9 times, and democrats have only won it 8 times).

-- Find the states where all of the elections since 1988 (including 1988) have been won by the same party

-- This is a bit of a strange question, the answer sheet suggests that the 2nd request, only looking at complete victory since 1988 is the query to make
-- I was thinking to measure partisianship we could subtract the number of victories per state, and positive would = democrat victory, 
--	while negative would = republican victory. Thus a number would suggest where on the spectrum each state lies.

WITH state_wins AS(
	SELECT *, 
		CASE
			WHEN democrat_votes >= republican_votes AND democrat_votes >= other_votes THEN 'democrat'
			WHEN republican_votes >= democrat_votes AND republican_votes >= other_votes THEN 'republican'
			ELSE 'other'
			END AS state_victory
	FROM election
	WHERE year >= 1988
)
SELECT state, state_victory
FROM state_wins
GROUP BY state, state_victory
HAVING COUNT(year) = 8
ORDER BY state_victory, state;

