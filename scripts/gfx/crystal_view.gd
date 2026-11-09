class_name CrystalView
extends Node3D
## Pooled energy crystal: spins, bobs and fades in.

var _mi: MeshInstance3D
var _mat: ShaderMaterial
var _phase := 0.0
var _born := 0.0

func _init() -> void:
    _mi = MeshInstance3D.new()
    _mi.mesh = MeshFactory.crystal()
    _mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    _mat = ShaderMaterial.new()
    _mat.shader = load("res://shaders/neon.gdshader")
    _mat.set_shader_parameter("color", GameConfig.COL_GOLD)
    _mat.set_shader_parameter("body_color", Color(0.35, 0.18, 0.02))
    _mat.set_shader_parameter("base_glow", 0.9)
    _mat.set_shader_parameter("rim_strength", 2.4)
    _mat.set_shader_parameter("rim_power", 1.6)
    _mi.material_override = _mat
    add_child(_mi)

func setup(theta: float, lane: int, t_now: float) -> void:
    _phase = randf() * TAU
    _born = t_now
    position = OrbitMath.polar_to_vec3(theta, float(OrbitMath.LANE_RADII[lane]), 0.28)
    _mi.scale = Vector3.ZERO
    visible = true

func animate(t: float, delta: float) -> void:
    _mi.rotate_y(delta * 2.6)
    var a := clampf((t - _born) / 0.3, 0.0, 1.0)
    var bob := 1.0 + 0.08 * sin(t * 4.0 + _phase)
    var s := a * bob
    _mi.scale = Vector3(s, s, s)

func release() -> void:
    visible = false
