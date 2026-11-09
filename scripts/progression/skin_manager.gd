extends Node
## Autoload SkinManager: turns catalog entries into materials / palettes and tracks the equipped selection.

const SKIN_SHADER := "res://shaders/skin.gdshader"
var _shader: Shader

func _ready() -> void:
    _shader = load(SKIN_SHADER)

func equipped_skin_id() -> String:
    return str(SaveManager.data["equipped_skin"])

func equipped_core_id() -> String:
    return str(SaveManager.data["equipped_core"])

func make_skin_material(id: String) -> ShaderMaterial:
    if _shader == null:
        _shader = load(SKIN_SHADER)
    var def := SkinCatalog.get_skin(id)
    var m := ShaderMaterial.new()
    m.shader = _shader
    m.set_shader_parameter("base_color", Color(def["color"]))
    m.set_shader_parameter("glow_color", Color(def["glow"]))
    m.set_shader_parameter("style", int(def["style"]))
    return m

func glow_color(id: String) -> Color:
    return Color(SkinCatalog.get_skin(id)["glow"])

func core_palette(id: String) -> Dictionary:
    var c := SkinCatalog.get_core(id)
    return {
        "core": Color(c["core"]), "emit": Color(c["emit"]), "ring": Color(c["ring"]),
        "track": Color(c["track"]), "bg": Color(c["bg"]), "light": Color(c["light"]),
    }
