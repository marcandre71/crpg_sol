class_name CharacterData
extends RefCounted
## Modèle du personnage (Fiche de personnage v0.2, §3 et §4 ; schéma ARCHITECTURE.md §6.1).
## Sans nœud : les scènes relaient les signaux vers l'EventBus.

signal condition_changed(condition_id: String, active: bool)
signal resources_changed

const CHARACTERISTICS: Array[String] = ["for", "con", "coo", "ref", "ada", "per", "int", "vol", "pre"]
const MAX_TRAINING := 60
const LOCATIONS: Array[String] = ["head", "torso", "rightArm", "leftArm", "rightLeg", "leftLeg"]
const SEVERITIES: Array[String] = ["light", "serious", "critical", "mortal"]

var id := ""
var name := ""
var faction := ""
var origin := ""
var gravity_native := 1.0
## Modificateur de TG de l'origine (LdR §9), lu dans Data/Rules/origins.json.
var tg_modifier := 0
## Valeurs actuelles, modificateurs d'origine compris.
var characteristics: Dictionary = {}
## Points de formation (0 à 60) par clé de compétence, pas le score.
var skills: Dictionary = {}
var armor := ""
var weapons: Array[String] = []

var endurance := 0
var sang_froid := 0
## Stade d'hypoxie (0 à 3).
var hypoxia := 0
var position := Conditions.ANCHORED
var conditions: Array[String] = []
## Blessures : { "location", "severity", "treated", "source" }.
var injuries: Array[Dictionary] = []


# --- Chargement -------------------------------------------------------------

## Erreurs de schéma d'une fiche JSON ; tableau vide si elle est valide.
static func validate(data: Dictionary, skills_db: Dictionary = {}, origins_db: Dictionary = {}) -> Array[String]:
	var errors: Array[String] = []
	if str(data.get("id", "")) == "":
		errors.append("id manquant")
	var chars: Variant = data.get("characteristics")
	if not chars is Dictionary:
		errors.append("characteristics manquant")
	else:
		for c in CHARACTERISTICS:
			var v: Variant = chars.get(c)
			if not (v is float or v is int) or v < 1 or v > 100:
				errors.append("caractéristique %s absente ou hors de 1 à 100" % c)
		for c: String in chars:
			if not c in CHARACTERISTICS:
				errors.append("caractéristique inconnue : %s" % c)
	var trained: Variant = data.get("skills", {})
	if not trained is Dictionary:
		errors.append("skills doit être un objet")
	else:
		for key: String in trained:
			if not skills_db.is_empty() and not skills_db.has(key):
				errors.append("compétence inconnue : %s" % key)
			var t: Variant = trained[key]
			if not (t is float or t is int) or t < 0 or t > MAX_TRAINING:
				errors.append("formation de %s hors de 0 à %d" % [key, MAX_TRAINING])
	var o := str(data.get("origin", ""))
	if o != "" and not origins_db.is_empty() and not origins_db.has(o):
		errors.append("origine inconnue : %s" % o)
	for c: Variant in data.get("conditions", []):
		if not Conditions.is_valid(str(c)):
			errors.append("condition inconnue : %s" % c)
	return errors


## Construit un personnage à partir d'une fiche déjà validée.
## null pour endurance et sangFroid = pleins.
static func from_dict(data: Dictionary, origins_db: Dictionary = {}) -> CharacterData:
	var ch := CharacterData.new()
	ch.id = data["id"]
	ch.name = data.get("name", ch.id)
	ch.faction = data.get("faction", "")
	ch.origin = data.get("origin", "")
	var origin_data: Dictionary = origins_db.get(ch.origin, {})
	ch.tg_modifier = int(origin_data.get("tgModifier", 0))
	ch.gravity_native = float(data.get("gravityNative", origin_data.get("gravityNative", 1.0)))
	for c in CHARACTERISTICS:
		ch.characteristics[c] = int(data["characteristics"][c])
	var trained: Dictionary = data.get("skills", {})
	for key: String in trained:
		ch.skills[key] = int(trained[key])
	ch.armor = data.get("armor", "")
	for w: Variant in data.get("weapons", []):
		ch.weapons.append(str(w))
	ch.endurance = ch.endurance_max() if data.get("endurance") == null else int(data["endurance"])
	ch.sang_froid = ch.sang_froid_max() if data.get("sangFroid") == null else int(data["sangFroid"])
	ch.hypoxia = int(data.get("hypoxia", 0))
	ch.position = data.get("position", Conditions.ANCHORED)
	for c: Variant in data.get("conditions", []):
		ch.conditions.append(str(c))
	for i: Variant in data.get("injuries", []):
		ch.injuries.append(i)
	return ch


## État courant pour la sauvegarde ; relu tel quel par from_dict.
func to_dict() -> Dictionary:
	return {
		"id": id, "name": name, "faction": faction, "origin": origin,
		"gravityNative": gravity_native, "characteristics": characteristics.duplicate(),
		"skills": skills.duplicate(), "armor": armor, "weapons": weapons.duplicate(),
		"endurance": endurance, "sangFroid": sang_froid, "hypoxia": hypoxia,
		"position": position, "conditions": conditions.duplicate(), "injuries": injuries.duplicate(true),
	}


# --- Valeurs dérivées (jamais stockées) -------------------------------------

func characteristic(key: String) -> int:
	return characteristics.get(key, 0)


