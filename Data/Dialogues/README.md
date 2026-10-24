# Scénario de la démo : « L'Impasse de l'Habitat Thulé-7 »

> **Statut : version provisoire du 24/10/2026, écrite pour rendre la démo jouable.** Trois points attendent une décision de Marc (`COMMUNICATIONS.md`) ; les choix faits en attendant sont marqués ⚠ et faciles à changer dans les fichiers JSON.
> Fichier jouable : `thule7_sas.json`. Personnages : `Data/Characters/`.

## Situation de départ

Thulé-7 est un petit habitat minier de la Ceinture, creusé dans son rocher. Il ne répond plus depuis 19 jours. Le personnage du joueur, **Ezra Tal**, sauveteur du vide de la Mutuelle ⚠ (décision n° 4), arrive après 11 jours de trajet, alors que la Veille avait demandé de ne pas y aller (accroche « Le silence de Thulé-7 », Bible §11).

Dans le sas principal, le recycleur lâche : **15 minutes** d'autonomie. Ezra a une combinaison pressurisée ; les trois survivants du sas et les **41 habitants** réfugiés derrière la cloison n'en ont pas. Trois personnes se tiennent en joue en micropesanteur autour d'un conteneur cryogénique.

## Ce qui s'est passé (connu du joueur par l'enquête)

⚠ Décision n° 5 : le contenu du conteneur. Pour éviter le problème de date de la comète Sereguine (échantillonnage en 2188), la démo n'utilise pas la comète.

- Thulé-7 a signé avec le **Kombinat Hélion** un contrat non déclaré, arrangé par la **Caisse Noire** sans vote de l'assemblée de l'habitat : des cultures d'organismes modifiés pour extraire le métal du rocher (biolixiviation).
- Il y a 19 jours, les cultures sont passées dans les bacs d'algues du recycleur. L'air s'est dégradé, le greffier a scellé l'habitat, et Voronov a coupé la balise sur ordre de Titan.
- L'équipe du Kombinat est partie avec sa navette. Voronov est resté pour garder le refuge en vie.
- Le conteneur contient le dernier lot (« lot B-14, souches de lixiviation, génération 6 ») et son journal : c'est la preuve du contrat.

Règles de cohérence (Bible §12) : aucun procédé de fabrication n'est décrit ; aucun lien n'est fait avec la nature de la Sereguine.

## Personnages

| Personnage | Faction | Ce qu'il veut | Le vice et la lueur |
| --- | --- | --- | --- |
| **Lina** ⚠ (décision n° 6 : on suppose la Lina de la Bible §8) | Mutuelle, technicienne de support vital venue de Cérès, blessée à la jambe par Voronov | Rapporter le conteneur devant l'assemblée de Cérès | Elle accepte que la vérité salisse aussi la Mutuelle |
| **Kael** | Office de la Veille, inspecteur | Que personne ne s'en serve : le conteneur sous scellé à Shackleton | Le réflexe du secret ; mais il ne veut pas tirer, il veut que quelqu'un décide |
| **Voronov** | Kombinat Hélion, chef de la sécurité | Rapporter le conteneur à Titan | Il a coupé la balise ; mais il est le seul du Kombinat à être resté |

## Les trois voies

1. **Dialogue.** Calmer Kael (Psychologie, puis Persuasion ; ou Bureaucratie et droit) et Voronov (Psychologie puis Persuasion, Négociation opposée, Intimidation), puis proposer une trêve. Un ordre de Commandement peut tout régler d'un coup. Deux maladresses (complications ou échecs sur les menaces) déclenchent le combat.
2. **Ingénierie.** Après la trêve, réparer le recycleur : test prolongé de 8 DR, 60 s par tentative (Systèmes de survie Délicate, Mécanique ou Électronique Difficile). Soigner Lina d'abord lui permet d'aider (+10).
3. **Combat.** Tirer, ou laisser la tension exploser. Kael se bat aux côtés d'Ezra s'il a été calmé. Le combat est très dangereux (carabine contre pistolet à fléchettes) ; le cessez-le-feu (Commandement) permet d'en sortir.

## Fins

| Id | Titre | Condition |
| --- | --- | --- |
| `fin_mutuelle` | La cargaison froide | Recycleur réparé ; conteneur confié à Lina |
| `fin_veille` | Sous scellé | Conteneur remis à Kael |
| `fin_kombinat` | Propriété du Kombinat | Conteneur rendu à Voronov (s'il est encore debout) |
| `fin_compromis` | Trois copies | Négociation Difficile, après avoir lu le journal du conteneur |
| `fin_vide` | Le large | Conteneur largué dans le vide |
| `fin_defaite` | Silence radio | Ezra hors de combat |
| `fin_silence` | Le silence de Thulé-7 | L'horloge atteint zéro avant la réparation |

## Drapeaux

`kael_lu_ok`, `kael_calme`, `voronov_lu`, `voronov_calme`, `voronov_aveu`, `voronov_hors_combat`, `lina_soignee`, `sait_contrat`, `sait_contenu`, `ordre_donne`, `tension`, `treve`, `support_repare`.
