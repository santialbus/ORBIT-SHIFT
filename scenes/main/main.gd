extends Control
## Splash screen: animated logo + energy rings, then fades into the main menu.

var _rings: Control
var _t := 0.0
var _go := false

class Rings extends Control:
    var t := 0.0
    func _draw() -> void:
        var c := size / 2.0
        for i in 3:
            var r := 150.0 + i * 70.0
            var a0 := t * (1.2 + i * 0.5) * (1 if i % 2 == 0 else -1)
            draw_arc(c, r, a0, a0 + 2.2, 48, GameConfig.COL_VIOLET.lerp(GameConfig.COL_CYAN, i / 2.0), 6.0, true)
            draw_arc(c, r, a0 + PI, a0 + PI + 1.0, 32, GameConfig.COL_CORAL, 6.0, true)
        draw_circle(c, 40.0 + sin(t * 4.0) * 4.0, GameConfig.COL_CORE)
        draw_arc(c, 40.0, 0, TAU, 32, Color("2b5cff"), 4.0, true)

func _ready() -> void:
    theme = UIKit.theme()
    GameStateManager.set_state(GameStateManager.State.BOOT)
    var bg := ColorRect.new()
    bg.color = GameConfig.COL_BG
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    _rings = Rings.new()
    _rings.set_anchors_preset(Control.PRESET_CENTER)
    _rings.custom_minimum_size = Vector2(700, 700)
    _rings.size = Vector2(700, 700)
    _rings.position = Vector2(190, 400)
    add_child(_rings)
    var logo := TextureRect.new()
    if ResourceLoader.exists("res://assets/icons/logo.png"):
        logo.texture = load("res://assets/icons/logo.png")
    logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    logo.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    logo.offset_left = -480
    logo.offset_right = 480
    logo.offset_top = -760
    logo.offset_bottom = -360
    logo.modulate.a = 0.0
    logo.pivot_offset = Vector2(480, 200)
    logo.scale = Vector2(0.85, 0.85)
    add_child(logo)
    var tw := create_tween()
    tw.tween_property(logo, "modulate:a", 1.0, 0.7)
    tw.parallel().tween_property(logo, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    var tag := UIKit.label("ONE FINGER. THREE ORBITS. ONE MISTAKE.", 26, GameConfig.COL_DIM)
    tag.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    tag.offset_left = -520
    tag.offset_right = 520
    tag.offset_top = -300
    tag.offset_bottom = -250
    tag.modulate.a = 0.0
    add_child(tag)
    tw.parallel().tween_property(tag, "modulate:a", 1.0, 1.0).set_delay(0.5)
    AudioManager.play_sfx("start")

func _process(delta: float) -> void:
    _t += delta
    (_rings as Rings).t = _t
    _rings.queue_redraw()
    if _t > 2.0 and not _go:
        _go = true
        UIManager.go("menu")

func _input(event: InputEvent) -> void:
    if not _go and _t > 0.5 and event is InputEventMouseButton and event.pressed:
        _go = true
        UIManager.go("menu")
