class_name AchievementLogic
extends RefCounted
## Extensible achievement table: add an entry to LIST and it is evaluated automatically.
## `key` refers to a value of the snapshot built by snapshot().

const LIST := [
    {"id": "first_orbit",    "name": "First Orbit",    "desc": "Finish your first run.",            "key": "runs",           "target": 1,     "reward": 20},
    {"id": "survivor",       "name": "Survivor",       "desc": "Survive 60 seconds in one run.",    "key": "run_time",       "target": 60,    "reward": 60},
    {"id": "marathon",       "name": "Marathon",       "desc": "Survive 120 seconds in one run.",   "key": "run_time",       "target": 120,   "reward": 150},
    {"id": "crystal_hunter", "name": "Crystal Hunter", "desc": "Collect 100 crystals in total.",    "key": "crystals_collected", "target": 100, "reward": 50},
    {"id": "crystal_baron",  "name": "Crystal Baron",  "desc": "Collect 1,000 crystals in total.",  "key": "crystals_collected", "target": 1000, "reward": 200},
    {"id": "combo_starter",  "name": "Chain Reaction", "desc": "Reach a x4 multiplier.",            "key": "best_combo",     "target": 4,     "reward": 30},
    {"id": "combo_master",   "name": "Combo Master",   "desc": "Reach the x8 multiplier.",          "key": "best_combo",     "target": 8,     "reward": 150},
    {"id": "perfect_shift",  "name": "Perfect Shift",  "desc": "Make 5 perfect shifts in one run.", "key": "run_near_misses", "target": 5,    "reward": 60},
    {"id": "hundred_runs",   "name": "100 Runs",       "desc": "Play 100 runs.",                    "key": "runs",           "target": 100,   "reward": 250},
    {"id": "high_scorer",    "name": "High Scorer",    "desc": "Reach a personal best of 10,000.",  "key": "record",         "target": 10000, "reward": 120},
    {"id": "dodger",         "name": "Untouchable",    "desc": "Dodge 500 obstacles in total.",     "key": "dodged",         "target": 500,   "reward": 100},
    {"id": "collector",      "name": "Collector",      "desc": "Own 5 sphere skins.",               "key": "skins_unlocked", "target": 5,     "reward": 80},
    {"id": "record_breaker", "name": "Record Breaker", "desc": "Break your record 5 times.",        "key": "records_broken", "target": 5,     "reward": 80},
    {"id": "core_tuner",     "name": "Core Tuner",     "desc": "Own 2 core variants.",              "key": "cores_unlocked", "target": 2,     "reward": 60},
]

static func snapshot(data: Dictionary, run: Dictionary = {}) -> Dictionary:
    var st: Dictionary = data["stats"]
    return {
        "runs": int(st["runs"]),
        "crystals_collected": int(st["crystals_collected"]),
        "best_combo": int(st["best_combo"]),
        "dodged": int(st["dodged"]),
        "records_broken": int(st["records_broken"]),
        "record": int(data["record"]),
        "skins_unlocked": (data["skins"] as Array).size(),
        "cores_unlocked": (data["cores"] as Array).size(),
        "run_time": float(run.get("time", 0.0)),
        "run_near_misses": int(run.get("near_misses", 0)),
    }

static func progress_of(def: Dictionary, snap: Dictionary) -> float:
    return float(snap.get(def["key"], 0))

## Unlocks every newly satisfied achievement, pays its reward. Returns the list of newly unlocked defs.
static func evaluate(data: Dictionary, run: Dictionary = {}) -> Array:
    var snap := snapshot(data, run)
    var unlocked: Array = []
    for def in LIST:
        if data["achievements"].has(def["id"]):
            continue
        if progress_of(def, snap) >= float(def["target"]):
            data["achievements"][def["id"]] = true
            data["crystals"] = int(data["crystals"]) + int(def["reward"])
            unlocked.append(def)
    return unlocked
