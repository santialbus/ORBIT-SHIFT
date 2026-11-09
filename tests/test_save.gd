extends "res://tests/test_case.gd"

func test_defaults_are_valid() -> void:
    var d := SaveData.defaults()
    eq(d, SaveData.sanitize(d), "defaults survive sanitize unchanged")
    eq(d["skins"], ["cyan_core"], "starter skin")
    eq(d["equipped_core"], "standard", "starter core")

func test_roundtrip_encode_decode() -> void:
    var d := SaveData.defaults()
    d["record"] = 12345
    d["crystals"] = 678
    d["skins"] = ["cyan_core", "plasma"]
    d["equipped_skin"] = "plasma"
    d["stats"]["best_time"] = 83.5
    d["settings"]["music_volume"] = 0.35
    d["tutorial_done"] = true
    var res := SaveData.decode(SaveData.encode(d))
    check(res["ok"], "decode ok")
    check(res["checksum_ok"], "checksum valid after roundtrip")
    eq(res["data"]["record"], 12345, "record persisted")
    eq(res["data"]["equipped_skin"], "plasma", "equipped skin persisted")
    near(float(res["data"]["stats"]["best_time"]), 83.5, "float persisted")
    near(float(res["data"]["settings"]["music_volume"]), 0.35, "volume persisted")
    check(res["data"]["tutorial_done"], "tutorial flag persisted")

func test_garbage_input_gives_defaults() -> void:
    eq(SaveData.decode("this is not json")["ok"], false, "plain text rejected")
    eq(SaveData.decode("[1,2,3]")["ok"], false, "array rejected")
    eq(SaveData.decode("{}")["ok"], false, "empty object rejected")
    eq(SaveData.decode("")["ok"], false, "empty string rejected")
    eq(SaveData.sanitize(42), SaveData.defaults(), "non-dictionary -> defaults")

func test_tampered_file_detected() -> void:
    var text := SaveData.encode(SaveData.defaults())
    var parsed: Dictionary = JSON.parse_string(text)
    parsed["data"]["crystals"] = 999999
    var res := SaveData.decode(JSON.stringify(parsed))
    check(res["ok"], "still decodable")
    check(not res["checksum_ok"], "checksum mismatch flagged")

func test_sanitize_clamps_and_repairs() -> void:
    var bad := {
        "record": -50, "crystals": "lots", "skins": ["plasma", "plasma", "nonexistent", 7],
        "cores": "nope", "equipped_skin": "inferno", "equipped_core": "void_heart",
        "stats": {"runs": -3, "best_combo": 500, "total_time": "x"},
        "settings": {"music_volume": 9.0, "sfx": "yes", "control_mode": 7, "quality": -1},
        "achievements": {"first_orbit": true, "bogus": 5},
        "missions": {"date": 5, "daily": [{"id": "score", "target": 0, "progress": -1}, "junk"]},
    }
    var d := SaveData.sanitize(bad)
    eq(d["record"], 0, "negative record clamped")
    eq(d["crystals"], 0, "non-number crystals default")
    check((d["skins"] as Array).has("cyan_core") and (d["skins"] as Array).has("plasma"), "valid skins kept + starter added")
    eq((d["skins"] as Array).count("plasma"), 1, "duplicates removed")
    check(not (d["skins"] as Array).has("nonexistent"), "unknown ids removed")
    eq(d["equipped_skin"], "cyan_core", "equipping an unowned skin falls back")
    eq(d["equipped_core"], "standard", "equipping an unowned core falls back")
    eq(d["stats"]["runs"], 0, "negative runs clamped")
    eq(d["stats"]["best_combo"], 99, "combo capped")
    near(float(d["settings"]["music_volume"]), 1.0, "volume clamped")
    eq(d["settings"]["sfx"], true, "bad bool falls back to default")
    eq(d["settings"]["control_mode"], 1, "control mode clamped")
    eq(d["settings"]["quality"], 0, "quality clamped")
    check(d["achievements"].has("first_orbit") and not d["achievements"].has("bogus"), "achievements filtered")
    eq((d["missions"]["daily"] as Array).size(), 1, "junk missions dropped")
    eq(d["missions"]["daily"][0]["target"], 1, "mission target minimum 1")
    eq(d["version"], GameConfig.SAVE_VERSION, "version stamped")

func test_migration_from_v0() -> void:
    var old := {"version": 0, "coins": 321, "record": 100}
    var d := SaveData.sanitize(SaveData.migrate(old))
    eq(d["crystals"], 321, "coins migrated to crystals")
    eq(d["record"], 100, "record kept")

func test_unlocked_content_cannot_be_lost_by_sanitize() -> void:
    var d := SaveData.defaults()
    d["skins"] = SkinCatalog.skin_ids()
    d["cores"] = SkinCatalog.core_ids()
    var r := SaveData.sanitize(d)
    eq((r["skins"] as Array).size(), 20, "20 skins preserved")
    eq((r["cores"] as Array).size(), 5, "5 cores preserved")
