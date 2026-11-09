class_name DifficultyManager
extends RefCounted
## Time-based difficulty curve driven by resources/difficulty.json (all values configurable).
## 0-15 s INTRO, 15-30 WARM-UP, 30-45 ADVANCED, 45-60 HARD, 60 s+ EXTREME (keeps scaling, bounded).

const CONFIG_PATH := "res://resources/difficulty.json"

const DEFAULT_CONFIG := {
    "phase_names": ["INTRO", "WARM-UP", "ADVANCED", "HARD", "EXTREME"],
    "phases": [
        {"t": 0, "omega": 1.3, "clear_time": 1.6, "double_chance": 0.0, "pattern_chance": 0.0, "w_static": 1.0, "w_moving": 0.0, "w_block": 0.0, "w_zone": 0.0, "mixed_chance": 0.0},
        {"t": 60, "omega": 2.4, "clear_time": 0.74, "double_chance": 0.65, "pattern_chance": 0.4, "w_static": 0.3, "w_moving": 0.25, "w_block": 0.25, "w_zone": 0.2, "mixed_chance": 0.45},
    ],
    "omega_growth_per_s": 0.012, "omega_max": 3.0, "clear_shrink_per_s": 0.0015, "clear_min": 0.62,
}

var config: Dictionary = {}

func _init(path: String = CONFIG_PATH) -> void:
    config = load_config(path)

static func load_config(path: String) -> Dictionary:
    if FileAccess.file_exists(path):
        var f := FileAccess.open(path, FileAccess.READ)
        if f != null:
            var parsed = JSON.parse_string(f.get_as_text())
            if parsed is Dictionary and parsed.has("phases") and (parsed["phases"] as Array).size() >= 2:
                return parsed
    push_warning("DifficultyManager: using built-in default config")
    return DEFAULT_CONFIG.duplicate(true)

func phase_index_at(t: float) -> int:
    var phases: Array = config["phases"]
    var idx := 0
    for i in phases.size():
        if t >= float(phases[i]["t"]):
            idx = i
    return idx

func phase_name_at(t: float) -> String:
    var names: Array = config.get("phase_names", [])
    var i := phase_index_at(t)
    return str(names[i]) if i < names.size() else "PHASE %d" % (i + 1)

## Seconds until the next phase starts (or -1 if in the last one).
func time_to_next_phase(t: float) -> float:
    var phases: Array = config["phases"]
    var i := phase_index_at(t)
    if i >= phases.size() - 1:
        return -1.0
    return float(phases[i + 1]["t"]) - t

func phase_progress(t: float) -> float:
    var phases: Array = config["phases"]
    var i := phase_index_at(t)
    if i >= phases.size() - 1:
        return 1.0
    var a := float(phases[i]["t"])
    var b := float(phases[i + 1]["t"])
    return clampf((t - a) / (b - a), 0.0, 1.0)

func params_at(t: float) -> Dictionary:
    var phases: Array = config["phases"]
    var last: Dictionary = phases[phases.size() - 1]
    var out: Dictionary = {}
    if t >= float(last["t"]):
        out = last.duplicate()
        var over := t - float(last["t"])
        out["omega"] = minf(float(config["omega_max"]), float(last["omega"]) + over * float(config["omega_growth_per_s"]))
        out["clear_time"] = maxf(float(config["clear_min"]), float(last["clear_time"]) - over * float(config["clear_shrink_per_s"]))
    else:
        var i := phase_index_at(t)
        var a: Dictionary = phases[i]
        var b: Dictionary = phases[i + 1]
        var f := clampf((t - float(a["t"])) / (float(b["t"]) - float(a["t"])), 0.0, 1.0)
        for k in a.keys():
            if k == "t":
                continue
            out[k] = lerpf(float(a[k]), float(b[k]), f)
    out["t"] = t
    out["phase"] = phase_index_at(t)
    return out
