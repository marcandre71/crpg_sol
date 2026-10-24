# ARCHITECTURE — Sol, Nouvelle Ère (prototype cRPG Godot)

> **Statut : proposition v0.1 du 23/10/2026, à valider par Marc.**
> Ce fichier est la référence technique du dépôt. Toute modification de structure (nouveau dossier, nouvel autoload, changement de schéma de données) se propose d'abord dans `COMMUNICATIONS.md`, puis se reporte ici une fois acceptée.
> ⚠ = point à valider (repris dans `COMMUNICATIONS.md`).

## 1. Sources de vérité

Le dépôt adapte au jeu vidéo un univers et des règles conçus pour le jeu de rôle sur table (FoundryVTT). Les documents de conception sont sur le Google Drive de Marc :

| Document | Version | Ce qu'on y prend pour la démo |
| --- | --- | --- |
| Bible de l'univers | v0.4 | Ton, factions (§6), technologie (§7), règles de cohérence (§12), accroche « Le silence de Thulé-7 » (§11), « La cargaison froide » (§10) |
| Livre de règles (LdR) | v0.2 | Jet D100, DR/DE, critiques (§2), compétences (§4), difficultés (§5), tests opposés et prolongés (§6), combat (§7), dangers (§8), conditions (§11) |
| Fiche de personnage | v0.2 | Modèle de données du personnage et noms de champs en anglais (§4) |
| Glossaire | v0.2 | Vocabulaire officiel : on reprend ses termes dans l'interface et dans les données |
| Règles des vaisseaux | v0.1 | Hors démo (pas de combat spatial dans Thulé-7) |

**Règle :** les documents du Drive priment sur ce dépôt pour l'univers et les règles. Si le code s'en écarte (adaptation au jeu vidéo), l'écart est noté dans la section 7 ci-dessous.

## 2. Périmètre de la démo « L'Impasse de l'Habitat Thulé-7 »

Un seul lieu, le sas principal de Thulé-7, en micropesanteur, avec un compte à rebours de support vital. Trois résolutions possibles, qui doivent toutes rester jouables jusqu'au bout :

1. **Dialogue** : arbres de choix avec tests de compétence (Persuasion, Négociation, Intimidation, Tromperie, Psychologie, Commandement).
2. **Ingénierie** : réparer le sas ou le support vital par un test prolongé (Systèmes de survie, Mécanique, Électronique), sous l'horloge.
3. **Combat tactique** : au tour par tour, en apesanteur (recul, ancrage, couvert en 3D, localisation, blessures, brèches de combinaison).

Personnages : le joueur (Sauveteur du vide de la Mutuelle) ; Lina (Mutuelle, blessée) ; Kael (Office de la Veille) ; Voronov (Kombinat Hélion). Objet clé : un conteneur cryogénique d'échantillons biologiques illégaux.

**Sous-ensemble des règles retenu pour la démo :** D100 et DR/DE, critiques, difficultés, tests opposés, tests prolongés, initiative glissante, actions (action, mouvement, réaction), localisation, dégâts/armure/SB, brèche de combinaison et rustine, recul et ancrage, hypoxie, froid, Endurance, Sang-froid, conditions. **Hors démo :** création de personnage, progression XP, radiations au-delà d'un affichage, vaisseaux, gravité de longue durée.

## 3. Stack

- **Moteur :** Godot **4.7.2 stable** (décision de Marc, 23/10/2026), rendu Compatibilité (suffisant pour une interface terminal).
- **Langage :** GDScript uniquement ⚠. Le README autorise le C#, mais il impose la version .NET de Godot et complique le mélange des deux langages ; on propose de s'en tenir à GDScript tant que le prototype est petit.
- **Données :** JSON pour tout ce qui est écrit par l'agent Narrative (dialogues, PNJ, objets), ressources `.tres` seulement pour ce qui est réglé dans l'éditeur (thèmes UI, scènes).
- **Tests :** lanceur maison sans dépendance (`Tests/run_tests.gd`) pour le moteur de règles, qui doit être testé sans lancer de scène. Chaque fichier `Tests/test_*.gd` étend `TestCase` et définit des méthodes `test_*`. Lancement :
  ```
  Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://Tests/run_tests.gd
  ```
  Code de sortie 0 si tout passe, 1 sinon.
  Test d'intégration de l'interface : `Tests/play_demo.gd` joue des parties complètes dans la vraie scène en cliquant au hasard et échoue si une partie reste bloquée (`-s res://Tests/play_demo.gd -- 40` pour 40 parties).
