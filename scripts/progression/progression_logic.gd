class_name ProgressionLogic
extends RefCounted
## Pure purchase / equip rules operating on a save dictionary (testable, no autoloads).

## Returns {ok: bool, reason: String}. Mutates `data` only on success.
static func unlock_skin(data: Dictionary, id: String) -> Dictionary:
    if not SkinCatalog.skin_ids().has(id):
        return {"ok": false, "reason": "unknown"}
    if (data["skins"] as Array).has(id):
        return {"ok": false, "reason": "owned"}
    var price: int = SkinCatalog.get_skin(id)["price"]
    if int(data["crystals"]) < price:
        return {"ok": false, "reason": "funds"}
    data["crystals"] = int(data["crystals"]) - price
    (data["skins"] as Array).append(id)
    return {"ok": true, "reason": ""}

static func unlock_core(data: Dictionary, id: String) -> Dictionary:
    if not SkinCatalog.core_ids().has(id):
        return {"ok": false, "reason": "unknown"}
    if (data["cores"] as Array).has(id):
        return {"ok": false, "reason": "owned"}
    var price: int = SkinCatalog.get_core(id)["price"]
    if int(data["crystals"]) < price:
        return {"ok": false, "reason": "funds"}
    data["crystals"] = int(data["crystals"]) - price
    (data["cores"] as Array).append(id)
    return {"ok": true, "reason": ""}

static func equip_skin(data: Dictionary, id: String) -> bool:
    if (data["skins"] as Array).has(id):
        data["equipped_skin"] = id
        return true
    return false

static func equip_core(data: Dictionary, id: String) -> bool:
    if (data["cores"] as Array).has(id):
        data["equipped_core"] = id
        return true
    return false

## Applies a finished run to the save data. `run` = {score, time, crystals, max_multiplier, dodged, near_misses}.
## Returns {is_record, bonus, earned, previous_record}.
static func apply_run(data: Dictionary, run: Dictionary) -> Dictionary:
    var score: int = int(run.get("score", 0))
    var crystals: int = int(run.get("crystals", 0))
    var t: float = float(run.get("time", 0.0))
    var prev: int = int(data["record"])
    var is_record := score > prev
    if is_record:
        data["record"] = score
    var bonus := int(float(score) / GameConfig.RUN_BONUS_DIVISOR)
    var earned := crystals + bonus
    data["crystals"] = int(data["crystals"]) + earned
    var st: Dictionary = data["stats"]
    st["runs"] = int(st["runs"]) + 1
    st["total_time"] = float(st["total_time"]) + t
    st["best_time"] = maxf(float(st["best_time"]), t)
    st["best_combo"] = maxi(int(st["best_combo"]), int(run.get("max_multiplier", 1)))
    st["crystals_collected"] = int(st["crystals_collected"]) + crystals
    st["dodged"] = int(st["dodged"]) + int(run.get("dodged", 0))
    st["near_misses"] = int(st["near_misses"]) + int(run.get("near_misses", 0))
    if is_record and prev > 0:
        st["records_broken"] = int(st["records_broken"]) + 1
    return {"is_record": is_record, "bonus": bonus, "earned": earned, "previous_record": prev}
