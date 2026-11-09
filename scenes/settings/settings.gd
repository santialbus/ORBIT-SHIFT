extends BackdropScreen
## Settings: audio, vibration, tutorial, control mode, quality, data reset (with confirmation), version.

var _confirm: Control

func _ready() -> void:
    add_backdrop(0.0, true)
    dim(0.8)
    var root := UIKit.safe_root(self)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 16)
    root.add_child(v)

    var top := HBoxContainer.new()
    var back := UIKit.button("BACK", "", Vector2(190, 84), 28)
    back.pressed.connect(on_back)
    top.add_child(back)
    var title := UIKit.label("SETTINGS", 46, GameConfig.COL_CYAN)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(title)
    top.add_child(UIKit.spacer(0))
    top.get_child(2).custom_minimum_size = Vector2(190, 0)
    v.add_child(top)

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    v.add_child(scroll)
    var list := VBoxContainer.new()
    list.add_theme_constant_override("separation", 14)
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(list)

    list.add_child(_toggle("MUSIC", "music"))
    list.add_child(_slider("MUSIC VOLUME", "music_volume"))
    list.add_child(_toggle("SOUND EFFECTS", "sfx"))
    list.add_child(_slider("SFX VOLUME", "sfx_volume"))
    list.add_child(_toggle("VIBRATION", "vibration"))
    list.add_child(_choice("CONTROLS", "control_mode", ["SPLIT TAP", "ONE TAP"], "Split: left half = inner orbit, right half = outer orbit. One tap: every tap moves to the next orbit and bounces at the edges."))
    list.add_child(_choice("GRAPHICS", "quality", ["LOW", "HIGH"], "Low disables bloom and halves particles for older devices."))
    list.add_child(_toggle("TUTORIAL ON FIRST PLAY", "tutorial_enabled"))
    var tut := UIKit.button("REPLAY TUTORIAL", "", Vector2(0, 96), 30)
    tut.pressed.connect(func() -> void: GameManager.replay_tutorial())
    list.add_child(tut)
    var reset := UIKit.button("RESET ALL DATA", "danger", Vector2(0, 96), 30)
    reset.pressed.connect(func() -> void: _confirm.visible = true)
    list.add_child(reset)
    list.add_child(UIKit.label("%s  v%s  (build %d)" % [GameConfig.GAME_NAME, GameConfig.VERSION, GameConfig.BUILD_NUMBER], 24, GameConfig.COL_DIM))
    list.add_child(UIKit.label("Godot 4 - Save v%d" % GameConfig.SAVE_VERSION, 20, GameConfig.COL_DIM))
    _build_confirm()

func _setting_row(title: String) -> HBoxContainer:
    var h := HBoxContainer.new()
    h.custom_minimum_size = Vector2(0, 90)
    h.add_theme_constant_override("separation", 16)
    var l := UIKit.label(title, 30, GameConfig.COL_WHITE, HORIZONTAL_ALIGNMENT_LEFT)
    l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    h.add_child(l)
    return h

func _panel_wrap(inner: Control) -> Control:
    var p := UIKit.panel("CardPanel")
    p.add_child(inner)
    return p

func _toggle(title: String, key: String) -> Control:
    var h := _setting_row(title)
    var b := UIKit.button("", "", Vector2(190, 78), 28)
    var refresh := func() -> void:
        var on: bool = SaveManager.data["settings"][key]
        b.text = "ON" if on else "OFF"
        b.add_theme_color_override("font_color", GameConfig.COL_CYAN if on else GameConfig.COL_DIM)
    refresh.call()
    b.pressed.connect(func() -> void:
        SaveManager.data["settings"][key] = not SaveManager.data["settings"][key]
        SaveManager.mark_dirty()
        refresh.call())
    h.add_child(b)
    return _panel_wrap(h)

func _slider(title: String, key: String) -> Control:
    var h := _setting_row(title)
    var s := HSlider.new()
    s.min_value = 0.0
    s.max_value = 1.0
    s.step = 0.05
    s.value = float(SaveManager.data["settings"][key])
    s.custom_minimum_size = Vector2(380, 60)
    s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    s.value_changed.connect(func(val: float) -> void:
        SaveManager.data["settings"][key] = snappedf(val, 0.01)
        SaveManager.mark_dirty())
    h.add_child(s)
    return _panel_wrap(h)

func _choice(title: String, key: String, options: Array, hint: String) -> Control:
    var v := VBoxContainer.new()
    var h := _setting_row(title)
    var b := UIKit.button("", "", Vector2(250, 78), 26)
    var refresh := func() -> void:
        b.text = options[int(SaveManager.data["settings"][key])]
    refresh.call()
    b.pressed.connect(func() -> void:
        SaveManager.data["settings"][key] = (int(SaveManager.data["settings"][key]) + 1) % options.size()
        SaveManager.mark_dirty()
        refresh.call())
    h.add_child(b)
    v.add_child(h)
    var hl := UIKit.label(hint, 20, GameConfig.COL_DIM, HORIZONTAL_ALIGNMENT_LEFT)
    hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hl.custom_minimum_size = Vector2(880, 0)
    v.add_child(hl)
    return _panel_wrap(v)

func _build_confirm() -> void:
    _confirm = Control.new()
    _confirm.set_anchors_preset(Control.PRESET_FULL_RECT)
    _confirm.visible = false
    var d := ColorRect.new()
    d.color = Color(0, 0, 0, 0.85)
    d.set_anchors_preset(Control.PRESET_FULL_RECT)
    _confirm.add_child(d)
    var c := CenterContainer.new()
    c.set_anchors_preset(Control.PRESET_FULL_RECT)
    _confirm.add_child(c)
    var p := UIKit.panel()
    p.custom_minimum_size = Vector2(800, 0)
    c.add_child(p)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 22)
    p.add_child(v)
    v.add_child(UIKit.label("RESET ALL DATA?", 52, GameConfig.COL_CORAL))
    var t := UIKit.label("Progress, crystals, skins, missions, achievements and statistics will be erased. This cannot be undone.", 28, GameConfig.COL_WHITE)
    t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    t.custom_minimum_size = Vector2(740, 0)
    v.add_child(t)
    var yes := UIKit.button("YES, ERASE EVERYTHING", "danger", Vector2(0, 100), 30)
    yes.pressed.connect(func() -> void:
        SaveManager.reset_all()
        MissionManager.refresh()
        _confirm.visible = false
        UIManager.go("menu"))
    v.add_child(yes)
    var no := UIKit.button("CANCEL", "primary", Vector2(0, 100), 34)
    no.pressed.connect(func() -> void: _confirm.visible = false)
    v.add_child(no)
    add_child(_confirm)

func on_back() -> void:
    if _confirm != null and _confirm.visible:
        _confirm.visible = false
        return
    SaveManager.save_game()
    UIManager.go("menu")
