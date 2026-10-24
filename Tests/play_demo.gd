extends SceneTree
## Joue des parties complètes dans la vraie interface en cliquant au hasard.
## Usage : godot --headless --path . -s res://Tests/play_demo.gd [-- <parties>]

const MAX_CLICKS := 600


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var games := 40
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		games = int(args[0])
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var endings := {}
	var failures := 0
	for g in games:
		var screen: Control = load("res://Scenes/UI/Game.tscn").instantiate()
		screen.ai_delay = 0.0
		root.add_child(screen)
		await process_frame
		var clicks := 0
		while clicks < MAX_CLICKS:
			if screen.mode == screen.Mode.ENDING:
				break
			var buttons: Array = screen._choices.get_children().filter(
				func(b: Node) -> bool: return b is Button and not b.disabled and not b.is_queued_for_deletion())
			if buttons.is_empty():
				await process_frame
				await process_frame
				clicks += 1
				continue
			var b: Button = buttons[rng.randi_range(0, buttons.size() - 1)]
			b.pressed.emit()
			clicks += 1
			await process_frame
		var id := "aucune"
		if screen.mode == screen.Mode.ENDING:
			id = screen.runner.node().get("ending", {}).get("id", "?")
		else:
			failures += 1
			print("  partie %d bloquée au nœud %s (mode %d)" % [g, screen.runner.node_id, screen.mode])
		endings[id] = endings.get(id, 0) + 1
		screen.queue_free()
		await process_frame
	print("Fins atteintes : %s" % str(endings))
	print("%d partie(s), %d bloquée(s)" % [games, failures])
	quit(1 if failures > 0 else 0)
