class_name OrbitController
extends RefCounted
## Orbit/lane logic.
##
## CONTROL MODES
##  SPLIT    (default): tap left half of screen = move one orbit inward, right half = one orbit outward.
##  PINGPONG: any tap moves one orbit in the current direction; at an edge the direction reverses
##            (0 -> 1 -> 2 -> 1 -> 0 ...). Completely single-input.
## Taps during a transition re-target instantly from the current lane position (no input is lost,
## no teleporting). Lane indices: 0 = inner, 1 = middle, 2 = outer. Limits are hard clamps.

enum Mode { SPLIT, PINGPONG }

var mode: int = Mode.SPLIT
var lane_pos: float = 1.0       # continuous lane position (0..2) used for rendering and collisions
var target_lane: int = 1
var direction: int = 1          # used by PINGPONG
var theta: float = 0.0          # unwrapped orbital angle
var omega: float = 1.4          # angular velocity (rad/s), driven by difficulty

var _from: float = 1.0
var _t: float = 1.0
var _duration: float = OrbitMath.SWITCH_TIME

func reset(start_lane: int = 1, start_theta: float = 0.0) -> void:
    target_lane = clampi(start_lane, 0, OrbitMath.LANE_COUNT - 1)
    lane_pos = float(target_lane)
    _from = lane_pos
    _t = 1.0
    direction = 1
    theta = start_theta

## Returns true if the tap produced a lane change.
func tap(side: int) -> bool:
    var new_target := target_lane
    if mode == Mode.PINGPONG:
        var nxt := target_lane + direction
        if nxt < 0 or nxt > OrbitMath.LANE_COUNT - 1:
            direction = -direction
            nxt = target_lane + direction
        new_target = clampi(nxt, 0, OrbitMath.LANE_COUNT - 1)
        if new_target == 0:
            direction = 1
        elif new_target == OrbitMath.LANE_COUNT - 1:
            direction = -1
    else:
        if side == 0:
            return false
        new_target = clampi(target_lane + signi(side), 0, OrbitMath.LANE_COUNT - 1)
    if new_target == target_lane:
        return false
    _from = lane_pos
    _t = 0.0
    _duration = OrbitMath.SWITCH_TIME * clampf(absf(float(new_target) - lane_pos), 0.5, 1.5)
    target_lane = new_target
    return true

func update(dt: float) -> void:
    theta += omega * dt
    if _t < 1.0:
        _t = minf(1.0, _t + dt / _duration)
        lane_pos = lerpf(_from, float(target_lane), smoothstep(0.0, 1.0, _t))
    else:
        lane_pos = float(target_lane)

func is_switching() -> bool:
    return _t < 1.0
