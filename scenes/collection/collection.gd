extends BackdropScreen
## Collection: browse, preview, unlock and equip sphere skins and core variants.

class Swatch extends Control:
    var color := Color.WHITE
    var glow := Color.WHITE
    var locked := false
    var is_core := false
    func _init(sz: float = 110.0) -> void:
        custom_minimum_size = Vector2(sz, sz)
        mouse_filter = Control.MOUSE_FILTER_IGNORE
    func _draw() -> void:
        var c := size / 2.0
        var r := size.x * 0.34
        if is_core:
            draw_circle(c, r, color)
            draw_arc(c, r + 10, 0, TAU, 40, glow, 4.0, true)
            draw_arc(c, r + 22, 0.5, 4.0, 32, glow.darkened(0.2), 3.0, true)
        else:
            draw_circle(c, r + 12, Color(glow.r, glow.g, glow.b, 0.18))
            draw_circle(c, r, color)
            draw_arc(c, r, 0, TAU, 40, glow, 4.0, true)
            draw_circle(c + Vector2(-r * 0.3, -r * 0.35), r * 0.2, Color(1, 1, 1, 0.55))
        if locked:
            draw_circle(c, r + 14, Color(0.02, 0.03, 0.08, 0.65))
            draw_rect(Rect2(c + Vector2(-14, -2), Vector2(28, 22)), GameConfig.COL_DIM)
            draw_arc(c + Vector2(0, -2), 10, PI, TAU, 16, GameConfig.COL_DIM, 5.0, true)

var _tab := "skins"
var _selected := ""
var _grid: GridContainer
var _info_name: Label
var _info_desc: Label
var _action: Button
var _tab_skins: Button
var _tab_cores: Button
var _cards := {}

func _ready() -> void:
    add_backdrop(-6.0, false)
    backdrop.lane = 1.0
    var root := UIKit.safe_root(self)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 16)
    root.add_child(v)

    var top := HBoxContainer.new()
    top.add_theme_constant_override("separation", 16)
    var back := UIKit.button("BACK", "", Vector2(190, 84), 28)
    back.pressed.connect(func() -> void: UIManager.go("menu"))
    top.add_child(back)
    top.add_child(UIKit.label("COLLECTION", 44, GameConfig.COL_CYAN))
    top.get_child(1).size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(CrystalChip.new())
    v.add_child(top)

    v.add_child(UIKit.spacer(520))   # window onto the 3D preview

    var tabs := HBoxContainer.new()
    tabs.add_theme_constant_override("separation", 14)
    _tab_skins = UIKit.button("SPHERES", "", Vector2(0, 84), 28)
    _tab_skins.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _tab_skins.pressed.connect(func() -> void: _set_tab("skins"))
    _tab_cores = UIKit.button("CORES", "", Vector2(0, 84), 28)
    _tab_cores.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _tab_cores.pressed.connect(func() -> void: _set_tab("cores"))
    tabs.add_child(_tab_skins)
    tabs.add_child(_tab_cores)
    v.add_child(tabs)

    var info := UIKit.panel()
    v.add_child(info)
    var ih := HBoxContainer.new()
    ih.add_theme_constant_override("separation", 20)
    info.add_child(ih)
    var iv := VBoxContainer.new()
    iv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _info_name = UIKit.label("", 38, GameConfig.COL_WHITE, HORIZONTAL_ALIGNMENT_LEFT)
    _info_desc = UIKit.label("", 22, GameConfig.COL_DIM, HORIZONTAL_ALIGNMENT_LEFT)
    iv.add_child(_info_name)
    iv.add_child(_info_desc)
    ih.add_child(iv)
    _action = UIKit.button("", "primary", Vector2(300, 96), 30)
    _action.pressed.connect(_on_action)
    ih.add_child(_action)

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    v.add_child(scroll)
    _grid = GridContainer.new()
    _grid.columns = 3
    _grid.add_theme_constant_override("h_separation", 14)
    _grid.add_theme_constant_override("v_separation", 14)
    _grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(_grid)
    _selected = SkinManager.equipped_skin_id()
    _set_tab("skins")

