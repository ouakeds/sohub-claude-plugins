---
name: harvest-retex
description: >
  Récolte les enseignements sur le plugin accumulés dans les retex des projets cibles
  (section « Enseignements plugin » de leur .sohub-claude-plugin/retex.md), les regroupe par
  récurrence, et les transforme en améliorations actionnables du plugin — fichier et section
  visés, changement proposé. À invoquer depuis le repo du plugin, quand on veut le faire
  progresser à partir de l'usage réel. Lecture seule côté projets ; n'applique aucune
  amélioration sans accord.
user-invocable: true
---

# harvest-retex

L'étape 7 de `/ticket` écrit les enseignements qui portent sur le plugin lui-même — découpage
systématiquement fautif, boucle de build gaspillée, agent mal outillé — dans la section
`## Enseignements plugin` du `retex.md` de chaque projet cible. Dispersés dans N projets, ils
ne servent à rien ; cette skill est l'autre moitié de la boucle : elle les rassemble et les
transforme en travail sur le plugin.

## Entrée

Le ou les chemins de projets cibles (racine du projet, ou directement leur
`.sohub-claude-plugin/retex.md`), passés en argument. Sans argument, demande à l'utilisateur
quels projets récolter — ne scanne jamais le disque à leur recherche.

## Récolte

1. Pour chaque projet : lis la seule section `## Enseignements plugin` de son `retex.md`.
   Fichier ou section absents = rien à récolter pour ce projet, dis-le sans en faire une
   erreur. **Lecture seule** : les retex des projets ne sont jamais modifiés — la récolte ne
   consomme pas les enseignements, elle les lit.
2. Agrège toutes les lignes, puis regroupe celles qui décrivent le même constat, même
   formulées différemment. Un constat présent dans **plusieurs projets ou plusieurs tickets
   est une récurrence** : il passe en tête de liste — c'est le signal le plus fiable qu'un
   défaut est structurel et non un accident de projet.

## Restitution

Pour chaque groupe, une **amélioration actionnable** :

- le constat, en une ligne, avec ses sources (projet + ticket + date, tels que les lignes
  récoltées les portent) ;
- le ou les fichiers du plugin visés, à la section près (ex. `commands/ticket.md` étape 5,
  `agents/planner.md` § contrat de sortie) ;
- le changement proposé, assez précis pour être implémenté sans re-dériver l'analyse.

Rends la liste triée par récurrence décroissante, puis propose à l'utilisateur de choisir
celles à implémenter — via `AskUserQuestion`, une question par amélioration si elles sont peu
nombreuses, ou une sélection multiple sinon. Un enseignement non retenu reste dans les retex
des projets : il reviendra à la prochaine récolte, plus appuyé s'il a récidivé.

## Ce que cette skill ne fait pas

- **N'applique rien elle-même sans accord** : elle propose, l'utilisateur choisit.
  L'implémentation des améliorations retenues se fait ensuite, dans le repo du plugin, comme
  n'importe quel changement — édition des fichiers concernés, `CHANGELOG.md` du plugin, et
  `create-pr` si l'utilisateur veut livrer.
- N'écrit jamais dans un projet cible — ni retex, ni plans, ni rien.
- Ne remplace pas l'étape 7 de `/ticket` : elle consomme ce que l'étape 7 a persisté, elle ne
  produit aucun enseignement elle-même.
