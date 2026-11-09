class_name MeshFactory
extends RefCounted
## Procedural low-poly meshes (faceted, neon sci-fi). Baked copies live in assets/models/*.tres
## (see tools/bake_assets.gd); when a baked file is missing the mesh is generated at runtime.

static var _cache := {}

static func _cached(key: String, builder: Callable) -> Mesh:
    if _cache.has(key):
        return _cache[key]
    var m: Mesh = builder.call()
    _cache[key] = m
    return m

static func _baked(path: String) -> Mesh:
    if ResourceLoader.exists(path):
        var r = load(path)
        if r is Mesh:
            return r
    return null

## Sweeps a 2D profile (x = radial distance, y = height) around the Y axis from angle a0 to a1.
## The mesh is built around the +X axis convention used by ObstacleView (angle 0 = +X).
static func sweep(profile: Array, a0: float, a1: float, segments: int, caps: bool, closed_profile: bool = true) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var n := profile.size()
    var edges := n if closed_profile else n - 1
    for s in segments:
        var t0 := lerpf(a0, a1, float(s) / float(segments))
        var t1 := lerpf(a0, a1, float(s + 1) / float(segments))
        for e in edges:
            var p0: Vector2 = profile[e]
            var p1: Vector2 = profile[(e + 1) % n]
            var v00 := Vector3(cos(t0) * p0.x, p0.y, sin(t0) * p0.x)
            var v01 := Vector3(cos(t0) * p1.x, p1.y, sin(t0) * p1.x)
            var v10 := Vector3(cos(t1) * p0.x, p0.y, sin(t1) * p0.x)
            var v11 := Vector3(cos(t1) * p1.x, p1.y, sin(t1) * p1.x)
            _tri(st, v00, v10, v11)
            _tri(st, v00, v11, v01)
    if caps and closed_profile:
        for end in 2:
            var ang := a0 if end == 0 else a1
            var pts: Array = []
            for p in profile:
                pts.append(Vector3(cos(ang) * p.x, p.y, sin(ang) * p.x))
            var c := Vector3.ZERO
            for q in pts:
                c += q
            c /= float(pts.size())
            for i in pts.size():
                var qa: Vector3 = pts[i]
                var qb: Vector3 = pts[(i + 1) % pts.size()]
                if end == 0:
                    _tri(st, c, qb, qa)
                else:
                    _tri(st, c, qa, qb)
    st.generate_normals()
    return st.commit()

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)

## Beveled arc barrier of the given angular half-width centered on angle 0.
static func arc_block(radius: float, half: float, thickness: float, height: float, bevel: float) -> Mesh:
    var key := "arc_%.2f_%.2f_%.2f_%.2f_%.2f" % [radius, half, thickness, height, bevel]
    return _cached(key, func() -> Mesh:
        var ri := radius - thickness * 0.5
        var ro := radius + thickness * 0.5
        var prof := [
            Vector2(ri, 0.0), Vector2(ro, 0.0), Vector2(ro, height - bevel),
            Vector2(ro - bevel, height), Vector2(ri + bevel, height), Vector2(ri, height - bevel),
        ]
        var segs := maxi(3, int(ceil(half * 2.0 / 0.16)))
        return sweep(prof, -half, half, segs, true))

## Flat hazard strip for ZONE obstacles.
static func zone_strip(radius: float, half: float, width: float) -> Mesh:
    var key := "zone_%.2f_%.2f_%.2f" % [radius, half, width]
    return _cached(key, func() -> Mesh:
        var prof := [Vector2(radius - width * 0.5, 0.02), Vector2(radius + width * 0.5, 0.02), Vector2(radius + width * 0.5, 0.07), Vector2(radius - width * 0.5, 0.07)]
        var segs := maxi(4, int(ceil(half * 2.0 / 0.14)))
        return sweep(prof, -half, half, segs, true))

