extends TestCase
## Fiche de personnage v0.2, §3 (valeurs dérivées), et LdR v0.2, §3, §7 et §11 (conditions).

const SKILLS_PATH := "res://Data/Rules/skills.json"
const ORIGINS_PATH := "res://Data/Rules/origins.json"
const ILKA_PATH := "res://Tests/Fixtures/ilka_moravec.json"

var data_db: GDScript = preload("res://Scripts/Autoload/data_db.gd")


func _ilka() -> CharacterData:
	return CharacterData.from_dict(data_db.read_json(ILKA_PATH), data_db.load_keyed(ORIGINS_PATH, "origins"))


func _skill(key: String) -> Dictionary:
	return data_db.load_skills(SKILLS_PATH)[key]


func test_fiche_valide() -> void:
	var errors := CharacterData.validate(data_db.read_json(ILKA_PATH),
		data_db.load_skills(SKILLS_PATH), data_db.load_keyed(ORIGINS_PATH, "origins"))
	check_eq(errors.size(), 0, "fiche d'Ilka valide : %s" % ", ".join(errors))


func test_fiche_invalide() -> void:
	var errors := CharacterData.validate(
		{"id": "x", "characteristics": {"for": 0, "chance": 50}, "skills": {"inconnue": 70}, "conditions": ["dort"]},
		data_db.load_skills(SKILLS_PATH))
	check(errors.size() >= 5, "caractéristiques manquantes ou hors bornes, compétence et condition inconnues (%d erreurs)" % errors.size())


func test_valeurs_derivees_d_ilka() -> void:
	var ilka := _ilka()
	check_eq(ilka.wound_threshold(), 3, "SB = (25 + 35) / 20")
	check_eq(ilka.g_tolerance(), 0, "TG = 2 - 2 (Ceinture)")
	check_eq(ilka.endurance_max(), 7, "Endurance = 35 / 5")
	check_eq(ilka.sang_froid_max(), 8, "Sang-froid = 36 / 5, arrondi au supérieur")
	check_eq(ilka.endurance, 7, "Endurance pleine au départ")
	check_eq(ilka.sang_froid, 8, "Sang-froid plein au départ")


func test_plancher_de_tg() -> void:
	var ilka := _ilka()
	ilka.characteristics["con"] = 15
	check_eq(ilka.g_tolerance(), 0, "TG jamais négative")


func test_scores_de_competences() -> void:
	var ilka := _ilka()
	check_eq(ilka.skill_score(_skill("mecanique")), 85, "Mécanique 55 + 30")
	check_eq(ilka.skill_score(_skill("sortie_extravehiculaire")), 80, "Sortie extravéhiculaire 60 + 20")
	check_eq(ilka.skill_score(_skill("pilotage")), 23, "Pilotage (F) non formé : 45 / 2")
	check_eq(ilka.skill_score(_skill("intimidation")), 36, "Intimidation : VOL sans formation")


func test_gravite_des_blessures() -> void:
	var ilka := _ilka()  # SB 3 : légère 1-2, grave 3-5, critique 6-8, mortelle 9+
	check_eq(ilka.wound_severity(0), "", "0 après armure : secoué")
	check_eq(ilka.wound_severity(2), "light", "2 : légère")
	check_eq(ilka.wound_severity(3), "serious", "3 : grave")
	check_eq(ilka.wound_severity(8), "critical", "8 : critique")
	check_eq(ilka.wound_severity(9), "mortal", "9 : mortelle")


func test_exemple_du_mineur() -> void:
	# LdR §7 : FOR 30, CON 40 → SB 4 ; 9 dégâts après armure = critique.
	var ilka := _ilka()
	ilka.characteristics["for"] = 30
	ilka.characteristics["con"] = 40
	check_eq(ilka.wound_threshold(), 4, "SB 3,5 arrondi à 4")
	check_eq(ilka.wound_severity(9), "critical", "9 entre 8 et 11")


