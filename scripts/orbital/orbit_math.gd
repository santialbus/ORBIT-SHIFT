class_name OrbitMath
extends RefCounted
## Pure orbital geometry helpers. Angles are "unwrapped" radians: the player's angle
## only ever increases, obstacles live at absolute unwrapped angles ahead of it.

const LANE_COUNT := 3
const LANE_RADII := [2.0, 3.1, 4.2]
const SWITCH_TIME := 0.16          # seconds to travel one lane
const REACTION_TIME := 0.22        # reaction margin the generator guarantees
const HIT_LANE_TOLERANCE := 0.42   # lane distance below which an obstacle can hit
const PLAYER_HALF_ANGLE := 0.05    # angular half-size of the player hitbox (rad)
const LEAD_ANGLE := 3.0            # how far ahead rows are spawned (rad)
const BEHIND_ANGLE := 0.7          # obstacles are recycled this far behind the player

static func angle_diff(a: float, b: float) -> float:
    return wrapf(a - b, -PI, PI)

static func lane_radius(lane_pos: float) -> float:
    var p := clampf(lane_pos, 0.0, float(LANE_COUNT - 1))
    var i := mini(int(floor(p)), LANE_COUNT - 2)
    var f := p - float(i)
    return lerpf(float(LANE_RADII[i]), float(LANE_RADII[i + 1]), f)

static func polar_to_vec3(theta: float, radius: float, y: float = 0.0) -> Vector3:
    return Vector3(cos(theta) * radius, y, sin(theta) * radius)

## Time needed to move `steps` lanes plus reaction margin. `factor` > 1 for harder control modes.
static func reach_time(steps: int, factor: float = 1.0) -> float:
    if steps <= 0:
        return 0.0
    return float(steps) * SWITCH_TIME * factor + REACTION_TIME
