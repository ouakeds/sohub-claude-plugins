---
name: readme-convention
description: >
  Convention de génération/mise à jour d'un README.md, basée sur Make a README et Standard
  Readme. À utiliser dès qu'un README.md doit être créé (project-scaffold) ou mis à jour suite
  à un changement structurant (nouvelle installation, nouvelle commande, changement d'API
  publique).
---

# Convention README.md

Sources : [Make a README](https://www.makeareadme.com/), [Standard Readme
Style](https://github.com/RichardLitt/standard-readme).

## Principe

Le README répond à trois questions dans l'ordre : **qu'est-ce que c'est**, **comment je
l'installe/lance**, **comment je l'utilise**. Le reste est secondaire. Mieux vaut un README un
peu long et complet qu'un README trop court qui oblige à lire le code.

## Structure (sections dans cet ordre, omettre celles non pertinentes)

1. **Titre + une phrase de description** — ce que fait le projet, pour qui, ce qui le
   différencie (pas un simple nom de repo).
2. **Badges** (optionnel) — build status, version, licence — seulement s'ils sont réellement
   configurés (CI, npm, etc.), jamais des badges décoratifs vides de sens.
3. **Table des matières** — obligatoire si le README dépasse ~4 sections.
4. **Prérequis** — versions de runtime/outils nécessaires.
5. **Installation** — étapes précises et copiables (`npm install`, variables d'env requises,
   etc.). Ne pas supposer un niveau d'expertise : un nouvel arrivant doit pouvoir suivre sans
   contexte implicite.
6. **Usage** — exemples de code avec la sortie attendue. Un exemple minimal fonctionnel prime
   sur une explication abstraite.
7. **Configuration** — variables d'environnement, fichiers de config, valeurs par défaut.
8. **Tests / Qualité** — commandes de lint et de test (`npm test`, `npm run lint`), pour que la
   contribution reste vérifiable.
9. **Contribuer** — lien vers `CONTRIBUTING.md` si présent, sinon règles minimales (branche,
   convention de commit → cf. skill `commit-convention`).
10. **Changelog** — lien vers `CHANGELOG.md` (cf. skill `changelog-convention`), jamais dupliqué
    dans le README.
11. **Licence** — nom + lien vers le fichier `LICENSE`.
12. **Statut du projet** — actif / maintenance / archivé, si pertinent.

## Règles

- Un seul README.md à la racine du projet (les sous-modules complexes peuvent avoir le leur,
  référencé depuis le README racine, pas dupliqué).
- Pas de contenu qui devient rapidement obsolète et non maintenu (ex. roadmap détaillée,
  captures d'écran datées) sans un moyen de le garder à jour — préférer un lien vers l'outil de
  suivi (issues, projet) plutôt qu'une liste figée dans le fichier.
- Le README documente l'usage **actuel** du projet, pas son historique de changements (ça,
  c'est le rôle du CHANGELOG.md) ni son design interne détaillé (ça, c'est la doc technique/
  `docs/`).
- Générer le README **tôt** dans la vie du projet (idéalement au scaffold), pas en fin de
  projet.

## Ce que cette skill ne fait pas

- Ne génère pas de CHANGELOG.md (cf. `changelog-convention`).
- Ne documente pas d'API détaillée (endpoints, schémas) — cf. skill `openapi-doc` pour une doc
  d'API générée depuis le code.