- **UI :** rétro-futuriste, terminal, texte ambre ou vert sur fond noir.

## 4. Arborescence

```
/
├── project.godot
├── README.md · ARCHITECTURE.md · TODO_LIST.md · COMMUNICATIONS.md
├── Scenes/
│   ├── Main.tscn                     # point d'entrée : écran titre (Scripts/UI/title_screen.gd)
│   └── UI/Game.tscn                  # écran de jeu de la démo (Scripts/UI/game_screen.gd)
├── Scripts/
│   ├── Core/        # domaine Core Systems : règles pures, sans nœud de scène
│   │   ├── dice.gd                   # D100, DR/DE, critiques
│   │   ├── rules.gd                  # tests simples, opposés, prolongés ; modificateurs
│   │   ├── character_data.gd         # modèle du personnage (cf. Fiche §4)
│   │   └── conditions.gd             # conditions du LdR §11 et leurs malus
│   ├── Combat/combat.gd              # CombatEngine : initiative, actions, esquive, localisation, dégâts, recul, IA
│   ├── Environment/life_support.gd   # LifeSupportClock : compte à rebours du support vital
│   ├── Dialogue/dialogue_runner.gd   # DialogueRunner : lecture et validation des dialogues JSON
│   ├── Autoload/    # singletons (section 5)
│   └── UI/          # terminal_theme.gd (thème ambre), title_screen.gd, game_screen.gd
├── Data/
│   ├── Dialogues/   # un fichier JSON par scène (section 6.2) ; README.md = document de scénario
│   ├── Characters/  # joueur pré-tiré et PNJ (section 6.1)
│   ├── Items/items.json              # armes, armures, équipement (valeurs provisoires du LdR)
│   └── Rules/       # skills.json, origins.json
└── Tests/           # test_*.gd (lanceur maison), play_demo.gd (parties automatiques), Fixtures/
```

Prévu plus tard : `Scenes/Levels/` (sas en 2D ou 3D), `Scenes/Actors/`, `Assets/`. La démo actuelle est entièrement textuelle : l'interface est construite par code dans `game_screen.gd`, sans scènes d'UI séparées.

Chaque dossier appartient à un domaine (voir `TODO_LIST.md`, section « Domaines »). On ne modifie pas un dossier d'un autre domaine sans l'annoncer dans `COMMUNICATIONS.md`.

## 5. Autoloads (singletons)

| Autoload | Rôle |
| --- | --- |
| `EventBus` | Signaux globaux (`skill_check_resolved`, `condition_changed`, `life_support_tick`, `combat_started`…). Les domaines communiquent par signaux, pas par appels directs. |
| `GameState` | État de la partie : personnages présents, drapeaux narratifs (`flags`), temps restant du support vital, conteneur cryogénique. Sérialisable en JSON pour la sauvegarde. |
| `DataDB` | Charge et valide les fichiers de `Data/` au démarrage ; expose `get_character(id)`, `get_dialogue(id)`, `get_item(id)`. |
| `Rules` | Façade vers `Scripts/Core` : `Rules.test(actor, skill_id, difficulty, mods)` renvoie un `TestResult`. |

Le moteur de règles (`Scripts/Core`) ne dépend d'aucun nœud : il prend des données et renvoie des résultats. C'est ce qui permet de le tester avec GUT et de garder l'UI indépendante.

### Contrat du résultat de test

```gdscript
# TestResult (Dictionary ou classe RefCounted)
{
  "roll": 38,            # 1 à 100 (00 = 100)
  "target": 55,          # score modifié, après plafond de ±50 sur les modificateurs
  "success": true,
  "degrees": 2,          # DR si succès, DE si échec ; jamais < 0 (dizaine = floor(n / 10))
  "critical": false,     # 01-05 toujours réussite critique ; 96-100 toujours échec critique ;
                         # entre les deux, un double ≤ target = réussite critique, > target = échec critique
  "complication": false  # échec à 3 DE ou plus, ou échec critique
}
```

Arrondis : toujours au supérieur (`ceil`), comme partout dans le LdR.

## 6. Schémas de données

### 6.1 Personnage (`Data/Characters/*.json`)

Les noms de champs reprennent ceux de la Fiche de personnage §4 (codes en anglais, sans accents : `ref`, `pre`). Version réduite pour la démo :

