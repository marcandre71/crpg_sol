class_name DialogueRunner
extends RefCounted
## Lecteur des dialogues JSON (schéma ARCHITECTURE.md §6.2).
##
## Le lecteur gère les nœuds, les choix, les conditions et les drapeaux ; il délègue les jets
## à `tester` et signale par `effect_requested` ce qui sort du dialogue (temps, combat,
## réparation, fin, Sang-froid).
##
## Nœud : speaker, text, choices, next (bouton « Continuer »), effects (appliqués à l'entrée),
##   redirects ([{conditions, next}] : le premier qui convient remplace le nœud), ending.
## Choix : text, conditions, once, timeCost, next, skillCheck {skill, difficulty, modifiers, opposedBy {npc, skill}},
##   success, failure, criticalSuccess, criticalFailure, complication, effects {always, onSuccess, onFailure}.
## Effets : setFlag, clearFlag (gérés ici) ; timeCost, loseSangFroid, startCombat, startRepair, ending (signalés).

signal effect_requested(effect: Dictionary)
signal node_entered(node_id: String)

const MAX_REDIRECTS := 16

var dialogue: Dictionary
var flags: Dictionary
## func(skill_check: Dictionary) -> Dictionary : TestResult (success = le joueur l'emporte), {} si impossible.
var tester: Callable
var node_id := ""
var _used: Dictionary = {}


func _init(data: Dictionary, flag_store: Dictionary, test_callable: Callable) -> void:
	dialogue = data
	flags = flag_store
	tester = test_callable


func start(start_id: String = "") -> void:
	goto(start_id if start_id != "" else str(dialogue["start"]))


func node() -> Dictionary:
	return dialogue["nodes"].get(node_id, {})


func is_ending() -> bool:
	return node().has("ending")


## Va au nœud demandé, suit les redirections, puis applique ses effets d'entrée.
func goto(target: String) -> void:
	var id := target
	for i in MAX_REDIRECTS:
		var redirected := false
		for r: Dictionary in dialogue["nodes"][id].get("redirects", []):
			if conditions_met(r.get("conditions", [])):
				id = r["next"]
				redirected = true
				break
		if not redirected:
			break
	node_id = id
	node_entered.emit(node_id)
	_apply_effects(node().get("effects", []))


func conditions_met(conditions: Array) -> bool:
	for c: Dictionary in conditions:
		if c.has("flag") and flags.get(c["flag"], false) != true:
			return false
		if c.has("notFlag") and flags.get(c["notFlag"], false) == true:
			return false
	return true


## Choix disponibles : [{ "index": int, "choice": Dictionary }].
func choices() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	var all: Array = node().get("choices", [])
	for i in all.size():
		var choice: Dictionary = all[i]
		if choice.get("once", false) and _used.has("%s:%d" % [node_id, i]):
			continue
		if conditions_met(choice.get("conditions", [])):
			list.append({"index": i, "choice": choice})
	return list


## Joue le choix d'indice `index` (indice dans node().choices). Renvoie { result, branch, next }.
## Si un effet déplace le dialogue (horloge à zéro → fin), le choix s'arrête là (branch = "interrupted").
func choose(index: int) -> Dictionary:
	var choice: Dictionary = node()["choices"][index]
	var from := node_id
	_used["%s:%d" % [node_id, index]] = true
	if choice.get("timeCost", 0) > 0:
		effect_requested.emit({"timeCost": choice["timeCost"]})
		if node_id != from:
			return {"result": {}, "branch": "interrupted", "next": node_id}

	var result := {}
	var branch := "next"
	if choice.has("skillCheck"):
		result = tester.call(choice["skillCheck"])
		branch = branch_for(result, choice)
	var effects: Dictionary = choice.get("effects", {})
	var list: Array = effects.get("always", []).duplicate()
	if choice.has("skillCheck"):
		list.append_array(effects.get("onSuccess" if result.get("success", false) else "onFailure", []))
	_apply_effects(list)
	if node_id != from:
		return {"result": result, "branch": "interrupted", "next": node_id}

	var next: String = choice.get(branch, choice.get("next", ""))
	if next != "":
		goto(next)
	return {"result": result, "branch": branch, "next": next}


## Branche suivie après un test : les branches facultatives retombent sur success ou failure.
static func branch_for(result: Dictionary, choice: Dictionary) -> String:
	if result.get("success", false):
		if result.get("critical", false) and choice.has("criticalSuccess"):
			return "criticalSuccess"
		return "success"
	if result.get("critical", false) and choice.has("criticalFailure"):
		return "criticalFailure"
	if result.get("complication", false) and choice.has("complication"):
		return "complication"
	return "failure"


## « Continuer » sur un nœud sans choix.
func advance() -> void:
	if node().has("next"):
		goto(node()["next"])


func _apply_effects(effects: Array) -> void:
	for e: Dictionary in effects:
		if e.has("setFlag"):
			flags[e["setFlag"]] = true
		elif e.has("clearFlag"):
			flags.erase(e["clearFlag"])
		else:
			effect_requested.emit(e)


# --- Validation ----------------------------------------------------------------------

## Erreurs de structure : nœuds manquants, clés de compétence ou de difficulté inconnues, impasses.
static func validate(data: Dictionary, skills_db: Dictionary = {}) -> Array[String]:
	var errors: Array[String] = []
	var nodes: Dictionary = data.get("nodes", {})
	if not nodes.has(data.get("start", "")):
		errors.append("nœud de départ introuvable")
	for id: String in nodes:
		var n: Dictionary = nodes[id]
		var targets: Array[String] = []
		if n.has("next"):
			targets.append(n["next"])
		for r: Dictionary in n.get("redirects", []):
			targets.append(r["next"])
		for e: Dictionary in n.get("effects", []):
			for key in ["startCombat", "startRepair"]:
				if e.has(key):
					for k: String in e[key].get("then", {}):
						targets.append(e[key]["then"][k])
		var has_exit: bool = n.has("ending") or n.has("next") or not n.get("choices", []).is_empty()
		for e: Dictionary in n.get("effects", []):
			has_exit = has_exit or e.has("startCombat") or e.has("startRepair")
		if not has_exit:
			errors.append("%s : impasse (ni choix, ni suite, ni fin)" % id)
		for c: Dictionary in n.get("choices", []):
			for key in ["next", "success", "failure", "criticalSuccess", "criticalFailure", "complication"]:
				if c.has(key):
					targets.append(c[key])
			if c.has("skillCheck"):
				var sc: Dictionary = c["skillCheck"]
				if not skills_db.is_empty() and not skills_db.has(sc.get("skill", "")):
					errors.append("%s : compétence inconnue %s" % [id, sc.get("skill", "")])
				if not RulesEngine.DIFFICULTIES.has(sc.get("difficulty", "normale")):
					errors.append("%s : difficulté inconnue %s" % [id, sc.get("difficulty")])
				if not (c.has("success") and c.has("failure")):
					errors.append("%s : test sans branche success ou failure" % id)
				var opp: Dictionary = sc.get("opposedBy", {})
				if not opp.is_empty() and not skills_db.is_empty() and not skills_db.has(opp.get("skill", "")):
					errors.append("%s : compétence opposée inconnue %s" % [id, opp.get("skill", "")])
			elif not c.has("next"):
				errors.append("%s : choix sans suite (%s)" % [id, c.get("text", "")])
		for t in targets:
			if not nodes.has(t):
				errors.append("%s : renvoie vers un nœud inconnu %s" % [id, t])
	return errors
