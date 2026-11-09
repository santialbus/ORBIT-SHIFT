extends "res://tests/test_case.gd"
## Continuous-time fairness proof: a bot with human-like reaction time must survive generated levels.

func test_bot_survives_three_minutes_split_controls() -> void:
    var fails := 0
    for s in 12:
        var r := SimRun.run(10000 + s, 180.0, 0.15, OrbitController.Mode.SPLIT)
        if not r["survived"]:
            fails += 1
            failures.append("seed %d died at %.1f s (kind %s lane %s) %s" % [s, float(r["time"]), str(r.get("hit_kind")), str(r.get("hit_lane")), str(r.get("error", ""))])
        assertions += 1
    eq(fails, 0, "bot deaths with split controls")

func test_bot_survives_one_tap_mode() -> void:
    var fails := 0
    for s in 8:
        var r := SimRun.run(20000 + s, 150.0, 0.12, OrbitController.Mode.PINGPONG)
        if not r["survived"]:
            fails += 1
            failures.append("seed %d died at %.1f s (kind %s lane %s)" % [s, float(r["time"]), str(r.get("hit_kind")), str(r.get("hit_lane"))])
        assertions += 1
    eq(fails, 0, "bot deaths with one-tap controls")

func test_late_game_reaches_extreme_speed_and_scores() -> void:
    var r := SimRun.run(4242, 200.0, 0.15)
    check(r["survived"], "survived 200 s")
    check(float(r["max_omega"]) > 2.4, "omega grows beyond 2.4 rad/s")
    check(int(r["score"]) > 1000, "score accumulates")
    check(int(r["rows"]) > 120, "many rows generated")

func test_idle_player_dies_early() -> void:
    # Sanity check that the game is not trivially safe: a player that never moves must collide.
    var diff := DifficultyManager.new()
    var gen := PatternGenerator.new()
    var orbit := OrbitController.new()
    orbit.reset(1, -PI / 2.0)
    gen.reset(3, orbit.theta + 1.5, 1, 1.0)
    var obstacles: Array = []
    var t := 0.0
    var died := false
    while t < 60.0 and not died:
        t += 1.0 / 60.0
        var p := diff.params_at(t)
        orbit.omega = float(p["omega"])
        orbit.update(1.0 / 60.0)
        while gen.last_end + float(p["clear_time"]) * float(p["omega"]) <= orbit.theta + OrbitMath.LEAD_ANGLE:
            for o in gen.next_row(p, t)["obstacles"]:
                obstacles.append(o)
        if CollisionManager.check_hit(orbit.theta, orbit.lane_pos, obstacles, t) != null:
            died = true
    check(died, "idle player collides within 60 s")
    check(t < 45.0, "idle player dies before 45 s (died at %.1f)" % t)
