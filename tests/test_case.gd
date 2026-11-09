class_name TestCase
extends RefCounted
## Minimal assertion helper. Test methods are named test_*; failures are collected, not thrown.

var failures: Array[String] = []
var assertions := 0

func check(cond: bool, msg: String) -> void:
    assertions += 1
    if not cond:
        failures.append(msg)

func eq(a, b, msg: String) -> void:
    assertions += 1
    if a != b:
        failures.append("%s (got %s, expected %s)" % [msg, str(a), str(b)])

func near(a: float, b: float, msg: String, eps: float = 0.0001) -> void:
    assertions += 1
    if absf(a - b) > eps:
        failures.append("%s (got %f, expected %f)" % [msg, a, b])
