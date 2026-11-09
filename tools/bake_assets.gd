extends SceneTree
## Bakes the procedural meshes to assets/models/*.tres so they ship as real project assets.
## Usage: godot --headless --path . -s tools/bake_assets.gd

func _init() -> void:
    var out := {
        "crystal": MeshFactory.crystal(),
        "core_gem": MeshFactory.core_gem(),
        "track_inner": MeshFactory.ring(OrbitMath.LANE_RADII[0], 0.34),
        "track_mid": MeshFactory.ring(OrbitMath.LANE_RADII[1], 0.34),
        "track_outer": MeshFactory.ring(OrbitMath.LANE_RADII[2], 0.34),
        "obstacle_arc_sample": MeshFactory.arc_block(OrbitMath.LANE_RADII[1], 0.32, 0.62, 0.42, 0.08),
        "zone_strip_sample": MeshFactory.zone_strip(OrbitMath.LANE_RADII[1], 0.55, 0.9),
        "player_sphere": MeshFactory.sphere(0.24),
    }
    for k in out.keys():
        var path := "res://assets/models/%s.tres" % k
        var err := ResourceSaver.save(out[k], path)
        print("baked ", path, " -> ", error_string(err))
    quit()
