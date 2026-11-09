class_name PatternGenerator
extends RefCounted
## Generates obstacle "rows" (aligned walls across the three lanes) with a fairness guarantee.
##
## FAIRNESS RULES
##  * Every row leaves at least one lane free.
##  * Each row owns a "zone" [center - eff_half, center + eff_half] that contains all of its obstacles
##    for as long as they are relevant (movers/blocks are bounded by their effective half-width).
##  * Between two zones there is `clear_time` seconds of free space. For EVERY lane a player may
##    legitimately occupy after the previous row, some free lane of the next row must be reachable
##    within that clear time (steps * SWITCH_TIME * step_factor + REACTION_TIME).
##  * If a candidate row violates this it is replaced by one keeping the previous free lanes.
## Crystals are placed along a guaranteed safe path.

const PATTERNS := {
    "slalom": [[0], [2], [0], [2]],
    "slalom_mid": [[0], [1], [2], [1], [0]],
    "tunnel": [[1], [1], [1]],
    "stairs": [[0], [1], [2]],
    "gate": [[0, 1], [1, 2], [0, 1], [1, 2]],
    "rails": [[0, 2], [1], [0, 2]],
}

var rng := RandomNumberGenerator.new()
var prev_free: Array = [0, 1, 2]
var last_end: float = 0.0
var path_lane: int = 1
var row_counter: int = 0
var step_factor: float = 1.0
var queue: Array = []

func reset(seed_value: int, start_angle: float, start_lane: int = 1, factor: float = 1.0) -> void:
    rng.seed = seed_value
    prev_free = [0, 1, 2]
    last_end = start_angle
    path_lane = start_lane
    row_counter = 0
    step_factor = factor
    queue.clear()

## Worst-case number of lane steps needed to go from any lane in `from_free` to some lane in `to_free`.
static func required_steps(from_free: Array, to_free: Array) -> int:
    var worst := 0
    for a in from_free:
        var best := 99
        for b in to_free:
            best = mini(best, absi(int(a) - int(b)))
        worst = maxi(worst, best)
    return worst

static func transition_ok(from_free: Array, to_free: Array, clear_time: float, factor: float) -> bool:
    return OrbitMath.reach_time(required_steps(from_free, to_free), factor) <= clear_time + 0.0001

func _pick_kind(p: Dictionary) -> int:
    var weights := [
        float(p.get("w_static", 1.0)),
        float(p.get("w_moving", 0.0)),
        float(p.get("w_block", 0.0)),
        float(p.get("w_zone", 0.0)),
    ]
    var total := 0.0
    for w in weights:
        total += w
    if total <= 0.0:
        return ObstacleData.Kind.STATIC
    var r := rng.randf() * total
    for i in weights.size():
        r -= weights[i]
        if r <= 0.0:
            return i
    return ObstacleData.Kind.STATIC

func _random_free_set(p: Dictionary) -> Array:
    var lanes := [0, 1, 2]
    var blocked_n := 1
    if rng.randf() < float(p.get("double_chance", 0.0)):
        blocked_n = 2
    for i in range(lanes.size() - 1, 0, -1):
        var j := rng.randi() % (i + 1)
        var tmp = lanes[i]
        lanes[i] = lanes[j]
        lanes[j] = tmp
    var free: Array = []
    for i in range(blocked_n, 3):
        free.append(lanes[i])
    free.sort()
    return free

func _start_pattern(p: Dictionary) -> void:
    var names := PATTERNS.keys()
    var pat_name: String = names[rng.randi() % names.size()]
    queue = (PATTERNS[pat_name] as Array).duplicate(true)
    # Randomly mirror lanes so patterns are not predictable.
    if rng.randf() < 0.5:
        for i in queue.size():
            var mirrored: Array = []
            for l in queue[i]:
                mirrored.append(2 - int(l))
            mirrored.sort()
            queue[i] = mirrored

