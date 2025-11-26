select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select match_date
from `pl-football-analytics`.`football_analytics_football_analytics_staging`.`stg_pl_matches`
where match_date is null



      
    ) dbt_internal_test