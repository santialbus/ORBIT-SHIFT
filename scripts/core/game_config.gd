class_name GameConfig
extends RefCounted
## Global constants: version, palette and tuning values shared across systems.

const GAME_NAME := "ORBIT SHIFT"
const VERSION := "0.9.0-beta"
const BUILD_NUMBER := 1
const SAVE_VERSION := 1

# Palette (Neon Sci-Fi Minimal)
const COL_BG := Color("050a18")
const COL_BG_PANEL := Color("0a1226")
const COL_CYAN := Color("19f0ff")
const COL_CORAL := Color("ff4d5e")
const COL_ORANGE := Color("ff8a1f")
const COL_GOLD := Color("ffc233")
const COL_VIOLET := Color("9b5cff")
const COL_WHITE := Color("f4f8ff")
const COL_DIM := Color("7d8bb0")
const COL_CORE := Color("0d1f5c")

# Run tuning
const START_DELAY := 1.4          # seconds before the first obstacle row reaches the player
const DEATH_FREEZE := 0.9         # seconds of death animation before results
const COUNTDOWN_SECONDS := 3
const SCORE_PER_SECOND := 8.0
const SCORE_CRYSTAL := 50.0
const SCORE_NEAR_MISS := 100.0
const SCORE_DODGE := 10.0
const RUN_BONUS_DIVISOR := 250.0  # bonus crystals = score / divisor

static func format_time(seconds: float) -> String:
    var s := int(seconds)
    return "%d:%02d" % [s / 60, s % 60]

static func format_int(n: int) -> String:
    var s := str(absi(n))
    var out := ""
    var count := 0
    for i in range(s.length() - 1, -1, -1):
        out = s[i] + out
        count += 1
        if count % 3 == 0 and i > 0:
            out = "," + out
    return ("-" if n < 0 else "") + out
