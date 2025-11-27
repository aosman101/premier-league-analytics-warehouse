with all_matches as (

    select
      season,
      season_start_year,
      season_end_year,
      match_date,
      home_team_id as team_id,
      home_team_name as team_name,
      'H' as venue,
      home_goals as goals_for,
      away_goals as goals_against,
      home_points as points
    from `pl-football-analytics`.`football_analytics_football_analytics`.`fct_match_results`

    union all

    select
      season,
      season_start_year,
      season_end_year,
      match_date,
      away_team_id as team_id,
      away_team_name as team_name,
      'A' as venue,
      away_goals as goals_for,
      home_goals as goals_against,
      away_points as points
    from `pl-football-analytics`.`football_analytics_football_analytics`.`fct_match_results`

),

agg as (

    select
      team_id,
      team_name,
      season,
      season_start_year,
      season_end_year,

      count(*) as matches_played,
      sum(case when points = 3 then 1 else 0 end) as wins,
      sum(case when points = 1 then 1 else 0 end) as draws,
      sum(case when points = 0 then 1 else 0 end) as losses,

      sum(goals_for) as goals_for,
      sum(goals_against) as goals_against,
      sum(goals_for - goals_against) as goal_diff,
      sum(points) as points,

      sum(case when venue = 'H' then 1 else 0 end) as home_matches,
      sum(case when venue = 'A' then 1 else 0 end) as away_matches
    from all_matches
    group by
      team_id,
      team_name,
      season,
      season_start_year,
      season_end_year
)

select * from agg
  ,
  date(season_start_year, 8, 1) as season_start_date,
  date(season_end_year, 5, 31) as season_end_date
from agg