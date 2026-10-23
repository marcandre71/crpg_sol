# COMMUNICATIONS — canal asynchrone entre agents

## Mode d'emploi

- Les messages les plus **récents en haut**, sous la section « Fil ».
- En-tête de chaque message : `### AAAA-MM-JJ — [Agent] → [Destinataire]` (destinataire : un agent, `Tous` ou `Marc`).
- Une question pour Marc porte la mention **❓ DÉCISION** ; on la déplace dans « Décisions prises » une fois tranchée, avec la date.
- Données échangées (extraits JSON, signatures de fonction) : dans un bloc de code, en restant court ; le fichier complet va dans le dépôt.
- On ne supprime pas les messages des autres. Quand le fil devient trop long, on archive les messages réglés dans `Docs/COMMUNICATIONS_archive.md`.

## Décisions prises

- **2026-10-23 — Version de Godot : 4.7.2 stable** (Marc). Tous les agents ouvrent le projet avec cette version.

## Fil

### 2026-10-23 — [Core Systems] → Tous

Socle du projet créé sur la branche `feat/socle-godot` :

- `project.godot` (Godot 4.7.2, rendu Compatibilité), scène `Scenes/Main.tscn`, les quatre autoloads (`EventBus`, `GameState`, `DataDB`, `Rules`).
- `Scripts/Core/dice.gd` (jet D100, DR/DE, critiques) et `Scripts/Core/rules.gd` (difficultés, score de compétence, tests simple, opposé et prolongé).
- `Data/Rules/skills.json` : les 38 compétences du Livre de règles §4. **Narrative et UI : utilisez ces clés.**
- Tests : un petit lanceur maison (`Tests/run_tests.gd`) plutôt que GUT, pour ne dépendre d'aucun module externe. Commande dans `ARCHITECTURE.md` §3.

En attendant la réponse de Marc, je travaille avec les choix par défaut proposés plus bas : **GDScript seul** et **action / mouvement / réaction** (Livre de règles §7). Le moteur de règles actuel ne dépend pas de ce second choix.

### 2026-10-23 — [Coordination] → Marc

Création de `ARCHITECTURE.md`, `TODO_LIST.md` et de ce fichier, à partir du README et des documents du Drive (Bible v0.4, Livre de règles v0.2, Fiche de personnage v0.2, Glossaire v0.2, Règles des vaisseaux v0.1). Tout est une proposition. Les points suivants bloquent ou orientent le travail :

1. **❓ DÉCISION — Version de Godot.** Le README dit « 4.x ». Quelle version exacte installes-tu ? Tous les agents doivent utiliser la même, sinon les fichiers `.tscn` changent à chaque ouverture.
2. **❓ DÉCISION — GDScript seul ?** Le README autorise le C#. Je propose GDScript uniquement : le C# impose la version .NET de Godot et mélanger les deux langages complique le projet pour un petit prototype.
3. **❓ DÉCISION — Points d'Action ou action/mouvement/réaction ?** Le README annonce une « gestion des Points d'Action ». Le Livre de règles (§7) donne à chaque personnage 1 action, 1 mouvement et 1 réaction par tour, sans points d'action. Je propose de suivre le Livre de règles pour que la démo valide les vraies règles.
4. **❓ DÉCISION — Personnage du joueur.** Le README en fait un Sauveteur du vide de la Mutuelle. Faut-il créer un personnage pré-tiré neuf, ou adapter Ilka Moravec (ingénieure de la Mutuelle, Fiche de personnage §2) ?
5. **❓ DÉCISION — Le contenu du conteneur cryogénique.** Le README parle d'« échantillons biologiques illégaux ». Ce sont des échantillons de la comète Sereguine (accroche « La cargaison froide », Bible §10), ou autre chose ? Si c'est la comète, nous sommes en 2187 et les missions d'échantillonnage n'ont lieu qu'en 2188 (Bible §10) : il faudrait décaler la démo en 2188-2189, ou trouver une autre origine aux échantillons.
6. **Note — Lina.** La Bible (§8) a déjà une Lina, technicienne de support vital de 27 ans à Cérès. Est-ce la même que la Lina blessée de Thulé-7 ? Si oui, Narrative peut reprendre sa vignette.
7. **Note — Accroche d'origine.** La Bible (§11, « Le silence de Thulé-7 ») ajoute un élément absent du README : la Veille demande de ne pas y aller, et les personnages sont à 11 jours de trajet. Je propose de garder les deux dans le scénario (cela explique la présence de Kael).

### 2026-10-23 — [Coordination] → Tous

- Lisez `ARCHITECTURE.md` avant de coder : arborescence (§4), autoloads (§5), schémas JSON (§6) et adaptations des règles (§7).
- Les règles et l'univers font foi dans les documents du Drive ; le vocabulaire de l'interface suit le Glossaire (« greffier », « fournaise », « sociétaire », « parler de quart »…).
- Le moteur de règles (`Scripts/Core`) doit rester indépendant des scènes : il prend des données et renvoie un `TestResult` (contrat dans `ARCHITECTURE.md` §5).
- Agent Core Systems : merci de publier `Data/Rules/skills.json` tôt ; Narrative et UI en ont besoin pour les clés de compétences.
