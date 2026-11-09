extends Node
## Autoload AchievementManager: read access for the UI (evaluation happens in ProgressionManager.finish_run).

func all() -> Array:
    return AchievementLogic.LIST

func is_unlocked(id: String) -> bool:
    return SaveManager.data["achievements"].has(id)

func unlocked_count() -> int:
    return (SaveManager.data["achievements"] as Dictionary).size()

func progress(def: Dictionary) -> float:
    return AchievementLogic.progress_of(def, AchievementLogic.snapshot(SaveManager.data))
