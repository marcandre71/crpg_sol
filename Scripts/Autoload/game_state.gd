extends Node
## État de la partie, sérialisable en JSON pour la sauvegarde.

## Drapeaux narratifs posés par les dialogues (ex. "kael_calme").
var flags: Dictionary = {}

## Secondes restantes avant l'arrêt du support vital du sas (valeur de démo à régler).
var life_support_seconds: int = 0

## Personnages présents dans la scène, indexés par id.
var characters: Dictionary = {}


func set_flag(flag: String, value: Variant = true) -> void:
	flags[flag] = value


func has_flag(flag: String) -> bool:
	return flags.get(flag, false) == true


## Ajoute un personnage et relaie ses changements de condition vers l'EventBus.
func add_character(character: CharacterData) -> void:
	characters[character.id] = character
	character.condition_changed.connect(
		func(condition_id: String, active: bool) -> void:
			EventBus.condition_changed.emit(character.id, condition_id, active))


func get_character(id: String) -> CharacterData:
	return characters.get(id)


func to_dict() -> Dictionary:
	var chars := {}
	for id: String in characters:
		chars[id] = characters[id].to_dict()
	return {"flags": flags, "life_support_seconds": life_support_seconds, "characters": chars}
