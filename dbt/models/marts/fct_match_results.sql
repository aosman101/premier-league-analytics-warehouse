with matches as (

    select
      m.*,
      t_home.team_id as home_team_id,
      t_away.team_id as away_team_id
    from {{ ref('stg_pl_matches') }} m
    left join {{ ref('dim_team') }} t_home
      on m.home_team_name = t_home.team_name
    left join {{ ref('dim_team') }} t_away
      on m.away_team_name = t_away.team_name

),

results as (

    select
      match_id,
      season,
      season_start_year,
      season_end_year,
      match_date,
      round_number,
      round_name,

      home_team_id,
      home_team_name,
      away_team_id,
      away_team_name,

      home_goals,
      away_goals,

      case
        when home_goals > away_goals then 'H'
        when home_goals < away_goals then 'A'
        when home_goals = away_goals then 'D'
        else null
      end as result,

      case
        when home_goals > away_goals then 3
        when home_goals = away_goals then 1
        else 0
      end as home_points,

      case
        when away_goals > home_goals then 3
        when home_goals = away_goals then 1
        else 0
      end as away_points
    from matches

)

select * from results;
