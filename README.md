# Premier League Analytics Warehouse (BigQuery + dbt)

End-to-end football analytics warehouse on Google BigQuery using dbt and GitHub Actions.

**Scope**

- Competition: English Premier League
- Seasons: 2014–15 → 2024–25
- Source: [openfootball/football.json](https://github.com/openfootball/football.json)
- Tech: BigQuery (sandbox), dbt-core, dbt-bigquery, GitHub Actions CI

---

## 1. Architecture

```text
openfootball JSON
    ↓ (Python extractor)
football_raw.pl_matches (BigQuery)
    ↓ (dbt staging)
stg_pl_matches
    ↓ (dbt marts)
dim_team, fct_match_results, fct_team_season_stats


premier-league-analytics-warehouse/
├─ README.md
├─ requirements.txt
├─ scripts/
│  └─ extract_openfootball_pl.py
├─ data/
│  └─ (local raw files, .gitignored)
├─ dbt/
│  ├─ dbt_project.yml
│  ├─ models/
│  │  ├─ staging/
│  │  │  └─ stg_pl_matches.sql
│  │  ├─ marts/
│  │  │  ├─ dim_team.sql
│  │  │  ├─ fct_match_results.sql
│  │  │  └─ fct_team_season_stats.sql
│  │  └─ schema.yml
│  └─ macros/
│     └─ (optional helpers)
├─ ci/
│  └─ profiles.yml
└─ .github/
   └─ workflows/
      └─ dbt-bigquery.yml