## Full flat ring (orbit track) - open profile strip.
static func ring(radius: float, width: float, y: float = 0.0, segments: int = 96) -> Mesh:
    var key := "ring_%.2f_%.3f_%.2f" % [radius, width, y]
    return _cached(key, func() -> Mesh:
        var prof := [Vector2(radius - width * 0.5, y), Vector2(radius + width * 0.5, y)]
        return sweep(prof, 0.0, TAU, segments, false, false))

## Elongated faceted bipyramid used for energy crystals.
static func crystal() -> Mesh:
    var baked := _baked("res://assets/models/crystal.tres")
    if baked != null:
        return baked
    return _cached("crystal", func() -> Mesh:
        var st := SurfaceTool.new()
        st.begin(Mesh.PRIMITIVE_TRIANGLES)
        var top := Vector3(0, 0.42, 0)
        var bot := Vector3(0, -0.42, 0)
        var n := 6
        for i in n:
            var a0 := TAU * float(i) / float(n)
            var a1 := TAU * float(i + 1) / float(n)
            var r0 := 0.2 if i % 2 == 0 else 0.15
            var r1 := 0.2 if (i + 1) % 2 == 0 else 0.15
            var p0 := Vector3(cos(a0) * r0, 0.0, sin(a0) * r0)
            var p1 := Vector3(cos(a1) * r1, 0.0, sin(a1) * r1)
            _tri(st, top, p1, p0)
            _tri(st, bot, p0, p1)
        st.generate_normals()
        return st.commit())

## Icosphere with flat normals (faceted gem look) for the central core.
static func core_gem(radius: float = 0.95, subdivisions: int = 1) -> Mesh:
    var baked := _baked("res://assets/models/core_gem.tres")
    if baked != null:
        return baked
    return _cached("core_gem_%d" % subdivisions, func() -> Mesh:
        var t := (1.0 + sqrt(5.0)) / 2.0
        var verts: Array = [
            Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
            Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
            Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1),
        ]
        for i in verts.size():
            verts[i] = (verts[i] as Vector3).normalized()
        var faces: Array = [
            [0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
            [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
            [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
            [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1],
        ]
        for _s in subdivisions:
            var nf: Array = []
            for f in faces:
                var a: Vector3 = verts[f[0]]
                var b: Vector3 = verts[f[1]]
                var c: Vector3 = verts[f[2]]
                var ab := ((a + b) * 0.5).normalized()
                var bc := ((b + c) * 0.5).normalized()
                var ca := ((c + a) * 0.5).normalized()
                var base := verts.size()
                verts.append(ab)
                verts.append(bc)
                verts.append(ca)
                nf.append([f[0], base, base + 2])
                nf.append([f[1], base + 1, base])
                nf.append([f[2], base + 2, base + 1])
                nf.append([base, base + 1, base + 2])
            faces = nf
        var st := SurfaceTool.new()
        st.begin(Mesh.PRIMITIVE_TRIANGLES)
        for f in faces:
            st.set_uv(Vector2(0, 0))
            for k in 3:
                var v: Vector3 = verts[f[k]]
                # spherical UVs so the veins in core.gdshader wrap around the gem
                st.set_uv(Vector2(atan2(v.z, v.x) / TAU + 0.5, acos(clampf(v.y, -1.0, 1.0)) / PI))
                st.add_vertex(v * radius)
        st.generate_normals()
        return st.commit())

static func sphere(radius: float, rings: int = 16, segments: int = 28) -> Mesh:
    return _cached("sphere_%.2f_%d_%d" % [radius, rings, segments], func() -> Mesh:
        var m := SphereMesh.new()
        m.radius = radius
        m.height = radius * 2.0
        m.rings = rings
        m.radial_segments = segments
        return m)

static func torus(inner: float, outer: float) -> Mesh:
    return _cached("torus_%.2f_%.2f" % [inner, outer], func() -> Mesh:
        var m := TorusMesh.new()
        m.inner_radius = inner
        m.outer_radius = outer
        m.rings = 48
        m.ring_segments = 8
        return m)

static func quad(size: float) -> Mesh:
    return _cached("quad_%.2f" % size, func() -> Mesh:
        var m := QuadMesh.new()
        m.size = Vector2(size, size)
        return m)
