# Premier League Analytics Warehouse (BigQuery + dbt)

End-to-end football analytics on Google BigQuery with dbt. Data flows from openfootball JSON into a clean staging layer and marts covering teams, matches, and season stats.

## Scope at a glance
- Competition: English Premier League (2014–15 → 2024–25)
- Source: [openfootball/football.json](https://github.com/openfootball/football.json)
- Stack: BigQuery, dbt-core, dbt-bigquery, GitHub Actions CI profile ready

## Data flow
```text
openfootball JSON (extracted via scripts/)
        ↓
football_raw.pl_matches (BigQuery raw)
        ↓  dbt staging
stg_pl_matches
        ↓  dbt marts
dim_team, fct_match_results, fct_team_season_stats
```

## Project layout
```text
premier-league-analytics-warehouse/
├─ README.md
├─ requirements.txt
├─ scripts/
│  └─ extract_openfootball_pl.py
├─ data/                      # local raw files (.gitignored)
├─ dbt/
│  ├─ dbt_project.yml
│  └─ models/
│     ├─ schema.yml           # sources + tests
│     ├─ staging/
│     │  └─ stg_pl_matches.sql
│     └─ marts/
│        ├─ dim_team.sql
│        ├─ fct_match_results.sql
│        └─ fct_team_season_stats.sql
└─ ci/
   └─ profiles.yml            # CI-only dbt profile (BigQuery)
```

## Models in place
- `stg_pl_matches`: types raw match fields, builds stable `match_id`, parses dates, and exposes cleaned columns.
- `dim_team`: distinct team dimension (home/away union) with generated `team_id`.
- `fct_match_results`: match-level fact with team ids, results (H/A/D), and match points.
- `fct_team_season_stats`: per-team, per-season rollups for matches, results, goals, and points.
- `schema.yml`: source definition for `football_raw.pl_matches` plus tests on the above models.

## Local setup
1) Install deps (Python 3.11+):
```bash
pip install -r requirements.txt
```
2) Configure dbt profile for development (`~/.dbt/profiles.yml`):
```yaml
premier_league_analytics:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: service-account
      keyfile: "/absolute/path/to/your/service-account.json"
      project: "pl-football-analytics"
      dataset: "football_analytics"
      location: "EU"
      threads: 4
      priority: interactive
```

## Running dbt locally
```bash
cd dbt
dbt run       # build staging + marts
dbt test      # run schema tests
dbt run --select stg_pl_matches dim_team fct_match_results fct_team_season_stats
```

## CI profile (GitHub Actions ready)
- File: `ci/profiles.yml`
- Uses `premier_league_analytics` target `ci` with `service-account-json`.
- Reads the service account JSON from an environment variable: `7d994e79a010ca9c0ee90da958543c43d7d6a6fc`.
- Example invocation in CI:
```bash
dbt run --profiles-dir ci --target ci
dbt test --profiles-dir ci --target ci
```

## What’s next?
- Add a `.github/workflows` pipeline to run `dbt run`/`dbt test` using `ci/profiles.yml`.
- Expand marts (form tables, player stats) and add coverage tests/alerts.
