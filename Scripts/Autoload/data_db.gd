extends Node
## Charge les fichiers de Data/ au démarrage.

const SKILLS_PATH := "res://Data/Rules/skills.json"

## Compétences indexées par clé (ex. "systemes_de_survie").
var skills: Dictionary = {}


func _ready() -> void:
	skills = load_skills(SKILLS_PATH)


static func load_skills(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DataDB : impossible d'ouvrir %s" % path)
		return {}
	var data: Variant = JSON.parse_string(file.get_as_text())
	if not data is Dictionary or not data.has("skills"):
		push_error("DataDB : format invalide dans %s" % path)
		return {}
	var by_key := {}
	for skill: Dictionary in data["skills"]:
		by_key[skill["key"]] = skill
	return by_key


func get_skill(key: String) -> Dictionary:
	return skills.get(key, {})
