class_name CollisionManager
extends RefCounted
## Pure collision + pass/near-miss detection against ObstacleData (no nodes involved).

const NEAR_MISS_LANE_DIST := 0.78    # skimming an obstacle laterally while switching
const SHIFT_WINDOW_SECONDS := 0.45   # leaving an obstacle's lane this late counts as a "perfect shift"

## Returns the first deadly obstacle touching the player, or null.
static func check_hit(theta: float, lane_pos: float, obstacles: Array, t: float) -> ObstacleData:
    for o in obstacles:
        var od := o as ObstacleData
        if od.passed:
            continue
        var d := absf(od.angle_at(t) - theta)
        if d > od.half + OrbitMath.PLAYER_HALF_ANGLE:
            continue
        if absf(lane_pos - float(od.lane)) >= OrbitMath.HIT_LANE_TOLERANCE:
            continue
        if od.is_deadly(t):
            return od
    return null

## Tracks lateral proximity for each obstacle while the player overlaps it angularly (+margin).
static func track_proximity(theta: float, lane_pos: float, obstacles: Array, t: float) -> void:
    for o in obstacles:
        var od := o as ObstacleData
        if od.passed:
            continue
        var d := absf(od.angle_at(t) - theta)
        if d <= od.half + OrbitMath.PLAYER_HALF_ANGLE + 0.1:
            od.min_lane_dist = minf(od.min_lane_dist, absf(lane_pos - float(od.lane)))

## Called when the player switches lanes: marks deadly obstacles right ahead in the lane being left.
static func mark_shift(theta: float, left_lane: int, omega: float, obstacles: Array, t: float) -> void:
    var window := SHIFT_WINDOW_SECONDS * omega
    for o in obstacles:
        var od := o as ObstacleData
        if od.passed or od.lane != left_lane:
            continue
        var ahead := od.angle_at(t) - od.half - theta
        if ahead >= -od.half and ahead <= window:
            od.shift_flag = true

## Marks obstacles the player has fully passed. Returns {dodged: int, near_misses: int}.
static func collect_passed(theta: float, obstacles: Array, t: float) -> Dictionary:
    var dodged := 0
    var near := 0
    for o in obstacles:
        var od := o as ObstacleData
        if od.passed:
            continue
        if theta > od.angle_at(t) + od.half + OrbitMath.PLAYER_HALF_ANGLE:
            od.passed = true
            dodged += 1
            if od.shift_flag or od.min_lane_dist < NEAR_MISS_LANE_DIST:
                near += 1
    return {"dodged": dodged, "near_misses": near}
