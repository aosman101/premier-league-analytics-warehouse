select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select team_id
from `pl-football-analytics`.`football_analytics_football_analytics`.`dim_team`
where team_id is null



      
    ) dbt_internal_test