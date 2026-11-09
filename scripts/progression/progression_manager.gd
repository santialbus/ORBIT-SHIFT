extends Node
## Autoload ProgressionManager: facade over save data for currency, record, stats and run results.

signal crystals_changed(total: int)
signal run_recorded(summary: Dictionary)

func crystals() -> int:
    return int(SaveManager.data["crystals"])

func record() -> int:
    return int(SaveManager.data["record"])

func stats() -> Dictionary:
    return SaveManager.data["stats"]

func owned_skins() -> Array:
    return SaveManager.data["skins"]

func owns_skin(id: String) -> bool:
    return (SaveManager.data["skins"] as Array).has(id)

func owns_core(id: String) -> bool:
    return (SaveManager.data["cores"] as Array).has(id)

func unlock_skin(id: String) -> Dictionary:
    var r := ProgressionLogic.unlock_skin(SaveManager.data, id)
    if r["ok"]:
        _after_change()
        _evaluate_achievements({})
    return r

func unlock_core(id: String) -> Dictionary:
    var r := ProgressionLogic.unlock_core(SaveManager.data, id)
    if r["ok"]:
        _after_change()
        _evaluate_achievements({})
    return r

func equip_skin(id: String) -> bool:
    var ok := ProgressionLogic.equip_skin(SaveManager.data, id)
    if ok:
        SaveManager.mark_dirty()
    return ok

func equip_core(id: String) -> bool:
    var ok := ProgressionLogic.equip_core(SaveManager.data, id)
    if ok:
        SaveManager.mark_dirty()
    return ok

func add_crystals(n: int) -> void:
    SaveManager.data["crystals"] = int(SaveManager.data["crystals"]) + n
    _after_change()

func _after_change() -> void:
    SaveManager.mark_dirty()
    crystals_changed.emit(crystals())

func _evaluate_achievements(run: Dictionary) -> Array:
    var unlocked := AchievementLogic.evaluate(SaveManager.data, run)
    if unlocked.size() > 0:
        SaveManager.mark_dirty()
        crystals_changed.emit(crystals())
    return unlocked

## Called once when a run ends. Updates everything and persists immediately.
func finish_run(run: Dictionary) -> Dictionary:
    MissionLogic.refresh(SaveManager.data, MissionLogic.today())
    var res := ProgressionLogic.apply_run(SaveManager.data, run)
    var missions_done := MissionLogic.apply_run(SaveManager.data, run)
    var unlocked := AchievementLogic.evaluate(SaveManager.data, run)
    SaveManager.mark_dirty()
    SaveManager.save_game()
    var summary := {
        "is_record": res["is_record"], "bonus": res["bonus"], "earned": res["earned"],
        "previous_record": res["previous_record"], "missions_done": missions_done,
        "achievements": unlocked,
    }
    crystals_changed.emit(crystals())
    run_recorded.emit(summary)
    return summary
