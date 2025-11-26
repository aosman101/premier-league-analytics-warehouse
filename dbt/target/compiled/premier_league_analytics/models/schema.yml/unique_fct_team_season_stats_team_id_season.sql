
    
    

with dbt_test__target as (

  select team_id || '-' || season as unique_field
  from `pl-football-analytics`.`football_analytics_football_analytics`.`fct_team_season_stats`
  where team_id || '-' || season is not null

)

select
    unique_field,
    count(*) as n_records

from dbt_test__target
group by unique_field
having count(*) > 1


