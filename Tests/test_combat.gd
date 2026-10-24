extends TestCase
## Livre de règles v0.2, §7 : localisation, dégâts, armure, brèches, initiative, recul.

var data_db: GDScript = preload("res://Scripts/Autoload/data_db.gd")
var skills: Dictionary = data_db.load_skills("res://Data/Rules/skills.json")
var items: Dictionary = data_db.load_keyed("res://Data/Items/items.json", "items")
var origins: Dictionary = data_db.load_keyed("res://Data/Rules/origins.json", "origins")


func _char(id: String) -> CharacterData:
	return CharacterData.from_dict(data_db.read_json("res://Data/Characters/%s.json" % id), origins)


func _engine(seed_value: int = 1) -> CombatEngine:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return CombatEngine.new(skills, rng)


func _fighters(engine: CombatEngine) -> Array:
	var ezra := engine.add(_char("ezra_tal"), "player", items["pistolet_a_flechettes"], items["combinaison_souple"])
	var voronov := engine.add(_char("voronov"), "enemy", items["carabine"], items["combinaison_renforcee"])
	return [ezra, voronov]


func test_localisation_par_jet_inverse() -> void:
	check_eq(CombatEngine.location_from_roll(37), "rightLeg", "37 → 73 : jambe droite")
	check_eq(CombatEngine.location_from_roll(10), "head", "10 → 01 : tête")
	check_eq(CombatEngine.location_from_roll(1), "head", "01 → 10 : tête")
	check_eq(CombatEngine.location_from_roll(100), "leftLeg", "00 : jambe gauche")
	check_eq(CombatEngine.location_from_roll(52), "rightArm", "52 → 25 : bras droit")
	check_eq(CombatEngine.location_from_roll(14), "torso", "14 → 41 : torse")


func test_exemple_du_mineur() -> void:
	# LdR §7 : carabine (10) + 2 DR au torse, combinaison renforcée (3), SB 4 → 9, critique ; brèche (12 > 8).
	var engine := _engine()
	var f := _fighters(engine)
	var target: CombatEngine.Combatant = f[1]
	target.character.characteristics["for"] = 30
	target.character.characteristics["con"] = 40
	var shooter := engine.add(_char("voronov"), "player", items["carabine"], items["combinaison_renforcee"])
	var report := engine._hit(shooter, target, {"roll": 41, "degrees": 2, "success": true, "critical": false}, "torso")
	check_eq(report["raw"], 12, "10 + 2 DR")
	check_eq(report["damage"], 9, "12 − 3")
	check_eq(report["severity"], "critical", "9 entre 8 et 11")
	check(report["breach"], "12 dépasse le seuil de brèche 8")
	check(target.character.has_condition(Conditions.SUIT_BREACHED), "combinaison percée")


func test_secoue_sans_blessure() -> void:
	var engine := _engine()
	var f := _fighters(engine)
	var report := engine._hit(f[0], f[1], {"roll": 41, "degrees": 0, "success": true, "critical": false}, "torso")
	check_eq(report["damage"], 1, "fléchettes 4 − 3")
	check_eq(report["severity"], "light", "1 < SB 5 : légère")
	report = engine._hit(f[0], f[1], {"roll": 41, "degrees": 0, "success": true, "critical": false}, "rightArm")
	check_eq(report["damage"], 2, "4 − 2 au bras")
	var weak := engine.add(_char("kael"), "enemy", items["pistolet_frangible"], items["armure_de_pont"])
	report = engine._hit(f[0], weak, {"roll": 41, "degrees": 0, "success": true, "critical": false}, "torso")
	check_eq(report["severity"], "", "4 − 6 : secoué")
	check(not report["breach"], "4 ne dépasse pas 12")


func test_coup_a_la_visiere() -> void:
	# Renforcée : tête 3 → 2 ; seuil 8 → 4. Pistolet frangible 6 + 0 DR : 4 dégâts, brèche (6 > 4).
	var engine := _engine()
	var f := _fighters(engine)
	var kael := engine.add(_char("kael"), "player", items["pistolet_frangible"], items["combinaison_souple"])
	var report := engine._hit(kael, f[1], {"roll": 30, "degrees": 0, "success": true, "critical": false}, "visor")
	check_eq(report["zone"], "head", "la visière est la tête")
	check_eq(report["damage"], 4, "6 − ceil(3 / 2)")
	check(report["breach"], "6 > ceil(8 / 2)")


