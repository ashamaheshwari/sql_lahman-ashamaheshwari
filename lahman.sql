
-- QUES 1.
-- Find all players in the database who played at Vanderbilt University. Create a list showing each player's 
--first and last names as well as the total salary they earned in the major leagues. 
--Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

--Solution:
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


--Ques 2
-- Using the fielding table, group players into three groups based on their position: label players with position OF as 
--"Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". 
--Determine the number of putouts made by each of these three groups in 2016.

--Solution:
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


--Solution
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


-- Number of games	
WITH generate_series AS (SELECT * 
						 FROM generate_series(1920,2010,10 ))
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

--Solution
WITH success AS (SELECT DISTINCT playerid, 
				        SUM(sb) AS stolen_bases,
				        SUM(cs) AS caught_stealing,
				        SUM(sb) + SUM(cs) AS attempts,
				        ROUND(SUM(sb)* 100/ (SUM(sb) + SUM(cs)), 2) AS success_percentage
                  FROM batting 
                  WHERE yearid = '2016' 
                  GROUP BY playerid
				  HAVING SUM(sb) + SUM(cs)  >= 20)
SELECT namefirst || ' ' || namelast AS fullname,
	   stolen_bases, 
	   attempts, 
	   success_percentage
FROM people AS p
INNER JOIN success
USING (playerid)
ORDER BY success_percentage DESC;



--Ques 5
-- a. From 1970 to 2016, what is the largest number of wins for a team that did not win the world series?
--b. What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion; determine why this is the case.
--c. Then redo your query, excluding the problem year. 
--d. How often from 1970 to 2016 was it the case that a
--team with the most wins also won the world series? What percentage of the time?

--Solution a.
SELECT DISTINCT teamid, 
                yearid, 
				SUM(W) AS wins
FROM teams
WHERE yearid BETWEEN 1970 AND 2016 AND wswin = 'N'
GROUP BY teamid, yearid
ORDER BY wins DESC, yearid;


--Solution b.
SELECT DISTINCT teamid, 
                yearid, 
				SUM(W) AS world_winner
FROM teams
WHERE yearid BETWEEN 1970 AND 2016 AND wswin = 'Y'
GROUP BY teamid, yearid
ORDER BY world_winner, yearid;


--Solution c.
SELECT DISTINCT teamid, 
                yearid, 
				SUM(W) AS world_winner
FROM teams
WHERE yearid BETWEEN 1970 AND 2016 AND wswin = 'Y' AND yearid != 1981
GROUP BY teamid, yearid
ORDER BY world_winner, yearid;


--Solution d.
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



--Ques 6
-- Which managers have won the TSN Manager of the Year award in both the National League (NL) and the 
--American League (AL)? Give their full name and the teams that they were managing when they won the award.

--Solution
WITH AL_winner AS (SELECT DISTINCT playerid
                   FROM awardsmanagers
                   WHERE awardid = 'TSN Manager of the Year' AND lgid = 'AL'
				  ),
NL_winner AS (SELECT DISTINCT playerid
                   FROM awardsmanagers 
                   WHERE awardid = 'TSN Manager of the Year' AND lgid = 'NL')
SELECT DISTINCT p.playerid, 
                teamid, 
				namefirst || ' ' || namelast AS full_name
FROM people as p
INNER JOIN managers
USING(playerid)
INNER JOIN NL_winner
USING(playerid) 
INNER JOIN AL_winner
USING(playerid)



--Ques 7
-- Which pitcher was the least efficient in 2016 in terms of salary / strikeouts?Only consider pitchers
--who started at least 10 games (across all teams). Note that pitchers often play for more than one team 
--in a season, so be sure that you are counting all stats for each player.


--Solution 
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
SELECT DISTINCT namefirst || namelast AS fullname,
      (total_salary/strikeouts)::numeric::money AS salary_per_so 
FROM people
INNER JOIN pitcher_2016
USING(playerid)
INNER JOIN salary_2016
USING(playerid)
GROUP BY namefirst, namelast, playerid, salary_per_so
ORDER BY salary_per_so DESC;



--Ques 8
-- Find all players who have had at least 3000 career hits. Report those players' names, total number of
--hits, and the year they were inducted into the hall of fame (If they were not inducted into the hall of
--fame, put a null in that column.) Note that a player being inducted into the hall of fame is indicated by
--a 'Y' in the inducted column of the halloffame table.

--Solution
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


--Ques 9
-- Find all players who had at least 1,000 hits for two different teams. Report those players' full names.

--Soultion
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
	SELECT playerid
	FROM thousandaires
	GROUP BY playerid
	HAVING COUNT(DISTINCT teamid) = 2)
SELECT namefirst || ' ' || namelast AS full_name
FROM double_thousandaires
NATURAL JOIN people;


-- Ques 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who
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


--Ques 11.  Is there any correlation between number of wins and team salary? Use data from 2000 and later to 
--answer this question. As you do this analysis, keep in mind that salaries across the whole league tend 
--to increase together, so you may want to look on a year-by-year basis.

--Solution
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

-- Ques 12. In this question, you will explore the connection between number of wins and attendance.
--Does there appear to be any correlation between attendance at home games and number of wins?

--Solution
SELECT CORR(attendance, total_wins)
FROM
(SELECT teamid,
        SUM(w) AS total_wins,
        attendance
 FROM teams
 GROUP BY teamid, attendance
) AS sub

