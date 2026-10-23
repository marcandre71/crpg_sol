class_name Dice
extends RefCounted
## Jet D100 du Livre de règles v0.2, §2.
##
## Règles appliquées :
## - 1D100 de 1 à 100 (le 00 vaut 100) ; réussite si le dé est inférieur ou égal au score.
## - 01 à 05 : toujours réussite critique ; 96 à 100 : toujours échec critique.
## - Entre 06 et 95, un double (11, 22… 88) est critique : réussite s'il est sous le score, échec sinon.
## - DR = dizaine du score − dizaine du dé ; DE = dizaine du dé − dizaine du score ; jamais sous 0.
## - Complication : échec à 3 DE ou plus, ou échec critique.

const AUTO_SUCCESS_MAX := 5
const AUTO_FAILURE_MIN := 96
const COMPLICATION_DEGREES := 3


static func roll_d100(rng: RandomNumberGenerator) -> int:
	return rng.randi_range(1, 100)


## Dizaine d'un nombre : partie entière de n / 10 (100 → 10, 38 → 3).
## Pour un score négatif (modificateurs très lourds), on prend la partie entière inférieure.
static func tens(n: int) -> int:
	return floori(n / 10.0)


static func is_double(roll: int) -> bool:
	return roll >= 11 and roll <= 99 and roll % 11 == 0


## Résultat d'un jet déjà lancé contre un score modifié. Contrat : ARCHITECTURE.md §5.
static func evaluate(roll: int, target: int) -> Dictionary:
	var success: bool
	var critical: bool
	if roll <= AUTO_SUCCESS_MAX:
		success = true
		critical = true
	elif roll >= AUTO_FAILURE_MIN:
		success = false
		critical = true
	else:
		success = roll <= target
		critical = is_double(roll)

	var degrees: int
	if success:
		degrees = maxi(0, tens(target) - tens(roll))
	else:
		degrees = maxi(0, tens(roll) - tens(target))

	return {
		"roll": roll,
		"target": target,
		"success": success,
		"degrees": degrees,
		"critical": critical,
		"complication": not success and (critical or degrees >= COMPLICATION_DEGREES),
	}
