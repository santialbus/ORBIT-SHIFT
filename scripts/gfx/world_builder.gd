class_name WorldBuilder
extends Node3D
## Builds the static 3D scenery shared by gameplay, menu and collection preview:
## environment (bloom), camera rig, central core with rings, three orbit tracks, starfield and floor.

const CAM_DISTANCE := 11.6
const CAM_ELEVATION_DEG := 63.0

var camera: Camera3D
var env: Environment
var core_mat: ShaderMaterial
var core_node: Node3D
var _ring_a: MeshInstance3D
var _ring_b: MeshInstance3D
var _ring_mats: Array[ShaderMaterial] = []
var _track_mats: Array[ShaderMaterial] = []
var _line_mats: Array[ShaderMaterial] = []
var _floor_mat: ShaderMaterial
var _core_light: OmniLight3D
var _stars: Node3D
var _pulse := 0.0
var _intensity := 1.0
var _shake := 0.0
var _time := 0.0
var _focus := Vector3.ZERO
var palette: Dictionary = {}
var lane_highlight := [0.0, 1.0, 0.0]

func build(core_id: String, cam_offset_y: float = 0.0) -> void:
    _build_environment()
    _build_camera(cam_offset_y)
    _build_floor()
    _build_stars()
    _build_core()
    _build_tracks()
    apply_core(core_id)

func _build_environment() -> void:
    env = Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = GameConfig.COL_BG
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.25, 0.3, 0.55)
    env.ambient_light_energy = 0.55
    var high := int(SaveManager.data["settings"]["quality"]) > 0
    env.glow_enabled = high
    env.glow_intensity = 0.9
    env.glow_strength = 1.0
    env.glow_bloom = 0.08
    env.glow_hdr_threshold = 0.85
    env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
    var we := WorldEnvironment.new()
    we.environment = env
    add_child(we)

func _build_camera(offset_y: float) -> void:
    camera = Camera3D.new()
    camera.fov = 52.0
    camera.keep_aspect = Camera3D.KEEP_WIDTH
    camera.near = 0.1
    camera.far = 80.0
    add_child(camera)
    _focus = Vector3(0, offset_y, 0)
    _update_camera(0.0)

func _update_camera(sway: float) -> void:
    var el := deg_to_rad(CAM_ELEVATION_DEG)
    var pos := _focus + Vector3(sin(_time * 0.37) * 0.25 * sway, sin(el) * CAM_DISTANCE, cos(el) * CAM_DISTANCE)
    pos += Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * _shake * 0.35
    camera.position = pos
    camera.look_at(_focus + Vector3(0, 0, -0.25), Vector3.UP)

func _build_floor() -> void:
    var mi := MeshInstance3D.new()
    var pm := PlaneMesh.new()
    pm.size = Vector2(60, 60)
    mi.mesh = pm
    _floor_mat = ShaderMaterial.new()
    _floor_mat.shader = load("res://shaders/floor.gdshader")
    mi.material_override = _floor_mat
    mi.position = Vector3(0, -2.6, 0)
    mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(mi)

func _build_stars() -> void:
    _stars = Node3D.new()
    add_child(_stars)
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    var count := 140 if int(SaveManager.data["settings"]["quality"]) > 0 else 60
    mm.instance_count = count
    var sm := SphereMesh.new()
    sm.radius = 0.045
    sm.height = 0.09
    sm.radial_segments = 4
    sm.rings = 2
    var mat := StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color = Color(0.75, 0.82, 1.0, 1.0)
    sm.material = mat
    mm.mesh = sm
    var rng := RandomNumberGenerator.new()
    rng.seed = 424242
    for i in count:
        var a := rng.randf() * TAU
        var r := rng.randf_range(4.5, 24.0)
        var y := rng.randf_range(-12.0, -2.0)
        var s := rng.randf_range(0.5, 1.8)
        mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, s)), Vector3(cos(a) * r, y, sin(a) * r)))
    var mmi := MultiMeshInstance3D.new()
    mmi.multimesh = mm
    mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    _stars.add_child(mmi)

