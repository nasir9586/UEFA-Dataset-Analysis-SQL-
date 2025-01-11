CREATE TABLE Stadium (
    Name VARCHAR(255),
    City VARCHAR(255),
    Country VARCHAR(255),
    Capacity INT,
    PRIMARY KEY (Name, City, Country)
);
copy Stadium from 'C:/DATA_SQL/Stadiums.csv' CSV HEADER;
select * from stadium;

CREATE TABLE Teams (
    Team_Name VARCHAR(255),
    Country VARCHAR(255),
    Home_Stadium VARCHAR(255),
    PRIMARY KEY (Team_Name)
);
copy teams from 'C:/DATA_SQL/teams.csv' CSV HEADER;
select * from teams;

CREATE TABLE Players (
    Player_ID VARCHAR(255),
    First_Name VARCHAR(255),
    Last_Name VARCHAR(255),
    Nationality VARCHAR(255),
    DOB DATE,
    Team VARCHAR(255),
    Jersey_Number FLOAT,
    Position VARCHAR(255),
    Height FLOAT,
    Weight FLOAT,
    Foot VARCHAR(1),
    PRIMARY KEY (Player_ID),
    FOREIGN KEY (Team) REFERENCES Teams(Team_Name)
);
copy Players from 'C:/DATA_SQL/players.csv' CSV HEADER;
select * from Players;

CREATE TABLE Matches (
    Match_ID VARCHAR(255),
    Season VARCHAR(255),
    Date VARCHAR(10),
    Home_Team VARCHAR(255),
    Away_Team VARCHAR(255),
    Stadium VARCHAR(255),
    Home_Team_Score INT,
    Away_Team_Score INT,
    Penalty_Shoot_Out INT,
    Attendance INT,
    PRIMARY KEY (Match_ID),
    FOREIGN KEY (Home_Team) REFERENCES Teams(Team_Name),
    FOREIGN KEY (Away_Team) REFERENCES Teams(Team_Name)
	--FOREIGN KEY (Stadium) REFERENCES Stadium(Name)
);
copy Matches from 'C:/DATA_SQL/matches.csv' CSV HEADER;
select * from Matches;

CREATE TABLE Goals (
    Goal_ID VARCHAR(255),
    Match_ID VARCHAR(255),
    Player_ID VARCHAR(255),
    Duration INT,
    Assist VARCHAR(255),
    Goal_Desc VARCHAR(255),
    PRIMARY KEY (Goal_ID),
    FOREIGN KEY (Match_ID) REFERENCES Matches(Match_ID),
    FOREIGN KEY (Player_ID) REFERENCES Players(Player_ID),
    FOREIGN KEY (Assist) REFERENCES Players(Player_ID)
);
copy Goals from 'C:/DATA_SQL/goals.csv' CSV HEADER;

select * from matches;
select * from players;
select * from teams;
select * from stadium;
------------------------------------------------------------------------------------------------
-----------------------------------------Queries------------------------------------------------


--1] Which player scored the most goals in a each season?
with ranked_goals as (select 
m.season, p.player_id, p.first_name, p.last_name, 
count(g.goal_id) as goals_count,row_number() over (partition by m.season order by count(g.goal_id) desc) as rank
from goals as g
join players as p on g.player_id = p.player_id
join matches as m on g.match_id = m.match_id
group by  m.season, p.player_id, p.first_name, p.last_name)

select season, player_id, first_name, last_name, goals_count
from ranked_goals
where rank = 1
order by season;

--2] How many goals did each player score in a given season?
select p.player_id,p.first_name,p.last_name,m.season,count(goal_id) as Goal_counts
from goals as g
join players as p
on g.player_id=p.player_id
join matches as m
on g.match_id=m.match_id
group by p.player_id,p.first_name,p.last_name,m.season
order by m.season desc;

--3] What is the total number of goals scored in a particular match?
select m.match_id,m.stadium,count(g.goal_id) as total_goals
from matches as m
join goals as g
on m.match_id=g.match_id
group by m.match_id,m.stadium
order by m.match_id desc;

--4] Which player assisted the most goals in a each season?
select m.season,p.player_id,p.first_name,p.last_name, 
count(g.assist) as total_assists
from goals as g
join players as p 
on g.assist = p.player_id
join matches as m 
on g.match_id = m.match_id
group by m.season, p.player_id, p.first_name, p.last_name
order by m.season, total_assists desc;