func test_blessure_grave_fait_saigner() -> void:
	var ilka := _ilka()
	ilka.add_injury("rightArm", "light")
	check(not ilka.has_condition(Conditions.BLEEDING), "légère : pas de saignement")
	ilka.add_injury("torso", "serious", "carabine")
	check(ilka.has_condition(Conditions.BLEEDING), "grave : saignement")
	check_eq(ilka.injuries.size(), 2, "deux blessures")


func test_endurance_a_zero() -> void:
	var ilka := _ilka()
	check(not ilka.lose_endurance(3), "7 → 4 : pas de test")
	check(ilka.lose_endurance(10), "4 → 0 : test de CON")
	check_eq(ilka.endurance, 0, "jamais sous 0")
	check(not ilka.lose_endurance(1), "déjà à 0 : pas de nouveau test")
	ilka.resolve_endurance_zero(true)
	check(ilka.has_condition(Conditions.EXHAUSTED), "test réussi : Épuisé")
	var other := _ilka()
	other.lose_endurance(7)
	other.resolve_endurance_zero(false)
	check(other.has_condition(Conditions.UNCONSCIOUS), "test raté : Inconscient")
	check(not other.can_act() and not other.can_react(), "inconscient : ni action ni réaction")


func test_sang_froid_a_zero() -> void:
	var ilka := _ilka()
	ilka.lose_sang_froid(5)
	check(not ilka.has_condition(Conditions.SHOCKED), "3 restants : pas Choqué")
	ilka.lose_sang_froid(5)
	check(ilka.has_condition(Conditions.SHOCKED), "0 : Choqué")
	ilka.recover_sang_froid(20)
	check_eq(ilka.sang_froid, 8, "récupération plafonnée au max")


func test_modificateurs_des_conditions() -> void:
	var ilka := _ilka()
	check_eq(ilka.condition_modifiers("technique"), [] as Array[int], "aucune condition")
	ilka.set_hypoxia(2)
	ilka.add_condition(Conditions.EXHAUSTED)
	ilka.add_condition(Conditions.SHOCKED)
	check_eq(ilka.condition_modifiers("technique"), [-20, -20, -20] as Array[int], "hypoxie 2, Épuisé, Choqué (technique)")
	check_eq(ilka.condition_modifiers("combat"), [-20, -20] as Array[int], "Choqué ne touche pas le combat")
	var target := RulesEngine.modified_target(85, "delicate", ilka.condition_modifiers("technique"))
	check_eq(target, 35, "85 - 10 - 60 : plafond de -50 atteint")


func test_hypoxie_stade_3() -> void:
	var ilka := _ilka()
	ilka.set_hypoxia(5)
	check_eq(ilka.hypoxia, 3, "stade plafonné à 3")
	check(ilka.has_condition(Conditions.UNCONSCIOUS), "stade 3 : inconscience")


func test_sonne() -> void:
	var ilka := _ilka()
	ilka.add_condition(Conditions.STUNNED)
	check(not ilka.can_act(), "sonné : pas d'action")
	check(ilka.can_react(), "sonné : réaction possible")


func test_position_et_signaux() -> void:
	var ilka := _ilka()
	var events: Array = []
	ilka.condition_changed.connect(func(c: String, active: bool) -> void: events.append([c, active]))
	ilka.set_position(Conditions.FLYING)
	check_eq(ilka.position, Conditions.FLYING, "en vol")
	check_eq(events, [[Conditions.ANCHORED, false], [Conditions.FLYING, true]], "signaux de position")
	ilka.add_condition(Conditions.STUNNED)
	ilka.add_condition(Conditions.STUNNED)
	check_eq(events.size(), 3, "pas de signal en double")


func test_sauvegarde_aller_retour() -> void:
	var ilka := _ilka()
	ilka.lose_endurance(2)
	ilka.set_hypoxia(1)
	ilka.add_injury("head", "light")
	var copy := CharacterData.from_dict(ilka.to_dict(), data_db.load_keyed(ORIGINS_PATH, "origins"))
	check_eq(copy.to_dict(), ilka.to_dict(), "to_dict puis from_dict redonne le même état")
	check_eq(copy.endurance, 5, "Endurance courante conservée")
	check_eq(copy.g_tolerance(), 0, "origine conservée")
