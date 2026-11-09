extends "res://tests/test_case.gd"

func test_multiplier_thresholds() -> void:
    eq(ComboManager.multiplier_for(0), 1, "chain 0")
    eq(ComboManager.multiplier_for(3), 1, "chain 3")
    eq(ComboManager.multiplier_for(4), 2, "chain 4")
    eq(ComboManager.multiplier_for(9), 3, "chain 9")
    eq(ComboManager.multiplier_for(52), 8, "chain 52")
    eq(ComboManager.multiplier_for(999), 8, "capped at x8")

func test_combo_grows_and_signals() -> void:
    var c := ComboManager.new()
    var seen: Array = []
    c.multiplier_changed.connect(func(n: int, o: int) -> void: seen.append([n, o]))
    for i in 4:
        c.on_crystal()
    eq(c.multiplier, 2, "x2 after 4 crystals")
    eq(seen, [[2, 1]], "signal emitted once")
    c.on_near_miss()
    eq(c.chain, 6, "near miss is worth 2")
    eq(c.max_multiplier, 2, "max tracked")

func test_chain_breaks_and_reports() -> void:
    var c := ComboManager.new()
    var lost := [0]
    c.chain_broken.connect(func(n: int) -> void: lost[0] = n)
    for i in 10:
        c.on_crystal()
    c.break_chain()
    eq(lost[0], 10, "lost chain reported")
    eq(c.multiplier, 1, "multiplier reset")
    eq(c.max_multiplier, 3, "max multiplier preserved")
    c.break_chain()   # no-op on empty chain
    eq(lost[0], 10, "no second signal")

func test_chain_times_out() -> void:
    var c := ComboManager.new()
    for i in 5:
        c.on_crystal()
    c.update(ComboManager.TIMEOUT - 0.1)
    check(c.chain == 5, "still alive just before timeout")
    c.update(0.2)
    eq(c.chain, 0, "broken by timeout")

func test_level_progress_bar() -> void:
    var c := ComboManager.new()
    near(c.level_progress(), 0.0, "start")
    c.add(2)
    near(c.level_progress(), 0.5, "halfway to x2")

func test_score_uses_multiplier() -> void:
    var s := ScoreManager.new()
    s.add_crystal(1)
    s.add_crystal(3)
    eq(s.value(), 50 + 150, "crystal points scale")
    eq(s.crystals, 2, "crystal count")
    s.add_near_miss(2)
    eq(s.near_misses, 1, "near miss counted")
    eq(s.value(), 50 + 150 + 200, "near miss points")
    s.add_survival(2.0, 2)
    eq(s.value(), 400 + int(GameConfig.SCORE_PER_SECOND * 2.0 * 2.0), "survival points")

func test_formatting_helpers() -> void:
    eq(GameConfig.format_int(1234567), "1,234,567", "thousands separators")
    eq(GameConfig.format_int(0), "0", "zero")
    eq(GameConfig.format_time(75.4), "1:15", "m:ss")