--5] Which players have scored goals in more than 10 matches?
select p.first_name,p.last_name,count(Distinct g.match_id) as Match_count
from goals as g
join matches as m
on g.match_id=m.match_id
join players as p
on g.player_id=p.player_id
group by p.first_name,p.last_name
having count(Distinct g.match_id)>10
order by Match_count Desc;

--6] What is the average number of goals scored per match in a given season?
select m.match_id,m.season,avg(count(g.goal_id))
over(partition by m.season order by m.match_id) as Avg_goals
from goals as g
join matches as m 
on g.match_id=m.match_id
group by m.match_id,m.season;

--7] Which player has the most goals in a single match?
select p.player_id,p.first_name,p.last_name,
max(max_goals) as max_match_goals from (
select g2.match_id,g2.player_id,count(g2.goal_id) as max_goals
from goals as g2
join players as p2
on g2.player_id=p2.player_id
group by g2.match_id,g2.player_id
)as max_goals
join players as p
on p.player_id=max_goals.player_id
group by  p.player_id,p.first_name,p.last_name;

--8] Which team scored the most goals in the all seasons?
select m.season,t.team_name,count(goal_id) as Max_goals
from goals as g
join matches as m
on g.match_id=m.match_id
join players as p
on g.player_id=p.player_id
join teams as t
on p.team=t.team_name
group by m.season,t.team_name
order by count(goal_id) desc
limit 1;

--9]Which stadium hosted the most goals scored in a single season?
select s.name,count(goal_id) as max_goals
from goals as g
join matches as m
on g.match_id=m.match_id
join stadium as s
on m.stadium=s.name
group by s.name
order by max_goals Desc;

----------------------Match Analysis---------------------------

--10] What was the highest-scoring match in a particular season?
with Highest_scoring as (
select m.match_id,m.season,t.team_name,
count(g.goal_id) as Goals,
rank() over(partition by season order by count(g.goal_id) Desc) as Highest_scoring
from goals as g
join matches as m
on g.match_id=m.match_id
join players as p
on g.player_id=p.player_id
join teams as t
on t.team_name=p.team
group by m.match_id,m.season,t.team_name)

select match_id,season,team_name
from Highest_scoring
where Highest_scoring=1
order by season;

--11] How many matches ended in a draw in a given season?
select m.match_id, m.season
from matches as m
where m.home_team_score = m.away_team_score
order by m.season;

--12] Which team had the highest average score (home and away) in the season 2021-2022?
select t.team_name,
avg(case when t.team_name = m.home_team then m.home_team_score
when t.team_name = m.away_team then m.away_team_score end) as avg_total_score
from matches as m
join teams as t 
on t.team_name in (m.home_team, m.away_team)
where m.season = '2021-2022'
group by t.team_name
order by avg_total_score desc
limit 1;

--13] How many penalty shootouts occurred in a each season?
select m.season,count(g.goal_desc)
from goals as g
join matches as m
on g.match_id=m.match_id
where goal_desc='penalty'
group by m.season
order by m.season;

--14] What is the average attendance for home teams in the 2021-2022 season?
select avg(m.attendance) as avg_attendance
from matches as m
join teams as t
on t.team_name=m.home_team
where season='2021-2022';






--15] Which stadium hosted the most matches in a each season?
select m.season,s.name,
count(m.match_id) as Matches
from matches as m
join stadium as s
on m.stadium=s.name
group by m.season,s.name
order by m.season,Matches desc;

--16] What is the distribution of matches played in different countries in a season?
select m.season,s.country,count(m.match_id) as matches
from matches as m
join stadium as s
on m.stadium=s.name
group by m.season,s.country
order by matches desc;

--17] What was the most common result in matches (home win, away win, draw)?
select result,count(*) as count from (select 
match_id,
case when home_team_score>away_team_score then 'home_win'
when home_team_score<away_team_score then 'away_win'
else 'Draw' end as result
from matches) as match_results
group by result 
order by count desc;

---------------------------Player Analysis ----------------------------

--18]Which players have the highest total goals scored (including assists)?
select p.player_id, p.first_name, p.last_name,
count(g.goal_id) as total_goals,
sum(case when g.assist is not null then 1 else 0 end) as total_assists,
count(g.goal_id) + sum(case when g.assist is not null then 1 else 0 end) as total_contributions
from players as p
left join goals as g
on p.player_id = g.player_id
group by p.player_id, p.first_name, p.last_name
order by total_contributions desc, total_goals desc, total_assists desc;

