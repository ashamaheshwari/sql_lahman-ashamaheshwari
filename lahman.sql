
-- QUES 1.
-- Find all players in the database who played at Vanderbilt University. Create a list showing each player's 
--first and last names as well as the total salary they earned in the major leagues. 
--Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

WITH vanderbilt_player AS (SELECT 
						      DISTINCT p.playerid, 
						      schoolid, 
						      namefirst, 
						      namelast
                           FROM people AS p
                           LEFT JOIN Collegeplaying as c
                           USING(playerid)
                           WHERE c.schoolid = 'vandy') 
SELECT namefirst, 
	   namelast, 
	   SUM(salary)::numeric::money AS total_salary  --Need to cast as numeric first
FROM salaries AS s
	 INNER JOIN vanderbilt_player
	 USING(playerid)
GROUP BY playerid, namefirst, namelast
ORDER BY total_salary DESC;

WITH earnings AS(
	SELECT playerid,
		SUM(salary) as big_league_pay 
	FROM salaries
	GROUP BY playerid),
vandy AS(
	SELECT DISTINCT(playerid)
	FROM collegeplaying
	WHERE schoolid = 'vandy')
SELECT playerid, p.namelast, p.namefirst, big_league_pay 
FROM people as p
INNER JOIN vandy
USING(playerid)
LEFT JOIN earnings
USING(playerid)
ORDER BY big_league_pay DESC;

(
SELECT 
	playerid
	FROM collegeplaying 
		LEFT JOIN schools
		USING(schoolid)
	WHERE schoolid = 'vandy'
)
GROUP BY playerid, namefirst, namelast
ORDER BY total_salary DESC;

--Ques 2
-- Using the fielding table, group players into three groups based on their position: label players with position OF as 
--"Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". 
--Determine the number of putouts made by each of these three groups in 2016.

SELECT SUM(po), 
CASE WHEN pos = 'OF' THEN 'Outfield'
     WHEN pos IN('SS', '1B', '2B', '3B' ) THEN 'Infield'
	 WHEN pos IN('P', 'C') THEN 'Battery' END AS group_position
FROM fielding
WHERE yearid = '2016'
GROUP BY group_position;

