extends Node
## Façade vers Scripts/Core pour les scènes. Le moteur lui-même reste sans nœud.

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()


## Test simple : score de base, clé de difficulté (LdR §5), modificateurs de situation.
func test(base_score: int, difficulty: String = "normale", modifiers: Array[int] = []) -> Dictionary:
	return RulesEngine.test(base_score, difficulty, modifiers, rng)


## Test de compétence d'un personnage, conditions comprises (Épuisé, Choqué, hypoxie).
## Renvoie {} si la compétence ne peut pas être tentée sans formation.
func test_skill(character: CharacterData, skill_key: String, difficulty: String = "normale", modifiers: Array[int] = []) -> Dictionary:
	var skill_def: Dictionary = DataDB.get_skill(skill_key)
	assert(not skill_def.is_empty(), "Compétence inconnue : %s" % skill_key)
	var score := character.skill_score(skill_def)
	if score == RulesEngine.IMPOSSIBLE:
		return {}
	var mods: Array[int] = modifiers.duplicate()
	mods.append_array(character.condition_modifiers(skill_def["domain"]))
	var result := test(score, difficulty, mods)
	EventBus.skill_check_resolved.emit(character.id, skill_key, result)
	return result
