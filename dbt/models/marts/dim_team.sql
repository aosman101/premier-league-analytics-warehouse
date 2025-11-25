with teams as (

    select
      home_team_name as team_name,
      home_team_code as team_code
    from {{ ref('stg_pl_matches') }}

    union distinct

    select
      away_team_name as team_name,
      away_team_code as team_code
    from {{ ref('stg_pl_matches') }}

),

final as (

    select
      generate_uuid() as team_id,
      team_name,
      team_code
    from teams

)

select * from final;
