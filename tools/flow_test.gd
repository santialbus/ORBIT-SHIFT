extends SceneTree
## Real-GPU (xvfb) end-to-end flow: splash -> menu -> gameplay -> death -> results -> play again -> menu.
## xvfb-run -a godot --path . --resolution 540x960 --rendering-driver opengl3 -s tools/flow_test.gd

func _initialize() -> void:
    await process_frame
    await process_frame
    var ui = root.get_node("UIManager")
    var sm = root.get_node("SaveManager")
    sm.data = SaveData.defaults()
    sm.data["tutorial_done"] = true
    ui.go("menu", {}, 0.05)
    await create_timer(1.2).timeout
    print("scene: ", current_scene.name)
    var gm = root.get_node("GameManager")
    gm.forced_seed = 99
    gm.play()
    await create_timer(1.2).timeout
    print("scene: ", current_scene.name)
    var gp = current_scene
    var guard := 0
    while gp.state == gp.S.PLAYING and guard < 4000:
        gp.tick(0.03)
        guard += 1
    await create_timer(2.5).timeout
    print("scene after death: ", current_scene.name, " score=", gm.last_run.get("score"))
    var img := root.get_texture().get_image()
    img.save_png("/tmp/flow_results.png")
    ui.go("gameplay", {}, 0.05)
    await create_timer(1.2).timeout
    print("scene after play again: ", current_scene.name)
    ui.go("collection", {}, 0.05)
    await create_timer(1.0).timeout
    print("scene: ", current_scene.name)
    ui.go("menu", {}, 0.05)
    await create_timer(1.0).timeout
    print("scene: ", current_scene.name)
    quit()
