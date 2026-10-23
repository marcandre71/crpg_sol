class_name RulesEngine
extends RefCounted
## Tests du Livre de règles v0.2 : difficultés (§5), compétences (§4), tests opposés et prolongés (§6).

## Difficultés du LdR §5.
const DIFFICULTIES := {
	"tres_facile": 30,
	"facile": 20,
	"aisee": 10,
	"normale": 0,
	"delicate": -10,
	"difficile": -20,
	"tres_difficile": -30,
	"extreme": -40,
}

## Plafond du total difficulté + situation + modificateur libre (LdR §5).
const MODIFIER_CAP := 50

## Score renvoyé quand une compétence ne peut pas être tentée sans formation.
const IMPOSSIBLE := -1


## Score de base d'une compétence (LdR §4), avant difficulté et modificateurs.
## Compétence (F) sans formation : moitié de la caractéristique, arrondie au supérieur,
## ou impossible si untrained_allowed est faux (piloter un vaisseau à fusion, opérer).
static func skill_score(characteristic: int, training: int, training_required: bool = false, untrained_allowed: bool = true) -> int:
	if training_required and training == 0:
		if not untrained_allowed:
			return IMPOSSIBLE
		return ceili(characteristic / 2.0)
	return characteristic + training


## Score modifié : base + (difficulté + modificateurs), le total des modificateurs plafonné à ±50.
static func modified_target(base_score: int, difficulty: String = "normale", modifiers: Array[int] = []) -> int:
	assert(DIFFICULTIES.has(difficulty), "Difficulté inconnue : %s" % difficulty)
	var total: int = DIFFICULTIES[difficulty]
	for m in modifiers:
		total += m
	return base_score + clampi(total, -MODIFIER_CAP, MODIFIER_CAP)


## Test simple : lance le dé et renvoie le résultat (contrat ARCHITECTURE.md §5).
static func test(base_score: int, difficulty: String, modifiers: Array[int], rng: RandomNumberGenerator) -> Dictionary:
	return Dice.evaluate(Dice.roll_d100(rng), modified_target(base_score, difficulty, modifiers))


## Test opposé (LdR §6). Renvoie {"winner": "a" | "b" | "none", "margin": int}.
## - Un seul réussit : il l'emporte.
## - Les deux réussissent : plus de DR, puis score le plus élevé ; sinon situation bloquée.
## - Les deux échouent : personne ne progresse (au code appelant de faire profiter le défenseur).
## La marge est la différence de DR entre les deux camps.
static func opposed(a: Dictionary, b: Dictionary) -> Dictionary:
	var winner := "none"
	if a["success"] and not b["success"]:
		winner = "a"
	elif b["success"] and not a["success"]:
		winner = "b"
	elif a["success"] and b["success"]:
		if a["degrees"] != b["degrees"]:
			winner = "a" if a["degrees"] > b["degrees"] else "b"
		elif a["target"] != b["target"]:
			winner = "a" if a["target"] > b["target"] else "b"

	var margin := 0
	if winner == "a":
		margin = a["degrees"] - (b["degrees"] if b["success"] else 0)
	elif winner == "b":
		margin = b["degrees"] - (a["degrees"] if a["success"] else 0)
	return {"winner": winner, "margin": margin}


## Test prolongé (LdR §6) : objectif de DR atteint par plusieurs jets à intervalle fixe.
class ExtendedTest:
	extends RefCounted

	var goal: int
	var interval_seconds: int
	var progress := 0
	var attempts := 0
	var complications := 0

	func _init(goal_degrees: int, interval: int) -> void:
		goal = goal_degrees
		interval_seconds = interval

	## Ajoute un résultat de test : une réussite apporte 1 + DR ; un échec perd l'intervalle.
	func add(result: Dictionary) -> void:
		attempts += 1
		if result["success"]:
			progress += 1 + result["degrees"]
		elif result["complication"]:
			complications += 1

	func is_complete() -> bool:
		return progress >= goal

	func elapsed_seconds() -> int:
		return attempts * interval_seconds
