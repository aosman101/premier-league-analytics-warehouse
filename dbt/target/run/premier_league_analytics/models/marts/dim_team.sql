
  
    

    create or replace table `pl-football-analytics`.`football_analytics_football_analytics`.`dim_team`
      
    
    

    OPTIONS()
    as (
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
      generate_uuid() as team_id,
      team_name,
      team_code
    from teams

)

select * from final
    );
  