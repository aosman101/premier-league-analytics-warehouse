# Premier League Analytics Warehouse (BigQuery + dbt)

End-to-end football analytics on Google BigQuery with dbt. The stack pulls Premier League match JSON from openfootball, lands it in BigQuery, and builds cleaned staging + marts for teams, matches, and season stats.

## What’s here now
- Seasons: English Premier League 2014–15 → 2024–25 (JSON lives in `data/football.json/`).
- Extractor: `scripts/extract_openfootball_pl.py` writes `data/openfootball_pl_matches.ndjson`.
- Raw table target: `football_raw.pl_matches` in BigQuery (loaded from the NDJSON).
- dbt models: `stg_pl_matches`, `dim_team`, `fct_match_results`, `fct_team_season_stats` plus schema tests; deployed to dataset `football_analytics_football_analytics` in project `pl-football-analytics` (with the current profile + schema config).
- CI profile: `ci/profiles.yml` (BigQuery; service-account path from `GCP_SERVICE_ACCOUNT_FILE`).
- Hygiene: virtualenvs/dbt logs/logs ignored via `.gitignore` to keep secrets/artifacts out of Git.

## Data flow
```text
openfootball JSON (data/football.json)
        │  python scripts/extract_openfootball_pl.py
        ▼
openfootball_pl_matches.ndjson (local)
        │  bq load --autodetect
        ▼
football_raw.pl_matches (BigQuery raw)
        │  dbt run
        ▼
stg_pl_matches
        │
        ├─ dim_team
        ├─ fct_match_results
        └─ fct_team_season_stats
```

## Quickstart (copy/paste friendly)
```bash
# 1) Create a virtualenv and install deps (Python 3.11+)
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# 2) Extract raw matches from openfootball JSON to NDJSON
python scripts/extract_openfootball_pl.py
# -> writes data/openfootball_pl_matches.ndjson

# 3) Create BigQuery datasets (adjust location if needed)
bq --location=EU mk -d football_raw || true
# With the current profile (+ schema "football_analytics"), dbt materializes into
# dataset "football_analytics_football_analytics" under your project:
bq --location=EU mk -d football_analytics_football_analytics || true

# 4) Load raw data into BigQuery
bq load --source_format=NEWLINE_DELIMITED_JSON --autodetect \
  football_raw.pl_matches ./data/openfootball_pl_matches.ndjson

# 5) Configure dbt profile (~/.dbt/profiles.yml)
```
```yaml
premier_league_analytics:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: service-account
      keyfile: "/absolute/path/to/your/service-account.json"  # or path from env
      project: "pl-football-analytics"
      dataset: "football_analytics"
      location: "EU"
      threads: 4
      priority: interactive
```
```bash
# 6) Build + test
cd dbt
dbt build   # run + test
# or
dbt run
dbt test
```

## Verification queries (copy/paste)
```bash
# Teams per season (sanity check on coverage)
bq query --use_legacy_sql=false 'select season, count(distinct team_name) as teams from `pl-football-analytics.football_analytics_football_analytics.fct_team_season_stats` group by season order by season'

# Match counts per season
bq query --use_legacy_sql=false 'select season, count(*) as matches from `pl-football-analytics.football_analytics_football_analytics.fct_match_results` group by season order by season'

# Top 5 table for 2018–19
bq query --use_legacy_sql=false 'select season, team_name, matches_played, wins, draws, losses, goals_for, goals_against, goal_diff, points from `pl-football-analytics.football_analytics_football_analytics.fct_team_season_stats` where season = "2018-19" order by points desc, goal_diff desc, goals_for desc limit 5'

# Top 5 table for 2022–23
bq query --use_legacy_sql=false 'select season, team_name, matches_played, wins, draws, losses, goals_for, goals_against, goal_diff, points from `pl-football-analytics.football_analytics_football_analytics.fct_team_season_stats` where season = "2022-23" order by points desc, goal_diff desc, goals_for desc limit 5'

# Title winners 2014–15 through 2024–25 (counts + share of seasons)
bq query --use_legacy_sql=false '
with ranked as (
  select season, team_name,
    row_number() over (partition by season order by points desc, goal_diff desc, goals_for desc) as rn
  from `pl-football-analytics.football_analytics_football_analytics.fct_team_season_stats`
  where season between "2014-15" and "2024-25"
),
champions as (select season, team_name from ranked where rn = 1),
season_count as (select count(distinct season) as seasons from champions)
select c.team_name, count(*) as titles,
  round(count(*) * 100.0 / s.seasons, 1) as title_pct
from champions c
cross join season_count s
group by c.team_name, s.seasons
order by titles desc, team_name
'

# Best attacks and defenses across all seasons (goals for/against per match)
bq query --use_legacy_sql=false '
with filtered as (
  select season, team_name, goals_for, goals_against, matches_played
  from `pl-football-analytics.football_analytics_football_analytics.fct_team_season_stats`
  where season between "2014-15" and "2024-25"
),
summary as (
  select
    team_name,
    count(*) as seasons,
    sum(goals_for) as total_gf,
    sum(goals_against) as total_ga,
    sum(matches_played) as total_mp,
    sum(goals_for) / sum(matches_played) as gf_per_match,
    sum(goals_against) / sum(matches_played) as ga_per_match
  from filtered
  group by team_name
),
attack as (
  select *, row_number() over (order by gf_per_match desc, ga_per_match asc, team_name) as rk
  from summary
),
defence as (
  select *, row_number() over (order by ga_per_match asc, gf_per_match desc, team_name) as rk
  from summary
)
select
  "attack" as category,
  team_name,
  seasons,
  round(gf_per_match, 3) as goals_for_per_match,
  round(ga_per_match, 3) as goals_against_per_match,
  rk as rank
from attack
where rk <= 5
union all
select
  "defence" as category,
  team_name,
  seasons,
  round(gf_per_match, 3) as goals_for_per_match,
  round(ga_per_match, 3) as goals_against_per_match,
  rk as rank
from defence
where rk <= 5
order by category, rank
'
```

## dbt models (what they do)
- `stg_pl_matches`: cleans/types raw fields, parses dates/times, and builds stable `match_id`.
- `dim_team`: distinct team dimension (home/away union) with generated UUID `team_id`.
- `fct_match_results`: match-level fact with team ids, result flag (H/A/D), and points.
- `fct_team_season_stats`: per-team, per-season aggregates (matches, wins/draws/losses, goals, points).
- `schema.yml`: source definition for `football_raw.pl_matches` plus tests on the above models.

## CI usage
- Profile: `ci/profiles.yml` (target `ci`) expects `GCP_SERVICE_ACCOUNT_FILE` env var pointing to the service account JSON file path.
- Example (GitHub Actions step):
```bash
dbt build --profiles-dir ci --target ci
```

## Repository layout (high level)
```text
premier-league-analytics-warehouse/
├─ README.md
├─ requirements.txt
├─ scripts/
│  └─ extract_openfootball_pl.py
├─ data/                      # openfootball JSON + generated NDJSON
├─ dbt/
│  ├─ dbt_project.yml
│  └─ models/ (staging + marts + schema tests)
└─ ci/
   └─ profiles.yml            # CI dbt profile (BigQuery)
```

## Tips & hygiene
- Keep secrets out of Git: rely on `GCP_SERVICE_ACCOUNT_FILE` and never commit service-account keys.
- Virtualenvs, dbt targets, and logs are ignored via `.gitignore`; keep using them to avoid noisy commits.
- When adding new models, prefer `dbt build --select new_model+` to include downstream dependencies and tests.
