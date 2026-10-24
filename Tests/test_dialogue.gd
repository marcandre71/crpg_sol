extends TestCase
## Lecteur de dialogues (ARCHITECTURE.md §6.2) et scénario de Thulé-7.

const SCENARIO := "res://Data/Dialogues/thule7_sas.json"

var data_db: GDScript = preload("res://Scripts/Autoload/data_db.gd")
var skills: Dictionary = data_db.load_skills("res://Data/Rules/skills.json")

var sample := {
	"id": "essai", "start": "a",
	"nodes": {
		"a": {"speaker": "kael", "text": "Pas un geste.", "choices": [
			{"text": "Persuader", "skillCheck": {"skill": "persuasion", "difficulty": "delicate"},
			 "success": "b", "failure": "c", "criticalFailure": "d",
			 "effects": {"onSuccess": [{"setFlag": "calme"}], "always": [{"setFlag": "essaye"}]}},
			{"text": "Poser l'arme", "next": "b", "conditions": [{"flag": "arme"}]},
			{"text": "Une fois", "next": "a", "once": true, "timeCost": 30},
		]},
		"b": {"speaker": "kael", "text": "Bien.", "ending": {"id": "fin"}},
		"c": {"speaker": "kael", "text": "Non.", "redirects": [{"conditions": [{"flag": "essaye"}], "next": "e"}], "next": "a"},
		"d": {"speaker": "kael", "text": "Feu !", "ending": {"id": "mort"}},
		"e": {"speaker": "kael", "text": "Encore raté.", "next": "a"},
	},
}


func _runner(result: Dictionary, flags: Dictionary = {}) -> DialogueRunner:
	var runner := DialogueRunner.new(sample, flags, func(_check: Dictionary) -> Dictionary: return result)
	runner.start()
	return runner


func test_choix_filtres_par_conditions() -> void:
	var runner := _runner({})
	check_eq(runner.choices().size(), 2, "le choix conditionné est caché")
	var flags := {"arme": true}
	runner = _runner({}, flags)
	check_eq(runner.choices().size(), 3, "drapeau présent : choix visible")


func test_reussite_et_effets() -> void:
	var flags := {}
	var runner := _runner({"success": true, "critical": false, "degrees": 1, "complication": false}, flags)
	var out := runner.choose(0)
	check_eq(out["branch"], "success", "branche success")
	check_eq(runner.node_id, "b", "nœud b")
	check(runner.is_ending(), "fin atteinte")
	check(flags.get("calme", false), "onSuccess appliqué")
	check(flags.get("essaye", false), "always appliqué")


func test_echec_critique_et_redirection() -> void:
	var runner := _runner({"success": false, "critical": true, "degrees": 5, "complication": true})
	runner.choose(0)
	check_eq(runner.node_id, "d", "branche criticalFailure")
	runner = _runner({"success": false, "critical": false, "degrees": 1, "complication": false})
	runner.choose(0)
	check_eq(runner.node_id, "e", "échec : c redirige vers e car « essaye » est posé")


func test_choix_unique_et_temps() -> void:
	var runner := _runner({})
	var spent := [0]
	runner.effect_requested.connect(func(e: Dictionary) -> void: spent[0] += e.get("timeCost", 0))
	runner.choose(2)
	check_eq(spent[0], 30, "timeCost signalé")
	check_eq(runner.choices().size(), 1, "le choix « once » disparaît")


func test_choix_interrompu_par_l_horloge() -> void:
	# Le temps du choix épuise l'horloge : le jeu saute à une fin, le choix ne doit pas en ressortir.
	var runner := _runner({})
	var expire := func(e: Dictionary) -> void:
		if e.has("timeCost"):
			runner.goto("d")
	runner.effect_requested.connect(expire)
	var out := runner.choose(2)
	runner.effect_requested.disconnect(expire)  # sinon référence circulaire
	check_eq(out["branch"], "interrupted", "choix interrompu")
	check_eq(runner.node_id, "d", "reste sur la fin")


func test_validation_du_scenario() -> void:
	var data: Dictionary = data_db.read_json(SCENARIO)
	var errors := DialogueRunner.validate(data, skills)
	check_eq(errors.size(), 0, "scénario valide : %s" % ", ".join(errors))
	check(not DialogueRunner.validate(sample, skills).is_empty() == false, "dialogue d'essai valide")
	var broken := {"start": "x", "nodes": {"x": {"choices": [{"text": "?", "next": "nulle_part"}]}}}
	check(not DialogueRunner.validate(broken, skills).is_empty(), "nœud inconnu détecté")


func test_scenario_toujours_jouable_jusqu_a_une_fin() -> void:
	# Parties au hasard : chaque partie doit atteindre une fin, sans impasse.
	var data: Dictionary = data_db.read_json(SCENARIO)
	var endings := {}
	for seed_value in 300:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var flags := {}
		var pending: Array = []
		var tester := func(check_def: Dictionary) -> Dictionary:
			return Dice.evaluate(rng.randi_range(1, 100), 50)
		var runner := DialogueRunner.new(data, flags, tester)
		runner.effect_requested.connect(func(e: Dictionary) -> void: pending.append(e))
		runner.start()
		var steps := 0
		while not runner.is_ending() and steps < 400:
			steps += 1
			var handled := false
			while not pending.is_empty():
				var e: Dictionary = pending.pop_front()
				if e.has("startCombat"):
					var then: Dictionary = e["startCombat"]["then"]
					pending.clear()
					runner.goto(then.values()[rng.randi_range(0, then.size() - 1)])
					handled = true
					break
				if e.has("startRepair"):
					pending.clear()
					runner.goto(e["startRepair"]["then"]["done" if rng.randf() < 0.8 else "abort"])
					handled = true
					break
			if handled or runner.is_ending():
				continue
			var options := runner.choices()
			if options.is_empty():
				check(runner.node().has("next"), "impasse au nœud %s" % runner.node_id)
				if not runner.node().has("next"):
					break
				runner.advance()
			else:
				runner.choose(options[rng.randi_range(0, options.size() - 1)]["index"])
		check(runner.is_ending(), "partie %d terminée (dernier nœud %s)" % [seed_value, runner.node_id])
		endings[runner.node()["ending"]["id"] if runner.is_ending() else "aucune"] = true
	for id in ["fin_mutuelle", "fin_veille", "fin_kombinat", "fin_vide", "fin_defaite"]:
		check(endings.has(id), "fin %s atteignable" % id)
