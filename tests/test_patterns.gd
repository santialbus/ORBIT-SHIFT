extends "res://tests/test_case.gd"

func _rows(seed_value: int, count: int, factor: float) -> Array:
    var diff := DifficultyManager.new()
    var gen := PatternGenerator.new()
    gen.reset(seed_value, 0.0, 1, factor)
    var out: Array = []
    var t := 0.0
    for i in count:
        var p := diff.params_at(t)
        out.append({"row": gen.next_row(p, t), "p": p})
        t += float(p["clear_time"]) + 0.6   # rough time advance
    return out

func test_every_row_has_a_free_lane_and_consistent_blocking() -> void:
    for s in 40:
        for entry in _rows(1000 + s, 120, 1.0):
            var row: Dictionary = entry["row"]
            var free: Array = row["free"]
            check(free.size() >= 1 and free.size() <= 3, "free lanes 1..3")
            eq((row["obstacles"] as Array).size(), 3 - free.size(), "blocked count = 3 - free")
            for o in row["obstacles"]:
                check(not free.has((o as ObstacleData).lane), "no obstacle on a free lane")

func test_transitions_are_always_reachable() -> void:
    for factor in [1.0, 1.9]:
        for s in 40:
            var prev_free: Array = [0, 1, 2]
            for entry in _rows(2000 + s, 150, factor):
                var row: Dictionary = entry["row"]
                var p: Dictionary = entry["p"]
                check(PatternGenerator.transition_ok(prev_free, row["free"], float(p["clear_time"]), factor),
                    "reachable transition (seed %d factor %.1f)" % [s, factor])
                prev_free = row["free"]

func test_zones_do_not_overlap_and_keep_clear_gap() -> void:
    for s in 20:
        var last_end := -INF
        var first := true
        for entry in _rows(3000 + s, 100, 1.0):
            var row: Dictionary = entry["row"]
            var p: Dictionary = entry["p"]
            var start: float = float(row["center"]) - float(row["eff_half"])
            if not first:
                var gap_time: float = (start - last_end) / float(p["omega"])
                check(gap_time >= float(p["clear_time"]) - 0.001, "clear gap kept (%.3f s)" % gap_time)
            last_end = float(row["center"]) + float(row["eff_half"])
            first = false

func test_obstacles_stay_inside_their_zone() -> void:
    for entry in _rows(77, 300, 1.0):
        var row: Dictionary = entry["row"]
        var lo: float = float(row["center"]) - float(row["eff_half"]) - 0.001
        var hi: float = float(row["center"]) + float(row["eff_half"]) + 0.001
        for o in row["obstacles"]:
            var od := o as ObstacleData
            # sample the whole life of the obstacle
            var t := od.born
            while t < od.born + 3.0:
                var a := od.angle_at(t)
                var left := a - od.half
                var right := a + od.half
                # BLOCK obstacles may leave the zone only after the player has passed (late life); check first 1.8 s
                if t < od.born + 1.8 or od.kind != ObstacleData.Kind.BLOCK:
                    check(left >= lo - 0.2 and right <= hi + 0.2, "obstacle within zone (kind %d t+%.1f)" % [od.kind, t - od.born])
                t += 0.1

func test_generation_is_deterministic_per_seed() -> void:
    var a := _rows(555, 50, 1.0)
    var b := _rows(555, 50, 1.0)
    for i in a.size():
        eq(a[i]["row"]["free"], b[i]["row"]["free"], "same seed same free set")
        near(float(a[i]["row"]["center"]), float(b[i]["row"]["center"]), "same seed same center")

func test_variety_of_obstacle_kinds_appears_late_game() -> void:
    var kinds := {}
    var diff := DifficultyManager.new()
    var gen := PatternGenerator.new()
    gen.reset(9, 0.0, 1, 1.0)
    for i in 400:
        var row := gen.next_row(diff.params_at(70.0), 70.0)
        for o in row["obstacles"]:
            kinds[(o as ObstacleData).kind] = true
    eq(kinds.size(), 4, "static, moving, block and zone obstacles all generated")

func test_crystals_lie_on_free_lane_of_row_center() -> void:
    for entry in _rows(31, 200, 1.0):
        var row: Dictionary = entry["row"]
        var last: Dictionary = (row["crystals"] as Array).back()
        check((row["free"] as Array).has(int(last["lane"])), "threading crystal sits on a free lane")
