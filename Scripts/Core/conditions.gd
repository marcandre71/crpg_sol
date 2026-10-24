class_name Conditions
extends RefCounted
## Conditions (états) du Livre de règles v0.2, §11, et leurs effets sur les jets.
## Identifiants repris de la Fiche de personnage v0.2, §4, en snake_case.

const ANCHORED := "anchored"
const FLOATING := "floating"
const FLYING := "flying"
const EXPOSED := "exposed"
const IRRADIATED := "irradiated"
const DOOMED := "doomed"
const BLEEDING := "bleeding"
const STUNNED := "stunned"
const UNCONSCIOUS := "unconscious"
const UNDER_G := "under_g"
const SUIT_BREACHED := "suit_breached"
const EXHAUSTED := "exhausted"
const SHOCKED := "shocked"

## L'hypoxie est une jauge (0 à 3) portée par le personnage, pas une condition de la liste.
const HYPOXIA_PENALTY_PER_STAGE := -10
const HYPOXIA_UNCONSCIOUS_STAGE := 3

## Position en apesanteur : exactement une des trois à la fois.
const POSITIONS: Array[String] = [ANCHORED, FLOATING, FLYING]

const ALL: Array[String] = [
	EXPOSED, IRRADIATED, DOOMED, BLEEDING, STUNNED, UNCONSCIOUS,
	UNDER_G, SUIT_BREACHED, EXHAUSTED, SHOCKED,
]

## Libellés français (Glossaire v0.2).
const NAMES := {
	ANCHORED: "Ancré", FLOATING: "Flottant", FLYING: "En vol", EXPOSED: "Exposé", IRRADIATED: "Irradié",
	DOOMED: "Condamné", BLEEDING: "Saignement", STUNNED: "Sonné", UNCONSCIOUS: "Inconscient",
	UNDER_G: "Sous accélération", SUIT_BREACHED: "Combinaison percée", EXHAUSTED: "Épuisé", SHOCKED: "Choqué",
}

const EXHAUSTED_PENALTY := -20
const SHOCKED_PENALTY := -20
## Choqué : « -20 aux actions sociales et techniques » (LdR §11), lu comme ces domaines de compétences.
const SHOCKED_DOMAINS: Array[String] = ["relations", "technique"]


static func is_valid(condition_id: String) -> bool:
	return condition_id in ALL


## Modificateurs dus aux conditions pour un test d'une compétence du domaine donné
## (domaine vide = test de caractéristique). Ils entrent dans le plafond de ±50 (LdR §5).
static func test_modifiers(conditions: Array[String], hypoxia: int, skill_domain: String = "") -> Array[int]:
	var mods: Array[int] = []
	if hypoxia > 0:
		mods.append(HYPOXIA_PENALTY_PER_STAGE * mini(hypoxia, HYPOXIA_UNCONSCIOUS_STAGE))
	if EXHAUSTED in conditions:
		mods.append(EXHAUSTED_PENALTY)
	if SHOCKED in conditions and skill_domain in SHOCKED_DOMAINS:
		mods.append(SHOCKED_PENALTY)
	return mods


## Sonné : pas d'action ce tour, réaction possible. Inconscient : rien.
static func can_act(conditions: Array[String]) -> bool:
	return not (STUNNED in conditions or UNCONSCIOUS in conditions)


static func can_react(conditions: Array[String]) -> bool:
	return not (UNCONSCIOUS in conditions)
