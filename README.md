# Sol, Nouvelle Ère - Prototype cRPG

Bienvenue sur le repository central du projet **Sol, Nouvelle Ère**, un prototype de jeu de rôle sur ordinateur (cRPG) au tour par tour, développé sous **Godot Engine**. 

Ce dépôt sert d'espace de travail, de codebase et de point de synchronisation unique pour toutes les Intelligences Artificielles (agents) collaborant sur ce projet.

## 🌌 L'Univers : Hard Science-Fiction Réaliste
Le jeu prend place en 2187. L'univers obéit à des règles physiques strictes :
*   **Réalisme absolu :** Pas de voyage plus rapide que la lumière, pas de gravité artificielle magique, pas de boucliers d'énergie. La gravité est générée par rotation ou accélération (moteurs à fusion pulsée).
*   **Lumière lente :** Les communications mettent des minutes ou des heures à traverser le système solaire. Chaque décision prise loin de la Terre se fait dans la solitude absolue.
*   **Thématique :** L'humanité n'a pas changé. Les factions reproduisent les mêmes erreurs et vices (soif de contrôle, avidité) à l'échelle spatiale. 
*   **Factions clés de la démo :**
    *   *La Mutuelle :* Coopérative d'entraide de la Ceinture d'astéroïdes.
    *   *Le Kombinat Hélion :* Mégacorporation contrôlant la chimie et le carburant (hélium 3).
    *   *L'Office de la Veille :* Autorité de contrôle spatial supranationale.

## 🎮 La Démo : "L'Impasse de l'Habitat Thulé-7"
Un huis clos spatial pour valider les mécaniques fondamentales du cRPG.
*   **Le Pitch :** Le joueur incarne un Sauveteur du vide de la Mutuelle arrivant dans l'habitat minier Thulé-7, silencieux depuis 19 jours. Dans le sas principal, le support vital lâche (froid extrême, compte à rebours). 
*   **Les PNJ :** Trois survivants armés se tiennent en joue en micropesanteur (Lina de la Mutuelle blessée, Kael de la Veille, Voronov du Kombinat). Ils se disputent un mystérieux conteneur cryogénique (échantillons biologiques illégaux).
*   **Gameplay :** Résolution par le dialogue (arbres de choix liés aux compétences), l'ingénierie (réparer le sas) ou le combat tactique (gestion des Points d'Action, recul des armes en apesanteur).

## 🛠️ Stack Technique
*   **Moteur :** Godot Engine (version 4.x).
*   **Langage :** GDScript (ou C# selon la spécialité de l'agent assigné au système).
*   **Architecture UI :** Rétro-futuriste (terminal, texte ambre/vert sur noir).
*   **Gestion des données :** JSON ou ressources natives Godot (`.tres`) pour les dialogues et statistiques.

## 🤖 Protocole de Collaboration et de Coordination des IA
Pour éviter les conflits et assurer une progression fluide, tous les agents IA intervenant sur ce dépôt **doivent respecter les règles suivantes** :

1.  **Répartition stricte des rôles :** Chaque agent doit définir clairement son domaine d'intervention dès son intégration (ex: Agent Narrative Design, Agent Godot UI, Agent Core Systems). Ne modifiez pas les fichiers hors de votre domaine sans vous concerter.
2.  **Fichiers de coordination :**
    *   `ARCHITECTURE.md` : Pour valider la structure des nœuds Godot et l'arborescence des scripts avant de coder.
    *   `TODO_LIST.md` : Pour piocher des tâches et indiquer sur quoi vous travaillez.
    *   `COMMUNICATIONS.md` : Utilisez ce fichier comme un "chat" asynchrone. Laissez des notes, des JSON de datas, ou des requêtes pour les autres agents (ex: *"Agent Narrative : J'ai mis à jour le JSON des dialogues, Agent UI peux-tu parser la nouvelle clé 'SkillCheck' ?"*).
3.  **Isolation des tâches :** Poussez votre code dans des dossiers séparés par domaine (`/Scripts/UI`, `/Scripts/Core`, `/Data/Dialogues`) pour éviter d'écraser le travail d'un autre agent.
