class_name Hud
extends Control
## In-run HUD: score, crystals, combo, phase bar, pause button, popups, banners and the pause menu.
## Priority is readability: everything sits in the top band; the play field stays clear.

signal pause_pressed
signal resume_pressed
signal restart_pressed
signal menu_pressed

var score_label: Label
var best_label: Label
var crystal_label: Label
var combo_label: Label
var combo_bar: ProgressBar
var phase_bar: ProgressBar
var phase_label: Label
var banner: Label
var countdown: Label
var pause_btn: Button
var pause_overlay: Control
var _popups: Array[Label] = []
var _popup_i := 0
var _combo_tween: Tween
var _banner_tween: Tween
var _top := 0

func build(best: int) -> void:
    theme = UIKit.theme()
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    var sm: Dictionary = UIManager.safe_margins()
    _top = int(sm["top"])

    # phase bar (very top)
    phase_bar = UIKit.progress(0.0, 8.0, GameConfig.COL_VIOLET)
    phase_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
    phase_bar.offset_left = 40 + int(sm["left"])
    phase_bar.offset_right = -(40 + int(sm["right"]))
    phase_bar.offset_top = _top + 14
    phase_bar.offset_bottom = _top + 22
    add_child(phase_bar)
    phase_label = UIKit.label("INTRO", 22, GameConfig.COL_DIM)
    phase_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
    phase_label.offset_top = _top + 26
    phase_label.offset_bottom = _top + 56
    add_child(phase_label)

    # score
    score_label = UIKit.label("0", 104, GameConfig.COL_WHITE)
    score_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
    score_label.offset_top = _top + 70
    score_label.offset_bottom = _top + 200
    add_child(score_label)
    best_label = UIKit.label("BEST %s" % GameConfig.format_int(best), 24, GameConfig.COL_DIM)
    best_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
    best_label.offset_top = _top + 196
    best_label.offset_bottom = _top + 230
    add_child(best_label)

    # crystals (top-left)
    var cbox := HBoxContainer.new()
    cbox.add_theme_constant_override("separation", 10)
    cbox.position = Vector2(44 + int(sm["left"]), _top + 74)
    cbox.add_child(UIKit.crystal_icon(46))
    crystal_label = UIKit.label("0", 44, GameConfig.COL_GOLD)
    cbox.add_child(crystal_label)
    cbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(cbox)

    # combo (under score)
    combo_label = UIKit.label("", 64, GameConfig.COL_ORANGE)
    combo_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
    combo_label.offset_top = _top + 236
    combo_label.offset_bottom = _top + 316
    combo_label.pivot_offset = Vector2(540, 40)
    add_child(combo_label)
    combo_bar = UIKit.progress(0.0, 10.0, GameConfig.COL_ORANGE)
    combo_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
    combo_bar.offset_left = -150
    combo_bar.offset_right = 150
    combo_bar.offset_top = _top + 318
    combo_bar.offset_bottom = _top + 328
    combo_bar.modulate.a = 0.0
    add_child(combo_bar)

    # pause button (top-right)
    pause_btn = UIKit.button("II", "", Vector2(96, 96), 38)
    pause_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    pause_btn.offset_right = -(40 + int(sm["right"]))
    pause_btn.offset_left = pause_btn.offset_right - 96
    pause_btn.offset_top = _top + 66
    pause_btn.offset_bottom = _top + 162
    pause_btn.pressed.connect(func() -> void: pause_pressed.emit())
    add_child(pause_btn)

    # banner + countdown
    banner = UIKit.label("", 70, GameConfig.COL_CYAN)
    banner.set_anchors_preset(Control.PRESET_CENTER)
    banner.offset_left = -520
    banner.offset_right = 520
    banner.offset_top = -420
    banner.offset_bottom = -320
    banner.modulate.a = 0.0
    add_child(banner)
    countdown = UIKit.label("", 220, GameConfig.COL_WHITE)
    countdown.set_anchors_preset(Control.PRESET_CENTER)
    countdown.offset_left = -300
    countdown.offset_right = 300
    countdown.offset_top = -160
    countdown.offset_bottom = 160
    countdown.pivot_offset = Vector2(300, 160)
    countdown.visible = false
    add_child(countdown)

    for i in 6:
        var p := UIKit.label("", 42, GameConfig.COL_GOLD)
        p.modulate.a = 0.0
        p.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(p)
        _popups.append(p)
    _build_pause_menu()

