class_name SaveData
extends RefCounted
## Pure save-file logic: defaults, sanitising/validation, version migration, checksum, encode/decode.
## No file I/O here so everything can be unit tested.

const SALT := "orbit-shift-v1"

static func defaults() -> Dictionary:
    return {
        "version": GameConfig.SAVE_VERSION,
        "record": 0,
        "crystals": 0,
        "skins": ["cyan_core"],
        "cores": ["standard"],
        "equipped_skin": "cyan_core",
        "equipped_core": "standard",
        "tutorial_done": false,
        "missions": {"date": "", "daily": [], "prog_claimed": {}},
        "achievements": {},
        "stats": {
            "runs": 0, "total_time": 0.0, "best_combo": 1, "best_time": 0.0,
            "crystals_collected": 0, "dodged": 0, "near_misses": 0, "records_broken": 0,
        },
        "settings": {
            "music": true, "sfx": true, "vibration": true, "tutorial_enabled": true,
            "music_volume": 0.7, "sfx_volume": 0.9, "control_mode": 0, "quality": 1,
        },
    }

static func _to_int(v, fallback: int, lo: int = 0, hi: int = 2000000000) -> int:
    if v is int or v is float:
        return clampi(int(v), lo, hi)
    return fallback

static func _to_float(v, fallback: float, lo: float, hi: float) -> float:
    if v is int or v is float:
        var f := float(v)
        if is_nan(f) or is_inf(f):
            return fallback
        return clampf(f, lo, hi)
    return fallback

static func _round2(v: float) -> float:
    return float(roundi(v * 100.0)) / 100.0

static func _to_bool(v, fallback: bool) -> bool:
    return v if v is bool else fallback

static func _id_list(v, valid_ids: Array, must_have: String) -> Array:
    var out: Array = []
    if v is Array:
        for x in v:
            if x is String and valid_ids.has(x) and not out.has(x):
                out.append(x)
    if not out.has(must_have):
        out.push_front(must_have)
    return out

## Turns arbitrary decoded data into a valid save dictionary (never throws).
static func sanitize(raw) -> Dictionary:
    var d := defaults()
    if not (raw is Dictionary):
        return d
    var r: Dictionary = raw
    var skin_ids: Array = SkinCatalog.skin_ids()
    var core_ids: Array = SkinCatalog.core_ids()

    d["record"] = _to_int(r.get("record"), 0)
    d["crystals"] = _to_int(r.get("crystals"), 0)
    d["skins"] = _id_list(r.get("skins"), skin_ids, "cyan_core")
    d["cores"] = _id_list(r.get("cores"), core_ids, "standard")
    var es = r.get("equipped_skin")
    d["equipped_skin"] = es if (es is String and (d["skins"] as Array).has(es)) else "cyan_core"
    var ec = r.get("equipped_core")
    d["equipped_core"] = ec if (ec is String and (d["cores"] as Array).has(ec)) else "standard"
    d["tutorial_done"] = _to_bool(r.get("tutorial_done"), false)

    # missions
    var m = r.get("missions")
    var md: Dictionary = d["missions"]
    if m is Dictionary:
        md["date"] = str(m.get("date", "")) if m.get("date") is String else ""
        var daily: Array = []
        if m.get("daily") is Array:
            for e in m["daily"]:
                if e is Dictionary and e.get("id") is String:
                    daily.append({
                        "id": e["id"],
                        "target": _to_int(e.get("target"), 1, 1),
                        "progress": _to_int(e.get("progress"), 0),
                        "claimed": _to_bool(e.get("claimed"), false),
                    })
        md["daily"] = daily.slice(0, 5)
        var pc := {}
        if m.get("prog_claimed") is Dictionary:
            for k in m["prog_claimed"].keys():
                if k is String:
                    pc[k] = _to_int(m["prog_claimed"][k], 0, 0, 1000)
        md["prog_claimed"] = pc

    # achievements
    var ach := {}
    if r.get("achievements") is Dictionary:
        for k in r["achievements"].keys():
            if k is String and r["achievements"][k] is bool and r["achievements"][k]:
                ach[k] = true
    d["achievements"] = ach

    # stats
    var s = r.get("stats")
    var sd: Dictionary = d["stats"]
    if s is Dictionary:
        sd["runs"] = _to_int(s.get("runs"), 0)
        sd["total_time"] = _to_float(s.get("total_time"), 0.0, 0.0, 1.0e9)
        sd["best_combo"] = _to_int(s.get("best_combo"), 1, 1, 99)
        sd["best_time"] = _to_float(s.get("best_time"), 0.0, 0.0, 1.0e6)
        sd["crystals_collected"] = _to_int(s.get("crystals_collected"), 0)
        sd["dodged"] = _to_int(s.get("dodged"), 0)
        sd["near_misses"] = _to_int(s.get("near_misses"), 0)
        sd["records_broken"] = _to_int(s.get("records_broken"), 0)

    # settings
    var st = r.get("settings")
    var setd: Dictionary = d["settings"]
    if st is Dictionary:
        for k in ["music", "sfx", "vibration", "tutorial_enabled"]:
            setd[k] = _to_bool(st.get(k), setd[k])
        setd["music_volume"] = _round2(_to_float(st.get("music_volume"), 0.7, 0.0, 1.0))
        setd["sfx_volume"] = _round2(_to_float(st.get("sfx_volume"), 0.9, 0.0, 1.0))
        setd["control_mode"] = _to_int(st.get("control_mode"), 0, 0, 1)
        setd["quality"] = _to_int(st.get("quality"), 1, 0, 1)
    d["version"] = GameConfig.SAVE_VERSION
    return d

## Upgrades older save versions to the current one. Add a branch per version bump.
static func migrate(raw: Dictionary) -> Dictionary:
    var v := _to_int(raw.get("version"), 0, 0, 1000)
    var out := raw.duplicate(true)
    if v < 1:
        # v0 (pre-release prototype) stored "coins" instead of "crystals".
        if out.has("coins") and not out.has("crystals"):
            out["crystals"] = out["coins"]
        out["version"] = 1
    return out

static func checksum(data: Dictionary) -> String:
    return (JSON.stringify(data, "", true) + SALT).sha256_text()

static func encode(data: Dictionary) -> String:
    var clean := sanitize(data)
    return JSON.stringify({"v": GameConfig.SAVE_VERSION, "checksum": checksum(clean), "data": clean}, "  ", true)

## Result: {ok: bool, data: Dictionary, reason: String, checksum_ok: bool}
static func decode(text: String) -> Dictionary:
    var parsed = JSON.parse_string(text)
    if not (parsed is Dictionary):
        return {"ok": false, "data": defaults(), "reason": "not a JSON object", "checksum_ok": false}
    var payload = parsed.get("data")
    if not (payload is Dictionary):
        return {"ok": false, "data": defaults(), "reason": "missing data", "checksum_ok": false}
    var clean := sanitize(migrate(payload))
    var cs_ok: bool = str(parsed.get("checksum", "")) == checksum(clean)
    return {"ok": true, "data": clean, "reason": "" if cs_ok else "checksum mismatch", "checksum_ok": cs_ok}
