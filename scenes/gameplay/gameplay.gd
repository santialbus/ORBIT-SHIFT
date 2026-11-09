extends Node3D
## Gameplay scene controller: orchestrates one run.
## Systems (all separate): OrbitController, DifficultyManager, ObstacleSpawner/Manager, CrystalManager,
## CollisionManager (static), ScoreManager, ComboManager, WorldBuilder/PlayerView/FxManager (presentation), Hud (UI).
## The scene is driven by tick(delta) so tests can simulate runs without real time.

enum S { PLAYING, PAUSED, COUNTDOWN, DYING, DONE }

var tutorial_mode := false
var god_mode := false
var state: int = S.PLAYING
var run_time := 0.0

var world: WorldBuilder
var player_view: PlayerView
var obstacles: ObstacleManager
var crystals: CrystalManager
var fx: FxManager
var hud: Hud
var orbit := OrbitController.new()
var difficulty := DifficultyManager.new()
var spawner := ObstacleSpawner.new()
var score := ScoreManager.new()
var combo := ComboManager.new()

var _layer: CanvasLayer
var _last_phase := 0
var _death_timer := 0.0
var _countdown := 0.0
var _count_shown := 0
var _record_at_start := 0
var _record_announced := false
var _last_popup_time := -1.0

# tutorial
var _tut_step := -1
var _tut_timer := 0.0
var _tut_taps := 0
var _tut_crystals := 0
var _tut_target_obstacle: ObstacleData = null

func _ready() -> void:
    get_tree().set_auto_accept_quit(false)
    god_mode = GameManager.god_mode
    world = WorldBuilder.new()
    add_child(world)
    world.build(SkinManager.equipped_core_id())
    player_view = PlayerView.new()
    add_child(player_view)
    player_view.set_skin(SkinManager.equipped_skin_id())
    obstacles = ObstacleManager.new()
    add_child(obstacles)
    crystals = CrystalManager.new()
    add_child(crystals)
    fx = FxManager.new()
    add_child(fx)

    _layer = CanvasLayer.new()
    add_child(_layer)
    hud = Hud.new()
    _layer.add_child(hud)
    _record_at_start = ProgressionManager.record()
    hud.build(_record_at_start)
    hud.pause_pressed.connect(pause)
    hud.resume_pressed.connect(resume)
    hud.restart_pressed.connect(restart)
    hud.menu_pressed.connect(_to_menu)
    if tutorial_mode:
        hud.pause_btn.visible = false

    spawner.setup(difficulty, obstacles, crystals)
    combo.multiplier_changed.connect(_on_multiplier_changed)
    combo.chain_broken.connect(_on_chain_broken)
    crystals.collected.connect(_on_crystal_collected)
    crystals.group_missed.connect(_on_group_missed)
    start_run()

func start_run() -> void:
    run_time = 0.0
    score.reset()
    combo.reset()
    orbit.mode = GameManager.control_mode()
    orbit.reset(1, -PI / 2.0)
    orbit.omega = float(difficulty.params_at(0.0)["omega"])
    obstacles.clear()
    crystals.clear()
    var seed_value: int = GameManager.forced_seed if GameManager.forced_seed != 0 else int(Time.get_ticks_usec() & 0x7fffffff)
    spawner.reset(seed_value, orbit.theta, orbit.omega, 1.0 if orbit.mode == OrbitController.Mode.SPLIT else 1.9)
    spawner.enabled = not tutorial_mode
    _last_phase = 0
    _record_announced = false
    state = S.PLAYING
    player_view.visible = true
    player_view.set_visible_trail(true)
    GameStateManager.set_state(GameStateManager.State.TUTORIAL if tutorial_mode else GameStateManager.State.PLAYING)
    hud.set_pause_visible(false)
    hud.set_score(0)
    hud.set_crystals(0)
    hud.set_combo(1, 0.0)
    world.set_intensity(1)
    AudioManager.duck(false)
    AudioManager.play_music("game")
    AudioManager.play_sfx("start")
    player_view.place(orbit.theta, orbit.lane_pos)
    if tutorial_mode:
        _tut_begin(0)

func _process(delta: float) -> void:
    tick(minf(delta, 0.05))

func tick(delta: float) -> void:
    match state:
        S.PLAYING:
            _tick_play(delta)
        S.DYING:
            _tick_dying(delta)
        S.COUNTDOWN:
            _tick_countdown(delta)