func test_blessure_mortelle() -> void:
	var engine := _engine()
	var f := _fighters(engine)
	var ezra: CombatEngine.Combatant = f[0]
	engine._hit(f[1], ezra, {"roll": 41, "degrees": 5, "success": true, "critical": false}, "torso")
	check(ezra.dead, "15 − 1 = 14 ≥ 3 × SB 4 : mortelle")
	engine._check_outcome()
	check_eq(engine.outcome, "defeat", "joueur hors de combat : défaite")
	var other := _engine()
	var g := _fighters(other)
	var ezra2: CombatEngine.Combatant = g[0]
	other._hit(g[1], ezra2, {"roll": 41, "degrees": 5, "success": true, "critical": false}, "leftArm")
	check(not ezra2.dead, "mortelle à un membre : pas de mort immédiate")
	check(ezra2.character.has_condition(Conditions.UNCONSCIOUS), "mais inconscient")
	check(ezra2.character.has_condition(Conditions.BLEEDING), "et en train de saigner")


func test_bras_gravement_blesse_lache_l_arme() -> void:
	var engine := _engine()
	var f := _fighters(engine)
	var ezra: CombatEngine.Combatant = f[0]
	engine._hit(f[1], ezra, {"roll": 41, "degrees": 0, "success": true, "critical": false}, "rightArm")
	check(ezra.disarmed, "10 − 1 = 9 ≥ 2 × SB : critique au bras, arme lâchée")
	check(not engine.can_attack(ezra), "désarmé : plus d'attaque")
	check(ezra.pushed_back, "renvoyé en fin d'ordre")


func test_ordre_d_initiative() -> void:
	var engine := _engine()
	var f := _fighters(engine)
	var a: CombatEngine.Combatant = f[0]
	var b: CombatEngine.Combatant = f[1]
	a.initiative = {"success": true, "degrees": 2, "critical": false, "vigilance": 50}
	b.initiative = {"success": true, "degrees": 3, "critical": false, "vigilance": 55}
	check(CombatEngine.initiative_before(b, a), "plus de DR d'abord")
	b.initiative = {"success": false, "degrees": 0, "critical": false, "vigilance": 55}
	check(CombatEngine.initiative_before(a, b), "réussite avant échec")
	a.initiative = {"success": false, "degrees": 2, "critical": false, "vigilance": 50}
	check(CombatEngine.initiative_before(b, a), "échecs : moins de DE d'abord")
	a.initiative = {"success": true, "degrees": 2, "critical": true, "vigilance": 50}
	b.initiative = {"success": true, "degrees": 2, "critical": false, "vigilance": 55}
	check(CombatEngine.initiative_before(a, b), "à DR égal, la critique passe devant")


func test_recul_hors_ancrage() -> void:
	var spins := 0
	for seed_value in 40:
		var engine := _engine(seed_value)
		var f := _fighters(engine)
		var voronov: CombatEngine.Combatant = f[1]
		voronov.character.set_position(Conditions.FLOATING)
		engine._recoil(voronov)
		if voronov.spinning:
			spins += 1
			check(not engine.can_attack(voronov), "en rotation : pas d'attaque avant de se stabiliser")
	check(spins > 0 and spins < 40, "Manœuvre 50 : rotation parfois (%d sur 40)" % spins)
	var anchored := _fighters(_engine())[1] as CombatEngine.Combatant
	check(not anchored.spinning, "ancré : pas de test de recul")


func test_combat_complet_se_termine() -> void:
	# Combats automatiques : ils doivent tous finir, sans erreur, avec une issue.
	for seed_value in 30:
		var engine := _engine(seed_value)
		var f := _fighters(engine)
		engine.add(_char("kael"), "ally", items["pistolet_frangible"], items["combinaison_renforcee"])
		engine.start()
		var guard := 0
		while engine.outcome == "" and guard < 500:
			engine.run_ai_turn(engine.current())
			guard += 1
		check(engine.outcome in ["victory", "defeat"], "combat %d terminé (%s, %d tours de PNJ)" % [seed_value, engine.outcome, guard])
