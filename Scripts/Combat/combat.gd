class_name CombatEngine
extends RefCounted
## Combat tactique en apesanteur (Livre de règles v0.2, §7). Sans nœud : l'UI lit l'état et appelle les actions.
##
## Tour : 1 action, 1 mouvement, 1 réaction par personnage ; un tour de combat = 5 secondes.
## Adaptations (ARCHITECTURE.md §7) : l'esquive est une réaction automatique (test opposé
## Esquive contre l'attaque), le couvert vaut −20, le cessez-le-feu est un test de Commandement.

signal logged(text: String)
signal round_started(round_number: int)

const ROUND_SECONDS := 5
const COVER_PENALTY := -20
const AIM_STEP := 10
const AIM_MAX := 30
const FLYING_TARGET_BONUS := 10
const BURST_RECOIL_PENALTY := -20

## Malus du tir visé (LdR §7). "visor" = coup à la visière (tête, protection et seuil de brèche divisés par deux).
const AIMED_PENALTIES := {"torso": -10, "rightArm": -20, "leftArm": -20, "rightLeg": -20, "leftLeg": -20, "head": -30, "visor": -40}

const ZONE_NAMES := {
	"head": "tête", "torso": "torse", "rightArm": "bras droit", "leftArm": "bras gauche",
	"rightLeg": "jambe droite", "leftLeg": "jambe gauche", "visor": "visière",
}
const SEVERITY_NAMES := {"light": "légère", "serious": "grave", "critical": "critique", "mortal": "mortelle"}


class Combatant:
	extends RefCounted

	var character: CharacterData
	var side: String  ## "player", "ally" ou "enemy"
	var weapon: Dictionary
	var armor: Dictionary
	var ammo := 0
	var cover := 0
	var aim := 0
	var spinning := false
	var disarmed := false
	var dead := false
	## PNJ qui s'est rendu (désarmé) : hors de combat.
	var surrendered := false
	## Renvoyé en fin d'ordre au tour suivant (blessure grave ou pire, Sonné).
	var pushed_back := false
	var action_used := false
	var move_used := false
	var reaction_used := false
	## Résultat du test de Vigilance d'initiative.
	var initiative: Dictionary = {}

	func _init(ch: CharacterData, combat_side: String, weapon_def: Dictionary, armor_def: Dictionary) -> void:
		character = ch
		side = combat_side
		weapon = weapon_def
		armor = armor_def
		ammo = weapon_def.get("ammo", 0)

	func display_name() -> String:
		return character.name

	func is_out() -> bool:
		return dead or surrendered or character.has_condition(Conditions.UNCONSCIOUS)

	func is_hostile_to(other: Combatant) -> bool:
		return (side == "enemy") != (other.side == "enemy")


var combatants: Array[Combatant] = []
var order: Array[Combatant] = []
var round_number := 0
var turn_index := 0
var rng: RandomNumberGenerator
var skills_db: Dictionary
## "" tant que le combat continue ; "victory", "defeat" ou "ceasefire" ensuite.
var outcome := ""


func _init(skills: Dictionary, random: RandomNumberGenerator) -> void:
	skills_db = skills
	rng = random


func add(ch: CharacterData, side: String, weapon_def: Dictionary, armor_def: Dictionary) -> Combatant:
	var c := Combatant.new(ch, side, weapon_def, armor_def)
	combatants.append(c)
	return c


func _log(text: String) -> void:
	logged.emit(text)


# --- Jets ----------------------------------------------------------------------

## Score de base d'une compétence ; sans formation possible, la caractéristique liée (LdR §7 : COO pour le tir).
func skill_base(c: Combatant, skill_key: String) -> int:
	var def: Dictionary = skills_db.get(skill_key, {})
	if def.is_empty():
		return c.character.characteristic("coo")
	var score := c.character.skill_score(def)
	return score if score != RulesEngine.IMPOSSIBLE else ceili(c.character.characteristic(def["characteristic"]) / 2.0)


func _skill_test(c: Combatant, skill_key: String, difficulty: String = "normale", mods: Array[int] = []) -> Dictionary:
	var all_mods: Array[int] = mods.duplicate()
	var domain: String = skills_db.get(skill_key, {}).get("domain", "")
	all_mods.append_array(c.character.condition_modifiers(domain))
	var result := RulesEngine.test(skill_base(c, skill_key), difficulty, all_mods, rng)
	result["skill"] = skill_key
	return result