func _set_tab(tab: String) -> void:
    _tab = tab
    _selected = SkinManager.equipped_skin_id() if tab == "skins" else SkinManager.equipped_core_id()
    _tab_skins.disabled = tab == "skins"
    _tab_cores.disabled = tab == "cores"
    backdrop.world.apply_core(SkinManager.equipped_core_id())
    backdrop.player.set_skin(SkinManager.equipped_skin_id())
    _rebuild()
    _preview(_selected)

func _entries() -> Array:
    return SkinCatalog.SKINS if _tab == "skins" else SkinCatalog.CORES

func _owned(id: String) -> bool:
    return ProgressionManager.owns_skin(id) if _tab == "skins" else ProgressionManager.owns_core(id)

func _equipped(id: String) -> bool:
    return (SkinManager.equipped_skin_id() if _tab == "skins" else SkinManager.equipped_core_id()) == id

func _rebuild() -> void:
    for c in _grid.get_children():
        c.queue_free()
    _cards.clear()
    for e in _entries():
        var id: String = e["id"]
        var b := Button.new()
        b.custom_minimum_size = Vector2(0, 212)
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.focus_mode = Control.FOCUS_NONE
        var card := VBoxContainer.new()
        card.set_anchors_preset(Control.PRESET_FULL_RECT)
        card.alignment = BoxContainer.ALIGNMENT_CENTER
        card.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var sw := Swatch.new()
        sw.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        if _tab == "skins":
            sw.color = Color(e["color"])
            sw.glow = Color(e["glow"])
        else:
            sw.color = Color(e["core"])
            sw.glow = Color(e["emit"])
            sw.is_core = true
        sw.locked = not _owned(id)
        card.add_child(sw)
        var nl := UIKit.label(e["name"], 20, GameConfig.COL_WHITE)
        nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
        card.add_child(nl)
        var status := ""
        var scol := GameConfig.COL_DIM
        if _equipped(id):
            status = "EQUIPPED"
            scol = GameConfig.COL_CYAN
        elif _owned(id):
            status = "OWNED"
            scol = GameConfig.COL_WHITE
        else:
            status = "%d" % int(e["price"])
            scol = GameConfig.COL_GOLD
        var sl := UIKit.label(status, 22, scol)
        sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
        card.add_child(sl)
        b.add_child(card)
        b.pressed.connect(func() -> void: _select(id))
        _grid.add_child(b)
        _cards[id] = b

func _select(id: String) -> void:
    _selected = id
    _preview(id)

func _preview(id: String) -> void:
    if _tab == "skins":
        backdrop.player.set_skin(id)
    else:
        backdrop.world.apply_core(id)
    var e: Dictionary = SkinCatalog.get_skin(id) if _tab == "skins" else SkinCatalog.get_core(id)
    _info_name.text = e["name"]
    _info_desc.text = e.get("desc", "Changes the look of the scenery. Never affects difficulty.")
    if _equipped(id):
        _action.text = "EQUIPPED"
        _action.disabled = true
    elif _owned(id):
        _action.text = "EQUIP"
        _action.disabled = false
    else:
        var price: int = int(e["price"])
        _action.text = "UNLOCK  %d" % price
        _action.disabled = ProgressionManager.crystals() < price

func _on_action() -> void:
    var id := _selected
    if _owned(id):
        if _tab == "skins":
            ProgressionManager.equip_skin(id)
        else:
            ProgressionManager.equip_core(id)
    else:
        var r := ProgressionManager.unlock_skin(id) if _tab == "skins" else ProgressionManager.unlock_core(id)
        if r["ok"]:
            AudioManager.play_sfx("unlock")
            if _tab == "skins":
                ProgressionManager.equip_skin(id)
            else:
                ProgressionManager.equip_core(id)
            GameManager.vibrate(30)
    _rebuild()
    _preview(id)

func on_back() -> void:
    UIManager.go("menu")
