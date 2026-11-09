class_name ComboManager
extends RefCounted
## Chain/multiplier system. Crystals (+1) and near misses (+2) grow the chain; a missed crystal or a
## long drought breaks it. Multiplier = number of thresholds reached (x1..x8).

signal multiplier_changed(new_mult: int, old_mult: int)
signal chain_broken(lost_chain: int)

const THRESHOLDS := [0, 4, 9, 15, 22, 30, 40, 52]
const TIMEOUT := 7.0

var chain: int = 0
var multiplier: int = 1
var max_multiplier: int = 1
var max_chain: int = 0
var _since_event: float = 0.0

func reset() -> void:
    chain = 0
    multiplier = 1
    max_multiplier = 1
    max_chain = 0
    _since_event = 0.0

static func multiplier_for(chain_value: int) -> int:
    var m := 0
    for th in THRESHOLDS:
        if chain_value >= int(th):
            m += 1
    return maxi(m, 1)

## Chain progress (0..1) toward the next multiplier level, for the HUD bar.
func level_progress() -> float:
    if multiplier >= THRESHOLDS.size():
        return 1.0
    var lo: int = THRESHOLDS[multiplier - 1]
    var hi: int = THRESHOLDS[multiplier]
    return clampf(float(chain - lo) / float(hi - lo), 0.0, 1.0)

func add(amount: int) -> void:
    chain += amount
    max_chain = maxi(max_chain, chain)
    _since_event = 0.0
    _refresh()

func on_crystal() -> void:
    add(1)

func on_near_miss() -> void:
    add(2)

func break_chain() -> void:
    if chain <= 0:
        return
    var lost := chain
    chain = 0
    _since_event = 0.0
    _refresh()
    chain_broken.emit(lost)

func update(dt: float) -> void:
    if chain <= 0:
        return
    _since_event += dt
    if _since_event >= TIMEOUT:
        break_chain()

func _refresh() -> void:
    var nm := multiplier_for(chain)
    if nm != multiplier:
        var old := multiplier
        multiplier = nm
        max_multiplier = maxi(max_multiplier, nm)
        multiplier_changed.emit(nm, old)