func _characteristic_test(c: Combatant, key: String) -> Dictionary:
	return RulesEngine.test(c.character.characteristic(key), "normale", c.character.condition_modifiers(), rng)


static func describe(result: Dictionary) -> String:
	var text := "jet %d sur %d : " % [result["roll"], result["target"]]
	if result["success"]:
		text += "réussite critique" if result["critical"] else "réussite"
		return text + ", %d DR" % result["degrees"]
	text += "échec critique" if result["critical"] else "échec"
	return text + ", %d DE" % result["degrees"]


# --- Initiative et tours -------------------------------------------------------

## Initiative glissante (LdR §7) : test de Vigilance ; réussites par DR décroissants (critique d'abord),
## puis échecs par DE croissants ; égalités départagées par la RÉF, puis le score de Vigilance.
func start() -> void:
	for c in combatants:
		c.initiative = _skill_test(c, "vigilance")
		c.initiative["vigilance"] = skill_base(c, "vigilance")
		_log("%s — initiative (Vigilance) : %s." % [c.display_name(), describe(c.initiative)])
	order = combatants.duplicate()
	order.sort_custom(initiative_before)
	round_number = 0
	_begin_round()


static func initiative_before(a: Combatant, b: Combatant) -> bool:
	var ia := a.initiative
	var ib := b.initiative
	if ia["success"] != ib["success"]:
		return ia["success"]
	if ia["degrees"] != ib["degrees"]:
		return ia["degrees"] > ib["degrees"] if ia["success"] else ia["degrees"] < ib["degrees"]
	if ia["success"] and ia["critical"] != ib["critical"]:
		return ia["critical"]
	var ra := a.character.characteristic("ref")
	var rb := b.character.characteristic("ref")
	if ra != rb:
		return ra > rb
	return ia.get("vigilance", 0) > ib.get("vigilance", 0)


func _begin_round() -> void:
	round_number += 1
	if round_number > 1:
		var kept: Array[Combatant] = []
		var pushed: Array[Combatant] = []
		for c in order:
			if c.pushed_back:
				pushed.append(c)
			else:
				kept.append(c)
			c.pushed_back = false
		kept.append_array(pushed)
		order = kept
		_apply_bleeding()
	for c in combatants:
		c.action_used = false
		c.move_used = false
		c.reaction_used = false
	turn_index = 0
	round_started.emit(round_number)
	_log("— Tour %d —" % round_number)
	_skip_out()


func _apply_bleeding() -> void:
	for c in combatants:
		if c.is_out() or not c.character.has_condition(Conditions.BLEEDING):
			continue
		_log("%s saigne : −1 Endurance." % c.display_name())
		if c.character.lose_endurance(1):
			_endurance_zero(c)


func _endurance_zero(c: Combatant) -> void:
	var con := _characteristic_test(c, "con")
	c.character.resolve_endurance_zero(con["success"])
	if con["success"]:
		_log("%s n'a plus d'Endurance ; test de CON (%s) : il tient, Épuisé." % [c.display_name(), describe(con)])
	else:
		_log("%s n'a plus d'Endurance ; test de CON (%s) : il perd connaissance." % [c.display_name(), describe(con)])
	_check_outcome()


func _skip_out() -> void:
	while outcome == "" and turn_index < order.size() and order[turn_index].is_out():
		turn_index += 1
	if outcome == "" and turn_index >= order.size():
		_begin_round()


func current() -> Combatant:
	if outcome != "" or order.is_empty():
		return null
	return order[turn_index]


## Termine le tour du personnage actif et passe au suivant.
func end_turn() -> void:
	var c := current()
	if c == null:
		return
	if c.character.has_condition(Conditions.STUNNED) and c.action_used:
		c.character.remove_condition(Conditions.STUNNED)
	turn_index += 1
	_skip_out()


## Au début de son tour, un personnage Sonné perd son action ; en rotation, il doit se stabiliser.
func begin_turn_constraints(c: Combatant) -> void:
	if c.character.has_condition(Conditions.STUNNED) and not c.action_used:
		c.action_used = true
		_log("%s est sonné : pas d'action ce tour." % c.display_name())


func opponents_of(c: Combatant) -> Array[Combatant]:
	var list: Array[Combatant] = []
	for o in combatants:
		if o != c and not o.is_out() and c.is_hostile_to(o):
			list.append(o)
	return list