--19] What is the average height and weight of players per position?
select position,AVG(height) AS avg_height, AVG(weight) AS avg_weight
from players
group by position
order bY position;

--20] Which player has the most goals scored with their left foot?
select p.player_id, p.first_name, p.last_name,
count(g.goal_id) as total_goals
from players as p
join goals as g
on p.player_id=g.player_id
where g.goal_desc = 'left-footed shot'
group by p.player_id, p.first_name, p.last_name
order by total_goals desc;

--21] What is the average age of players per team?
select t.team_name,avg(extract(year from age(p.dob))) as average_age
from players as p
join teams as t
on t.team_name=p.team
group by t.team_name;

--22] How many players are listed as playing for a each team in a season?
select t.team_name, m.season, count(distinct p.player_id) as total_players
from players as p
join teams as t 
on t.team_name = p.team
join matches as m 
on m.home_team = t.team_name or m.away_team = t.team_name
group by t.team_name, m.season
order by m.season, t.team_name;

--23]	Which player has played in the most matches in the each season?
select p.player_id, p.first_name, p.last_name,m.season,
count(m.match_id) as total_matches
from players as p
join goals as g
on p.player_id=g.player_id
join matches as m
on g.match_id=m.match_id
group by p.player_id, p.first_name, p.last_name,m.season 
order by m.season ,total_matches desc;

--24] What is the most common position for players across all teams?
select p.position,count(p.player_id) as counts
from players as p
group by p.position 
order by counts desc;

--25] Which players have never scored a goal?
select p.player_id,p.first_name,p.last_name
from players as p
left join goals as g
on p.player_id=g.player_id
where g.goal_id is null; 

------------------------Team Analysis-----------------------------------------

--26] Which team has the largest home stadium in terms of capacity?
select t.team_name,max(s.capacity) as capacity
from teams as t
join stadium as s
on t.home_stadium=s.name
group by t.team_name
order by capacity desc;

--27] Which teams from a each country participated in the UEFA competition in a season?
select t.country, t.team_name,m.season
from teams as t
join matches as m on m.home_team = t.team_name or m.away_team = t.team_name
group by t.country, t.team_name, m.season
order by t.country, m.season, t.team_name;

--28] Which team scored the most goals across home and away matches in a given season?
select t.team_name,m.season,count(g.goal_id) as total_goals
from goals as g
join matches as m
on g.match_id=m.match_id
join teams as t
on m.home_team = t.team_name or m.away_team = t.team_name
where (m.home_team = t.team_name and m.home_team_score > m.away_team_score) or 
(m.away_team = t.team_name and m.away_team_score > m.home_team_score)
group by t.team_name,m.season
order by total_goals desc;


--29] How many teams have home stadiums in a each city or country?
select s.city,s.country,count(t.team_name) as counts
from teams as t
join stadium as s
on t.home_stadium=s.name
group by s.city,s.country
order by counts desc;

--30] Which teams had the most home wins in the 2021-2022 season?
select t.team_name,m.season,count(*) as home_wins
from teams as t
join matches as m
on t.team_name=m.home_team
where home_team_score>away_team_score and m.season='2021-2022'
group by t.team_name,m.season
order by home_wins desc;


--------------------------Stadium Analysis --------------------------------

--31] Which stadium has the highest capacity?
select name,max(capacity) as max_capacity
from stadium
group by name,city,country
order by max_capacity desc;

--32] How many stadiums are located in a particular country or city?
select name,city,country
from stadium 
group by name,city,country
order by name;

--33] Which stadium hosted the most matches during a season?
select s.name,m.season,count(m.match_id) as total_matches
from stadium as s
join matches as m
on s.name=m.stadium 
group by s.name,m.season
order by m.season,total_matches desc;

--34] What is the average stadium capacity for teams participating in a specific season?
select m.season, avg(s.capacity) as avg_capacity
from teams as t
join stadium as s 
on t.home_stadium = s.name
join  matches as m 
on m.home_team = t.team_name or m.away_team = t.team_name
group by m.season;

--35] How many teams play in stadiums with a capacity of more than 50,000?
select * from teams;
select count(t.team_name) as team_count
from teams as t
join stadium as s
on t.home_stadium=s.name
where capacity>50000;

