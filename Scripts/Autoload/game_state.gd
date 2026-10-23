extends Node
## État de la partie, sérialisable en JSON pour la sauvegarde.

## Drapeaux narratifs posés par les dialogues (ex. "kael_calme").
var flags: Dictionary = {}

## Secondes restantes avant l'arrêt du support vital du sas (valeur de démo à régler).
var life_support_seconds: int = 0


func set_flag(flag: String, value: Variant = true) -> void:
	flags[flag] = value


func has_flag(flag: String) -> bool:
	return flags.get(flag, false) == true


func to_dict() -> Dictionary:
	return {"flags": flags, "life_support_seconds": life_support_seconds}
