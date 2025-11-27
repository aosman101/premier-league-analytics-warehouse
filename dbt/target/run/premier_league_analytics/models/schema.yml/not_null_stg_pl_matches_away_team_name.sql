
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select away_team_name
from `pl-football-analytics`.`football_analytics_football_analytics_staging`.`stg_pl_matches`
where away_team_name is null



  
  
      
    ) dbt_internal_test