func _tick_play(dt: float) -> void:
    run_time += dt
    var p := difficulty.params_at(run_time)
    orbit.omega = float(p["omega"])
    orbit.update(dt)
    spawner.update(orbit.theta, run_time)

    var active := obstacles.active
    CollisionManager.track_proximity(orbit.theta, orbit.lane_pos, active, run_time)
    var hit := CollisionManager.check_hit(orbit.theta, orbit.lane_pos, active, run_time)
    if hit != null:
        if tutorial_mode:
            _tut_hit(hit)
        elif not god_mode:
            _die(hit)
            return
    var passed := CollisionManager.collect_passed(orbit.theta, active, run_time)
    if int(passed["dodged"]) > 0:
        score.add_dodges(int(passed["dodged"]), combo.multiplier)
        for i in int(passed["near_misses"]):
            _on_near_miss()
    crystals.update(orbit.theta, orbit.lane_pos, run_time, dt)
    combo.update(dt)
    score.add_survival(dt, combo.multiplier)
    obstacles.recycle_behind(orbit.theta, run_time)

    # presentation
    player_view.place(orbit.theta, orbit.lane_pos)
    obstacles.update_views(run_time)
    world.set_lane_position(orbit.lane_pos)
    hud.set_score(score.value())
    hud.set_combo(combo.multiplier, combo.level_progress())
    if not tutorial_mode:
        var ph := difficulty.phase_index_at(run_time)
        hud.set_phase(difficulty.phase_name_at(run_time), difficulty.phase_progress(run_time))
        if ph != _last_phase:
            _last_phase = ph
            hud.show_banner(difficulty.phase_name_at(run_time), GameConfig.COL_VIOLET if ph < 4 else GameConfig.COL_CORAL)
            AudioManager.play_sfx("phase")
        if not _record_announced and _record_at_start > 0 and score.value() > _record_at_start:
            _record_announced = true
            hud.show_banner("NEW RECORD!", GameConfig.COL_GOLD)
            AudioManager.play_sfx("record")
    else:
        _tut_update(dt)

## Public input entry point. side: -1 inner orbit, +1 outer orbit (ignored in PINGPONG mode).
func tap_side(side: int) -> void:
    if state != S.PLAYING:
        return
    var left_lane := orbit.target_lane
    if orbit.tap(side):
        CollisionManager.mark_shift(orbit.theta, left_lane, orbit.omega, obstacles.active, run_time)
        AudioManager.play_sfx("shift", 1.0 + 0.08 * float(orbit.target_lane))
        GameManager.vibrate(12)
        player_view.pop(0.5)
        _tut_taps += 1

func _unhandled_input(event: InputEvent) -> void:
    if state != S.PLAYING:
        return
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        var w := get_viewport().get_visible_rect().size.x
        tap_side(-1 if event.position.x < w * 0.5 else 1)
    elif event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_LEFT, KEY_A: tap_side(-1)
            KEY_RIGHT, KEY_D, KEY_SPACE: tap_side(1)
            KEY_ESCAPE, KEY_P: pause()

# ---------------- events ----------------
func _on_crystal_collected(world_pos: Vector3, _lane: int) -> void:
    var pts := score.add_crystal(combo.multiplier)
    combo.on_crystal()
    hud.set_crystals(score.crystals)
    fx.burst(world_pos, GameConfig.COL_GOLD, 12, 2.6, 0.55)
    world.pulse_core(0.7)
    player_view.pop(0.6)
    AudioManager.play_sfx("crystal", 1.0 + minf(float(combo.chain), 24.0) * 0.025)
    GameManager.vibrate(8)
    _spawn_popup("+%d" % pts, world_pos, GameConfig.COL_GOLD)
    _tut_crystals += 1

func _on_near_miss() -> void:
    var pts := score.add_near_miss(combo.multiplier)
    combo.on_near_miss()
    AudioManager.play_sfx("near_miss")
    world.pulse_core(0.9)
    fx.burst(player_view.position, GameConfig.COL_CYAN, 10, 2.2, 0.45)
    _spawn_popup("PERFECT +%d" % pts, player_view.position, GameConfig.COL_CYAN)

func _on_multiplier_changed(new_mult: int, old_mult: int) -> void:
    world.set_intensity(new_mult)
    if new_mult > old_mult:
        hud.pop_combo(new_mult)
        AudioManager.play_sfx("combo_up", 1.0 + 0.04 * float(new_mult))
        hud.show_banner("COMBO x%d" % new_mult, GameConfig.COL_ORANGE)

func _on_chain_broken(lost: int) -> void:
    if lost >= 4:
        hud.show_banner("CHAIN LOST", GameConfig.COL_CORAL)
        AudioManager.play_sfx("chain_lost")

func _on_group_missed(streak: int) -> void:
    if streak >= 2:
        combo.break_chain()

func _spawn_popup(text: String, world_pos: Vector3, color: Color) -> void:
    if run_time - _last_popup_time < 0.05:
        return
    _last_popup_time = run_time
    if world.camera != null and world.camera.is_inside_tree():
        hud.popup(text, world.camera.unproject_position(world_pos) + Vector2(0, -40), color)

# ---------------- death / finish ----------------
func _die(hit: ObstacleData) -> void:
    state = S.DYING
    _death_timer = GameConfig.DEATH_FREEZE
    GameStateManager.set_state(GameStateManager.State.DYING)
    if hit != null and hit.view != null:
        (hit.view as ObstacleView).flash_hit()
    fx.burst(player_view.position, SkinManager.glow_color(SkinManager.equipped_skin_id()), 40, 5.0, 0.9)
    fx.burst(player_view.position, GameConfig.COL_CORAL, 24, 3.5, 0.7)
    world.shake(1.0)
    player_view.visible = false
    player_view.set_visible_trail(false)
    combo.break_chain()
    AudioManager.play_sfx("hit")
    GameManager.vibrate(90)
    hud.show_banner("", GameConfig.COL_CORAL)

