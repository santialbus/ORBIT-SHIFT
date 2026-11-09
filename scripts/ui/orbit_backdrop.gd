class_name OrbitBackdrop
extends Node3D
## Idle 3D scene (core + orbits + orbiting sphere) used behind the menu, results and collection screens.

var world: WorldBuilder
var player: PlayerView
var theta := -PI / 2.0
var _t := 0.0
var _auto_lane := true
var lane := 1.0

func setup(core_id: String, skin_id: String, v_offset: float = 0.0, auto_lane: bool = true) -> void:
    _auto_lane = auto_lane
    world = WorldBuilder.new()
    add_child(world)
    world.build(core_id)
    world.camera.v_offset = v_offset
    player = PlayerView.new()
    add_child(player)
    player.set_skin(skin_id)

func _process(delta: float) -> void:
    _t += delta
    theta += 1.1 * delta
    if _auto_lane:
        lane = 1.0 + sin(_t * 0.6) * 0.9
    player.place(theta, lane)
    world.set_lane_position(lane)