--Ques 3
-- Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places.
--Do the same for home runs per game. Do you see any trends? 
--(Hint: For this question, you might find it helpful to look at the generate_series function (https://www.postgresql.org/docs/9.1/functions-srf.html). 
--If you want to see an example of this in action, check out this DataCamp video: https://campus.datacamp.com/courses/exploratory-data-analysis-in-sql/summarizing-and-aggregating-numeric-data?ex=6)


WITH generate_series AS (SELECT * 
						 FROM generate_series(1920,2016,10 ))		 
SELECT  generate_series, 
        ROUND(SUM(so)*1.0/SUM(g), 2) AS avg_strikeouts,
		ROUND(SUM(hr)*1.0/SUM(g), 2) AS avg_homeruns
FROM pitching
INNER JOIN generate_series
ON generate_series+1 <= yearid AND generate_series+10 >= yearid
WHERE yearid >= 1920
GROUP BY generate_series
ORDER BY generate_series DESC

--Micheal code

/*					
WITH decade_cte AS (
	SELECT generate_series(1920, 2020, 10) AS beginning_of_decade
)
SELECT 
	ROUND(SUM(hr) * 1.0 / (SUM(g) / 2), 2) AS hr_per_game,
	ROUND(SUM(so) * 1.0 / (SUM(g) / 2), 2) AS so_per_game,
	beginning_of_decade::text || 's' AS decade
FROM teams
INNER JOIN decade_cte
ON yearid BETWEEN beginning_of_decade AND beginning_of_decade + 9
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade;

*/

--Smita code
/*
WITH decade AS (SELECT 
generate_series (1920, 2016, 10) AS decade_group)
	SELECT decade_group,
	COALESCE(ROUND (SUM(g), 2), 0) as sum_game,
	COALESCE(ROUND (SUM(so), 2), 0) as sum_strikeout,
	COALESCE(ROUND (SUM(hr), 2), 0) as sum_homerun,
	COALESCE(ROUND (SUM(so)*1.0/SUM(g), 2), 0) as AvgSO_game,
	COALESCE(ROUND (SUM(hr)*1.0/SUM(g), 2), 0) as AvgHR_game
	FROM pitching
	INNER JOIN decade
		ON decade_group+1 <= yearid 
		AND decade_group+10 >= yearid
		WHERE yearid >= 1920
		GROUP BY decade_group
	ORDER BY decade_group ASC;
*/

-- Number of games	
WITH generate_series AS (SELECT * FROM
					 generate_series(1920,2010,10 ))
SELECT generate_series, SUM(g)	
FROM pitching
INNER JOIN generate_series
ON generate_series+1 <= yearid AND generate_series+10 >= yearid
GROUP BY generate_series
ORDER BY generate_series DESC

--Ques 4
-- Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of 
--stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.)
--Consider only players who attempted at least 20 stolen bases. Report the players' names, number of stolen bases, number of 
--attempts, and stolen base percentage.


WITH success AS (SELECT DISTINCT playerid, 
				        SUM(sb) AS stolen_bases,
				        SUM(cs) AS caught_stealing,
				        SUM(sb) + SUM(cs) AS attempts,
				        ROUND(SUM(sb)* 100/ (SUM(sb) + SUM(cs)), 2) AS success_percentage
                  FROM batting 
                  WHERE yearid = '2016' 
                  GROUP BY playerid
				  HAVING SUM(sb) + SUM(cs)  >= 20)
SELECT namefirst, 
       namelast, 
	   stolen_bases, 
	   attempts, 
	   success_percentage
FROM people AS p
INNER JOIN success
USING (playerid)
ORDER BY success_percentage DESC;

--Micheal code
/*
WITH full_batting AS (
	SELECT
		playerid,
		SUM(sb) AS sb,
		SUM(cs) AS cs,
		SUM(sb) + SUM(cs) AS attempts
	FROM batting
	WHERE yearid = 2016
	GROUP BY playerid
)
SELECT
	namefirst || ' ' || namelast AS fullname,
	sb,
	attempts,
	ROUND(sb*1.0 / attempts, 2) AS sb_percentage
FROM full_batting
INNER JOIN people
USING(playerid)
WHERE attempts >= 20
ORDER BY sb_percentage DESC;
*/

--Alison Code
/*
SELECT success.nameFirst, 
       success.nameLast, 
	   CAST(CAST(Success.stolen_bases AS DECIMAL(5, 2)) / success.total_attempts * 100 AS DECIMAL(5, 2)) AS success_stealing 
FROM(SELECT nameFirst,
            nameLast, SUM(sb) AS stolen_bases, 
			SUM(sb + cs) AS total_attempts
 FROM people
 INNER JOIN batting AS B
 USING(playerid)
 WHERE sb >= 20 
 AND yearid = 2016
 GROUP BY nameFirst, nameLast) AS success
ORDER BY success_stealing DESC
LIMIT 1;
*/


--Ques 5
-- From 1970 to 2016, what is the largest number of wins for a team that did not win the world series?
--What is the smallest number of wins for a team that did win the world series? Doing this will probably 
--result in an unusually small number of wins for a world series champion; determine why this is the case.
--Then redo your query, excluding the problem year. How often from 1970 to 2016 was it the case that a
--team with the most wins also won the world series? What percentage of the time?


SELECT DISTINCT teamid, yearid, SUM(W) AS wins
FROM teams
WHERE yearid BETWEEN 1970 AND 2016 AND wswin = 'N'
GROUP BY teamid, yearid
ORDER BY wins DESC, yearid;


SELECT DISTINCT teamid, yearid, SUM(W) AS world_winner
FROM teams
WHERE yearid BETWEEN 1970 AND 2016 AND wswin = 'Y'
GROUP BY teamid, yearid
ORDER BY world_winner, yearid;

SELECT DISTINCT teamid, yearid, SUM(W) AS world_winner
FROM teams
WHERE yearid BETWEEN 1970 AND 2016 AND wswin = 'Y' AND yearid != 1981
GROUP BY teamid, yearid
ORDER BY world_winner, yearid;





SELECT teamid, yearid, MAX(wins)
FROM
(SELECT DISTINCT teamid, 
                yearid, 
	            SUM(W) AS wins,
                wswin
				FROM teams
WHERE yearid BETWEEN 1970 AND 2016 AND yearid != 1981 
GROUP BY wswin, teamid, yearid) AS wins
WHERE wswin = 'Y'
GROUP BY teamid, yearid

/*
SELECT *
FROM (SELECT franchid AS franchise, yearid AS year,
 CASE WHEN WSWin = 'Y' THEN 1 ELSE 0 END AS total_ws_wins,
 W AS total_regular_wins
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
ORDER BY franchid) AS franch
WHERE total_ws_wins = 0
ORDER BY total_regular_wins DESC
LIMIT 1;
*/

-- Micheal code
/*
WITH top_wins AS (
	SELECT yearid, MAX(w) AS w
	FROM teams
	WHERE yearid between 1970 AND 2016
	GROUP BY yearid
),
top_wins_teams AS (
	SELECT teamid, yearid, w, wswin
	FROM teams
	INNER JOIN top_wins
	USING(yearid, w)
)
SELECT
	SUM(CASE WHEN wswin = 'Y' THEN 1 ELSE 0 END),
	AVG(CASE WHEN wswin = 'Y' THEN 1 ELSE 0 END)
FROM top_wins_teams
WHERE yearid <> 1981 AND wswin IS NOT NULL;

*/

--Hayden code
/*
WITH max_win AS(
	SELECT *,
		RANK() OVER(PARTITION BY yearid ORDER BY w DESC) as ranks
	FROM teams
	WHERE yearid BETWEEN 1970 AND 2019
)
SELECT COUNT(*), ROUND(100 * COUNT(*) / (2016 - 1970 + 1)::decimal, 2) AS percent
FROM max_win
WHERE ranks = '1' AND
	wswin = 'Y'
*/

--Ques 6
-- Which managers have won the TSN Manager of the Year award in both the National League (NL) and the 
--American League (AL)? Give their full name and the teams that they were managing when they won the award.

WITH AL_winner AS (SELECT DISTINCT playerid
                   FROM awardsmanagers
                   WHERE awardid = 'TSN Manager of the Year' AND lgid = 'AL'
				  ),
NL_winner AS (SELECT DISTINCT playerid
                   FROM awardsmanagers 
                   WHERE awardid = 'TSN Manager of the Year' AND lgid = 'NL')
SELECT DISTINCT p.playerid, teamid, namefirst, namelast
FROM people as p
INNER JOIN managers
USING(playerid)
INNER JOIN NL_winner
USING(playerid) 
INNER JOIN AL_winner
USING(playerid)

/*
with both_league_manager AS (SELECT DISTINCT playerid
                             FROM awardsmanagers
                             WHERE awardid = 'TSN Manager of the Year' AND lgid IN ('AL', 'NL')
							 GROUP BY playerid
							 HAVING COUNT (DISTINCT lgid) = 2),
both_league_manager_years AS (SELECT DISTINCT playerid, yearid
                             FROM awardsmanagers
						     INNER JOIN both_league_manager
                             USING(playerid)
							 WHERE awardid = 'TSN Manager of the Year' AND lgid IN ('AL', 'NL')
							 GROUP BY playerid
	HAVING COUNT (DISTINCT lgid) = 2),
*/

/*
SELECT
 namefirst || ' ' || namelast AS full_name,
 awmg.yearid,
 awmg.lgid,
 teamid
FROM awardsmanagers AS awmg
INNER JOIN people
USING(playerid)
INNER JOIN managers AS m
ON awmg.playerid = m.playerid
 AND awmg.yearid = m.yearid
WHERE (awmg.playerid, awmg.awardid) IN (
 SELECT playerid,
  awardid
 FROM awardsmanagers
 WHERE awardid = 'TSN Manager of the Year'
  AND lgid IN ('NL','AL')
 GROUP BY playerid, awardid
 HAVING COUNT( DISTINCT lgid) = 2
)							 							 
*/

--Ques 7
-- Which pitcher was the least efficient in 2016 in terms of salary / strikeouts?Only consider pitchers
--who started at least 10 games (across all teams). Note that pitchers often play for more than one team 
--in a season, so be sure that you are counting all stats for each player.


WITH pitcher_2016 AS (SELECT DISTINCT playerid, 
					         SUM(so) AS strikeouts
                      FROM pitching
                      WHERE yearid = 2016 
                      GROUP BY playerid
					  HAVING SUM(gs) >= 10),
salary_2016 AS (SELECT DISTINCT playerid, 
			           SUM(salary)::numeric::money AS total_salary
				FROM salaries
			    WHERE yearid = 2016
			    GROUP BY playerid)
SELECT DISTINCT p.playerid, 
       namefirst, 
	   namelast,
      (total_salary/strikeouts)::numeric::money AS salary_per_so 
FROM people as p
INNER JOIN pitcher_2016
USING(playerid)
INNER JOIN salary_2016
USING(playerid)
GROUP BY namefirst, namelast, playerid, salary_per_so
ORDER BY salary_per_so;

--micheal code 
/*
WITH full_pitching AS (
	SELECT 
		playerid,
		SUM(so) AS so
	FROM pitching
	WHERE yearid = 2016
	GROUP BY playerid
	HAVING SUM(gs) >= 10
),
full_salary AS (
	SELECT
		playerid,
		SUM(salary) AS salary
	FROM salaries
	WHERE yearid = 2016
	GROUP BY playerid
)
SELECT 
	namefirst || ' ' || namelast AS fullname,
	salary::numeric::MONEY / so AS so_efficiency
FROM full_pitching
NATURAL JOIN full_salary
INNER JOIN people
USING(playerid)
ORDER BY so_efficiency DESC;

*/

--Ques 8
-- Find all players who have had at least 3000 career hits. Report those players' names, total number of
--hits, and the year they were inducted into the hall of fame (If they were not inducted into the hall of
--fame, put a null in that column.) Note that a player being inducted into the hall of fame is indicated by
--a 'Y' in the inducted column of the halloffame table.


WITH hits AS (SELECT playerid, 
                     SUM(h) as total_hits
              FROM batting
              GROUP BY playerid
              HAVING SUM(h) >= 3000),
Fame AS (SELECT playerid,
		        yearid
		 FROM halloffame
		 WHERE inducted = 'Y')
SELECT namefirst || ' ' || namelast AS fullname,
	   total_hits,
       yearid
FROM people 
INNER JOIN hits
USING(playerid)
LEFT JOIN fame
USING(playerid)

Ajay code

/*
WITH career_hits AS(
	SELECT DISTINCT playerid, 
			SUM(h) AS hits 
	FROM batting
		GROUP BY playerid
		HAVING  SUM(h) >= 3000
		ORDER BY 2 DESC
)
SELECT DISTINCT ON (namefirst, namelast) namefirst,
	   namelast,
	   ch.hits,	   
	   CASE WHEN hf.inducted = 'Y' THEN 'Y'
	   		ELSE NULL END AS hf_inducted,
	   CASE WHEN hf.inducted = 'Y' THEN hf.yearid 
	   		END AS hf_yearid	   
FROM people p
	INNER JOIN career_hits ch 
		USING (playerid)
	LEFT JOIN halloffame hf 
		USING (playerid)
ORDER BY namefirst, namelast, hf_yearid desc NULLS LAST
*/

--Ques 9
-- Find all players who had at least 1,000 hits for two different teams. Report those players' full names.

WITH thousandaires AS (
	SELECT 
		playerid,
		teamid,
		SUM(h) AS total_hits
	FROM batting
	GROUP BY playerid, teamid
	HAVING SUM(H) >= 1000
),
double_thousandaires AS (
	SELECT
		playerid
	FROM thousandaires
	GROUP BY playerid
	HAVING COUNT(DISTINCT teamid) = 2)
SELECT 
	namefirst || ' ' || namelast AS full_name
FROM double_thousandaires
NATURAL JOIN people;


-- Find all players who hit their career highest number of home runs in 2016. Consider only players who
--have played in the league for at least 10 years, and who hit at least one home run in 2016.
--Report the players' first and last names and the number of home runs they hit in 2016.

WITH player_2016 AS (SELECT playerid,
                            SUM(hr) AS homeruns_2016
                     FROM batting
                     WHERE yearid = 2016
                     GROUP BY playerid
                     HAVING SUM(hr) >= 1), --CTE to filter player with atleast one homerun in year 2016
player_total AS (SELECT playerid,
                    SUM(hr) AS total_home_runs,
			        COUNT(DISTINCT yearid) AS year_played
                    FROM batting
                    GROUP BY playerid
                    HAVING COUNT(DISTINCT yearid) >= 10 ),--CTE to filter players played atleast 10 years				 
player_max AS (SELECT playerid,
		          MAX(hr) AS max_homerun
		   FROM batting
		   GROUP BY playerid
		  ) --CTE to find max homerun for a player

SELECT namefirst,
	   namelast,
	   homeruns_2016
FROM people
INNER JOIN player_2016
USING(playerid)
INNER JOIN player_total
USING(playerid)
INNER JOIN player_max
USING(playerid)
WHERE homeruns_2016 = max_homerun
ORDER BY homeruns_2016 DESC



-- After finishing the above questions, here are some open-ended questions to consider.

-- Open-ended questions


-- Is there any correlation between number of wins and team salary? Use data from 2000 and later to 
--answer this question. As you do this analysis, keep in mind that salaries across the whole league tend 
--to increase together, so you may want to look on a year-by-year basis.

SELECT CORR(total_wins, total_team_salary)
FROM
(SELECT DISTINCT teamid, 
       SUM(W) AS total_wins,
	   SUM(salary) AS total_team_salary
FROM teams as t
INNER JOIN salaries
USING(teamid)
WHERE t.yearid = 2000
GROUP BY teamid) AS sub

-- In this question, you will explore the connection between number of wins and attendance.

-- a. Does there appear to be any correlation between attendance at home games and number of wins?

SELECT CORR(attendance, total_wins)
FROM
(SELECT teamid,
        SUM(w) AS total_wins,
        attendance
 FROM teams
 GROUP BY teamid, attendance
) AS sub


select *
FROM teams

-- b. Do teams that win the world series see a boost in attendance the following year? What about teams 
--that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.

SELECT teamid, yearid, attendance
FROM teams
WHERE wswin = 'Y'

-- It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?

