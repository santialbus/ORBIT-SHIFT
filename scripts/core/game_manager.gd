extends Node
## Autoload GameManager: cross-scene session data and high level flow.

var last_run: Dictionary = {}
var last_summary: Dictionary = {}
var god_mode := false           # dev/testing: collisions do not end the run
var forced_seed := 0            # dev/testing: deterministic generation when != 0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func should_show_tutorial() -> bool:
    var d: Dictionary = SaveManager.data
    return bool(d["settings"]["tutorial_enabled"]) and not bool(d["tutorial_done"])

## Entry point of the PLAY button: tutorial the first time, otherwise straight into a run.
func play() -> void:
    if should_show_tutorial():
        UIManager.go("tutorial")
    else:
        UIManager.go("gameplay")

func replay_tutorial() -> void:
    UIManager.go("tutorial")

func vibrate(ms: int) -> void:
    if SaveManager.data["settings"]["vibration"] and OS.has_feature("mobile"):
        Input.vibrate_handheld(ms)

func control_mode() -> int:
    return int(SaveManager.data["settings"]["control_mode"])