func _make_obstacle(kind: int, lane: int, center: float, t_spawn: float, omega: float) -> ObstacleData:
    var o := ObstacleData.new()
    o.kind = kind
    o.lane = lane
    o.born = t_spawn
    o.base_angle = center
    match kind:
        ObstacleData.Kind.STATIC:
            o.half = rng.randf_range(0.27, 0.40)
        ObstacleData.Kind.MOVING:
            o.half = rng.randf_range(0.20, 0.28)
            o.amp = rng.randf_range(0.18, 0.34)
            o.freq = rng.randf_range(1.2, 2.0)
            o.phase = rng.randf_range(0.0, TAU)
        ObstacleData.Kind.BLOCK:
            o.half = rng.randf_range(0.15, 0.19)
            o.drift_speed = -rng.randf_range(0.28, 0.45)
            # Start ahead of the zone center so that it travels through the zone toward the player.
            o.base_angle = center + absf(o.drift_speed) * 0.8
        ObstacleData.Kind.ZONE:
            o.half = rng.randf_range(0.45, 0.7)
            o.zone_period = rng.randf_range(1.5, 2.0)
            o.zone_phase = rng.randf_range(0.0, o.zone_period)
            o.zone_active = 0.6
    return o

## Produces the next row. `p` = DifficultyManager.params_at(t). Returns:
## { id, center, eff_half, free, obstacles: Array[ObstacleData], crystals: Array[{angle, lane}] }
func next_row(p: Dictionary, t_spawn: float) -> Dictionary:
    var omega: float = float(p["omega"])
    var clear_time: float = float(p["clear_time"])

    # 1. choose free lanes (pattern step or random), validate fairness
    var free: Array = []
    if queue.is_empty() and rng.randf() < float(p.get("pattern_chance", 0.0)):
        _start_pattern(p)
    if not queue.is_empty():
        free = queue.pop_front()
    else:
        free = _random_free_set(p)
    if not transition_ok(prev_free, free, clear_time, step_factor):
        # try a couple of random alternatives, otherwise keep the previous free lanes (always legal)
        var ok := false
        for _i in 6:
            var cand := _random_free_set(p)
            if transition_ok(prev_free, cand, clear_time, step_factor):
                free = cand
                ok = true
                break
        if not ok:
            free = prev_free.duplicate()
            if free.size() == 3:
                free = [rng.randi() % 3]
        queue.clear()

    # 2. blocked lanes + obstacle kinds
    var primary_kind := _pick_kind(p)
    var mixed := rng.randf() < float(p.get("mixed_chance", 0.0))
    var raw: Array = []
    var eff_half := 0.0
    for lane in 3:
        if free.has(lane):
            continue
        var kind := primary_kind
        if mixed:
            kind = _pick_kind(p)
        var o := _make_obstacle(kind, lane, 0.0, t_spawn, omega)
        raw.append(o)
        eff_half = maxf(eff_half, o.effective_half())
    if raw.is_empty():
        eff_half = 0.2

    # 3. place the zone
    var gap_angle := clear_time * omega
    var zone_start := last_end + gap_angle
    var center := zone_start + eff_half
    for o in raw:
        var od := o as ObstacleData
        if od.kind == ObstacleData.Kind.BLOCK:
            od.base_angle = center + absf(od.drift_speed) * 0.8
        else:
            od.base_angle = center
        od.row_id = row_counter

    # 4. crystals along a safe path
    var new_path := int(free[0])
    var best_d := 99
    for l in free:
        var d := absi(int(l) - path_lane)
        if d < best_d:
            best_d = d
            new_path = int(l)
    var crystals: Array = _plan_crystals(last_end, zone_start, center, path_lane, new_path, gap_angle, clear_time)

    var row := {
        "id": row_counter,
        "center": center,
        "eff_half": eff_half,
        "free": free.duplicate(),
        "obstacles": raw,
        "crystals": crystals,
    }
    prev_free = free.duplicate()
    last_end = center + eff_half
    path_lane = new_path
    row_counter += 1
    return row

func _plan_crystals(gap_start: float, gap_end: float, center: float, from_lane: int, to_lane: int, gap_angle: float, clear_time: float) -> Array:
    var out: Array = []
    var n := clampi(int(gap_angle / 0.34), 0, 5)
    if from_lane == to_lane:
        for i in n:
            var f := (float(i) + 0.5) / float(maxi(n, 1))
            out.append({"angle": lerpf(gap_start, gap_end, f), "lane": to_lane})
    else:
        # Reward the lane change: crystals only in the final stretch, on the destination lane.
        var steps := absi(from_lane - to_lane)
        if OrbitMath.reach_time(steps, step_factor) <= clear_time * 0.8:
            out.append({"angle": lerpf(gap_start, gap_end, 0.78), "lane": to_lane})
            out.append({"angle": lerpf(gap_start, gap_end, 0.92), "lane": to_lane})
    # one crystal threading through the row itself, on the free lane
    out.append({"angle": center, "lane": to_lane})
    return out
