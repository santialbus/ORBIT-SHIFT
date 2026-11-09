extends "res://tests/test_case.gd"

func test_angle_diff_wraps() -> void:
    near(OrbitMath.angle_diff(0.1, TAU - 0.1), 0.2, "diff across wrap")
    near(OrbitMath.angle_diff(TAU - 0.1, 0.1), -0.2, "negative diff across wrap")

func test_lane_radius_interpolates_and_clamps() -> void:
    near(OrbitMath.lane_radius(0.0), 2.0, "inner")
    near(OrbitMath.lane_radius(2.0), 4.2, "outer")
    near(OrbitMath.lane_radius(0.5), 2.55, "between inner and middle")
    near(OrbitMath.lane_radius(-3.0), 2.0, "clamped low")
    near(OrbitMath.lane_radius(9.0), 4.2, "clamped high")

func test_split_mode_limits() -> void:
    var c := OrbitController.new()
    c.mode = OrbitController.Mode.SPLIT
    c.reset(1)
    check(c.tap(-1), "1 -> 0")
    eq(c.target_lane, 0, "target inner")
    check(not c.tap(-1), "cannot go below lane 0")
    eq(c.target_lane, 0, "still inner")
    check(c.tap(1), "0 -> 1")
    check(c.tap(1), "1 -> 2")
    check(not c.tap(1), "cannot go above lane 2")
    eq(c.target_lane, 2, "still outer")

func test_pingpong_bounces() -> void:
    var c := OrbitController.new()
    c.mode = OrbitController.Mode.PINGPONG
    c.reset(1)
    var seq: Array[int] = []
    for i in 6:
        c.tap(0)
        seq.append(c.target_lane)
    eq(seq, [2, 1, 0, 1, 2, 1] as Array[int], "ping-pong sequence")

func test_transition_is_smooth_and_completes() -> void:
    var c := OrbitController.new()
    c.reset(0)
    c.tap(1)
    var prev := c.lane_pos
    var monotonic := true
    var steps := 0
    while c.is_switching() and steps < 200:
        c.update(1.0 / 60.0)
        if c.lane_pos < prev - 0.0001:
            monotonic = false
        check(absf(c.lane_pos - prev) < 0.2, "no teleporting between frames")
        prev = c.lane_pos
        steps += 1
    check(monotonic, "lane position monotonic")
    near(c.lane_pos, 1.0, "arrives exactly")
    check(float(steps) / 60.0 < 0.25, "transition faster than 0.25 s")

func test_retarget_mid_transition_keeps_input() -> void:
    var c := OrbitController.new()
    c.reset(0)
    c.tap(1)
    for i in 3:
        c.update(1.0 / 60.0)
    check(c.tap(1), "second tap during transition accepted")
    eq(c.target_lane, 2, "retargeted to outer")
    for i in 60:
        c.update(1.0 / 60.0)
    near(c.lane_pos, 2.0, "reaches outer lane")

func test_theta_advances_with_omega() -> void:
    var c := OrbitController.new()
    c.reset(1, 0.0)
    c.omega = 2.0
    for i in 60:
        c.update(1.0 / 60.0)
    near(c.theta, 2.0, "one second at omega 2", 0.001)