## Seuil de blessure (SB) : (FOR + CON) / 20, arrondi au supérieur (LdR §3).
func wound_threshold() -> int:
	return ceili((characteristic("for") + characteristic("con")) / 20.0)


## Tolérance aux g (TG) : CON / 20, arrondi au supérieur, + origine ; plancher à 0 (proposé par la Fiche §3).
func g_tolerance() -> int:
	return maxi(0, ceili(characteristic("con") / 20.0) + tg_modifier)


## Endurance max : CON / 5, arrondi au supérieur.
func endurance_max() -> int:
	return ceili(characteristic("con") / 5.0)


## Sang-froid max : VOL / 5, arrondi au supérieur.
func sang_froid_max() -> int:
	return ceili(characteristic("vol") / 5.0)


## Bornes basses des blessures (LdR §7) : grave à SB, critique à 2 SB, mortelle à 3 SB.
func wound_bands() -> Dictionary:
	var sb := wound_threshold()
	return {"serious": sb, "critical": 2 * sb, "mortal": 3 * sb}


## Gravité d'une blessure d'après les dégâts restant après armure ; "" = secoué, sans blessure.
func wound_severity(damage_after_armor: int) -> String:
	if damage_after_armor <= 0:
		return ""
	var bands := wound_bands()
	if damage_after_armor >= bands["mortal"]:
		return "mortal"
	if damage_after_armor >= bands["critical"]:
		return "critical"
	if damage_after_armor >= bands["serious"]:
		return "serious"
	return "light"


## Score de base d'une compétence (LdR §4), d'après sa définition dans skills.json.
func skill_score(skill_def: Dictionary) -> int:
	return RulesEngine.skill_score(
		characteristic(skill_def["characteristic"]),
		skills.get(skill_def["key"], 0),
		skill_def.get("trainingRequired", false),
		skill_def.get("untrainedAllowed", true))


## Modificateurs de conditions pour un test ; domaine vide = test de caractéristique.
func condition_modifiers(skill_domain: String = "") -> Array[int]:
	return Conditions.test_modifiers(conditions, hypoxia, skill_domain)


func can_act() -> bool:
	return Conditions.can_act(conditions)


func can_react() -> bool:
	return Conditions.can_react(conditions)


# --- Conditions --------------------------------------------------------------

func has_condition(condition_id: String) -> bool:
	return condition_id in conditions


func add_condition(condition_id: String) -> void:
	assert(Conditions.is_valid(condition_id), "Condition inconnue : %s" % condition_id)
	if not condition_id in conditions:
		conditions.append(condition_id)
		condition_changed.emit(condition_id, true)


func remove_condition(condition_id: String) -> void:
	if condition_id in conditions:
		conditions.erase(condition_id)
		condition_changed.emit(condition_id, false)


## Ancré, Flottant ou En vol : la nouvelle position remplace l'ancienne.
func set_position(new_position: String) -> void:
	assert(new_position in Conditions.POSITIONS, "Position inconnue : %s" % new_position)
	if new_position == position:
		return
	condition_changed.emit(position, false)
	position = new_position
	condition_changed.emit(position, true)


## Stade d'hypoxie (0 à 3) ; au stade 3, le personnage perd connaissance.
## Redescendre ne le réveille pas : c'est à la scène de retirer Inconscient.
func set_hypoxia(stage: int) -> void:
	hypoxia = clampi(stage, 0, Conditions.HYPOXIA_UNCONSCIOUS_STAGE)
	resources_changed.emit()
	if hypoxia >= Conditions.HYPOXIA_UNCONSCIOUS_STAGE:
		add_condition(Conditions.UNCONSCIOUS)


# --- Ressources ----------------------------------------------------------------

## Retire des points d'Endurance. Renvoie vrai si elle vient de tomber à 0 :
## l'appelant fait alors le test de CON et passe le résultat à resolve_endurance_zero().
func lose_endurance(amount: int) -> bool:
	var before := endurance
	endurance = maxi(0, endurance - amount)
	resources_changed.emit()
	return before > 0 and endurance == 0


## Endurance à 0 (LdR §3) : test de CON réussi = Épuisé (−20) ; raté = Inconscient.
func resolve_endurance_zero(con_test_success: bool) -> void:
	add_condition(Conditions.EXHAUSTED if con_test_success else Conditions.UNCONSCIOUS)


func recover_endurance(amount: int) -> void:
	endurance = mini(endurance_max(), endurance + amount)
	resources_changed.emit()


## Retire des points de Sang-froid ; à 0, le personnage est Choqué (LdR §11).
func lose_sang_froid(amount: int) -> void:
	sang_froid = maxi(0, sang_froid - amount)
	resources_changed.emit()
	if sang_froid == 0:
		add_condition(Conditions.SHOCKED)


func recover_sang_froid(amount: int) -> void:
	sang_froid = mini(sang_froid_max(), sang_froid + amount)
	resources_changed.emit()


# --- Blessures -----------------------------------------------------------------

## Ajoute une blessure ; une blessure grave fait saigner (LdR §7).
## Les autres effets (lâcher l'objet, inconscience, mort) relèvent du combat.
func add_injury(location: String, severity: String, source: String = "") -> Dictionary:
	assert(location in LOCATIONS, "Zone inconnue : %s" % location)
	assert(severity in SEVERITIES, "Gravité inconnue : %s" % severity)
	var injury := {"location": location, "severity": severity, "treated": false, "source": source}
	injuries.append(injury)
	if severity == "serious":
		add_condition(Conditions.BLEEDING)
	return injury
