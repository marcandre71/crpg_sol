extends TestCase
## Livre de règles v0.2, §4 à §6.


func test_score_de_competence() -> void:
	check_eq(RulesEngine.skill_score(55, 30), 85, "caractéristique + formation")
	check_eq(RulesEngine.skill_score(45, 0, true), 23, "(F) non formée : moitié arrondie au supérieur")
	check_eq(RulesEngine.skill_score(45, 0, true, false), RulesEngine.IMPOSSIBLE, "impossible sans formation")
	check_eq(RulesEngine.skill_score(45, 10, true, false), 55, "formée : score normal")


func test_difficultes() -> void:
	check_eq(RulesEngine.modified_target(50, "normale"), 50, "Normale = 0")
	check_eq(RulesEngine.modified_target(50, "delicate"), 40, "Délicate = -10")
	check_eq(RulesEngine.modified_target(50, "tres_facile", [10]), 90, "difficulté + situation")


func test_plafond_des_modificateurs() -> void:
	check_eq(RulesEngine.modified_target(50, "extreme", [-20]), 0, "total plafonné à -50")
	check_eq(RulesEngine.modified_target(50, "tres_facile", [30]), 100, "total plafonné à +50")


func test_oppose_un_seul_reussit() -> void:
	var r := RulesEngine.opposed(Dice.evaluate(30, 50), Dice.evaluate(70, 50))
	check_eq(r["winner"], "a", "seul A réussit")
	check_eq(r["margin"], 2, "marge = DR de A")


func test_oppose_par_dr_puis_score() -> void:
	var by_dr := RulesEngine.opposed(Dice.evaluate(30, 60), Dice.evaluate(50, 60))
	check_eq(by_dr["winner"], "a", "plus de DR")
	check_eq(by_dr["margin"], 2, "différence de DR")
	var by_score := RulesEngine.opposed(Dice.evaluate(41, 52), Dice.evaluate(42, 57))
	check_eq(by_score["winner"], "b", "DR égaux : le score le plus élevé gagne")
	var blocked := RulesEngine.opposed(Dice.evaluate(41, 52), Dice.evaluate(42, 52))
	check_eq(blocked["winner"], "none", "DR et scores égaux : bloqué")


func test_oppose_double_echec() -> void:
	var r := RulesEngine.opposed(Dice.evaluate(80, 40), Dice.evaluate(90, 40))
	check_eq(r["winner"], "none", "deux échecs : personne ne progresse")


func test_prolonge() -> void:
	# Réparer un recycleur : 8 DR, 30 minutes par test.
	var t := RulesEngine.ExtendedTest.new(8, 1800)
	t.add(Dice.evaluate(32, 65))  # 1 + 3 DR
	t.add(Dice.evaluate(70, 65))  # échec sans complication
	t.add(Dice.evaluate(98, 65))  # échec critique : complication
	check(not t.is_complete(), "4 DR sur 8")
	t.add(Dice.evaluate(21, 65))  # 1 + 4 DR
	check(t.is_complete(), "9 DR sur 8")
	check_eq(t.progress, 9, "réserve de progression")
	check_eq(t.complications, 1, "une complication")
	check_eq(t.elapsed_seconds(), 7200, "4 intervalles de 30 minutes")


func test_competences_du_livre() -> void:
	var data_db: GDScript = preload("res://Scripts/Autoload/data_db.gd")
	var skills: Dictionary = data_db.load_skills("res://Data/Rules/skills.json")
	check_eq(skills.size(), 38, "38 compétences")
	for key: String in skills:
		var s: Dictionary = skills[key]
		check(s["characteristic"] in ["for", "con", "coo", "ref", "ada", "per", "int", "vol", "pre"], "caractéristique de %s" % key)
