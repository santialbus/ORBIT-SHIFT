extends "res://tests/test_case.gd"

func test_daily_missions_are_deterministic_per_date() -> void:
    var a := MissionLogic.generate_daily("2026-11-08")
    var b := MissionLogic.generate_daily("2026-11-08")
    eq(a, b, "same date same missions")
    eq(a.size(), 3, "three daily missions")
    var ids := {}
    for m in a:
        ids[m["id"]] = true
    eq(ids.size(), 3, "distinct mission types")

func test_missions_differ_across_days() -> void:
    var seen := {}
    for day in range(1, 29):
        var m := MissionLogic.generate_daily("2026-11-%02d" % day)
        seen[str(m)] = true
    check(seen.size() > 5, "missions vary between days")

func test_refresh_only_on_new_date() -> void:
    var d := SaveData.defaults()
    check(MissionLogic.refresh(d, "2026-11-08"), "first refresh generates")
    d["missions"]["daily"][0]["progress"] = 5
    check(not MissionLogic.refresh(d, "2026-11-08"), "same day keeps progress")
    eq(d["missions"]["daily"][0]["progress"], 5, "progress kept")
    check(MissionLogic.refresh(d, "2026-11-09"), "new day regenerates")
    eq(d["missions"]["daily"][0]["progress"], 0, "progress reset on new day")

func test_progress_and_claim() -> void:
    var d := SaveData.defaults()
    d["missions"]["date"] = "x"
    d["missions"]["daily"] = [
        {"id": "crystals", "target": 20, "progress": 0, "claimed": false},
        {"id": "score", "target": 1500, "progress": 0, "claimed": false},
        {"id": "combo", "target": 3, "progress": 0, "claimed": false},
    ]
    var done := MissionLogic.apply_run(d, {"crystals": 12, "score": 2000, "max_multiplier": 2, "time": 30.0})
    eq(done, ["score"], "only the score mission completed")
    eq(d["missions"]["daily"][0]["progress"], 12, "cumulative progress")
    eq(d["missions"]["daily"][2]["progress"], 2, "best-of progress")
    MissionLogic.apply_run(d, {"crystals": 12, "score": 100, "max_multiplier": 1, "time": 5.0})
    eq(d["missions"]["daily"][0]["progress"], 20, "progress capped at target")
    eq(MissionLogic.claim_daily(d, 2), 0, "cannot claim unfinished")
    var before: int = d["crystals"]
    var reward := MissionLogic.claim_daily(d, 1)
    check(reward > 0, "reward paid")
    eq(d["crystals"], before + reward, "crystals credited")
    eq(MissionLogic.claim_daily(d, 1), 0, "cannot claim twice")

func test_progressive_objectives() -> void:
    var d := SaveData.defaults()
    check(not MissionLogic.progressive_claimable("runs", d), "not claimable at 0 runs")
    d["stats"]["runs"] = 5
    check(MissionLogic.progressive_claimable("runs", d), "claimable at 5 runs")
    var r := MissionLogic.claim_progressive(d, "runs")
    eq(r, MissionLogic.progressive_reward(0), "tier 0 reward")
    eq(MissionLogic.progressive_tier("runs", d), 1, "tier advanced")
    check(not MissionLogic.progressive_claimable("runs", d), "next tier needs 15 runs")
    eq(MissionLogic.claim_progressive(d, "runs"), 0, "no double claim")
    check(MissionLogic.progressive_target("runs", 50) > MissionLogic.progressive_target("runs", 5), "tiers keep growing forever")

func test_rewards_are_balanced() -> void:
    for id in MissionLogic.TYPES.keys():
        var targets: Array = MissionLogic.TYPES[id]["targets"]
        var prev := 0
        for t in targets:
            var r := MissionLogic.reward_for(id, int(t))
            check(r >= prev and r > 0 and r < 400, "reward grows with difficulty for " + id)
            prev = r
