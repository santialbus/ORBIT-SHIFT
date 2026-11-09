extends SceneTree
## Integration test: drives the REAL gameplay / tutorial scenes headless (no rendering) through tick().
## Run: godot --headless --path . -s tests/integration_run.gd

var passed := 0
var failed := 0

func ok(cond: bool, msg: String) -> void:
    if cond:
        passed += 1
        print("  PASS  ", msg)
    else:
        failed += 1
        print("  FAIL  ", msg)

func _initialize() -> void:
    await _run()
    var sm = root.get_node("SaveManager")
    DirAccess.remove_absolute(sm.SAVE_PATH)
    DirAccess.remove_absolute(sm.BACKUP_PATH)
    print("")
    print("INTEGRATION RESULT: %d passed, %d failed" % [passed, failed])
    quit(1 if failed > 0 else 0)

func _spawn(scene_path: String) -> Node:
    var s: Node = (load(scene_path) as PackedScene).instantiate()
    root.add_child(s)
    await process_frame
    return s

## Greedy bot over live ObstacleData: pick the nearest lane that is clear for the next ~0.75 s.
func _bot(gp: Node) -> void:
    var o = gp.orbit
    var window: float = o.omega * 0.75
    var clear := [true, true, true]
    for d in gp.obstacles.active:
        var od := d as ObstacleData
        if od.passed:
            continue
        var lo := od.base_angle - od.effective_half() - 0.12
        var hi := od.base_angle + od.effective_half() + 0.12
        if hi >= o.theta and lo <= o.theta + window:
            clear[od.lane] = false
    var cur: int = o.target_lane
    if clear[cur]:
        return
    for dist in [1, 2]:
        for sgn in [-1, 1]:
            var cand: int = cur + sgn * dist
            if cand >= 0 and cand <= 2 and clear[cand]:
                gp.tap_side(sgn)
                return

