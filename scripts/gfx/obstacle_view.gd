class_name ObstacleView
extends Node3D
## Pooled visual for one ObstacleData. Owns its own material so per-obstacle uniforms are safe.

const NEON_SHADER := "res://shaders/neon.gdshader"
const ZONE_SHADER := "res://shaders/zone.gdshader"
const HEIGHT := 0.42

var data: ObstacleData
var _mi: MeshInstance3D
var _mat: ShaderMaterial
var _born_time := 0.0

func _init() -> void:
    _mi = MeshInstance3D.new()
    _mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(_mi)

func bind(d: ObstacleData, t_now: float) -> void:
    data = d
    d.view = self
    _born_time = t_now
    var radius: float = OrbitMath.LANE_RADII[d.lane]
    _mat = ShaderMaterial.new()
    var qhalf := snappedf(d.half, 0.02)
    match d.kind:
        ObstacleData.Kind.STATIC:
            _mi.mesh = MeshFactory.arc_block(radius, qhalf, 0.62, HEIGHT, 0.08)
            _mat.shader = load(NEON_SHADER)
            _mat.set_shader_parameter("color", GameConfig.COL_CORAL)
        ObstacleData.Kind.MOVING:
            _mi.mesh = MeshFactory.arc_block(radius, qhalf, 0.55, HEIGHT * 0.9, 0.1)
            _mat.shader = load(NEON_SHADER)
            _mat.set_shader_parameter("color", Color("ff6a88"))
            _mat.set_shader_parameter("shimmer", 1.0)
            _mat.set_shader_parameter("body_color", Color(0.12, 0.05, 0.14))
        ObstacleData.Kind.BLOCK:
            _mi.mesh = MeshFactory.arc_block(radius, qhalf, 0.7, HEIGHT * 1.35, 0.14)
            _mat.shader = load(NEON_SHADER)
            _mat.set_shader_parameter("color", Color("ff2d4a"))
            _mat.set_shader_parameter("base_glow", 0.8)
            _mat.set_shader_parameter("rim_strength", 3.0)
        ObstacleData.Kind.ZONE:
            _mi.mesh = MeshFactory.zone_strip(radius, qhalf, 0.95)
            _mat.shader = load(ZONE_SHADER)
            _mat.set_shader_parameter("color", Color("ff3a4d"))
    _mat.set_shader_parameter("appear", 0.0)
    _mi.material_override = _mat
    visible = true
    update_view(t_now)

func update_view(t: float) -> void:
    if data == null:
        return
    rotation.y = -data.angle_at(t)
    var a := clampf((t - _born_time) / 0.35, 0.0, 1.0)
    _mat.set_shader_parameter("appear", a)
    scale = Vector3(1.0, 0.2 + 0.8 * a, 1.0)
    if data.kind == ObstacleData.Kind.ZONE:
        _mat.set_shader_parameter("state", data.zone_warning(t))
    elif data.passed:
        _mat.set_shader_parameter("alpha", 0.55)

func flash_hit() -> void:
    _mat.set_shader_parameter("flash", 1.0)

func release() -> void:
    if data != null:
        data.view = null
    data = null
    visible = false
