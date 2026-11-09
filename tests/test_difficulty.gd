extends "res://tests/test_case.gd"

func test_config_loads_five_phases() -> void:
    var d := DifficultyManager.new()
    eq((d.config["phases"] as Array).size(), 5, "five phases")

func test_phase_boundaries_match_spec() -> void:
    var d := DifficultyManager.new()
    eq(d.phase_index_at(0.0), 0, "0 s intro")
    eq(d.phase_index_at(14.9), 0, "14.9 s intro")
    eq(d.phase_index_at(15.0), 1, "15 s intermediate")
    eq(d.phase_index_at(30.0), 2, "30 s advanced")
    eq(d.phase_index_at(45.0), 3, "45 s hard")
    eq(d.phase_index_at(60.0), 4, "60 s extreme")
    eq(d.phase_index_at(500.0), 4, "500 s still extreme")

func test_speed_increases_and_clear_time_shrinks() -> void:
    var d := DifficultyManager.new()
    var prev_omega := 0.0
    var prev_clear := 99.0
    for t in range(0, 241, 5):
        var p := d.params_at(float(t))
        check(float(p["omega"]) >= prev_omega - 0.0001, "omega never decreases at t=%d" % t)
        check(float(p["clear_time"]) <= prev_clear + 0.0001, "clear_time never grows at t=%d" % t)
        prev_omega = float(p["omega"])
        prev_clear = float(p["clear_time"])

func test_bounds_respected_in_long_runs() -> void:
    var d := DifficultyManager.new()
    var p := d.params_at(100000.0)
    check(float(p["omega"]) <= float(d.config["omega_max"]) + 0.0001, "omega capped")
    check(float(p["clear_time"]) >= float(d.config["clear_min"]) - 0.0001, "clear_time floored")

func test_clear_time_always_allows_one_lane_change() -> void:
    var d := DifficultyManager.new()
    var need := OrbitMath.reach_time(1, 1.0)
    for t in range(0, 600, 3):
        check(float(d.params_at(float(t))["clear_time"]) >= need, "one lane change always possible at t=%d" % t)

func test_fallback_config_when_missing() -> void:
    var d := DifficultyManager.new("res://does_not_exist.json")
    check(d.config.has("phases"), "fallback config used")
