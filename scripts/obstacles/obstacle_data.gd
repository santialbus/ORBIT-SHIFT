class_name ObstacleData
extends RefCounted
## Pure data + motion model of one obstacle (no nodes). Used by collision, spawner and tests.
##
## Kinds
##  STATIC : fixed arc barrier.
##  MOVING : barrier oscillating along its orbit (amp / freq / phase).
##  BLOCK  : small "orbital block" that counter-orbits toward the player (negative drift_speed).
##  ZONE   : wide pulsing hazard; harmless during its warning phase, deadly while active.

enum Kind { STATIC, MOVING, BLOCK, ZONE }

var kind: int = Kind.STATIC
var lane: int = 0
var base_angle: float = 0.0
var half: float = 0.3
var amp: float = 0.0
var freq: float = 1.2
var phase: float = 0.0
var drift_speed: float = 0.0
var born: float = 0.0
var zone_period: float = 1.7
var zone_phase: float = 0.0
var zone_active: float = 0.6     # fraction of the period in which the zone is deadly

var row_id: int = 0
var passed: bool = false
var shift_flag: bool = false     # player left this obstacle's lane at the last moment
var min_lane_dist: float = 99.0  # closest lane distance while overlapping angularly
var view = null                  # ObstacleView node, set by ObstacleManager

func angle_at(t: float) -> float:
    match kind:
        Kind.MOVING:
            return base_angle + amp * sin(freq * t + phase)
        Kind.BLOCK:
            return base_angle + drift_speed * (t - born)
        _:
            return base_angle

func is_deadly(t: float) -> bool:
    if kind == Kind.ZONE:
        return fposmod((t + zone_phase) / zone_period, 1.0) < zone_active
    return true

## 0..1 telegraph value for zones (rises during the last part of the warning phase).
func zone_warning(t: float) -> float:
    if kind != Kind.ZONE:
        return 0.0
    var f := fposmod((t + zone_phase) / zone_period, 1.0)
    if f < zone_active:
        return 1.0
    return smoothstep(zone_active, 1.0, f) * 0.8

## Maximum angular extent from base_angle that the obstacle can ever reach while relevant.
func effective_half() -> float:
    match kind:
        Kind.MOVING:
            return half + amp
        Kind.BLOCK:
            return half + absf(drift_speed) * 1.6
        _:
            return half
