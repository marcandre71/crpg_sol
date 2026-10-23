extends TestCase
## Livre de règles v0.2, §2.


func test_exemple_du_livre() -> void:
	# Lina, Systèmes de survie 55, lance 38 : réussite, 2 DR.
	var r := Dice.evaluate(38, 55)
	check(r["success"], "38 sous 55 réussit")
	check_eq(r["degrees"], 2, "DR de 38 contre 55")
	check(not r["critical"], "38 n'est pas critique")


func test_reussite_de_justesse() -> void:
	var r := Dice.evaluate(52, 55)
	check(r["success"], "52 sous 55 réussit")
	check_eq(r["degrees"], 0, "même dizaine = 0 DR")


func test_plages_fixes() -> void:
	for roll in range(1, 6):
		var r := Dice.evaluate(roll, 0)
		check(r["success"] and r["critical"], "%d est toujours une réussite critique" % roll)
	for roll in range(96, 101):
		var r := Dice.evaluate(roll, 150)
		check(not r["success"] and r["critical"], "%d est toujours un échec critique" % roll)


func test_99_echoue_meme_avec_score_99() -> void:
	var r := Dice.evaluate(99, 99)
	check(not r["success"] and r["critical"], "99 prime sur le double")


func test_00_vaut_100() -> void:
	var r := Dice.evaluate(100, 50)
	check_eq(r["degrees"], 5, "dizaine de 100 = 10, DE = 10 - 5")
	check(r["complication"], "échec critique = complication")


func test_doubles() -> void:
	var under := Dice.evaluate(44, 44)
	check(under["success"] and under["critical"], "double égal au score = réussite critique")
	var over := Dice.evaluate(55, 44)
	check(not over["success"] and over["critical"], "double au-dessus = échec critique")
	check(over["complication"], "échec critique = complication")


func test_complication_a_3_de() -> void:
	check(not Dice.evaluate(57, 35)["complication"], "2 DE : pas de complication")
	check(Dice.evaluate(67, 35)["complication"], "3 DE : complication")


func test_degres_jamais_negatifs() -> void:
	var r := Dice.evaluate(58, 52)
	check(not r["success"], "58 au-dessus de 52 échoue")
	check_eq(r["degrees"], 0, "même dizaine en échec = 0 DE")


func test_score_negatif() -> void:
	var r := Dice.evaluate(40, -10)
	check(not r["success"], "score négatif : échec hors 01-05")
	check_eq(r["degrees"], 5, "DE contre un score de -10 (dizaine -1)")


func test_tirage_dans_les_bornes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 1000:
		var roll := Dice.roll_d100(rng)
		check(roll >= 1 and roll <= 100, "jet hors bornes : %d" % roll)
