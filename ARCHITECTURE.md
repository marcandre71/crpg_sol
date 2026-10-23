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

- **Moteur :** Godot 4.x ⚠ version exacte à fixer (proposition : la dernière 4.x stable installée chez Marc, notée dans `project.godot`).
- **Langage :** GDScript uniquement ⚠. Le README autorise le C#, mais il impose la version .NET de Godot et complique le mélange des deux langages ; on propose de s'en tenir à GDScript tant que le prototype est petit.
- **Données :** JSON pour tout ce qui est écrit par l'agent Narrative (dialogues, PNJ, objets), ressources `.tres` seulement pour ce qui est réglé dans l'éditeur (thèmes UI, scènes).
- **Tests :** GUT (Godot Unit Test) ⚠ pour le moteur de règles, qui doit être testé sans lancer de scène.
- **UI :** rétro-futuriste, terminal, texte ambre ou vert sur fond noir.

## 4. Arborescence

```
/
├── project.godot
├── README.md · ARCHITECTURE.md · TODO_LIST.md · COMMUNICATIONS.md
├── Scenes/
│   ├── Main.tscn                     # point d'entrée, charge le niveau et l'UI
│   ├── Levels/Thule7_SasPrincipal.tscn
│   ├── Actors/Actor.tscn             # pion générique (joueur et PNJ)
│   └── UI/                           # Terminal, DialogueBox, CombatHUD, CharacterSheet, LifeSupportClock
├── Scripts/
│   ├── Core/        # domaine Core Systems : règles pures, sans nœud de scène
│   │   ├── dice.gd                   # D100, DR/DE, critiques
│   │   ├── rules.gd                  # tests simples, opposés, prolongés ; modificateurs
│   │   ├── character_data.gd         # modèle du personnage (cf. Fiche §4)
│   │   └── conditions.gd
│   ├── Combat/      # domaine Core Systems : initiative, actions, dégâts, localisation
│   ├── Environment/ # domaine Core Systems : horloge du support vital, froid, hypoxie, décompression
│   ├── Dialogue/    # domaine Narrative : lecteur de dialogues JSON, résolution des SkillCheck
│   ├── Autoload/    # singletons (section 5)
│   └── UI/          # domaine UI : scripts des scènes de Scenes/UI
├── Data/
│   ├── Dialogues/   # un fichier JSON par PNJ ou par scène (section 6.2)
│   ├── Characters/  # joueur pré-tiré et PNJ (section 6.1)
│   ├── Items/       # armes, armures, équipement
│   └── Rules/       # compétences, tables (localisation), difficultés
├── Assets/          # Fonts/, Audio/, Sprites/
└── Tests/           # tests GUT, miroir de Scripts/
```

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
  "characteristics": { "for": 45, "con": 50, "coo": 40, "ref": 35, "ada": 30, "per": 40, "int": 50, "vol": 55, "pre": 45 },
  "gravityNative": 0.14,
  "skills": { "armes_de_poing": 15, "intimidation": 20, "negociation": 10, "manoeuvre_apesanteur": 0 },
  "armor": "combinaison_renforcee",
  "weapons": ["pistolet_frangible"],
  "endurance": null,
  "sangFroid": null,
  "conditions": [],
  "injuries": []
}
```

- `skills` donne les **points de formation** (0 à 60), pas le score : le score se calcule (caractéristique + formation ; moitié de la caractéristique pour une compétence (F) non formée).
- `endurance` et `sangFroid` à `null` = pleins au départ (max calculés : CON / 5 et VOL / 5, arrondis au supérieur).
- Valeurs dérivées jamais stockées : SB = ceil((FOR + CON) / 20), TG = ceil(CON / 20) + origine.
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
| Valeurs d'armes provisoires (LdR §7) | Reprises telles quelles dans `Data/Items/`, marquées provisoires. | proposé |
