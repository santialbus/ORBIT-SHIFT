class_name MissionLogic
extends RefCounted
## Pure mission logic: daily missions (seeded by the LOCAL date) and progressive objectives.
## Missions never expire punitively: missing a day simply generates new ones.

const TYPES := {
    "crystals":  {"label": "Collect %d crystals",           "targets": [20, 30, 45, 60],        "cumulative": true},
    "survive":   {"label": "Survive %d seconds in one run", "targets": [25, 35, 45, 60],        "cumulative": false},
    "score":     {"label": "Score %d in one run",           "targets": [1500, 2500, 4000, 6000], "cumulative": false},
    "combo":     {"label": "Reach a x%d multiplier",        "targets": [3, 4, 5, 6],            "cumulative": false},
    "dodge":     {"label": "Dodge %d obstacles",            "targets": [30, 50, 80, 120],       "cumulative": true},
    "near_miss": {"label": "Perform %d perfect shifts",     "targets": [3, 5, 8, 12],           "cumulative": true},
}

const PROGRESSIVE := {
    "crystals": {"label": "Total crystals: %d",   "targets": [50, 150, 300, 600, 1000, 1600, 2500, 4000]},
    "dodge":    {"label": "Total dodges: %d",     "targets": [100, 300, 600, 1000, 1800, 3000]},
    "runs":     {"label": "Play %d runs",         "targets": [5, 15, 30, 60, 100, 200]},
    "survive":  {"label": "Survive %d s once",    "targets": [30, 45, 60, 90, 120, 180]},
}
const PROGRESSIVE_REWARDS := [30, 60, 100, 150, 220, 300, 400, 550]

static func today() -> String:
    return Time.get_date_string_from_system()   # local date

static func mission_text(id: String, target: int) -> String:
    return str(TYPES[id]["label"]) % target if TYPES.has(id) else id

static func reward_for(id: String, target: int) -> int:
    match id:
        "crystals": return target + 10
        "survive": return int(target * 1.2)
        "score": return maxi(20, target / 60)
        "combo": return target * 15
        "dodge": return maxi(15, target / 2)
        "near_miss": return target * 6
    return 20

static func generate_daily(date: String) -> Array:
    var rng := RandomNumberGenerator.new()
    rng.seed = date.hash()
    var ids: Array = TYPES.keys()
    for i in range(ids.size() - 1, 0, -1):
        var j := rng.randi() % (i + 1)
        var tmp = ids[i]
        ids[i] = ids[j]
        ids[j] = tmp
    var out: Array = []
    for k in 3:
        var id: String = ids[k]
        var targets: Array = TYPES[id]["targets"]
        # first mission easy, second medium, third harder
        var tier := clampi(k + rng.randi_range(0, 1), 0, targets.size() - 1)
        out.append({"id": id, "target": int(targets[tier]), "progress": 0, "claimed": false})
    return out

## Regenerates daily missions if the stored date differs from `date`. Returns true if refreshed.
static func refresh(data: Dictionary, date: String) -> bool:
    var m: Dictionary = data["missions"]
    if m["date"] == date and (m["daily"] as Array).size() > 0:
        return false
    m["date"] = date
    m["daily"] = generate_daily(date)
    return true

## Applies a finished run. Returns ids of daily missions completed by this run.
static func apply_run(data: Dictionary, run: Dictionary) -> Array:
    var done: Array = []
    for e in data["missions"]["daily"]:
        var id: String = e["id"]
        var before: int = int(e["progress"])
        var target: int = int(e["target"])
        if before >= target:
            continue
        var after := before
        match id:
            "crystals": after = before + int(run.get("crystals", 0))
            "dodge": after = before + int(run.get("dodged", 0))
            "near_miss": after = before + int(run.get("near_misses", 0))
            "survive": after = maxi(before, int(run.get("time", 0.0)))
            "score": after = maxi(before, int(run.get("score", 0)))
            "combo": after = maxi(before, int(run.get("max_multiplier", 1)))
        e["progress"] = mini(after, target)
        if before < target and int(e["progress"]) >= target:
            done.append(id)
    return done

static func claim_daily(data: Dictionary, index: int) -> int:
    var daily: Array = data["missions"]["daily"]
    if index < 0 or index >= daily.size():
        return 0
    var e: Dictionary = daily[index]
    if e["claimed"] or int(e["progress"]) < int(e["target"]):
        return 0
    e["claimed"] = true
    var r := reward_for(e["id"], int(e["target"]))
    data["crystals"] = int(data["crystals"]) + r
    return r

# ---- progressive objectives -------------------------------------------------
static func progressive_value(track: String, data: Dictionary) -> int:
    var st: Dictionary = data["stats"]
    match track:
        "crystals": return int(st["crystals_collected"])
        "dodge": return int(st["dodged"])
        "runs": return int(st["runs"])
        "survive": return int(st["best_time"])
    return 0

static func progressive_tier(track: String, data: Dictionary) -> int:
    return int(data["missions"]["prog_claimed"].get(track, 0))

static func progressive_target(track: String, tier: int) -> int:
    var targets: Array = PROGRESSIVE[track]["targets"]
    if tier < targets.size():
        return int(targets[tier])
    return int(targets[targets.size() - 1]) * (tier - targets.size() + 2)

static func progressive_reward(tier: int) -> int:
    if tier < PROGRESSIVE_REWARDS.size():
        return int(PROGRESSIVE_REWARDS[tier])
    return int(PROGRESSIVE_REWARDS[PROGRESSIVE_REWARDS.size() - 1]) + (tier - PROGRESSIVE_REWARDS.size() + 1) * 100

static func progressive_claimable(track: String, data: Dictionary) -> bool:
    var tier := progressive_tier(track, data)
    return progressive_value(track, data) >= progressive_target(track, tier)

static func claim_progressive(data: Dictionary, track: String) -> int:
    if not PROGRESSIVE.has(track) or not progressive_claimable(track, data):
        return 0
    var tier := progressive_tier(track, data)
    var r := progressive_reward(tier)
    data["missions"]["prog_claimed"][track] = tier + 1
    data["crystals"] = int(data["crystals"]) + r
    return r
