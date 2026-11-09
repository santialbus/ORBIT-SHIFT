extends Node
## Autoload UIManager: scene navigation with fade transitions + safe-area helper.

const SCENES := {
    "main": "res://scenes/main/main.tscn",
    "menu": "res://scenes/menu/menu.tscn",
    "gameplay": "res://scenes/gameplay/gameplay.tscn",
    "results": "res://scenes/results/results.tscn",
    "collection": "res://scenes/collection/collection.tscn",
    "settings": "res://scenes/settings/settings.tscn",
    "tutorial": "res://scenes/tutorial/tutorial.tscn",
    "missions": "res://scenes/missions/missions.tscn",
}

var _layer: CanvasLayer
var _fade: ColorRect
var _busy := false
var params: Dictionary = {}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _layer = CanvasLayer.new()
    _layer.layer = 100
    add_child(_layer)
    _fade = ColorRect.new()
    _fade.color = GameConfig.COL_BG
    _fade.set_anchors_preset(Control.PRESET_FULL_RECT)
    _fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _fade.modulate.a = 0.0
    _layer.add_child(_fade)

func go(key: String, new_params: Dictionary = {}, fade_time: float = 0.18) -> void:
    if _busy or not SCENES.has(key):
        return
    _busy = true
    params = new_params
    _fade.mouse_filter = Control.MOUSE_FILTER_STOP
    var tw := create_tween()
    tw.tween_property(_fade, "modulate:a", 1.0, fade_time)
    await tw.finished
    get_tree().change_scene_to_file(SCENES[key])
    await get_tree().process_frame
    await get_tree().process_frame
    var tw2 := create_tween()
    tw2.tween_property(_fade, "modulate:a", 0.0, fade_time)
    await tw2.finished
    _fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _busy = false

func is_busy() -> bool:
    return _busy

## Safe-area insets converted to viewport (canvas) units. Falls back to small defaults on desktop.
func safe_margins() -> Dictionary:
    var out := {"top": 12, "bottom": 12, "left": 0, "right": 0}
    var win := DisplayServer.window_get_size()
    var vp := get_tree().root.get_visible_rect().size
    if win.x <= 0 or win.y <= 0:
        return out
    var safe := DisplayServer.get_display_safe_area()
    var screen := DisplayServer.screen_get_size()
    if safe.size.x <= 0 or screen.x <= 0 or not OS.has_feature("mobile"):
        return out
    var sx := vp.x / float(screen.x)
    var sy := vp.y / float(screen.y)
    out["top"] = maxi(12, int(float(safe.position.y) * sy))
    out["left"] = int(float(safe.position.x) * sx)
    out["right"] = int(float(screen.x - safe.end.x) * sx)
    out["bottom"] = maxi(12, int(float(screen.y - safe.end.y) * sy))
    return out

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_GO_BACK_REQUEST:
        var cur := get_tree().current_scene
        if cur != null and cur.has_method("on_back"):
            cur.on_back()