func _run() -> void:
    var gm = root.get_node("GameManager")
    var pm = root.get_node("ProgressionManager")
    var sm = root.get_node("SaveManager")
    sm.data = SaveData.defaults()
    sm.data["tutorial_done"] = true

    print("-- gameplay scene boots and runs")
    gm.forced_seed = 777
    var gp: Node = await _spawn("res://scenes/gameplay/gameplay.tscn")
    ok(gp.state == gp.S.PLAYING, "starts immediately in PLAYING state")
    ok(gp.hud != null and gp.world != null and gp.player_view != null, "hud, world and player created")
    for i in 300:
        _bot(gp)
        gp.tick(1.0 / 60.0)
    ok(gp.state == gp.S.PLAYING, "bot alive after 5 s")
    ok(gp.score.value() > 0, "score increases (%d)" % gp.score.value())
    ok(gp.obstacles.active.size() > 0, "obstacles are being generated")
    ok(gp.run_time > 4.9, "run time advances")

    print("-- pause / resume")
    var t_before: float = gp.run_time
    gp.pause()
    ok(gp.state == gp.S.PAUSED, "pause switches state")
    for i in 120:
        gp.tick(1.0 / 60.0)
    ok(absf(gp.run_time - t_before) < 0.0001, "game time frozen while paused")
    ok(gp.hud.pause_overlay.visible, "pause overlay visible")
    gp.resume()
    ok(gp.state == gp.S.COUNTDOWN, "resume starts countdown")
    for i in 200:
        gp.tick(1.0 / 60.0)
    ok(gp.state == gp.S.PLAYING, "back to PLAYING after countdown")
    ok(not gp.hud.pause_overlay.visible, "overlay hidden")

    print("-- long run: pooling, difficulty phases, no pile-up (god mode)")
    gp.god_mode = true
    var max_pool := 0
    var max_active := 0
    for i in 60 * 130:
        if i % 20 == 0:
            gp.tap_side(1 if gp.orbit.target_lane == 0 else (-1 if gp.orbit.target_lane == 2 else (1 if (i / 20) % 2 == 0 else -1)))
        gp.tick(1.0 / 60.0)
        max_pool = maxi(max_pool, gp.obstacles.pool_size())
        max_active = maxi(max_active, gp.obstacles.active.size())
    ok(gp.run_time > 130.0, "simulated >130 s of play (%.0f)" % gp.run_time)
    ok(max_pool < 60, "obstacle views pooled, max instances %d" % max_pool)
    ok(max_active < 40, "active obstacles bounded (%d)" % max_active)
    ok(gp.difficulty.phase_index_at(gp.run_time) == 4, "reached EXTREME phase")
    ok(gp.score.crystals > 0, "crystals collected (%d)" % gp.score.crystals)
    ok(gp.combo.max_multiplier >= 1, "combo tracked (x%d)" % gp.combo.max_multiplier)
    ok(gp.crystals.active.size() < 30, "crystal pool bounded")

    print("-- death flow, results hand-off and persistence")
    gp.god_mode = false
    gp.restart()
    ok(gp.run_time == 0.0 and gp.score.value() == 0, "restart resets the run")
    var rec_before: int = pm.record()
    # idle player: never taps -> must die
    var guard := 0
    while gp.state == gp.S.PLAYING and guard < 60 * 60:
        gp.tick(1.0 / 60.0)
        guard += 1
    ok(gp.state == gp.S.DYING, "idle player collides and enters DYING (%.1f s)" % gp.run_time)
    for i in 80:
        gp.tick(1.0 / 60.0)
    ok(gp.state == gp.S.DONE, "death animation completes")
    ok(not gm.last_run.is_empty() and gm.last_run.has("score"), "last_run handed to results")
    ok(int(gm.last_run["time"]) > 0, "run time recorded (%.1f s)" % float(gm.last_run["time"]))
    ok(int(sm.data["stats"]["runs"]) == 1, "stats.runs incremented")
    ok(pm.record() >= rec_before, "record never decreases")
    var reloaded := SaveData.decode(FileAccess.open(sm.SAVE_PATH, FileAccess.READ).get_as_text())
    ok(reloaded["ok"] and reloaded["checksum_ok"], "save file on disk valid after the run")
    ok(int(reloaded["data"]["stats"]["runs"]) == 1, "run persisted to disk")
    gp.queue_free()
    await create_timer(0.8).timeout

    print("-- tutorial scene completes and is remembered")
    sm.data["tutorial_done"] = false
    var tu: Node = await _spawn("res://scenes/tutorial/tutorial.tscn")
    ok(tu.tutorial_mode, "tutorial mode on")
    ok(tu._tut_step == 0, "tutorial starts at step 0")
    var seen := {}
    for i in 60 * 70:
        seen[tu._tut_step] = true
        if tu._tut_step == 1 and i % 40 == 0:
            tu.tap_side(1 if tu.orbit.target_lane < 2 else -1)
        elif tu._tut_step == 2:
            _bot(tu)
        elif tu._tut_step == 3 and i % 15 == 0:
            tu.tap_side(1 if tu.orbit.target_lane == 0 else (-1 if tu.orbit.target_lane == 2 else 1))
        tu.tick(1.0 / 60.0)
        if tu.state == tu.S.DONE:
            break
    ok(seen.size() == 5, "all 5 tutorial steps visited (%s)" % str(seen.keys()))
    ok(sm.data["tutorial_done"], "tutorial_done flag saved")
    tu.queue_free()
    await create_timer(0.8).timeout

    print("-- one-tap control mode")
    sm.data["settings"]["control_mode"] = 1
    var gp2: Node = await _spawn("res://scenes/gameplay/gameplay.tscn")
    ok(gp2.orbit.mode == OrbitController.Mode.PINGPONG, "control mode read from settings")
    gp2.tap_side(0)
    ok(gp2.orbit.target_lane == 2, "one-tap moves to adjacent orbit")
    gp2.tap_side(0)
    ok(gp2.orbit.target_lane == 1, "and bounces at the edge")
    gp2.queue_free()
