class_name ObstacleManager
extends Node3D
## Owns active obstacles (data + pooled views). Visual recycling only; logic lives in ObstacleData.

var active: Array = []          # Array[ObstacleData]
var _pool: Array = []           # Array[ObstacleView]

func spawn(d: ObstacleData, t_now: float) -> void:
    var v: ObstacleView
    if _pool.is_empty():
        v = ObstacleView.new()
        add_child(v)
    else:
        v = _pool.pop_back()
    v.bind(d, t_now)
    active.append(d)

## Recycles obstacles that are far behind the player.
func recycle_behind(theta: float, t: float) -> void:
    var i := active.size() - 1
    while i >= 0:
        var d: ObstacleData = active[i]
        if theta - d.angle_at(t) - d.half > OrbitMath.BEHIND_ANGLE:
            _release(d)
            active.remove_at(i)
        i -= 1

func update_views(t: float) -> void:
    for d in active:
        var v: ObstacleView = (d as ObstacleData).view
        if v != null:
            v.update_view(t)

func clear() -> void:
    for d in active:
        _release(d)
    active.clear()

func _release(d: ObstacleData) -> void:
    var v: ObstacleView = d.view
    if v != null:
        v.release()
        _pool.append(v)

func pool_size() -> int:
    return _pool.size() + active.size()
