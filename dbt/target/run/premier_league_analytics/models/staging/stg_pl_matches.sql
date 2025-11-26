

  create or replace view `pl-football-analytics`.`football_analytics_football_analytics_staging`.`stg_pl_matches`
  OPTIONS()
  as with raw as (

    select
      season,
      round_number,
      round_name,
      match_num,
      date,
      time,
      home_team_name,
      home_team_code,
      away_team_name,
      away_team_code,
      home_goals_ft,
      away_goals_ft,
      home_goals_ht,
      away_goals_ht,
      stadium_name,
      city,
      `group`
    from `pl-football-analytics`.`football_raw`.`pl_matches`

),

typed as (

    select
      -- Create a stable ID
      concat(season, '-', cast(match_num as string)) as match_id,

      season,
      safe_cast(split(season, '-')[offset(0)] as int64) as season_start_year,
      safe_cast(split(season, '-')[offset(1)] as int64) as season_end_year,

      round_number,
      round_name,
      match_num,
      safe_cast(date as date) as match_date,
      time as match_time,

      home_team_name,
      home_team_code,
      away_team_name,
      away_team_code,

      safe_cast(home_goals_ft as int64) as home_goals,
      safe_cast(away_goals_ft as int64) as away_goals,
      safe_cast(home_goals_ht as int64) as home_goals_ht,
      safe_cast(away_goals_ht as int64) as away_goals_ht,

      stadium_name,
      city,
      `group` as round_group
    from raw
    where season is not null
      and match_num is not null

)

select * from typed;

