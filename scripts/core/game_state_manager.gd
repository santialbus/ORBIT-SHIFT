extends Node
## Autoload GameStateManager: tiny finite state machine shared by UI, audio and gameplay.

signal state_changed(new_state: int, old_state: int)

enum State { BOOT, MENU, PLAYING, PAUSED, DYING, RESULTS, TUTORIAL }

var state: int = State.BOOT

func set_state(new_state: int) -> void:
    if new_state == state:
        return
    var old := state
    state = new_state
    state_changed.emit(new_state, old)

func is_playing() -> bool:
    return state == State.PLAYING or state == State.TUTORIAL
