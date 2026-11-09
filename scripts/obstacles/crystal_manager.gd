class_name CrystalManager
extends Node3D
## Crystal collection, pooling and chain-miss tracking.
## A "group" is the set of crystals planned for one obstacle row. Passing a whole group without
## collecting anything counts as a miss; two consecutive missed groups break the combo chain.

signal collected(world_pos: Vector3, lane: int)
signal group_missed(miss_streak: int)

const COLLECT_ANGLE := 0.13
const COLLECT_LANE := 0.55

var active: Array = []    # Array[Dictionary] {angle, lane, group, view}
var _groups := {}         # group id -> {total, got, last_angle}
var _pool: Array = []
var miss_streak := 0

func spawn_group(group_id: int, items: Array, t_now: float) -> void:
    if items.is_empty():
        return
    var last := -1.0e9
    for it in items:
        var v: CrystalView
        if _pool.is_empty():
            v = CrystalView.new()
            add_child(v)
        else:
            v = _pool.pop_back()
        v.setup(float(it["angle"]), int(it["lane"]), t_now)
        active.append({"angle": float(it["angle"]), "lane": int(it["lane"]), "group": group_id, "view": v})
        last = maxf(last, float(it["angle"]))
    _groups[group_id] = {"total": items.size(), "got": 0, "last_angle": last}

## Returns number of crystals collected this step.
func update(theta: float, lane_pos: float, t: float, delta: float) -> int:
    var got := 0
    var i := active.size() - 1
    while i >= 0:
        var c: Dictionary = active[i]
        var view: CrystalView = c["view"]
        view.animate(t, delta)
        var d: float = theta - float(c["angle"])
        if absf(d) <= COLLECT_ANGLE and absf(lane_pos - float(c["lane"])) <= COLLECT_LANE:
            got += 1
            miss_streak = 0
            var g: Dictionary = _groups[c["group"]]
            g["got"] = int(g["got"]) + 1
            collected.emit(view.position, int(c["lane"]))
            view.release()
            _pool.append(view)
            active.remove_at(i)
        elif d > COLLECT_ANGLE + OrbitMath.BEHIND_ANGLE * 0.5:
            view.release()
            _pool.append(view)
            active.remove_at(i)
        i -= 1
    _evaluate_groups(theta)
    return got

func _evaluate_groups(theta: float) -> void:
    for gid in _groups.keys():
        var g: Dictionary = _groups[gid]
        if theta > float(g["last_angle"]) + COLLECT_ANGLE + 0.05:
            if int(g["got"]) == 0:
                miss_streak += 1
                group_missed.emit(miss_streak)
            _groups.erase(gid)

func clear() -> void:
    for c in active:
        (c["view"] as CrystalView).release()
        _pool.append(c["view"])
    active.clear()
    _groups.clear()
    miss_streak = 0
