extends SceneTree
## Run: godot --headless --path . -s tests/run_tests.gd
## Executes every tests/test_*.gd (excluding test_case.gd) and exits non-zero on failure.

func _init() -> void:
    var dir := DirAccess.open("res://tests")
    var files: Array[String] = []
    for f in dir.get_files():
        if f.begins_with("test_") and f.ends_with(".gd") and f != "test_case.gd":
            files.append(f)
    files.sort()
    var total_tests := 0
    var total_asserts := 0
    var failed := 0
    for f in files:
        var script: GDScript = load("res://tests/" + f)
        var inst = script.new()
        for m in inst.get_method_list():
            var mname: String = m["name"]
            if not mname.begins_with("test_"):
                continue
            inst.failures.clear()
            var before: int = inst.assertions
            var t0 := Time.get_ticks_msec()
            inst.call(mname)
            total_tests += 1
            total_asserts += inst.assertions - before
            var ms := Time.get_ticks_msec() - t0
            if inst.failures.is_empty():
                print("  PASS  %s::%s  (%d ms)" % [f.get_basename(), mname, ms])
            else:
                failed += 1
                print("  FAIL  %s::%s" % [f.get_basename(), mname])
                for msg in inst.failures:
                    print("        - " + msg)
    print("")
    print("RESULT: %d tests, %d assertions, %d failed" % [total_tests, total_asserts, failed])
    quit(1 if failed > 0 else 0)
