with teams as (

    select
      home_team_name as team_name,
      home_team_code as team_code
    from `pl-football-analytics`.`football_analytics_football_analytics_staging`.`stg_pl_matches`

    union distinct

    select
      away_team_name as team_name,
      away_team_code as team_code
    from `pl-football-analytics`.`football_analytics_football_analytics_staging`.`stg_pl_matches`

),

final as (

    select
      -- Deterministic ID so it stays stable across builds
      to_hex(md5(lower(trim(team_name)))) as team_id,
      team_name,
      team_code
    from teams

)

select * from final