--36] Which stadium had the highest attendance on average during a season?
select s.name,m.season,avg(m.attendance) as avg_attendance
from stadium as s
join matches as m
on s.name=m.stadium
group by s.name,m.season
order by avg_attendance desc;

--37] What is the distribution of stadium capacities by country?
select s.country,s.name as stadium_name,s.capacity
from stadium as s
order by s.country, s.capacity desc;

--------------------------------Cross-Table Analysis-----------------------------

--38] Which players scored the most goals in matches held at a specific stadium?
select p.player_id,p.first_name,p.last_name,s.name as Stadium_name,
count(g.goal_id) as total_goals
from players as p
join goals as g
on p.player_id=g.player_id
join matches as m
on g.match_id=m.match_id
join stadium as s
on m.stadium=s.name
group by p.player_id,p.first_name,p.last_name,Stadium_name
order by total_goals desc;

--39] Which team won the most home matches in the season 2021-2022 (based on match scores)?
select t.team_name,count(m.match_id) as total_wins
from matches as m
join teams as t
on m.home_team=t.team_name
where home_team_score > away_team_score and season='2021-2022'
group by t.team_name
order by total_wins desc;

--40] Which players played for a team that scored the most goals in the 2021-2022 season?
select p.player_id,p.first_name,p.last_name,t.team_name,
count(g.goal_id) as total_goals
from goals as g
join matches as m
on g.match_id=m.match_id
join players as p
on g.player_id=p.player_id
join teams as t
on  m.home_team = t.team_name or m.away_team = t.team_name
where season='2021-2022'
group by p.player_id,p.first_name,p.last_name,t.team_name
order by total_goals desc;

--41] How many goals were scored by home teams in matches where the attendance was above 50,000?
select count(g.goal_id) as total_goals
from goals as g
join matches as m
on g.match_id=m.match_id
join teams as t
on t.team_name=m.home_team
join stadium as s
on s.name=m.stadium
where m.home_team_score>m.away_team_score and s.capacity>50000;

--42] Which players played in matches where the score difference 
------(home team score - away team score) was the highest?
with highest_score as (
select match_id,abs(home_team_score - away_team_score) as score_difference
from matches as m
order by score_difference desc
limit 1)

select p.player_id,p.first_name,p.last_name,hs.score_difference
from players as p
join goals as g
on p.player_id=g.player_id
join highest_score as hs
on hs.match_id=g.match_id;

--43] How many goals did players score in matches that ended in penalty shootouts?
select p.player_id,p.first_name,p.last_name,count(g.goal_id) as total_goals
from goals as g
join players as p
on g.player_id=p.player_id
join matches as m
on g.match_id=g.match_id
where (m.home_team_score = m.away_team_score)
and g.goal_desc = 'penalty' 
group by p.player_id,p.first_name,p.last_name
order by total_goals desc;

--44] What is the distribution of home team wins vs away team wins by country for all seasons?
select t.country,m.season,
sum(case when home_team_score>away_team_score then 1 else 0 end) as home_team_wins,
sum(case when away_team_score>home_team_score then 1 else 0 end) as away_team_wins
from teams as t
join matches as m
on t.team_name=m.home_team or t.team_name=m.away_team
group by t.country,m.season
order by t.country,m.season;

--45] Which team scored the most goals in the highest-attended matches?
select t.team_name,count(g.goal_id) as total_goals
from goals as g
join matches as m
on g.match_id=m.match_id
join teams as t
on t.team_name=m.home_team or t.team_name=m.away_team
where m.attendance = (select max(attendance) from matches as m)
group by t.team_name
order by total_goals desc;

--46] Which players assisted the most goals in matches where their team lost?
select p.player_id,p.first_name,p.last_name,
count(g.goal_id) as total_goals
from goals as g
join players as p
on g.player_id=p.player_id
join matches as m on 
g.match_id = m.match_id
join teams as t
on t.team_name = m.home_team or t.team_name = m.away_team
where g.assist is not null  and 
((m.home_team = t.team_name and m.home_team_score < m.away_team_score)
or (m.away_team = t.team_name and m.away_team_score < m.home_team_score))
group by p.player_id,p.first_name,p.last_name
order by total_goals desc;

--47] What is the total number of goals scored by players who are positioned as defenders?
select count(g.goal_id) as total_goals
from goals as g
join players as p
on g.player_id=p.player_id
where position='Defender';

