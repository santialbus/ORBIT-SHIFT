extends BackdropScreen
## Missions: daily missions (local date), progressive objectives and achievements.

var _tab := "missions"
var _list: VBoxContainer
var _tab_m: Button
var _tab_a: Button

func _ready() -> void:
    add_backdrop(0.0, true)
    dim(0.82)
    MissionManager.refresh()
    var root := UIKit.safe_root(self)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 16)
    root.add_child(v)
    var top := HBoxContainer.new()
    top.add_theme_constant_override("separation", 16)
    var back := UIKit.button("BACK", "", Vector2(190, 84), 28)
    back.pressed.connect(on_back)
    top.add_child(back)
    var title := UIKit.label("MISSIONS", 44, GameConfig.COL_CYAN)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(title)
    top.add_child(CrystalChip.new())
    v.add_child(top)

    var tabs := HBoxContainer.new()
    tabs.add_theme_constant_override("separation", 14)
    _tab_m = UIKit.button("MISSIONS", "", Vector2(0, 84), 28)
    _tab_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _tab_m.pressed.connect(func() -> void: _set_tab("missions"))
    _tab_a = UIKit.button("ACHIEVEMENTS %d/%d" % [AchievementManager.unlocked_count(), AchievementManager.all().size()], "", Vector2(0, 84), 24)
    _tab_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _tab_a.pressed.connect(func() -> void: _set_tab("achievements"))
    tabs.add_child(_tab_m)
    tabs.add_child(_tab_a)
    v.add_child(tabs)

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    v.add_child(scroll)
    _list = VBoxContainer.new()
    _list.add_theme_constant_override("separation", 14)
    _list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(_list)
    MissionManager.missions_changed.connect(_rebuild)
    _set_tab("missions")

func _set_tab(t: String) -> void:
    _tab = t
    _tab_m.disabled = t == "missions"
    _tab_a.disabled = t == "achievements"
    _rebuild()

func _rebuild() -> void:
    for c in _list.get_children():
        c.queue_free()
    if _tab == "missions":
        _list.add_child(UIKit.label("DAILY  (%s)" % MissionLogic.today(), 26, GameConfig.COL_DIM, HORIZONTAL_ALIGNMENT_LEFT))
        var daily := MissionManager.daily()
        for i in daily.size():
            var e: Dictionary = daily[i]
            var idx := i
            _list.add_child(_card(MissionLogic.mission_text(e["id"], int(e["target"])), int(e["progress"]), int(e["target"]),
                MissionLogic.reward_for(e["id"], int(e["target"])), bool(e["claimed"]), func() -> void: _claim_daily(idx)))
        _list.add_child(UIKit.spacer(10))
        _list.add_child(UIKit.label("OBJECTIVES", 26, GameConfig.COL_DIM, HORIZONTAL_ALIGNMENT_LEFT))
        for track in MissionLogic.PROGRESSIVE.keys():
            var tier := MissionLogic.progressive_tier(track, SaveManager.data)
            var target := MissionLogic.progressive_target(track, tier)
            var val := MissionLogic.progressive_value(track, SaveManager.data)
            var tr: String = track
            _list.add_child(_card(str(MissionLogic.PROGRESSIVE[track]["label"]) % target, mini(val, target), target,
                MissionLogic.progressive_reward(tier), false, func() -> void: _claim_prog(tr)))
    else:
        for def in AchievementManager.all():
            var unlocked := AchievementManager.is_unlocked(def["id"])
            var prog := minf(AchievementManager.progress(def), float(def["target"]))
            _list.add_child(_ach_card(def, unlocked, prog))

func _card(text: String, progress: int, target: int, reward: int, claimed: bool, on_claim: Callable) -> Control:
    var p := UIKit.panel("CardPanel")
    var h := HBoxContainer.new()
    h.add_theme_constant_override("separation", 18)
    p.add_child(h)
    var v := VBoxContainer.new()
    v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    v.add_theme_constant_override("separation", 8)
    h.add_child(v)
    var t := UIKit.label(text, 28, GameConfig.COL_WHITE, HORIZONTAL_ALIGNMENT_LEFT)
    t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    t.custom_minimum_size = Vector2(540, 0)
    v.add_child(t)
    v.add_child(UIKit.progress(float(progress) / float(maxi(target, 1)), 16.0, GameConfig.COL_ORANGE if progress < target else GameConfig.COL_CYAN))
    v.add_child(UIKit.label("%s / %s" % [GameConfig.format_int(progress), GameConfig.format_int(target)], 20, GameConfig.COL_DIM, HORIZONTAL_ALIGNMENT_LEFT))
    var b := UIKit.button("", "primary", Vector2(250, 90), 26)
    if claimed:
        b.text = "CLAIMED"
        b.disabled = true
    elif progress >= target:
        b.text = "CLAIM +%d" % reward
        b.pressed.connect(on_claim)
    else:
        b.text = "+%d" % reward
        b.disabled = true
    h.add_child(b)
    return p

func _ach_card(def: Dictionary, unlocked: bool, prog: float) -> Control:
    var p := UIKit.panel("CardPanel")
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 6)
    p.add_child(v)
    var head := HBoxContainer.new()
    var n := UIKit.label(def["name"], 30, GameConfig.COL_GOLD if unlocked else GameConfig.COL_WHITE, HORIZONTAL_ALIGNMENT_LEFT)
    n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    head.add_child(n)
    head.add_child(UIKit.label("UNLOCKED" if unlocked else "+%d" % int(def["reward"]), 24, GameConfig.COL_CYAN if unlocked else GameConfig.COL_GOLD))
    v.add_child(head)
    v.add_child(UIKit.label(def["desc"], 22, GameConfig.COL_DIM, HORIZONTAL_ALIGNMENT_LEFT))
    v.add_child(UIKit.progress(prog / float(def["target"]), 12.0, GameConfig.COL_CYAN if unlocked else GameConfig.COL_VIOLET))
    return p

func _claim_daily(i: int) -> void:
    if MissionManager.claim_daily(i) > 0:
        AudioManager.play_sfx("unlock")

func _claim_prog(track: String) -> void:
    if MissionManager.claim_progressive(track) > 0:
        AudioManager.play_sfx("unlock")

func on_back() -> void:
    UIManager.go("menu")