func _check_outcome() -> void:
	if outcome != "":
		return
	var enemies_up := false
	var player_up := false
	for c in combatants:
		if c.is_out():
			continue
		if c.side == "enemy":
			enemies_up = true
		elif c.side == "player":
			player_up = true
	if not player_up:
		outcome = "defeat"
	elif not enemies_up:
		outcome = "victory"


# --- Attaque -------------------------------------------------------------------

## Zone touchée sans tir visé : chiffres du dé inversés (37 → 73, 10 → 01, 100 → 100).
static func location_from_roll(roll: int) -> String:
	var n := roll
	if roll < 100:
		n = (roll % 10) * 10 + floori(roll / 10.0)
		if n == 0:
			n = 100
	if n <= 10:
		return "head"
	if n <= 25:
		return "rightArm"
	if n <= 40:
		return "leftArm"
	if n <= 70:
		return "torso"
	if n <= 85:
		return "rightLeg"
	return "leftLeg"


## Malus aux attaques dû aux blessures des bras (légère −10, grave −20, critique : bras hors d'usage −20).
static func arm_penalty(ch: CharacterData) -> int:
	var worst := 0
	for injury in ch.injuries:
		if injury["location"] in ["rightArm", "leftArm"]:
			var p := -10 if injury["severity"] == "light" else -20
			worst = mini(worst, p)
	return worst


## Modificateurs d'une attaque, hors conditions (ajoutées par _skill_test).
func attack_modifiers(attacker: Combatant, target: Combatant, aimed_zone: String = "") -> Array[int]:
	var mods: Array[int] = []
	if attacker.aim > 0:
		mods.append(attacker.aim)
	if aimed_zone != "":
		mods.append(AIMED_PENALTIES[aimed_zone])
	if target.cover != 0:
		mods.append(target.cover)
	if target.character.position == Conditions.FLYING:
		mods.append(FLYING_TARGET_BONUS)
	var arms := arm_penalty(attacker.character)
	if arms != 0:
		mods.append(arms)
	return mods


## Score modifié affiché avant de tirer (chance de toucher, avant esquive).
func attack_chance(attacker: Combatant, target: Combatant, aimed_zone: String = "") -> int:
	var mods := attack_modifiers(attacker, target, aimed_zone)
	mods.append_array(attacker.character.condition_modifiers("combat"))
	return clampi(RulesEngine.modified_target(skill_base(attacker, attacker.weapon.get("skill", "")), "normale", mods), 0, 100)


func can_attack(c: Combatant) -> bool:
	return not c.action_used and not c.spinning and not c.disarmed and c.ammo > 0 and c.character.can_act()


func attack(attacker: Combatant, target: Combatant, aimed_zone: String = "") -> Dictionary:
	assert(can_attack(attacker), "Attaque impossible")
	attacker.action_used = true
	attacker.ammo -= 1
	var skill: String = attacker.weapon.get("skill", "")
	var result := _skill_test(attacker, skill, "normale", attack_modifiers(attacker, target, aimed_zone))
	attacker.aim = 0
	var zone_label: String = (" (tir visé : %s)" % ZONE_NAMES[aimed_zone]) if aimed_zone != "" else ""
	_log("%s tire sur %s%s : %s." % [attacker.display_name(), target.display_name(), zone_label, describe(result)])
	var report := {"result": result, "hit": false}
	if result["success"] and _dodged(target, result):
		report["dodged"] = true
	elif result["success"]:
		report = _hit(attacker, target, result, aimed_zone)
	_recoil(attacker)
	_check_outcome()
	return report


## Réaction automatique : test d'Esquive opposé à l'attaque (LdR §6).
func _dodged(target: Combatant, attack_result: Dictionary) -> bool:
	if target.reaction_used or not target.character.can_react():
		return false
	target.reaction_used = true
	var dodge := _skill_test(target, "esquive")
	var opposed := RulesEngine.opposed(attack_result, dodge)
	if opposed["winner"] == "a":
		_log("%s tente d'esquiver (%s) : touché." % [target.display_name(), describe(dodge)])
		return false
	_log("%s esquive (%s)." % [target.display_name(), describe(dodge)])
	return true