```json
{
  "id": "voronov",
  "name": "Voronov",
  "faction": "kombinat",
  "origin": "systemes_exterieurs",
  "characteristics": { "for": 45, "con": 50, "coo": 40, "ref": 35, "ada": 30, "per": 40, "int": 50, "vol": 55, "pre": 45 },
  "gravityNative": 0.14,
  "skills": { "armes_de_poing": 15, "intimidation": 20, "negociation": 10, "manoeuvre_apesanteur": 0 },
  "armor": "combinaison_renforcee",
  "weapons": ["pistolet_frangible"],
  "endurance": null,
  "sangFroid": null,
  "hypoxia": 0,
  "position": "anchored",
  "conditions": [],
  "injuries": []
}
```

- `skills` donne les **points de formation** (0 à 60), pas le score : le score se calcule (caractéristique + formation ; moitié de la caractéristique pour une compétence (F) non formée).
- `endurance` et `sangFroid` à `null` = pleins au départ (max calculés : CON / 5 et VOL / 5, arrondis au supérieur).
- Valeurs dérivées jamais stockées : SB = ceil((FOR + CON) / 20), TG = max(0, ceil(CON / 20) + origine).
- `characteristics` = valeurs actuelles, modificateurs d'origine déjà inclus. `origin` est une clé de `Data/Rules/origins.json` (LdR §9) : elle donne le modificateur de TG et la gravité natale par défaut (`gravityNative` de la fiche prime).
- `hypoxia` : stade 0 à 3. `position` : `anchored`, `floating` ou `flying`. `conditions` : `exposed`, `irradiated`, `doomed`, `bleeding`, `stunned`, `unconscious`, `under_g`, `suit_breached`, `exhausted`, `shocked` (liste dans `Scripts/Core/conditions.gd`).
- `injuries` : `{ "location": "head" | "torso" | "rightArm" | "leftArm" | "rightLeg" | "leftLeg", "severity": "light" | "serious" | "critical" | "mortal", "treated": false, "source": "" }`.
- `DataDB` valide chaque fiche au chargement (`CharacterData.validate`) et écarte une fiche invalide avec ses erreurs. `DataDB.get_character(id)` renvoie un `CharacterData` neuf ; `GameState.add_character()` le rend présent dans la scène et relaie ses changements de condition vers `EventBus.condition_changed`.
- Test d'un personnage : `Rules.test_skill(character, skill_key, difficulty, mods)` ajoute les malus de conditions (hypoxie −10 par stade, Épuisé −20, Choqué −20 en `relations` et `technique`), qui entrent dans le plafond de ±50.
- Les chiffres de l'exemple sont fictifs : les PNJ sont à écrire par l'agent Narrative.

### 6.2 Dialogue (`Data/Dialogues/*.json`)

```json
{
  "id": "kael_intro",
  "start": "n1",
  "nodes": {
    "n1": {
      "speaker": "kael",
      "text": "Pas un geste de plus, sauveteur.",
      "choices": [
        {
          "text": "[Persuasion] Le support vital lâche. On n'a pas le temps pour ça.",
          "skillCheck": { "skill": "persuasion", "difficulty": "delicate", "modifiers": [] },
          "success": "n2", "failure": "n3",
          "criticalFailure": "n4",
          "effects": { "onSuccess": [{ "setFlag": "kael_calme" }] }
        },
        { "text": "Je pose mon arme.", "next": "n5", "conditions": [{ "flag": "arme_degainee" }] }
      ]
    }
  }
}
```

- `difficulty` : clés du LdR §5 (`tres_facile` +30, `facile` +20, `aisee` +10, `normale` 0, `delicate` −10, `difficile` −20, `tres_difficile` −30, `extreme` −40).
- Branches facultatives : `criticalSuccess`, `criticalFailure`, `complication` ; sans elles, on retombe sur `success` ou `failure`.
- `opposedBy` (facultatif) : id d'un PNJ et compétence, pour un test opposé (Tromperie contre Psychologie…).
- `timeCost` (facultatif) : secondes retirées à l'horloge du support vital.

Ajouts implémentés par `Scripts/Dialogue/dialogue_runner.gd` (le commentaire en tête du fichier fait foi) :

