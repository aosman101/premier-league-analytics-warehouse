
    
    

with all_values as (

    select
        result as value_field,
        count(*) as n_records

    from `pl-football-analytics`.`football_analytics_football_analytics`.`fct_match_results`
    group by result

)

select *
from all_values
where value_field not in (
    'H','A','D'
)