func _hit(attacker: Combatant, target: Combatant, result: Dictionary, aimed_zone: String) -> Dictionary:
	var zone := aimed_zone if aimed_zone != "" else location_from_roll(result["roll"])
	var visor := zone == "visor"
	if visor:
		zone = "head"
	var raw: int = attacker.weapon.get("damage", 0) + result["degrees"]
	var protection: int = target.armor.get("protection", {}).get(zone, 0)
	var breach_threshold: int = target.armor.get("breachThreshold", 0)
	if visor:
		protection = ceili(protection / 2.0)
		breach_threshold = ceili(breach_threshold / 2.0)
	var damage := raw - protection
	var report := {"result": result, "hit": true, "zone": zone, "raw": raw, "damage": damage, "severity": "", "breach": false}

	if target.armor.get("pressurized", false) and raw > breach_threshold and not target.character.has_condition(Conditions.SUIT_BREACHED):
		target.character.add_condition(Conditions.SUIT_BREACHED)
		report["breach"] = true

	var severity := target.character.wound_severity(damage)
	report["severity"] = severity
	var text := "Touché au %s : %d dégâts, %d après armure" % [ZONE_NAMES[zone], raw, maxi(damage, 0)]
	if severity == "":
		_log(text + " ; %s est secoué, sans blessure." % target.display_name())
	else:
		_log(text + " ; blessure %s." % SEVERITY_NAMES[severity])
		target.character.add_injury(zone, severity, attacker.weapon.get("name", ""))
		_wound_effects(target, zone, severity)
	if report["breach"]:
		_log("La combinaison de %s est percée !" % target.display_name())
	return report


## Effets d'une blessure (LdR §7). Blessure mortelle « mort immédiate ou en quelques tours, selon la zone » :
## tête ou torse = mort ; membre = inconscient et saignement (adaptation, ARCHITECTURE.md §7).
func _wound_effects(c: Combatant, zone: String, severity: String) -> void:
	if severity == "mortal":
		if zone in ["head", "torso"]:
			c.dead = true
			_log("%s est mortellement touché." % c.display_name())
		else:
			c.character.add_condition(Conditions.UNCONSCIOUS)
			c.character.add_condition(Conditions.BLEEDING)
			_log("%s s'effondre, la combinaison pleine de sang : sans soins, il ne passera pas l'heure." % c.display_name())
		return
	c.pushed_back = true
	if zone in ["rightArm", "leftArm"] and severity in ["serious", "critical"] and not c.disarmed:
		c.disarmed = true
		_log("%s lâche son arme, qui dérive dans le sas." % c.display_name())
	if severity == "serious":
		var vol := _characteristic_test(c, "vol")
		if not vol["success"]:
			c.character.add_condition(Conditions.STUNNED)
			_log("%s, sous le choc (VOL : %s), est sonné." % [c.display_name(), describe(vol)])
	elif severity == "critical":
		if zone == "head":
			c.character.add_condition(Conditions.UNCONSCIOUS)
			_log("%s perd connaissance." % c.display_name())
			return
		var con := _characteristic_test(c, "con")
		if not con["success"]:
			c.character.add_condition(Conditions.UNCONSCIOUS)
			_log("%s perd connaissance (CON : %s)." % [c.display_name(), describe(con)])


## Recul en apesanteur : un tireur non ancré teste Manœuvre en apesanteur, sinon il part en rotation.
func _recoil(c: Combatant) -> void:
	if not c.weapon.get("recoil", false) or c.character.position == Conditions.ANCHORED:
		return
	var test := _skill_test(c, "manoeuvre_apesanteur")
	if test["success"]:
		_log("%s encaisse le recul (Manœuvre en apesanteur : %s)." % [c.display_name(), describe(test)])
	else:
		c.spinning = true
		c.character.set_position(Conditions.FLOATING)
		_log("%s part en rotation sous le recul (Manœuvre en apesanteur : %s)." % [c.display_name(), describe(test)])


# --- Autres actions --------------------------------------------------------------

func can_reload(c: Combatant) -> bool:
	return not c.action_used and not c.spinning and not c.disarmed and c.ammo < c.weapon.get("ammo", 0) and c.character.can_act()


## Recharger : une action (LdR §7) ; les chargeurs de rechange ne sont pas comptés.
func reload(c: Combatant) -> void:
	c.action_used = true
	c.ammo = c.weapon.get("ammo", 0)
	_log("%s recharge." % c.display_name())


func can_aim(c: Combatant) -> bool:
	return not c.action_used and not c.spinning and not c.disarmed and c.aim < AIM_MAX and c.character.can_act()


