extends Node
## Autoload AudioManager: SFX pool, looping music, Music/SFX buses and user settings.

const SFX_NAMES := ["click", "back", "start", "shift", "crystal", "combo_up", "near_miss", "hit",
    "gameover", "record", "unlock", "count", "go", "chain_lost", "phase"]
const MUSIC_NAMES := ["menu", "game"]
const POOL_SIZE := 8

var _sfx: Dictionary = {}
var _music: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music_player: AudioStreamPlayer
var _current_music := ""
var _duck := false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _ensure_bus("Music")
    _ensure_bus("SFX")
    for n in SFX_NAMES:
        var path := "res://assets/audio/sfx_%s.wav" % n
        if ResourceLoader.exists(path):
            _sfx[n] = load(path)
    for n in MUSIC_NAMES:
        var path := "res://assets/audio/music_%s.wav" % n
        if ResourceLoader.exists(path):
            var s: AudioStreamWAV = (load(path) as AudioStreamWAV).duplicate()
            s.loop_mode = AudioStreamWAV.LOOP_FORWARD
            s.loop_begin = 0
            s.loop_end = s.data.size() / 2   # 16-bit mono
            _music[n] = s
    for i in POOL_SIZE:
        var p := AudioStreamPlayer.new()
        p.bus = "SFX"
        add_child(p)
        _players.append(p)
    _music_player = AudioStreamPlayer.new()
    _music_player.bus = "Music"
    add_child(_music_player)
    SaveManager.data_changed.connect(apply_settings)
    apply_settings()

func _ensure_bus(bus_name: String) -> void:
    if AudioServer.get_bus_index(bus_name) == -1:
        AudioServer.add_bus()
        var idx := AudioServer.bus_count - 1
        AudioServer.set_bus_name(idx, bus_name)
        AudioServer.set_bus_send(idx, "Master")

func apply_settings() -> void:
    var s: Dictionary = SaveManager.data["settings"]
    var mi := AudioServer.get_bus_index("Music")
    var si := AudioServer.get_bus_index("SFX")
    AudioServer.set_bus_mute(mi, not bool(s["music"]))
    AudioServer.set_bus_mute(si, not bool(s["sfx"]))
    var mv := float(s["music_volume"]) * (0.4 if _duck else 1.0)
    AudioServer.set_bus_volume_db(mi, linear_to_db(maxf(mv, 0.0001)))
    AudioServer.set_bus_volume_db(si, linear_to_db(maxf(float(s["sfx_volume"]), 0.0001)))

func play_sfx(sfx_name: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
    if not _sfx.has(sfx_name):
        return
    var p := _players[_next]
    _next = (_next + 1) % POOL_SIZE
    p.stream = _sfx[sfx_name]
    p.pitch_scale = pitch
    p.volume_db = volume_db
    p.play()

func play_music(music_name: String) -> void:
    if music_name == _current_music and _music_player.playing:
        return
    _current_music = music_name
    if not _music.has(music_name):
        _music_player.stop()
        return
    _music_player.stream = _music[music_name]
    _music_player.play()

func stop_music() -> void:
    _current_music = ""
    _music_player.stop()

func duck(on: bool) -> void:
    _duck = on
    apply_settings()
