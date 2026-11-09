extends Node
## Autoload MissionManager: keeps daily missions current (local date) and exposes claim helpers.

signal missions_changed

func _ready() -> void:
    refresh()

func refresh() -> void:
    if MissionLogic.refresh(SaveManager.data, MissionLogic.today()):
        SaveManager.mark_dirty()
        missions_changed.emit()

func daily() -> Array:
    refresh()
    return SaveManager.data["missions"]["daily"]

func claim_daily(index: int) -> int:
    var r := MissionLogic.claim_daily(SaveManager.data, index)
    if r > 0:
        ProgressionManager.crystals_changed.emit(ProgressionManager.crystals())
        SaveManager.mark_dirty()
        SaveManager.save_game()
        missions_changed.emit()
    return r

func claim_progressive(track: String) -> int:
    var r := MissionLogic.claim_progressive(SaveManager.data, track)
    if r > 0:
        ProgressionManager.crystals_changed.emit(ProgressionManager.crystals())
        SaveManager.mark_dirty()
        SaveManager.save_game()
        missions_changed.emit()
    return r

func claimable_count() -> int:
    var n := 0
    for e in daily():
        if not e["claimed"] and int(e["progress"]) >= int(e["target"]):
            n += 1
    for track in MissionLogic.PROGRESSIVE.keys():
        if MissionLogic.progressive_claimable(track, SaveManager.data):
            n += 1
    return n