func aim(c: Combatant) -> void:
	c.action_used = true
	c.aim = mini(AIM_MAX, c.aim + AIM_STEP)
	_log("%s vise (+%d)." % [c.display_name(), c.aim])


## Se stabiliser après une rotation : une action.
func stabilize(c: Combatant) -> void:
	c.action_used = true
	c.spinning = false
	_log("%s se stabilise." % c.display_name())


func can_move(c: Combatant) -> bool:
	return not c.move_used and not c.spinning and c.character.can_act()


func anchor(c: Combatant) -> void:
	c.move_used = true
	c.character.set_position(Conditions.ANCHORED)
	_log("%s s'ancre à une poignée." % c.display_name())


func take_cover(c: Combatant) -> void:
	c.move_used = true
	c.cover = COVER_PENALTY
	_log("%s se met à couvert derrière les caisses du sas (%d pour le toucher)." % [c.display_name(), COVER_PENALTY])


func can_patch(c: Combatant) -> bool:
	return not c.action_used and c.character.has_condition(Conditions.SUIT_BREACHED) and c.character.gear_count("rustine") > 0 and c.character.can_act()


## Rustine sous le feu : test de Survie (Normale) ; un échec ne la consomme pas (LdR §7).
func patch(c: Combatant) -> void:
	c.action_used = true
	var test := _skill_test(c, "survie")
	if test["success"]:
		c.character.use_gear("rustine")
		c.character.remove_condition(Conditions.SUIT_BREACHED)
		_log("%s colmate sa combinaison (Survie : %s)." % [c.display_name(), describe(test)])
	else:
		_log("%s rate sa rustine (Survie : %s)." % [c.display_name(), describe(test)])


func can_first_aid(c: Combatant) -> bool:
	return not c.action_used and c.character.has_condition(Conditions.BLEEDING) and c.character.can_act()


func first_aid(c: Combatant) -> void:
	c.action_used = true
	var test := _skill_test(c, "premiers_secours")
	if test["success"]:
		c.character.remove_condition(Conditions.BLEEDING)
		_log("%s arrête son saignement (Premiers secours : %s)." % [c.display_name(), describe(test)])
	else:
		_log("%s n'arrive pas à arrêter le saignement (Premiers secours : %s)." % [c.display_name(), describe(test)])


func can_call_ceasefire(c: Combatant) -> bool:
	return not c.action_used and c.character.can_act() and c.side == "player"


## Cessez-le-feu : Commandement Difficile ; +20 si chaque adversaire debout est gravement blessé.
func ceasefire_modifiers(c: Combatant) -> Array[int]:
	var all_hurt := true
	for o in opponents_of(c):
		var hurt := false
		for injury in o.character.injuries:
			if injury["severity"] != "light":
				hurt = true
		all_hurt = all_hurt and hurt
	var mods: Array[int] = []
	if all_hurt:
		mods.append(20)
	return mods


func call_ceasefire(c: Combatant) -> bool:
	c.action_used = true
	var test := _skill_test(c, "commandement", "difficile", ceasefire_modifiers(c))
	if test["success"]:
		_log("%s ordonne le cessez-le-feu (Commandement : %s). Les armes s'abaissent." % [c.display_name(), describe(test)])
		outcome = "ceasefire"
		return true
	_log("%s crie de cesser le feu (Commandement : %s). Personne n'écoute." % [c.display_name(), describe(test)])
	return false


# --- Personnages non joueurs -------------------------------------------------------

## Tour simple d'un PNJ : se stabiliser, s'ancrer ou se couvrir, puis tirer sur un adversaire.
func run_ai_turn(c: Combatant) -> void:
	begin_turn_constraints(c)
	if c.disarmed and c.side != "player":
		c.surrendered = true
		_log("%s, désarmé, lève les mains et se rend." % c.display_name())
		_check_outcome()
		end_turn()
		return
	if c.spinning and not c.action_used:
		stabilize(c)
	if can_move(c):
		if c.weapon.get("recoil", false) and c.character.position != Conditions.ANCHORED:
			anchor(c)
		elif c.cover == 0:
			take_cover(c)
	var targets := opponents_of(c)
	if outcome == "" and not targets.is_empty():
		var target: Combatant = targets[0]
		for t in targets:
			if t.side == "player":
				target = t
		if can_attack(c):
			attack(c, target)
		elif can_reload(c):
			reload(c)
		elif can_first_aid(c):
			first_aid(c)
	end_turn()
