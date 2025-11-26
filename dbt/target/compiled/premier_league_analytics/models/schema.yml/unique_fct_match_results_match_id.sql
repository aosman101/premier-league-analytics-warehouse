
    
    

with dbt_test__target as (

  select match_id as unique_field
  from `pl-football-analytics`.`football_analytics_football_analytics`.`fct_match_results`
  where match_id is not null

)

select
    unique_field,
    count(*) as n_records

from dbt_test__target
group by unique_field
having count(*) > 1