func _build_core() -> void:
    core_node = Node3D.new()
    add_child(core_node)
    var gem := MeshInstance3D.new()
    gem.mesh = MeshFactory.core_gem()
    core_mat = ShaderMaterial.new()
    core_mat.shader = load("res://shaders/core.gdshader")
    gem.material_override = core_mat
    core_node.add_child(gem)
    _ring_a = _make_ring(1.35, 0.045, Vector3(0.0, 0.0, 0.0))
    _ring_b = _make_ring(1.62, 0.035, Vector3(PI / 2.0, 0.0, 0.0))
    _core_light = OmniLight3D.new()
    _core_light.omni_range = 9.0
    _core_light.light_energy = 1.6
    core_node.add_child(_core_light)

func _make_ring(radius: float, thickness: float, rot: Vector3) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    mi.mesh = MeshFactory.torus(radius - thickness, radius + thickness)
    var m := ShaderMaterial.new()
    m.shader = load("res://shaders/neon.gdshader")
    m.set_shader_parameter("base_glow", 1.2)
    m.set_shader_parameter("body_color", Color(0.05, 0.05, 0.1))
    _ring_mats.append(m)
    mi.material_override = m
    mi.rotation = rot
    core_node.add_child(mi)
    return mi

func _build_tracks() -> void:
    for lane in OrbitMath.LANE_COUNT:
        var r: float = OrbitMath.LANE_RADII[lane]
        var band := MeshInstance3D.new()
        band.mesh = MeshFactory.ring(r, 0.5, -0.02)
        var bm := ShaderMaterial.new()
        bm.shader = load("res://shaders/zone.gdshader")
        bm.set_shader_parameter("state", 0.0)
        band.material_override = bm
        add_child(band)
        _track_mats.append(bm)
        var line := MeshInstance3D.new()
        line.mesh = MeshFactory.ring(r, 0.05, 0.0)
        var lm := ShaderMaterial.new()
        lm.shader = load("res://shaders/line.gdshader")
        lm.set_shader_parameter("strength", 0.7)
        line.material_override = lm
        add_child(line)
        _line_mats.append(lm)

func apply_core(core_id: String) -> void:
    palette = SkinManager.core_palette(core_id)
    env.background_color = palette["bg"]
    core_mat.set_shader_parameter("core_color", palette["core"])
    core_mat.set_shader_parameter("emit_color", palette["emit"])
    _core_light.light_color = palette["light"]
    for m in _ring_mats:
        m.set_shader_parameter("color", palette["ring"])
    for m in _line_mats:
        m.set_shader_parameter("color", palette["track"])
    for m in _track_mats:
        m.set_shader_parameter("color", palette["track"])
    _floor_mat.set_shader_parameter("base_color", (palette["bg"] as Color).lightened(0.05))
    _floor_mat.set_shader_parameter("ring_color", palette["track"])

## Pop the core (pickups) and set the combo-driven intensity (1..2).
func pulse_core(amount: float = 1.0) -> void:
    _pulse = maxf(_pulse, amount)

func set_intensity(multiplier: int) -> void:
    _intensity = 1.0 + 0.12 * float(clampi(multiplier - 1, 0, 8))

func shake(amount: float) -> void:
    _shake = maxf(_shake, amount)

func set_lane_position(lane_pos: float) -> void:
    for i in 3:
        var d := absf(lane_pos - float(i))
        var w := clampf(1.0 - d, 0.0, 1.0)
        lane_highlight[i] = w
        var m := _line_mats[i]
        m.set_shader_parameter("strength", 0.55 + 1.1 * w)
        (_track_mats[i] as ShaderMaterial).set_shader_parameter("state", 0.1 + 0.4 * w)

func _process(delta: float) -> void:
    _time += delta
    _pulse = maxf(0.0, _pulse - delta * 3.0)
    _shake = maxf(0.0, _shake - delta * 2.5)
    core_node.rotate_y(delta * 0.35)
    _ring_a.rotate_x(delta * 0.8)
    _ring_a.rotate_z(delta * 0.3)
    _ring_b.rotate_y(delta * -0.6)
    _ring_b.rotate_x(delta * 0.2)
    _stars.rotate_y(delta * 0.01)
    core_mat.set_shader_parameter("pulse", _pulse)
    core_mat.set_shader_parameter("intensity", _intensity)
    var s := 1.0 + _pulse * 0.12
    core_node.scale = Vector3(s, s, s)
    _core_light.light_energy = 1.4 + _pulse * 1.5 + (_intensity - 1.0)
    _update_camera(1.0)
