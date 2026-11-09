extends BackdropScreen
## Results: final score, record animation, stats, rewards, PLAY AGAIN / MENU.

func _ready() -> void:
    GameStateManager.set_state(GameStateManager.State.RESULTS)
    AudioManager.play_music("menu")
    add_backdrop(-0.5, true)
    dim(0.7)
    var run: Dictionary = GameManager.last_run
    var summary: Dictionary = GameManager.last_summary
    if run.is_empty():
        run = {"score": 0, "time": 0.0, "crystals": 0, "max_multiplier": 1}
        summary = {"is_record": false, "bonus": 0, "earned": 0, "missions_done": [], "achievements": []}
    var is_record: bool = summary.get("is_record", false)

    var root := UIKit.safe_root(self)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 18)
    root.add_child(v)

    var head := UIKit.label("NEW RECORD!" if is_record else "RUN OVER", 84, GameConfig.COL_GOLD if is_record else GameConfig.COL_CORAL)
    head.pivot_offset = Vector2(504, 50)
    v.add_child(head)
    if is_record:
        var tw := create_tween().set_loops()
        tw.tween_property(head, "scale", Vector2(1.08, 1.08), 0.45).set_trans(Tween.TRANS_SINE)
        tw.tween_property(head, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SINE)
        _confetti()

    v.add_child(UIKit.label("SCORE", 26, GameConfig.COL_DIM))
    var score_label := UIKit.label("0", 150, GameConfig.COL_WHITE)
    v.add_child(score_label)
    var final_score: int = int(run["score"])
    var count := create_tween()
    count.tween_method(func(x: float) -> void: score_label.text = GameConfig.format_int(int(x)), 0.0, float(final_score), 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    var best_text := "PERSONAL BEST  %s" % GameConfig.format_int(ProgressionManager.record())
    v.add_child(UIKit.label(best_text, 30, GameConfig.COL_GOLD if is_record else GameConfig.COL_DIM))

    var panel := UIKit.panel()
    v.add_child(panel)
    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 30)
    grid.add_theme_constant_override("v_separation", 12)
    panel.add_child(grid)
    _row(grid, "TIME SURVIVED", GameConfig.format_time(float(run["time"])))
    _row(grid, "CRYSTALS", str(int(run["crystals"])))
    _row(grid, "MAX MULTIPLIER", "x%d" % int(run["max_multiplier"]))
    _row(grid, "PERFECT SHIFTS", str(int(run.get("near_misses", 0))))
    _row(grid, "OBSTACLES DODGED", str(int(run.get("dodged", 0))))

    var rewards := UIKit.panel()
    v.add_child(rewards)
    var rv := VBoxContainer.new()
    rv.add_theme_constant_override("separation", 8)
    rewards.add_child(rv)
    var rh := HBoxContainer.new()
    rh.alignment = BoxContainer.ALIGNMENT_CENTER
    rh.add_theme_constant_override("separation", 12)
    rh.add_child(UIKit.crystal_icon(48))
    rh.add_child(UIKit.label("+%d" % int(summary.get("earned", 0)), 54, GameConfig.COL_GOLD))
    rv.add_child(rh)
    rv.add_child(UIKit.label("%d collected  +  %d score bonus" % [int(run["crystals"]), int(summary.get("bonus", 0))], 24, GameConfig.COL_DIM))
    for _id in summary.get("missions_done", []):
        rv.add_child(UIKit.label("DAILY MISSION COMPLETE - claim it in MISSIONS", 24, GameConfig.COL_CYAN))
        break
    for def in summary.get("achievements", []):
        rv.add_child(UIKit.label("ACHIEVEMENT: %s  (+%d)" % [def["name"], int(def["reward"])], 26, GameConfig.COL_VIOLET))
        AudioManager.play_sfx("unlock")

    v.add_child(UIKit.spacer(0, true))
    var again := UIKit.button("PLAY AGAIN", "primary", Vector2(0, 180), 66)
    again.pressed.connect(func() -> void: UIManager.go("gameplay", {}, 0.1))
    v.add_child(again)
    var menu := UIKit.button("MENU", "", Vector2(0, 100), 36)
    menu.pressed.connect(func() -> void: UIManager.go("menu"))
    v.add_child(menu)

func _row(grid: GridContainer, title: String, value: String) -> void:
    var a := UIKit.label(title, 26, GameConfig.COL_DIM, HORIZONTAL_ALIGNMENT_LEFT)
    a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_child(a)
    grid.add_child(UIKit.label(value, 34, GameConfig.COL_WHITE, HORIZONTAL_ALIGNMENT_RIGHT))

func _confetti() -> void:
    AudioManager.play_sfx("record")
    for i in 36:
        var c := ColorRect.new()
        c.color = [GameConfig.COL_GOLD, GameConfig.COL_CYAN, GameConfig.COL_VIOLET, GameConfig.COL_CORAL][i % 4]
        c.size = Vector2(12, 12)
        c.position = Vector2(randf_range(60, 1020), -40)
        c.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(c)
        var tw := create_tween()
        tw.tween_property(c, "position:y", randf_range(900, 1900), randf_range(1.4, 2.6)).set_delay(randf() * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
        tw.parallel().tween_property(c, "rotation", randf_range(-6, 6), 2.0)
        tw.tween_callback(c.queue_free)

func on_back() -> void:
    UIManager.go("menu")
