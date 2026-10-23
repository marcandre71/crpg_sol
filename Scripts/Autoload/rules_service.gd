extends Node
## Façade vers Scripts/Core pour les scènes. Le moteur lui-même reste sans nœud.

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()


## Test simple : score de base, clé de difficulté (LdR §5), modificateurs de situation.
func test(base_score: int, difficulty: String = "normale", modifiers: Array[int] = []) -> Dictionary:
	return RulesEngine.test(base_score, difficulty, modifiers, rng)
