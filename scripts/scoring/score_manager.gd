class_name ScoreManager
extends RefCounted
## Score accumulation. Everything is multiplied by the current combo multiplier.

var score: float = 0.0
var crystals: int = 0
var dodged: int = 0
var near_misses: int = 0

func reset() -> void:
    score = 0.0
    crystals = 0
    dodged = 0
    near_misses = 0

func add_survival(dt: float, mult: int) -> void:
    score += GameConfig.SCORE_PER_SECOND * dt * float(mult)

func add_crystal(mult: int) -> int:
    crystals += 1
    var pts := int(GameConfig.SCORE_CRYSTAL * mult)
    score += pts
    return pts

func add_near_miss(mult: int) -> int:
    near_misses += 1
    var pts := int(GameConfig.SCORE_NEAR_MISS * mult)
    score += pts
    return pts

func add_dodges(n: int, mult: int) -> void:
    dodged += n
    score += GameConfig.SCORE_DODGE * float(n) * float(mult)

func value() -> int:
    return int(score)
