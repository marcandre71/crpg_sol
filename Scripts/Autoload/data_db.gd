extends Node
## Charge les fichiers de Data/ au démarrage.

const SKILLS_PATH := "res://Data/Rules/skills.json"
const ORIGINS_PATH := "res://Data/Rules/origins.json"
const CHARACTERS_DIR := "res://Data/Characters"
const ITEMS_PATH := "res://Data/Items/items.json"
const DIALOGUES_DIR := "res://Data/Dialogues"

## Compétences indexées par clé (ex. "systemes_de_survie").
var skills: Dictionary = {}
## Origines indexées par clé (ex. "ceinture").
var origins: Dictionary = {}
## Fiches JSON brutes des personnages, indexées par id ; get_character() en fait un CharacterData.
var characters: Dictionary = {}
## Objets (armes, armures, équipement) indexés par clé.
var items: Dictionary = {}
## Dialogues indexés par id.
var dialogues: Dictionary = {}


func _ready() -> void:
	skills = load_skills(SKILLS_PATH)
	origins = load_keyed(ORIGINS_PATH, "origins")
	characters = load_characters(CHARACTERS_DIR, skills, origins)
	items = load_keyed(ITEMS_PATH, "items")
	dialogues = load_dialogues(DIALOGUES_DIR, skills)


static func read_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DataDB : impossible d'ouvrir %s" % path)
		return null
	return JSON.parse_string(file.get_as_text())


## Fichier de la forme { "<list_key>": [ { "key": ... }, ... ] }, indexé par "key".
static func load_keyed(path: String, list_key: String) -> Dictionary:
	var data: Variant = read_json(path)
	if not data is Dictionary or not data.has(list_key):
		push_error("DataDB : format invalide dans %s" % path)
		return {}
	var by_key := {}
	for entry: Dictionary in data[list_key]:
		by_key[entry["key"]] = entry
	return by_key


static func load_skills(path: String) -> Dictionary:
	return load_keyed(path, "skills")


## Charge et valide chaque fiche *.json du dossier ; une fiche invalide est écartée avec ses erreurs.
static func load_characters(dir: String, skills_db: Dictionary, origins_db: Dictionary) -> Dictionary:
	var by_id := {}
	if not DirAccess.dir_exists_absolute(dir):
		return by_id
	for file in DirAccess.get_files_at(dir):
		if not file.ends_with(".json"):
			continue
		var path := dir.path_join(file)
		var data: Variant = read_json(path)
		if not data is Dictionary:
			push_error("DataDB : format invalide dans %s" % path)
			continue
		var errors := CharacterData.validate(data, skills_db, origins_db)
		if not errors.is_empty():
			push_error("DataDB : %s invalide : %s" % [path, ", ".join(errors)])
			continue
		by_id[data["id"]] = data
	return by_id


## Charge et valide chaque dialogue *.json du dossier ; un dialogue invalide est écarté avec ses erreurs.
static func load_dialogues(dir: String, skills_db: Dictionary) -> Dictionary:
	var by_id := {}
	if not DirAccess.dir_exists_absolute(dir):
		return by_id
	for file in DirAccess.get_files_at(dir):
		if not file.ends_with(".json"):
			continue
		var path := dir.path_join(file)
		var data: Variant = read_json(path)
		if not data is Dictionary:
			push_error("DataDB : format invalide dans %s" % path)
			continue
		var errors := DialogueRunner.validate(data, skills_db)
		if not errors.is_empty():
			push_error("DataDB : %s invalide : %s" % [path, ", ".join(errors)])
			continue
		by_id[data["id"]] = data
	return by_id


func get_skill(key: String) -> Dictionary:
	return skills.get(key, {})


func get_item(key: String) -> Dictionary:
	return items.get(key, {})


func get_dialogue(id: String) -> Dictionary:
	return dialogues.get(id, {})


func get_origin(key: String) -> Dictionary:
	return origins.get(key, {})


## Nouveau CharacterData à partir de la fiche ; null si l'id est inconnu.
func get_character(id: String) -> CharacterData:
	if not characters.has(id):
		return null
	return CharacterData.from_dict(characters[id], origins)