func _tick_dying(dt: float) -> void:
    _death_timer -= dt
    obstacles.update_views(run_time)
    if _death_timer <= 0.0:
        state = S.DONE
        _finish_run()

func build_run_result() -> Dictionary:
    return {
        "score": score.value(), "time": run_time, "crystals": score.crystals,
        "max_multiplier": combo.max_multiplier, "max_chain": combo.max_chain,
        "dodged": score.dodged, "near_misses": score.near_misses,
    }

func _finish_run() -> void:
    var run := build_run_result()
    var summary := ProgressionManager.finish_run(run)
    GameManager.last_run = run
    GameManager.last_summary = summary
    AudioManager.play_sfx("record" if summary["is_record"] else "gameover")
    UIManager.go("results")

# ---------------- pause / resume ----------------
func pause() -> void:
    if state != S.PLAYING or tutorial_mode:
        return
    state = S.PAUSED
    GameStateManager.set_state(GameStateManager.State.PAUSED)
    hud.set_pause_visible(true)
    AudioManager.duck(true)

func resume() -> void:
    if state != S.PAUSED:
        return
    hud.set_pause_visible(false)
    state = S.COUNTDOWN
    _countdown = float(GameConfig.COUNTDOWN_SECONDS)
    _count_shown = 0

func _tick_countdown(dt: float) -> void:
    _countdown -= dt
    var n := int(ceil(_countdown))
    if n != _count_shown and n > 0:
        _count_shown = n
        hud.show_countdown(str(n))
        AudioManager.play_sfx("count")
    if _countdown <= 0.0:
        hud.show_countdown("")
        AudioManager.play_sfx("go")
        AudioManager.duck(false)
        state = S.PLAYING
        GameStateManager.set_state(GameStateManager.State.PLAYING)

func restart() -> void:
    hud.set_pause_visible(false)
    hud.show_countdown("")
    start_run()

func _to_menu() -> void:
    AudioManager.duck(false)
    UIManager.go("menu")

func on_back() -> void:
    if state == S.PLAYING:
        pause()
    elif state == S.PAUSED:
        resume()

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        if state == S.PLAYING and not tutorial_mode:
            pause()

# ---------------- tutorial ----------------
const TUT_TEXT := [
    "Your sphere orbits the core by itself.",
    "Tap LEFT / RIGHT of the screen to change orbit.",
    "Red barriers end the run. Switch orbit to dodge!",
    "Collect the golden crystals.",
    "Chain crystals and perfect shifts to raise your multiplier.",
]

func _tut_begin(step: int) -> void:
    _tut_step = step
    _tut_timer = 0.0
    _tut_taps = 0
    _tut_crystals = 0
    _tut_target_obstacle = null
    hud.set_tutorial_text(TUT_TEXT[step], "%d / %d" % [step + 1, TUT_TEXT.size()])
    match step:
        2:
            _tut_spawn_barrier()
        3:
            _tut_spawn_crystals()

func _tut_spawn_barrier() -> void:
    var o := ObstacleData.new()
    o.kind = ObstacleData.Kind.STATIC
    o.lane = orbit.target_lane
    o.half = 0.34
    o.base_angle = orbit.theta + 2.4
    o.born = run_time
    obstacles.spawn(o, run_time)
    _tut_target_obstacle = o

func _tut_spawn_crystals() -> void:
    var items: Array = []
    for i in 5:
        items.append({"angle": orbit.theta + 1.3 + 0.35 * i, "lane": [1, 2, 2, 1, 0][i]})
    crystals.spawn_group(900 + _tut_step * 10 + int(run_time), items, run_time)

func _tut_hit(hit: ObstacleData) -> void:
    if hit.view != null:
        (hit.view as ObstacleView).flash_hit()
    hit.passed = true
    world.shake(0.6)
    AudioManager.play_sfx("chain_lost")
    hud.show_banner("TRY AGAIN", GameConfig.COL_CORAL)
    # re-spawn a fresh barrier ahead
    _tut_spawn_barrier()

func _tut_update(dt: float) -> void:
    _tut_timer += dt
    match _tut_step:
        0:
            if _tut_timer > 3.2:
                _tut_begin(1)
        1:
            if _tut_taps >= 3:
                _tut_begin(2)
        2:
            if _tut_target_obstacle != null and _tut_target_obstacle.passed:
                _tut_begin(3)
        3:
            if _tut_crystals >= 3:
                _tut_begin(4)
            elif _tut_timer > 4.5 and crystals.active.is_empty():
                _tut_spawn_crystals()
                _tut_timer = 0.0
        4:
            if _tut_timer > 4.0:
                _tut_finish()

func _tut_finish() -> void:
    state = S.DONE
    SaveManager.data["tutorial_done"] = true
    SaveManager.mark_dirty()
    SaveManager.save_game()
    AudioManager.play_sfx("unlock")
    UIManager.go("menu")
