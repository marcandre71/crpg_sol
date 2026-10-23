extends SceneTree
## Lanceur de tests sans dépendance.
## Usage : Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://Tests/run_tests.gd

const TEST_DIR := "res://Tests"


func _init() -> void:
	var total := 0
	var failed := 0
	for file in DirAccess.get_files_at(TEST_DIR):
		if not (file.begins_with("test_") and file.ends_with(".gd")) or file == "test_case.gd":
			continue
		var script: GDScript = load(TEST_DIR.path_join(file))
		for method in script.get_script_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			var case: TestCase = script.new()
			case.call(name)
			total += 1
			if case.failures.is_empty():
				print("  ok    %s::%s" % [file, name])
			else:
				failed += 1
				print("  ÉCHEC %s::%s" % [file, name])
				for f in case.failures:
					print("        - %s" % f)
	print("\n%d test(s), %d échec(s)" % [total, failed])
	quit(1 if failed > 0 else 0)