--48] Which players scored goals in matches that were held in stadiums with a capacity over 60,000?
select distinct p.player_id,p.first_name,p.last_name
from players as p
join goals as g
on p.player_id=g.player_id
join matches as m
on g.match_id=m.match_id
join stadium as s
on m.stadium=s.name
where s.capacity>60000;

--49] How many goals were scored in matches played in cities with specific stadiums in a season?
select m.season, s.city, count(g.goal_id) as total_goals
from goals as g
join matches as m 
on g.match_id = m.match_id
join stadium as s 
on m.stadium = s.name
group by m.season, s.city
order by total_goals desc;

--50] Which players scored goals in matches with the highest attendance (over 100,000)?
select distinct p.player_id,p.first_name,p.last_name
from goals as g
join matches as m
on g.match_id=m.match_id
join players as p
on p.player_id=g.player_id
where m.attendance>100000;

--51] What is the average number of goals scored by each team in the first 30 minutes of a match?
select t.team_name, 
floor(count(g.goal_id) * 1.0 / count(distinct m.match_id)) as avg_goals
from goals as g
join matches as m
on g.match_id=m.match_id
join teams as t
on m.home_team=t.team_name or m.away_team=t.team_name
where g.duration<30
group by t.team_name
order by avg_goals desc;

--52] Which stadium had the highest average score difference between home and away teams? 
select s.name,avg(abs(m.home_team_score - m.away_team_score)) as avg_score
from matches as m
join stadium as s
on m.stadium = s.name
group by s.name
order by avg_score desc
limit 1;

--53] How many players scored in every match they played during a given season?
select p.player_id, p.first_name, p.last_name
from players as p
join goals as g
on p.player_id = g.player_id
join matches as m
on g.match_id = m.match_id
group by p.player_id, p.first_name, p.last_name
having count(distinct g.match_id) = count(distinct m.match_id);

--54] Which teams won the most matches with a goal difference of 3 or more in the 2021-2022 season?
select t.team_name,count(*) as total_wins
from teams as t
join matches as m
on t.team_name=m.home_team or t.team_name=m.away_team
where abs(m.home_team_score-m.away_team_score)>=3 and season='2021-2022'
group by t.team_name
order by total_wins desc;


--55] Which player from a specific country has the highest goals per match ratio?
select p.player_id,p.first_name,p.last_name,p.nationality,
floor(count(g.goal_id) * 1.0 / count(distinct m.match_id)) as highest_goals
from players as p
join goals as g
on p.player_id=g.player_id
join matches as m
on g.match_id=m.match_id
group by  p.player_id,p.first_name,p.last_name,p.nationality
order by highest_goals desc
limit 1;


--56] What is the correlation between stadium capacity and average match attendance?
select s.name as stadium_name,s.capacity,avg(m.attendance) as avg_attendance
from stadium as s
join matches as m
on s.name = m.stadium
group by s.name, s.capacity;

--57] How many goals did teams score in matches where their home stadium was over 80% full?
select t.team_name, count(g.goal_id) as total_goals
from goals as g
join matches as m
on g.match_id = m.match_id
join teams as t
on m.home_team = t.team_name
join stadium as s
on m.stadium = s.name
where m.attendance > (s.capacity * 0.8)
group by t.team_name
order by total_goals desc;

--58] Which player has scored the most goals in matches played in a specific stadium?
select p.player_id, p.first_name, p.last_name, s.name as stadium_name, 
count(g.goal_id) as total_goals
from goals as g
join players as p 
on g.player_id = p.player_id
join matches as m 
on g.match_id = m.match_id
join stadium as s 
on m.stadium = s.name
group by p.player_id, p.first_name, p.last_name, s.name
order by total_goals desc
limit 1;


--59] How many times did a team lose despite having the highest possession in a match (if possession data were included)?
select count(*) as loss_with_better_performance
from matches as m
join teams as t1 
on t1.team_name = m.home_team or t1.team_name = m.away_team
where ((m.home_team_score < m.away_team_score and m.home_team = t1.team_name) 
or (m.away_team_score < m.home_team_score and m.away_team = t1.team_name));


--60] Which team had the lowest goals conceded average per match in the 2021-2022 season?
select t.team_name, 
avg(case when m.home_team = t.team_name then m.away_team_score
else m.home_team_score end) as avg_goals_conceded
from teams as t
join matches as m
on t.team_name = m.home_team or t.team_name = m.away_team
where m.season = '2021-2022'
group by t.team_name
order by avg_goals_conceded asc
limit 1;










