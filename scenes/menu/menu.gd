extends Control
## Main menu: logo, PLAY, record, crystals, collection, missions, settings, progress summary.

func _ready() -> void:
    theme = UIKit.theme()
    GameStateManager.set_state(GameStateManager.State.MENU)
    AudioManager.play_music("menu")
    MissionManager.refresh()
    # 3D backdrop lives behind the UI in its own viewport container
    var svc := SubViewportContainer.new()
    svc.stretch = true
    svc.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(svc)
    var sv := SubViewport.new()
    sv.handle_input_locally = false
    sv.own_world_3d = true
    svc.add_child(sv)
    var bd := OrbitBackdrop.new()
    sv.add_child(bd)
    bd.setup(SkinManager.equipped_core_id(), SkinManager.equipped_skin_id(), -1.2)

    var root := UIKit.safe_root(self)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 20)
    root.add_child(v)

    var top := HBoxContainer.new()
    top.add_child(CrystalChip.new())
    top.add_child(UIKit.hspacer())
    var set_btn := UIKit.button("SETTINGS", "", Vector2(250, 84), 26)
    set_btn.pressed.connect(func() -> void: UIManager.go("settings"))
    top.add_child(set_btn)
    v.add_child(top)

    var logo := TextureRect.new()
    logo.texture = load("res://assets/icons/logo.png")
    logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    logo.custom_minimum_size = Vector2(0, 330)
    v.add_child(logo)

    var rec := UIKit.label("PERSONAL BEST", 24, GameConfig.COL_DIM)
    v.add_child(rec)
    var recv := UIKit.label(GameConfig.format_int(ProgressionManager.record()), 76, GameConfig.COL_GOLD)
    v.add_child(recv)

    v.add_child(UIKit.spacer(0, true))

    var play := UIKit.button("PLAY", "primary", Vector2(0, 190), 74)
    play.pressed.connect(func() -> void: GameManager.play())
    v.add_child(play)
    var pulse := create_tween().set_loops()
    pulse.tween_property(play, "scale", Vector2(1.02, 1.02), 0.8).set_trans(Tween.TRANS_SINE)
    pulse.tween_property(play, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_SINE)
    play.pivot_offset = Vector2(450, 95)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 18)
    v.add_child(row)
    var col := UIKit.button("COLLECTION", "", Vector2(0, 112), 30)
    col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    col.pressed.connect(func() -> void: UIManager.go("collection"))
    row.add_child(col)
    var claim := MissionManager.claimable_count()
    var mis := UIKit.button("MISSIONS" + (" (%d)" % claim if claim > 0 else ""), "", Vector2(0, 112), 30)
    mis.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    mis.pressed.connect(func() -> void: UIManager.go("missions"))
    row.add_child(mis)

    var st: Dictionary = ProgressionManager.stats()
    var info := UIKit.label("RUNS %d    SKINS %d/%d    ACHIEVEMENTS %d/%d" % [
        int(st["runs"]), ProgressionManager.owned_skins().size(), SkinCatalog.SKINS.size(),
        AchievementManager.unlocked_count(), AchievementManager.all().size()], 22, GameConfig.COL_DIM)
    v.add_child(info)

func on_back() -> void:
    get_tree().quit()
