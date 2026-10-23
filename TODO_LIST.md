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
- [ ] *(Core)* `character_data.gd` : chargement JSON, valeurs dérivées (SB, TG, Endurance max, Sang-froid max), conditions.

## Jalon 2 — Contenu narratif

- [ ] *(Narrative)* Fiches des PNJ dans `Data/Characters/` : Lina (Mutuelle, blessée), Kael (Office de la Veille), Voronov (Kombinat Hélion). Pour chacun : caractéristiques, formations, équipement, ce qu'il sait du conteneur, ce qu'il veut, « le vice et la lueur » (Bible §9).
- [ ] *(Narrative)* Personnage joueur pré-tiré : Sauveteur du vide de la Mutuelle (origine, milieu, profession du LdR §9). 🔒 Créer un nouveau personnage, ou adapter Ilka Moravec (Fiche §2) ?
- [ ] *(Narrative)* Document de scénario `Data/Dialogues/README.md` : situation de départ, ce qui s'est passé à Thulé-7 pendant les 19 jours, contenu réel du conteneur, fins possibles. Respecter la Bible §12 (aucune réponse sur la nature de la Sereguine, aucun procédé d'arme biologique).
- [ ] *(Narrative)* Dialogues JSON (schéma `ARCHITECTURE.md` §6.2) : un fichier par PNJ, avec au moins une voie de désescalade complète.
- [ ] *(Narrative)* `Data/Items/` : pistolet frangible (6), carabine (10), pistolet à fléchettes, électrochoc, outils détournés ; combinaison souple, renforcée, armure de pont ; rustines ; kit d'outils (+10). Valeurs provisoires du LdR.

## Jalon 3 — Interface terminal

- [ ] *(UI)* Thème Godot rétro-futuriste (police monospace, ambre ou vert sur noir), dans `Scenes/UI/theme.tres`.
- [ ] *(UI)* `DialogueBox` : texte du PNJ, choix, étiquette de compétence et chance de réussite affichée (score modifié).
- [ ] *(UI)* Carte de résultat de test (dé, score, DR/DE, critique), équivalent de la « chat card » du LdR §15.
- [ ] *(UI)* `LifeSupportClock` : compte à rebours toujours visible.
- [ ] *(UI)* `CharacterSheet` réduite : caractéristiques, compétences utiles, Endurance, Sang-froid, blessures par zone, conditions.

## Jalon 4 — Environnement et ingénierie

- [ ] *(Core)* Horloge du support vital dans `GameState` : temps restant, tick par tour (5 s) et par action (`timeCost`).
- [ ] *(Core)* Effets du froid et de l'hypoxie (stades 1 à 3, −10 par stade ; perte d'Endurance), Épuisé à Endurance 0.
- [ ] *(Core)* Réparation du sas ou du support vital en test prolongé (ex. LdR : recycleur 8 DR, 30 min ; à ajuster pour la démo).
- [ ] *(Level)* Scène `Thule7_SasPrincipal` : points d'appui, couverts, panneau de réparation, conteneur cryogénique.

## Jalon 5 — Combat en apesanteur

- [ ] *(Core)* Initiative glissante (LdR §7) avec tous les départages et renvois en fin d'ordre.
- [ ] *(Core)* Attaque : compétence de l'arme, visée (+10 par action, max +30), tir visé, localisation par jet inversé, dégâts + DR − armure, gravité de blessure contre le SB.
- [ ] *(Core)* Brèche de combinaison : seuil de brèche, compte à rebours de 5 min puis 2 min, rustine (Survie sous le feu).
- [ ] *(Core)* Apesanteur : recul (test de Manœuvre en apesanteur si non ancré, −20 en rafale), Ancré / Flottant / En vol, lutte (moyenne FOR et ADA).
- [ ] *(UI)* `CombatHUD` : ordre d'initiative, action/mouvement/réaction restants, choix de zone visée.
- [ ] *(Level)* Comportement des PNJ en combat (simple : se mettre à couvert, tirer, se rendre).

## Jalon 6 — Démo jouable

- [ ] *(Level)* Enchaîner arrivée → dialogue → résolution (dialogue, ingénierie ou combat) → fin.
- [ ] *(Tous)* Partie test complète par chacune des trois voies ; noter les déséquilibres dans `COMMUNICATIONS.md`.
