import json
from pathlib import Path

SEASONS = [
    "2014-15",
    "2015-16",
    "2016-17",
    "2017-18",
    "2018-19",
    "2019-20",
    "2020-21",
    "2021-22",
    "2022-23",
    "2023-24",
    "2024-25",
]

BASE_DIR = Path(__file__).resolve().parents[1]
OPENFOOTBALL_DIR = BASE_DIR / "data" / "football.json"
OUTPUT_PATH = BASE_DIR / "data" / "openfootball_pl_matches.ndjson"


def extract_matches():
    rows = []
    for season in SEASONS:
        season_file = OPENFOOTBALL_DIR / season / "en.1.json"
        if not season_file.exists():
            print(f"WARNING: {season_file} not found, skipping.")
            continue

        with open(season_file, "r", encoding="utf-8") as f:
            data = json.load(f)

        rounds = data.get("rounds", [])
        for round_idx, rnd in enumerate(rounds, start=1):
            round_name = rnd.get("name")
            matches = rnd.get("matches", [])

            for m in matches:
                # score variants – euro.json style uses score.ft, some older files use score1/score2
                score = m.get("score", {})
                if "ft" in score:
                    home_goals, away_goals = score["ft"]
                    home_ht, away_ht = (score.get("ht") or [None, None])
                else:
                    home_goals = m.get("score1")
                    away_goals = m.get("score2")
                    home_ht = m.get("score1i")
                    away_ht = m.get("score2i")

                team1 = m.get("team1", {})
                team2 = m.get("team2", {})

                row = {
                    "season": season,
                    "round_number": round_idx,
                    "round_name": round_name,
                    "match_num": m.get("num"),
                    "date": m.get("date"),
                    "time": m.get("time"),
                    "home_team_name": team1.get("name") or team1,
                    "home_team_code": team1.get("code"),
                    "away_team_name": team2.get("name") or team2,
                    "away_team_code": team2.get("code"),
                    "home_goals_ft": home_goals,
                    "away_goals_ft": away_goals,
                    "home_goals_ht": home_ht,
                    "away_goals_ht": away_ht,
                    "stadium_name": (m.get("stadium") or {}).get("name"),
                    "city": m.get("city"),
                    "group": m.get("group"),
                }
                rows.append(row)

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_PATH, "w", encoding="utf-8") as out_f:
        for r in rows:
            out_f.write(json.dumps(r) + "\n")

    print(f"Wrote {len(rows)} matches to {OUTPUT_PATH}")


if __name__ == "__main__":
    extract_matches()
