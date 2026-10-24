# TODO_LIST — Sol, Nouvelle Ère (prototype cRPG Godot)

> Pour prendre une tâche : remplacez `[ ]` par `[~]`, ajoutez votre nom d'agent et la date, et annoncez-le dans `COMMUNICATIONS.md`. Une tâche terminée passe en `[x]` avec le lien du commit ou de la PR.
> Une tâche marquée **🔒 bloquée** attend une décision de Marc (voir `COMMUNICATIONS.md`).
> Structure et schémas de référence : `ARCHITECTURE.md`.

## Domaines

| Domaine | Dossiers | Agent assigné |
| --- | --- | --- |
| **Core Systems** | `Scripts/Core`, `Scripts/Combat`, `Scripts/Environment`, `Scripts/Autoload`, `Data/Rules`, `Tests/` | *libre* |
| **Narrative Design** | `Scripts/Dialogue`, `Data/Dialogues`, `Data/Characters`, `Data/Items` | *libre* |
| **Godot UI** | `Scenes/UI`, `Scripts/UI`, `Assets/Fonts` | *libre* |
| **Level & Intégration** | `Scenes/Main.tscn`, `Scenes/Levels`, `Scenes/Actors`, `project.godot`, `Assets/Sprites`, `Assets/Audio` | *libre* |

Légende : `[ ]` libre · `[~]` en cours · `[x]` fait.

---

## Jalon 0 — Socle du dépôt

- [x] Version de Godot : 4.7.2 stable (Marc, 23/10/2026).
- [ ] **Décisions à obtenir de Marc** 🔒 : GDScript seul, Points d'Action ou action/mouvement/réaction (voir `COMMUNICATIONS.md`, 23/10/2026). Choix par défaut en attendant : GDScript, action/mouvement/réaction.
- [x] *(Core, provisoirement pour Level)* Créer le projet Godot (`project.godot`), l'arborescence et le `.gitignore` (23/10/2026, branche `feat/socle-godot`).
- [x] *(Core)* Déclarer les autoloads `EventBus`, `GameState`, `DataDB`, `Rules` (23/10/2026).
- [x] *(Core)* Lanceur de tests sans dépendance et premiers tests qui passent (23/10/2026 ; remplace GUT).
- [x] *(Coordination)* Créer `ARCHITECTURE.md`, `TODO_LIST.md`, `COMMUNICATIONS.md` (23/10/2026).

## Jalon 1 — Moteur de règles (sans interface)

- [x] *(Core)* `dice.gd` : jet D100 (00 = 100), DR/DE par dizaines, critiques (plages fixes 01-05 / 96-100, puis doubles), complication à 3 DE ou plus, avec tests des cas limites (23/10/2026).
- [x] *(Core)* `rules.gd` : test simple avec difficulté + modificateurs plafonnés à ±50 ; compétence (F) non formée = ceil(caractéristique / 2) ; `untrainedAllowed = false` = test impossible (23/10/2026).
- [x] *(Core)* Test opposé (LdR §6) : un seul réussit ; sinon DR, puis score ; marge de victoire (23/10/2026).
- [x] *(Core)* Test prolongé : réserve de progression (1 + DR par réussite), objectif, intervalles, complications (23/10/2026).
- [x] *(Core)* `Data/Rules/skills.json` : les 38 compétences du LdR §4 (23/10/2026).
- [x] *(Core)* `character_data.gd` et `conditions.gd` : chargement et validation JSON, valeurs dérivées (SB, TG, Endurance max, Sang-froid max, bornes des blessures), Endurance et Sang-froid, hypoxie, position, conditions et leurs malus, blessures ; `Data/Rules/origins.json` ; `Rules.test_skill()` (23/10/2026).

## Jalon 2 — Contenu narratif

> Version provisoire jouable faite le 24/10/2026 (démo textuelle). Les ⚠ attendent une décision de Marc.

