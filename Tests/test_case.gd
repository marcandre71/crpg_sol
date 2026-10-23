class_name TestCase
extends RefCounted
## Base des tests : chaque méthode test_* appelle check() ou check_eq().

var failures: Array[String] = []


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func check_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (attendu %s, obtenu %s)" % [message, str(expected), str(actual)])
