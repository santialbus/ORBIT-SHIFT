extends "res://tests/test_case.gd"

func _obs(lane: int, angle: float, half: float = 0.3, kind: int = ObstacleData.Kind.STATIC) -> ObstacleData:
    var o := ObstacleData.new()
    o.lane = lane
    o.base_angle = angle
    o.half = half
    o.kind = kind
    return o

func test_hit_same_lane_overlapping_angle() -> void:
    var o := _obs(1, 5.0)
    check(CollisionManager.check_hit(5.1, 1.0, [o], 0.0) == o, "hit")

func test_no_hit_other_lane() -> void:
    var o := _obs(1, 5.0)
    check(CollisionManager.check_hit(5.0, 0.0, [o], 0.0) == null, "inner lane is safe")
    check(CollisionManager.check_hit(5.0, 2.0, [o], 0.0) == null, "outer lane is safe")

func test_no_hit_before_or_after() -> void:
    var o := _obs(1, 5.0, 0.3)
    check(CollisionManager.check_hit(4.0, 1.0, [o], 0.0) == null, "not reached yet")
    check(CollisionManager.check_hit(6.0, 1.0, [o], 0.0) == null, "already past")

func test_lane_tolerance_boundary() -> void:
    var o := _obs(1, 5.0)
    check(CollisionManager.check_hit(5.0, 1.0 + OrbitMath.HIT_LANE_TOLERANCE - 0.02, [o], 0.0) == o, "inside tolerance hits")
    check(CollisionManager.check_hit(5.0, 1.0 + OrbitMath.HIT_LANE_TOLERANCE + 0.02, [o], 0.0) == null, "outside tolerance misses")

func test_moving_obstacle_uses_current_angle() -> void:
    var o := _obs(0, 3.0, 0.2, ObstacleData.Kind.MOVING)
    o.amp = 0.3
    o.freq = 1.0
    o.phase = 0.0
    # at t = PI/2, angle = 3.3
    var t := PI / 2.0
    near(o.angle_at(t), 3.3, "oscillation position")
    check(CollisionManager.check_hit(3.3, 0.0, [o], t) == o, "hit at current angle")
    check(CollisionManager.check_hit(2.6, 0.0, [o], t) == null, "no hit at base angle region far away")

func test_orbital_block_drifts_toward_player() -> void:
    var o := _obs(2, 10.0, 0.15, ObstacleData.Kind.BLOCK)
    o.drift_speed = -0.4
    o.born = 0.0
    near(o.angle_at(2.0), 9.2, "drifted backwards")

func test_zone_is_harmless_while_dormant() -> void:
    var o := _obs(1, 5.0, 0.5, ObstacleData.Kind.ZONE)
    o.zone_period = 2.0
    o.zone_phase = 0.0
    o.zone_active = 0.5
    check(o.is_deadly(0.5), "active early in period")
    check(not o.is_deadly(1.5), "dormant late in period")
    check(CollisionManager.check_hit(5.0, 1.0, [o], 1.5) == null, "dormant zone does not hit")
    check(CollisionManager.check_hit(5.0, 1.0, [o], 0.5) == o, "active zone hits")

func test_passed_and_dodged_counting() -> void:
    var o := _obs(1, 5.0, 0.3)
    var r := CollisionManager.collect_passed(4.0, [o], 0.0)
    eq(int(r["dodged"]), 0, "not passed yet")
    r = CollisionManager.collect_passed(5.5, [o], 0.0)
    eq(int(r["dodged"]), 1, "passed once")
    r = CollisionManager.collect_passed(6.0, [o], 0.0)
    eq(int(r["dodged"]), 0, "never counted twice")

func test_near_miss_by_skimming() -> void:
    var o := _obs(1, 5.0, 0.3)
    CollisionManager.track_proximity(5.0, 1.6, [o], 0.0)   # skimmed laterally (0.6 away)
    var r := CollisionManager.collect_passed(5.6, [o], 0.0)
    eq(int(r["near_misses"]), 1, "skim counts as perfect shift")

func test_no_near_miss_when_far_away() -> void:
    var o := _obs(0, 5.0, 0.3)
    CollisionManager.track_proximity(5.0, 2.0, [o], 0.0)   # two lanes away
    var r := CollisionManager.collect_passed(5.6, [o], 0.0)
    eq(int(r["near_misses"]), 0, "far lane is not a near miss")

func test_late_shift_flag_gives_perfect_shift() -> void:
    var o := _obs(1, 5.0, 0.3)
    CollisionManager.mark_shift(4.5, 1, 2.0, [o], 0.0)    # left lane 1 just before the obstacle
    check(o.shift_flag, "shift flagged")
    CollisionManager.track_proximity(5.0, 2.0, [o], 0.0)
    var r := CollisionManager.collect_passed(5.6, [o], 0.0)
    eq(int(r["near_misses"]), 1, "late shift rewarded")

func test_early_shift_not_flagged() -> void:
    var o := _obs(1, 9.0, 0.3)
    CollisionManager.mark_shift(4.0, 1, 2.0, [o], 0.0)    # obstacle is far ahead
    check(not o.shift_flag, "early shift not flagged")