- [x] *(Narrative)* Fiches des PNJ dans `Data/Characters/` : Lina, Kael, Voronov (24/10/2026). ⚠ Lina = celle de la Bible §8 (décision n° 6).
- [x] *(Narrative)* Personnage joueur pré-tiré provisoire : Ezra Tal, sauveteur du vide de la Mutuelle (`ezra_tal.json`, création du LdR §9 ; profession « Sauveteur du vide » proposée) (24/10/2026). 🔒 À confirmer : garder Ezra ou adapter Ilka Moravec (décision n° 4).
- [x] *(Narrative)* Document de scénario `Data/Dialogues/README.md` (24/10/2026). ⚠ Contenu du conteneur provisoire (décision n° 5).
- [x] *(Narrative)* Dialogue JSON `thule7_sas.json` : 50 nœuds, voie de désescalade complète, 7 fins (24/10/2026). Un fichier par scène plutôt que par PNJ.
- [x] *(Narrative)* `Data/Items/items.json` : armes, combinaisons, rustines, kit d'outils (valeurs provisoires du LdR) (24/10/2026). Électrochoc non repris (pas utilisé dans la démo).
- [ ] *(Narrative)* Relecture du ton et des textes par Marc ; enrichir les répliques (Lina, Kael et Voronov ont chacun 3 à 6 répliques).

## Jalon 3 — Interface terminal

- [x] *(UI)* Thème rétro-futuriste ambre sur noir, police à chasse fixe (`Scripts/UI/terminal_theme.gd`, construit par code plutôt qu'en `.tres`) (24/10/2026).
- [x] *(UI)* Écran de jeu (`Scenes/UI/Game.tscn`) : journal façon terminal, choix numérotés (touches 1 à 9) avec compétence et chance de réussite, résultat de chaque jet (dé, score, DR/DE, critique), compte à rebours toujours visible, fiche réduite et état des PNJ (24/10/2026).
- [x] *(UI)* Écran titre (`Scenes/Main.tscn`) (24/10/2026).
- [ ] *(UI)* Habillage : police dédiée (`Assets/Fonts`), effet de balayage d'écran, sons d'interface.

## Jalon 4 — Environnement et ingénierie

- [x] *(Core)* Horloge du support vital (`Scripts/Environment/life_support.gd`) : 15 min, `timeCost` des choix, 5 s par tour de combat, alertes à 5, 2 et 1 min (24/10/2026).
- [x] *(Core)* Réparation du recycleur en test prolongé : 8 DR, 60 s par tentative, trois compétences au choix, complications (24/10/2026).
- [ ] *(Core)* Effets du froid et de l'hypoxie sur les personnages (le modèle les gère ; la démo ne les déclenche pas encore).
- [ ] *(Level)* Scène `Thule7_SasPrincipal` en 2D ou 3D : points d'appui, couverts, panneau de réparation, conteneur cryogénique.

## Jalon 5 — Combat en apesanteur

- [x] *(Core)* `Scripts/Combat/combat.gd` : initiative glissante (départages, renvois en fin d'ordre), attaque, visée, tir visé (torse, visière), esquive en réaction, localisation par jet inversé, dégâts + DR − armure, gravité contre le SB, effets des blessures, brèche de combinaison, rustine, recul hors ancrage, ancrage, couvert, recharge, premiers secours, cessez-le-feu, IA simple (24/10/2026).
- [x] *(UI)* Combat dans l'écran de jeu : ordre d'initiative, actions disponibles avec chances, état des combattants (24/10/2026).
- [ ] *(Core)* Compte à rebours de la brèche (5 min puis 2 min), En vol et élan, rafale, lutte (FOR + ADA) / 2.
- [ ] *(Core)* Équilibrage : un sauveteur seul contre la carabine de Voronov gagne environ 1 fois sur 10 en simulation (IA contre IA). Voulu (« le combat doit faire peur ») ou à adoucir ?

## Jalon 6 — Démo jouable

- [x] *(Level)* Enchaîner arrivée → dialogue → résolution (dialogue, ingénierie ou combat) → fin (24/10/2026).
- [x] *(Tous)* Parties automatiques dans la vraie interface (`Tests/play_demo.gd`) : aucune partie bloquée (24/10/2026).
- [ ] *(Marc)* Partie test complète par chacune des trois voies ; noter les déséquilibres dans `COMMUNICATIONS.md`.
