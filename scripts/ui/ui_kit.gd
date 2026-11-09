class_name UIKit
extends RefCounted
## Code-driven UI toolkit: neon theme, styled buttons/labels/panels and small helpers.

static var _theme: Theme
static var _font: Font

static func font() -> Font:
    if _font == null:
        if ResourceLoader.exists("res://assets/fonts/Orbitron.ttf"):
            var ff := FontVariation.new()
            ff.base_font = load("res://assets/fonts/Orbitron.ttf")
            ff.variation_opentype = {"wght": 700}
            _font = ff
        else:
            _font = ThemeDB.fallback_font
    return _font

static func box(bg: Color, border: Color = Color(0, 0, 0, 0), radius: int = 22, border_w: int = 3, glow: float = 0.0) -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = bg
    sb.border_color = border
    sb.set_border_width_all(border_w)
    sb.set_corner_radius_all(radius)
    sb.content_margin_left = 28
    sb.content_margin_right = 28
    sb.content_margin_top = 14
    sb.content_margin_bottom = 14
    if glow > 0.0:
        sb.shadow_color = Color(border.r, border.g, border.b, 0.55)
        sb.shadow_size = int(glow)
    return sb

static func theme() -> Theme:
    if _theme != null:
        return _theme
    var t := Theme.new()
    t.default_font = font()
    t.default_font_size = 34
    # Primary (cyan filled)
    t.set_type_variation("PrimaryButton", "Button")
    t.set_stylebox("normal", "PrimaryButton", box(GameConfig.COL_CYAN, GameConfig.COL_WHITE, 34, 3, 26))
    t.set_stylebox("hover", "PrimaryButton", box(GameConfig.COL_CYAN.lightened(0.15), GameConfig.COL_WHITE, 34, 3, 30))
    t.set_stylebox("pressed", "PrimaryButton", box(GameConfig.COL_CYAN.darkened(0.2), GameConfig.COL_WHITE, 34, 3, 12))
    t.set_stylebox("disabled", "PrimaryButton", box(Color(0.2, 0.3, 0.35), Color(0.3, 0.4, 0.45), 34, 3))
    for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
        t.set_color(st, "PrimaryButton", GameConfig.COL_BG)
    t.set_color("font_disabled_color", "PrimaryButton", Color(0.55, 0.65, 0.7))
    # Secondary (outlined)
    t.set_stylebox("normal", "Button", box(Color(0.04, 0.08, 0.18, 0.85), GameConfig.COL_VIOLET, 22, 3, 14))
    t.set_stylebox("hover", "Button", box(Color(0.08, 0.14, 0.3, 0.9), GameConfig.COL_CYAN, 22, 3, 16))
    t.set_stylebox("pressed", "Button", box(Color(0.02, 0.05, 0.12, 0.95), GameConfig.COL_CYAN, 22, 3, 6))
    t.set_stylebox("disabled", "Button", box(Color(0.05, 0.07, 0.12, 0.7), Color(0.2, 0.25, 0.4), 22, 3))
    t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
    t.set_color("font_color", "Button", GameConfig.COL_WHITE)
    t.set_color("font_hover_color", "Button", GameConfig.COL_WHITE)
    t.set_color("font_pressed_color", "Button", GameConfig.COL_CYAN)
    t.set_color("font_disabled_color", "Button", GameConfig.COL_DIM)
    t.set_font_size("font_size", "Button", 32)
    # Danger
    t.set_type_variation("DangerButton", "Button")
    t.set_stylebox("normal", "DangerButton", box(Color(0.2, 0.04, 0.08, 0.9), GameConfig.COL_CORAL, 22, 3, 14))
    t.set_stylebox("hover", "DangerButton", box(Color(0.3, 0.06, 0.1, 0.95), GameConfig.COL_CORAL, 22, 3, 18))
    t.set_stylebox("pressed", "DangerButton", box(Color(0.12, 0.02, 0.05, 0.95), GameConfig.COL_CORAL, 22, 3, 6))
    # Panels
    t.set_type_variation("GlassPanel", "PanelContainer")
    t.set_stylebox("panel", "GlassPanel", box(Color(0.04, 0.08, 0.18, 0.82), Color(0.35, 0.3, 0.8, 0.7), 26, 2))
    t.set_type_variation("CardPanel", "PanelContainer")
    t.set_stylebox("panel", "CardPanel", box(Color(0.05, 0.09, 0.2, 0.9), Color(0.3, 0.35, 0.7, 0.6), 22, 2))
    # Progress bars
    var bg := box(Color(0.1, 0.14, 0.26, 0.9), Color(0, 0, 0, 0), 10, 0)
    var fill := box(GameConfig.COL_CYAN, Color(0, 0, 0, 0), 10, 0)
    bg.content_margin_top = 0
    bg.content_margin_bottom = 0
    t.set_stylebox("background", "ProgressBar", bg)
    t.set_stylebox("fill", "ProgressBar", fill)
    t.set_font_size("font_size", "Label", 32)
    t.set_color("font_color", "Label", GameConfig.COL_WHITE)
    _theme = t
    return t

