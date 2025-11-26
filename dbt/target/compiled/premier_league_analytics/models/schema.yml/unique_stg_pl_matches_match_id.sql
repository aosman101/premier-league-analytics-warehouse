
    
    

with dbt_test__target as (

  select match_id as unique_field
  from `pl-football-analytics`.`football_analytics_football_analytics_staging`.`stg_pl_matches`
  where match_id is not null

)

select
    unique_field,
    count(*) as n_records

from dbt_test__target
group by unique_field
having count(*) > 1


