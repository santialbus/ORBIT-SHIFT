extends "res://tests/test_case.gd"

func test_catalog_sizes_and_uniqueness() -> void:
    eq(SkinCatalog.SKINS.size(), 20, "20 skins")
    eq(SkinCatalog.CORES.size(), 5, "5 cores")
    var seen := {}
    for s in SkinCatalog.SKINS:
        check(not seen.has(s["id"]), "unique skin id " + s["id"])
        seen[s["id"]] = true
        check(String(s["name"]) != "" and int(s["price"]) >= 0 and int(s["style"]) >= 0 and int(s["style"]) <= 7, "valid skin " + s["id"])
    for name in ["Cyan Core", "Plasma", "Solar", "Violet Pulse", "Inferno", "Quantum", "Nebula", "Shadow", "Golden Core"]:
        var found := false
        for s in SkinCatalog.SKINS:
            if s["name"] == name:
                found = true
        check(found, "required skin present: " + name)
    eq(int(SkinCatalog.get_skin("cyan_core")["price"]), 0, "starter skin is free")

func test_purchase_flow() -> void:
    var d := SaveData.defaults()
    d["crystals"] = 100
    var r := ProgressionLogic.unlock_skin(d, "plasma")    # costs 80
    check(r["ok"], "bought plasma")
    eq(d["crystals"], 20, "crystals deducted")
    check((d["skins"] as Array).has("plasma"), "skin added")
    r = ProgressionLogic.unlock_skin(d, "plasma")
    eq(r["reason"], "owned", "cannot buy twice")
    eq(d["crystals"], 20, "no double charge")
    r = ProgressionLogic.unlock_skin(d, "golden_core")
    eq(r["reason"], "funds", "insufficient funds")
    eq(d["crystals"], 20, "no charge on failure")
    r = ProgressionLogic.unlock_skin(d, "does_not_exist")
    eq(r["reason"], "unknown", "unknown id")

func test_equip_rules() -> void:
    var d := SaveData.defaults()
    check(not ProgressionLogic.equip_skin(d, "plasma"), "cannot equip locked skin")
    eq(d["equipped_skin"], "cyan_core", "unchanged")
    d["crystals"] = 500
    ProgressionLogic.unlock_skin(d, "plasma")
    check(ProgressionLogic.equip_skin(d, "plasma"), "can equip owned skin")
    eq(d["equipped_skin"], "plasma", "equipped")
    check(ProgressionLogic.unlock_core(d, "pulse_reactor")["ok"], "bought core")
    check(ProgressionLogic.equip_core(d, "pulse_reactor"), "equip core")

func test_apply_run_updates_everything() -> void:
    var d := SaveData.defaults()
    var run := {"score": 2500, "time": 47.0, "crystals": 12, "max_multiplier": 4, "dodged": 30, "near_misses": 3}
    var res := ProgressionLogic.apply_run(d, run)
    check(res["is_record"], "first run is a record")
    eq(d["record"], 2500, "record stored")
    eq(res["bonus"], 10, "bonus = score / 250")
    eq(d["crystals"], 12 + 10, "crystals earned")
    eq(d["stats"]["runs"], 1, "runs")
    near(float(d["stats"]["best_time"]), 47.0, "best time")
    eq(d["stats"]["best_combo"], 4, "best combo")
    eq(d["stats"]["dodged"], 30, "dodged")
    var res2 := ProgressionLogic.apply_run(d, {"score": 1000, "time": 20.0, "crystals": 3, "max_multiplier": 2, "dodged": 5, "near_misses": 0})
    check(not res2["is_record"], "lower score is not a record")
    eq(d["record"], 2500, "record unchanged")
    eq(d["stats"]["runs"], 2, "runs incremented")
    near(float(d["stats"]["total_time"]), 67.0, "total time")
    eq(d["stats"]["best_combo"], 4, "best combo kept")
    var res3 := ProgressionLogic.apply_run(d, {"score": 3000, "time": 30.0, "crystals": 0, "max_multiplier": 1})
    check(res3["is_record"], "higher score is a record")
    eq(d["stats"]["records_broken"], 1, "second record counted (first run does not count)")

func test_save_survives_apply_run_roundtrip() -> void:
    var d := SaveData.defaults()
    ProgressionLogic.apply_run(d, {"score": 999, "time": 12.0, "crystals": 4, "max_multiplier": 1})
    var back := SaveData.decode(SaveData.encode(d))
    check(back["checksum_ok"], "valid after run")
    eq(back["data"]["record"], 999, "record persisted")

func test_save_manager_persistence_on_disk() -> void:
    var sm = load("res://scripts/save/save_manager.gd").new()
    sm.data = SaveData.defaults()
    sm.data["crystals"] = 4242
    sm.data["record"] = 777
    check(sm.save_game(), "save written")
    var sm2 = load("res://scripts/save/save_manager.gd").new()
    sm2.load_game()
    eq(sm2.data["crystals"], 4242, "crystals reloaded from disk")
    eq(sm2.data["record"], 777, "record reloaded from disk")
    # corrupt the main file: the backup must be used
    sm.data["crystals"] = 5000
    sm.save_game()     # now .bak holds 4242, main holds 5000
    var f := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.WRITE)
    f.store_string("{ corrupted")
    f.close()
    var sm3 = load("res://scripts/save/save_manager.gd").new()
    sm3.load_game()
    eq(sm3.data["crystals"], 4242, "backup restored after corruption")
    check(sm3.load_report != "ok", "report mentions recovery")
    DirAccess.remove_absolute(SaveManager.SAVE_PATH)
    DirAccess.remove_absolute(SaveManager.BACKUP_PATH)
    sm.free()
    sm2.free()
    sm3.free()
