class_name ObstacleSpawner
extends RefCounted
## Keeps rows of obstacles + crystals spawned ahead of the player using PatternGenerator.

var generator := PatternGenerator.new()
var difficulty: DifficultyManager
var obstacles: ObstacleManager
var crystals: CrystalManager
var enabled := true
var rows_spawned := 0

func setup(diff: DifficultyManager, om: ObstacleManager, cm: CrystalManager) -> void:
    difficulty = diff
    obstacles = om
    crystals = cm

func reset(seed_value: int, theta: float, omega: float, step_factor: float) -> void:
    generator.reset(seed_value, theta + GameConfig.START_DELAY * omega, 1, step_factor)
    rows_spawned = 0

func update(theta: float, t: float) -> void:
    if not enabled:
        return
    var p := difficulty.params_at(t)
    var guard := 0
    while generator.last_end + float(p["clear_time"]) * float(p["omega"]) <= theta + OrbitMath.LEAD_ANGLE and guard < 6:
        var row := generator.next_row(p, t)
        for o in row["obstacles"]:
            obstacles.spawn(o, t)
        crystals.spawn_group(int(row["id"]), row["crystals"], t)
        rows_spawned += 1
        guard += 1