func _build_pause_menu() -> void:
    pause_overlay = Control.new()
    pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    pause_overlay.visible = false
    var dim := ColorRect.new()
    dim.color = Color(0.01, 0.02, 0.06, 0.82)
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    pause_overlay.add_child(dim)
    var center := CenterContainer.new()
    center.set_anchors_preset(Control.PRESET_FULL_RECT)
    pause_overlay.add_child(center)
    var panel := UIKit.panel()
    panel.custom_minimum_size = Vector2(780, 0)
    center.add_child(panel)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 22)
    panel.add_child(v)
    v.add_child(UIKit.label("PAUSED", 72, GameConfig.COL_CYAN))
    var cont := UIKit.button("CONTINUE", "primary", Vector2(0, 124), 44)
    cont.pressed.connect(func() -> void: resume_pressed.emit())
    v.add_child(cont)
    var restart := UIKit.button("RESTART", "", Vector2(0, 100))
    restart.pressed.connect(func() -> void: restart_pressed.emit())
    v.add_child(restart)
    var menu := UIKit.button("MENU", "", Vector2(0, 100))
    menu.pressed.connect(func() -> void: menu_pressed.emit())
    v.add_child(menu)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 20)
    v.add_child(row)
    var mb := _toggle_button("MUSIC", "music")
    var sb := _toggle_button("SOUND", "sfx")
    row.add_child(mb)
    row.add_child(sb)
    add_child(pause_overlay)

func _toggle_button(title: String, key: String) -> Button:
    var b := UIKit.button("", "", Vector2(0, 90), 28)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var refresh := func() -> void:
        b.text = "%s: %s" % [title, "ON" if SaveManager.data["settings"][key] else "OFF"]
    refresh.call()
    b.pressed.connect(func() -> void:
        SaveManager.data["settings"][key] = not SaveManager.data["settings"][key]
        SaveManager.mark_dirty()
        refresh.call())
    return b

func set_pause_visible(on: bool) -> void:
    pause_overlay.visible = on
    pause_btn.visible = not on

func set_score(v: int) -> void:
    score_label.text = GameConfig.format_int(v)

func set_crystals(n: int) -> void:
    crystal_label.text = str(n)

func set_combo(mult: int, progress: float) -> void:
    if mult <= 1:
        combo_label.text = ""
        combo_bar.modulate.a = 0.0
        return
    combo_label.text = "x%d" % mult
    combo_bar.modulate.a = 0.9
    combo_bar.value = progress

func pop_combo(mult: int) -> void:
    if _combo_tween != null:
        _combo_tween.kill()
    combo_label.scale = Vector2(1.6, 1.6)
    combo_label.modulate = GameConfig.COL_GOLD if mult >= 6 else GameConfig.COL_ORANGE
    _combo_tween = create_tween()
    _combo_tween.tween_property(combo_label, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func set_phase(name_text: String, progress: float) -> void:
    phase_label.text = name_text
    phase_bar.value = progress

func show_banner(text: String, color: Color = GameConfig.COL_CYAN) -> void:
    banner.text = text
    banner.add_theme_color_override("font_color", color)
    if _banner_tween != null:
        _banner_tween.kill()
    banner.modulate.a = 0.0
    banner.scale = Vector2(0.9, 0.9)
    banner.pivot_offset = Vector2(520, 50)
    _banner_tween = create_tween()
    _banner_tween.tween_property(banner, "modulate:a", 1.0, 0.12)
    _banner_tween.parallel().tween_property(banner, "scale", Vector2.ONE, 0.2)
    _banner_tween.tween_interval(0.9)
    _banner_tween.tween_property(banner, "modulate:a", 0.0, 0.35)

## Floating text at a screen position (viewport coordinates).
func popup(text: String, screen_pos: Vector2, color: Color = GameConfig.COL_GOLD) -> void:
    var p := _popups[_popup_i]
    _popup_i = (_popup_i + 1) % _popups.size()
    p.text = text
    p.add_theme_color_override("font_color", color)
    p.size = Vector2(300, 60)
    p.position = screen_pos - Vector2(150, 30)
    p.modulate.a = 1.0
    var tw := create_tween()
    tw.tween_property(p, "position:y", p.position.y - 90.0, 0.7)
    tw.parallel().tween_property(p, "modulate:a", 0.0, 0.7).set_delay(0.2)

func show_countdown(text: String) -> void:
    countdown.visible = text != ""
    countdown.text = text
    countdown.scale = Vector2(1.5, 1.5)
    var tw := create_tween()
    tw.tween_property(countdown, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

var _tut_panel: PanelContainer
var _tut_text: Label
var _tut_step: Label

func set_tutorial_text(text: String, step_text: String) -> void:
    if _tut_panel == null:
        _tut_panel = UIKit.panel()
        _tut_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
        _tut_panel.offset_left = 50
        _tut_panel.offset_right = -50
        _tut_panel.offset_top = -330
        _tut_panel.offset_bottom = -110
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 8)
        _tut_panel.add_child(v)
        _tut_step = UIKit.label("", 24, GameConfig.COL_VIOLET)
        v.add_child(_tut_step)
        _tut_text = UIKit.label("", 38, GameConfig.COL_WHITE)
        _tut_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        _tut_text.custom_minimum_size = Vector2(900, 0)
        v.add_child(_tut_text)
        add_child(_tut_panel)
    _tut_text.text = text
    _tut_step.text = "TUTORIAL  " + step_text
