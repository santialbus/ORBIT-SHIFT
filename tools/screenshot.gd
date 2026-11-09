extends SceneTree
## Renders a scene to a PNG (needs a GPU / xvfb with llvmpipe). Usage:
## xvfb-run -a godot --path . --resolution 540x960 -s tools/screenshot.gd -- <scene_key> <out.png> [sim_seconds]

func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    var key: String = args[0] if args.size() > 0 else "menu"
    var out: String = args[1] if args.size() > 1 else "/tmp/shot.png"
    var sim: float = float(args[2]) if args.size() > 2 else 0.0
    var gm = root.get_node("GameManager")
    var path: String = "res://scenes/%s/%s.tscn" % [key, key]
    var scene: Node = (load(path) as PackedScene).instantiate()
    if key == "gameplay":
        gm.god_mode = true
        gm.forced_seed = 12345
    if key == "results":
        gm.last_run = {"score": 4820, "time": 52.4, "crystals": 17, "max_multiplier": 4, "dodged": 38, "near_misses": 3}
        gm.last_summary = {"is_record": true, "bonus": 19, "earned": 36, "missions_done": [], "achievements": []}
    root.add_child(scene)
    for i in 12:
        await process_frame
    if key == "gameplay" and sim > 0.0:
        var steps := int(sim / 0.05)
        for i in steps:
            # crude autopilot: keep to a free lane so we see crystals + obstacles in flight
            if i % 14 == 0:
                scene.tap_side(1 if scene.orbit.target_lane < 1 else -1)
            scene.tick(0.05)
        for i in 6:
            await process_frame
    await create_timer(0.4).timeout
    for i in 3:
        await process_frame
    var img := root.get_texture().get_image()
    img.save_png(out)
    print("saved ", out, " ", img.get_size())
    quit()
