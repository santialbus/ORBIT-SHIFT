extends "res://tests/test_case.gd"

func test_ids_unique_and_extensible_table() -> void:
    var seen := {}
    for def in AchievementLogic.LIST:
        check(not seen.has(def["id"]), "unique " + def["id"])
        seen[def["id"]] = true
    for required in ["first_orbit", "survivor", "crystal_hunter", "combo_master", "perfect_shift", "hundred_runs"]:
        check(seen.has(required), "spec achievement present: " + required)

func test_first_orbit_unlocks_after_first_run_and_pays() -> void:
    var d := SaveData.defaults()
    var run := {"score": 100, "time": 10.0, "crystals": 1, "max_multiplier": 1, "dodged": 3, "near_misses": 0}
    ProgressionLogic.apply_run(d, run)
    var before: int = d["crystals"]
    var unlocked := AchievementLogic.evaluate(d, run)
    eq(unlocked.size(), 1, "one achievement")
    eq(unlocked[0]["id"], "first_orbit", "first orbit")
    eq(d["crystals"], before + int(unlocked[0]["reward"]), "reward paid")
    eq(AchievementLogic.evaluate(d, run).size(), 0, "never unlocked twice")

func test_run_based_achievements() -> void:
    var d := SaveData.defaults()
    var run := {"score": 5000, "time": 65.0, "crystals": 10, "max_multiplier": 3, "dodged": 40, "near_misses": 6}
    ProgressionLogic.apply_run(d, run)
    var ids: Array = []
    for def in AchievementLogic.evaluate(d, run):
        ids.append(def["id"])
    check(ids.has("survivor"), "survivor at 60 s")
    check(ids.has("perfect_shift"), "perfect shift x5")
    check(not ids.has("marathon"), "marathon needs 120 s")
    check(not ids.has("combo_master"), "combo master needs x8")

func test_cumulative_achievements() -> void:
    var d := SaveData.defaults()
    d["stats"]["crystals_collected"] = 100
    d["stats"]["runs"] = 100
    d["stats"]["best_combo"] = 8
    var ids: Array = []
    for def in AchievementLogic.evaluate(d, {}):
        ids.append(def["id"])
    for want in ["crystal_hunter", "hundred_runs", "combo_master", "combo_starter", "first_orbit"]:
        check(ids.has(want), "unlocked " + want)

func test_collector_from_purchases() -> void:
    var d := SaveData.defaults()
    d["skins"] = ["cyan_core", "plasma", "solar", "violet_pulse", "inferno"]
    var ids: Array = []
    for def in AchievementLogic.evaluate(d, {}):
        ids.append(def["id"])
    check(ids.has("collector"), "5 skins unlock collector")