- Fichier : `speakers` (id → nom affiché ; `narrateur` = "" pour un texte sans locuteur), `lifeSupportSeconds` (durée de l'horloge).
- Nœud : `next` (bouton « Continuer »), `effects` (liste appliquée à l'entrée), `redirects` (`[{ "conditions": [...], "next": "id" }]` : le premier qui convient remplace le nœud), `ending` (`{ "id", "title" }` : fin de partie).
- Choix : `once` (disparaît une fois choisi), `conditions` avec `flag` ou `notFlag`, `effects` avec `always`, `onSuccess`, `onFailure`.
- Effets : `setFlag`, `clearFlag`, `loseSangFroid`, `repairLifeSupport`, `startRepair` (`{ "goal", "interval", "then": { "done", "abort" } }`), `startCombat` (`{ "enemies", "allies", "then": { "victory", "defeat", "ceasefire" } }`).
- `DialogueRunner.validate()` refuse un dialogue avec un nœud inconnu, une compétence ou une difficulté inconnue, un test sans branche `success`/`failure`, ou un nœud sans issue ; `DataDB` écarte un tel fichier au démarrage.

### 6.3 Clés de compétences

Les 38 compétences du LdR §4, en `snake_case` sans accents (`systemes_de_survie`, `manoeuvre_apesanteur`, `bureaucratie_droit`…). La liste fait foi dans `Data/Rules/skills.json` (à créer par Core Systems) ; les autres domaines n'inventent pas de clé.

## 7. Adaptations du jeu de rôle au jeu vidéo

Le LdR laisse beaucoup de décisions au meneur. Dans le jeu, chaque décision du meneur doit devenir une règle codée ou une donnée écrite par Narrative. Écarts déjà identifiés :

| Règle du LdR | Adaptation proposée | Statut |
| --- | --- | --- |
| Action + mouvement + réaction par tour (§7) | Le README parle de « Points d'Action ». On garde la structure du LdR (1 action, 1 mouvement, 1 réaction) ; l'UI peut l'afficher comme 3 pastilles. | ⚠ à valider |
| Mouvement non chiffré (proposé 10 m, Fiche §3) | Déplacement par cases ou par points d'appui dans le sas ; en apesanteur, élan en ligne droite jusqu'au prochain appui. | ⚠ à valider |
| Le meneur fixe difficulté et modificateurs | Fixés dans les données (dialogues, objets interactifs). | proposé |
| Surprise : le meneur désigne les surpris | Déclenchée par la scène (ex. tir hors dialogue). | proposé |
| Tour de combat ≈ 5 s ; horloge en minutes | L'horloge du support vital avance de 5 s par tour de combat et du `timeCost` des actions hors combat. | proposé |
| Endurance à 0 : test de CON pour rester conscient (LdR §3) | Réussi = Épuisé ; raté = Inconscient (le LdR ne dit pas explicitement l'effet de l'échec). Le jeu ne retire pas Épuisé tout seul : c'est la scène qui décide (le LdR laisse ce choix au meneur). | proposé |
| Choqué : −20 aux « actions sociales et techniques » (LdR §11) | −20 aux compétences des domaines `relations` et `technique`. | proposé |
| Gravité natale de la Ceinture (0,03 à 0,5 g) et des habitats tournants (0,3 à 0,7 g) | Valeur par défaut 0,35 g et 0,5 g dans `origins.json` ; la fiche peut donner la sienne. | proposé |
| Valeurs d'armes provisoires (LdR §7) | Reprises telles quelles dans `Data/Items/`, marquées provisoires. Pistolet à fléchettes : 4 (absent du LdR). | proposé |
| Réaction (esquiver, parer, se couvrir) sans mécanique précise | Esquive automatique : test opposé Esquive contre l'attaque réussie, une fois par tour. | proposé |
| Couvert de −10 à −30 | Les caisses du sas donnent −20. | proposé |
| Fin d'un combat décidée par le meneur | Cessez-le-feu : action du joueur, Commandement Difficile, +20 si chaque adversaire est gravement blessé. Un PNJ désarmé se rend. | proposé |
| Blessure mortelle : « mort immédiate ou en quelques tours, selon la zone » | Tête ou torse : mort ; membre : inconscient et saignement. | proposé |
| Recharger : une action ; chargeurs non comptés | Chargeurs de rechange illimités dans la démo. | proposé |
| Combinaison : −10 en manipulation fine (Fiche, onglet 6) | Appliqué aux tentatives de réparation (compensé par le kit d'outils +10). | proposé |
| Horloge du support vital | Le joueur a une combinaison pressurisée : ce sont les survivants et le refuge qui meurent à zéro (fin « Le silence de Thulé-7 »). 15 minutes ; réparation : test prolongé de 8 DR, 60 s par tentative. | proposé |
