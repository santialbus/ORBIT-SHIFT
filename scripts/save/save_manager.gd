extends Node
## Persistent local storage with atomic writes, a rolling backup, checksum and validation.
## Autoload name: SaveManager. `data` is always a valid, sanitised dictionary.

signal data_changed

const SAVE_PATH := "user://orbit_shift_save.json"
const BACKUP_PATH := "user://orbit_shift_save.bak.json"
const TMP_PATH := "user://orbit_shift_save.tmp"
const AUTOSAVE_DELAY := 1.5

var data: Dictionary = SaveData.defaults()
var load_report: String = ""
var _dirty := false
var _timer := 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().set_auto_accept_quit(false)
    load_game()

func load_game() -> void:
    var result := _read(SAVE_PATH)
    if not result["ok"] or not result["checksum_ok"]:
        var backup := _read(BACKUP_PATH)
        if backup["ok"] and backup["checksum_ok"]:
            result = backup
            load_report = "main save invalid (%s); restored backup" % str(result.get("reason", ""))
        elif result["ok"]:
            load_report = "checksum mismatch; loaded sanitised data"
        elif backup["ok"]:
            result = backup
            load_report = "main save unreadable; loaded backup with warnings"
        else:
            load_report = "no valid save found; starting fresh"
            result = {"ok": true, "data": SaveData.defaults()}
    else:
        load_report = "ok"
    data = result["data"]
    if load_report != "ok" and FileAccess.file_exists(SAVE_PATH):
        push_warning("SaveManager: " + load_report)
    data_changed.emit()

func _read(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {"ok": false, "data": SaveData.defaults(), "reason": "missing", "checksum_ok": false}
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
        return {"ok": false, "data": SaveData.defaults(), "reason": "open error", "checksum_ok": false}
    return SaveData.decode(f.get_as_text())

func save_game() -> bool:
    _dirty = false
    var text := SaveData.encode(data)
    var f := FileAccess.open(TMP_PATH, FileAccess.WRITE)
    if f == null:
        push_warning("SaveManager: cannot write temp file")
        return false
    f.store_string(text)
    f.close()
    # keep the previous good save as backup, then promote the temp file
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH)
    var err := DirAccess.rename_absolute(TMP_PATH, SAVE_PATH)
    if err != OK:
        push_warning("SaveManager: rename failed (%d)" % err)
        return false
    return true

func mark_dirty() -> void:
    _dirty = true
    _timer = 0.0
    data_changed.emit()

func _process(delta: float) -> void:
    if _dirty:
        _timer += delta
        if _timer >= AUTOSAVE_DELAY:
            save_game()

func reset_all() -> void:
    data = SaveData.defaults()
    save_game()
    data_changed.emit()

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_CLOSE_REQUEST:
        save_game()
        if what == NOTIFICATION_WM_CLOSE_REQUEST:
            get_tree().quit()
