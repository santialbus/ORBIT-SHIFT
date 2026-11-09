class_name FxManager
extends Node3D
## Pooled one-shot particle bursts (pickups, impacts, record flares).

const POOL := 8
var _emitters: Array[CPUParticles3D] = []
var _next := 0
var quality := 1

func _ready() -> void:
    quality = int(SaveManager.data["settings"]["quality"])
    for i in POOL:
        var p := CPUParticles3D.new()
        p.one_shot = true
        p.emitting = false
        p.explosiveness = 1.0
        p.lifetime = 0.7
        p.local_coords = false
        p.gravity = Vector3.ZERO
        p.direction = Vector3.UP
        p.spread = 180.0
        var m := SphereMesh.new()
        m.radius = 0.07
        m.height = 0.14
        m.radial_segments = 6
        m.rings = 3
        var mat := StandardMaterial3D.new()
        mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        mat.vertex_color_use_as_albedo = true
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        m.material = mat
        p.mesh = m
        var curve := Curve.new()
        curve.add_point(Vector2(0, 1))
        curve.add_point(Vector2(1, 0))
        p.scale_amount_curve = curve
        var grad := Gradient.new()
        grad.set_color(0, Color(1, 1, 1, 1))
        grad.set_color(1, Color(1, 1, 1, 0))
        p.color_ramp = grad
        add_child(p)
        _emitters.append(p)

func burst(pos: Vector3, color: Color, amount: int = 14, speed: float = 3.0, life: float = 0.7) -> void:
    var p := _emitters[_next]
    _next = (_next + 1) % POOL
    p.global_position = pos
    p.amount = maxi(4, int(amount * (1.0 if quality > 0 else 0.5)))
    p.color = color
    p.initial_velocity_min = speed * 0.4
    p.initial_velocity_max = speed
    p.lifetime = life
    p.restart()
    p.emitting = true