static func label(text: String, size: int = 32, color: Color = GameConfig.COL_WHITE, align: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    l.horizontal_alignment = align
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.autowrap_mode = TextServer.AUTOWRAP_OFF
    return l

static func button(text: String, kind: String = "", min_size: Vector2 = Vector2(0, 110), font_size: int = 34) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = min_size
    b.focus_mode = Control.FOCUS_NONE
    b.add_theme_font_size_override("font_size", font_size)
    match kind:
        "primary": b.theme_type_variation = "PrimaryButton"
        "danger": b.theme_type_variation = "DangerButton"
    b.pressed.connect(func() -> void: AudioManager.play_sfx("click"))
    return b

static func panel(variation: String = "GlassPanel") -> PanelContainer:
    var p := PanelContainer.new()
    p.theme_type_variation = variation
    return p

static func spacer(h: float = 0.0, expand: bool = false) -> Control:
    var c := Control.new()
    c.custom_minimum_size = Vector2(0, h)
    if expand:
        c.size_flags_vertical = Control.SIZE_EXPAND_FILL
    c.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return c

static func hspacer(expand: bool = true) -> Control:
    var c := Control.new()
    if expand:
        c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    c.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return c

static func progress(value: float, height: float = 16.0, color: Color = GameConfig.COL_CYAN) -> ProgressBar:
    var pb := ProgressBar.new()
    pb.min_value = 0.0
    pb.max_value = 1.0
    pb.value = value
    pb.show_percentage = false
    pb.custom_minimum_size = Vector2(0, height)
    var fill := box(color, Color(0, 0, 0, 0), 10, 0)
    pb.add_theme_stylebox_override("fill", fill)
    return pb

## Root control for a full-screen UI layer that honours the device safe area.
static func safe_root(parent: Node) -> MarginContainer:
    var m := MarginContainer.new()
    m.set_anchors_preset(Control.PRESET_FULL_RECT)
    m.theme = theme()
    var sm: Dictionary = UIManager.safe_margins()
    m.add_theme_constant_override("margin_left", int(sm["left"]) + 36)
    m.add_theme_constant_override("margin_right", int(sm["right"]) + 36)
    m.add_theme_constant_override("margin_top", int(sm["top"]) + 28)
    m.add_theme_constant_override("margin_bottom", int(sm["bottom"]) + 28)
    parent.add_child(m)
    return m

## Small drawn crystal icon.
class CrystalIcon extends Control:
    var color := GameConfig.COL_GOLD
    func _init(sz: float = 44.0) -> void:
        custom_minimum_size = Vector2(sz, sz)
        mouse_filter = Control.MOUSE_FILTER_IGNORE
    func _draw() -> void:
        var c := size / 2.0
        var w := size.x * 0.34
        var h := size.y * 0.46
        draw_colored_polygon(PackedVector2Array([c + Vector2(0, -h), c + Vector2(w, 0), c + Vector2(0, h), c + Vector2(-w, 0)]), color)
        draw_polyline(PackedVector2Array([c + Vector2(0, -h), c + Vector2(w, 0), c + Vector2(0, h), c + Vector2(-w, 0), c + Vector2(0, -h)]), Color(1, 0.95, 0.7), 2.0, true)
        draw_line(c + Vector2(-w, 0), c + Vector2(w, 0), Color(1, 1, 1, 0.5), 2.0)

static func crystal_icon(sz: float = 44.0) -> Control:
    return CrystalIcon.new(sz)
