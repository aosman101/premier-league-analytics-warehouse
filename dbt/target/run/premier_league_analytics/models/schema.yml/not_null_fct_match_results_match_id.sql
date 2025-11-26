select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select match_id
from `pl-football-analytics`.`football_analytics_football_analytics`.`fct_match_results`
where match_id is null



      
    ) dbt_internal_test