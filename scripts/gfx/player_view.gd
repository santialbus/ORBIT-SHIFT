class_name PlayerView
extends Node3D
## Visual of the energy sphere: skin-shader sphere, soft halo, light and a motion trail.

var skin_id := "cyan_core"
var _mesh: MeshInstance3D
var _halo: MeshInstance3D
var _halo_mat: ShaderMaterial
var _light: OmniLight3D
var _trail: CPUParticles3D
var _pop := 0.0

func _ready() -> void:
    _mesh = MeshInstance3D.new()
    _mesh.mesh = MeshFactory.sphere(0.3)
    add_child(_mesh)

    _halo = MeshInstance3D.new()
    _halo.mesh = MeshFactory.quad(1.9)
    _halo_mat = ShaderMaterial.new()
    _halo_mat.shader = load("res://shaders/glow_sprite.gdshader")
    _halo.material_override = _halo_mat
    _halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(_halo)

    _light = OmniLight3D.new()
    _light.omni_range = 4.5
    _light.light_energy = 1.2
    _light.shadow_enabled = false
    add_child(_light)

    _trail = CPUParticles3D.new()
    _trail.amount = 36 if int(SaveManager.data["settings"]["quality"]) > 0 else 16
    _trail.lifetime = 0.55
    _trail.local_coords = false
    _trail.emitting = true
    _trail.direction = Vector3.ZERO
    _trail.spread = 180.0
    _trail.initial_velocity_min = 0.0
    _trail.initial_velocity_max = 0.15
    _trail.gravity = Vector3.ZERO
    var tm := SphereMesh.new()
    tm.radius = 0.09
    tm.height = 0.18
    tm.radial_segments = 6
    tm.rings = 3
    var tmat := StandardMaterial3D.new()
    tmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    tmat.vertex_color_use_as_albedo = true
    tmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    tm.material = tmat
    _trail.mesh = tm
    var curve := Curve.new()
    curve.add_point(Vector2(0, 1))
    curve.add_point(Vector2(1, 0))
    _trail.scale_amount_curve = curve
    var grad := Gradient.new()
    grad.set_color(0, Color(1, 1, 1, 0.9))
    grad.set_color(1, Color(1, 1, 1, 0.0))
    _trail.color_ramp = grad
    add_child(_trail)
    set_skin(skin_id)

func set_skin(id: String) -> void:
    skin_id = id
    if _mesh == null:
        return
    _mesh.material_override = SkinManager.make_skin_material(id)
    var g := SkinManager.glow_color(id)
    if SkinCatalog.get_skin(id)["style"] == 7:
        g = Color(SkinCatalog.get_skin(id)["glow"])
    _halo_mat.set_shader_parameter("color", g)
    _halo_mat.set_shader_parameter("strength", 0.55)
    _light.light_color = g
    _trail.color = g

func place(theta: float, lane_pos: float) -> void:
    position = OrbitMath.polar_to_vec3(theta, OrbitMath.lane_radius(lane_pos), 0.0)

func pop(amount: float = 1.0) -> void:
    _pop = amount

func set_visible_trail(on: bool) -> void:
    _trail.emitting = on

func _process(delta: float) -> void:
    _pop = maxf(0.0, _pop - delta * 5.0)
    var s := 1.0 + _pop * 0.35
    _mesh.scale = Vector3(s, s, s)
    _halo.scale = Vector3(1.0 + _pop * 0.5, 1.0 + _pop * 0.5, 1.0)
    _mesh.rotate_y(delta * 1.6)
