with raw as (

    select
      season,
      round_number,
      round_name,
      match_num,
      date,
      time,
      home_team_name,
      home_team_code,
      away_team_name,
      away_team_code,
      home_goals_ft,
      away_goals_ft,
      home_goals_ht,
      away_goals_ht,
      stadium_name,
      city,
      `group`
    from {{ source('football_raw', 'pl_matches') }}

),

typed as (

    select
      -- Create a stable ID even when match_num is missing by hashing key fields
      to_hex(
        md5(
          concat(
            season,
            '-',
            coalesce(cast(match_num as string), ''),
            '-',
            coalesce(cast(round_number as string), ''),
            '-',
            coalesce(format_date('%F', safe_cast(date as date)), ''),
            '-',
            coalesce(time, ''),
            '-',
            coalesce(home_team_name, ''),
            '-',
            coalesce(away_team_name, '')
          )
        )
      ) as match_id,

      season,
      safe_cast(split(season, '-')[offset(0)] as int64) as season_start_year,
      safe_cast(split(season, '-')[offset(1)] as int64) as season_end_year,

      round_number,
      round_name,
      safe_cast(match_num as int64) as match_num,
      safe_cast(date as date) as match_date,
      time as match_time,

      home_team_name,
      home_team_code,
      away_team_name,
      away_team_code,

      safe_cast(home_goals_ft as int64) as home_goals,
      safe_cast(away_goals_ft as int64) as away_goals,
      safe_cast(home_goals_ht as int64) as home_goals_ht,
      safe_cast(away_goals_ht as int64) as away_goals_ht,

      stadium_name,
      city,
      `group` as round_group
    from raw
    where season is not null

),

deduped as (

    select
      *,
      row_number() over (
        partition by match_id
        order by match_date desc, match_time desc, round_number desc
      ) as row_num
    from typed

)

select
  match_id,
  season,
  season_start_year,
  season_end_year,
  round_number,
  round_name,
  match_num,
  match_date,
  match_time,
  home_team_name,
  home_team_code,
  away_team_name,
  away_team_code,
  home_goals,
  away_goals,
  home_goals_ht,
  away_goals_ht,
  stadium_name,
  city,
  round_group
from deduped
where row_num = 1
