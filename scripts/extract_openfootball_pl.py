import json
import re
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


def parse_round_number(round_name):
    if not round_name:
        return None
    match = re.search(r"\d+", str(round_name))
    return int(match.group()) if match else None


def parse_team(team):
    if isinstance(team, dict):
        return team.get("name") or team, team.get("code")
    return team, None


def extract_scores(match):
    score = match.get("score") or {}
    if "ft" in score:
        home_goals, away_goals = score["ft"]
        home_ht, away_ht = (score.get("ht") or [None, None])
    else:
        home_goals = match.get("score1")
        away_goals = match.get("score2")
        home_ht = match.get("score1i")
        away_ht = match.get("score2i")
    return home_goals, away_goals, home_ht, away_ht


def get_stadium_name(match):
    stadium = match.get("stadium")
    if isinstance(stadium, dict):
        return stadium.get("name")
    return stadium


def build_row(match, season, round_number, round_name):
    home_name, home_code = parse_team(match.get("team1"))
    away_name, away_code = parse_team(match.get("team2"))
    home_goals_ft, away_goals_ft, home_goals_ht, away_goals_ht = extract_scores(match)

    return {
        "season": season,
        "round_number": round_number,
        "round_name": round_name,
        "match_num": match.get("num"),
        "date": match.get("date"),
        "time": match.get("time"),
        "home_team_name": home_name,
        "home_team_code": home_code,
        "away_team_name": away_name,
        "away_team_code": away_code,
        "home_goals_ft": home_goals_ft,
        "away_goals_ft": away_goals_ft,
        "home_goals_ht": home_goals_ht,
        "away_goals_ht": away_goals_ht,
        "stadium_name": get_stadium_name(match),
        "city": match.get("city"),
        "group": match.get("group"),
    }


def extract_matches():
    rows = []
    for season in SEASONS:
        season_file = OPENFOOTBALL_DIR / season / "en.1.json"
        if not season_file.exists():
            print(f"WARNING: {season_file} not found, skipping.")
            continue

        with open(season_file, "r", encoding="utf-8") as f:
            data = json.load(f)

        # Older openfootball structure nests rounds -> matches. Newer files are flat under matches[].
        rounds = data.get("rounds") or []
        if rounds:
            for round_idx, rnd in enumerate(rounds, start=1):
                round_name = rnd.get("name")
                matches = rnd.get("matches") or []
                for match in matches:
                    rows.append(build_row(match, season, round_idx, round_name))
            continue

        matches = data.get("matches") or []
        if matches:
            round_numbers = {}
            next_round_idx = 1
            for match in matches:
                round_name = match.get("round") or match.get("group")
                round_key = round_name or ""
                if round_key not in round_numbers:
                    parsed_round = parse_round_number(round_name)
                    round_numbers[round_key] = parsed_round or next_round_idx
                    next_round_idx += 1
                rows.append(
                    build_row(match, season, round_numbers[round_key], round_name)
                )
            continue

        print(f"WARNING: {season_file} had no rounds or matches, skipping.")

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_PATH, "w", encoding="utf-8") as out_f:
        for r in rows:
            out_f.write(json.dumps(r) + "\n")

    print(f"Wrote {len(rows)} matches to {OUTPUT_PATH}")


if __name__ == "__main__":
    extract_matches()
