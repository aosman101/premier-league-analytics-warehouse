{{ config(materialized='table', alias='mf_time_spine') }}

-- Time spine for MetricFlow (daily grain).
with spine as (
  select day as date_day
  from unnest(generate_date_array(date '2014-07-01', date '2025-06-30', interval 1 day)) as day
)

select * from spine
