---
name: bootstrap-project
description: >
  Amorce un projet dont le cadrage est fermé : pose sur disque l'ossature que docs/ décrit
  déjà (manifeste, dépendances, dossiers, contrats, configuration de build et de test, points
  d'entrée, .gitignore, README), puis lance installation et build de fumée. Invoquée par
  /new-project (étape 11) et par /ticket sur un projet cadré non amorcé — jamais directement
  par l'utilisateur, jamais déléguée à un sous-agent.
user-invocable: false
---

# bootstrap-project

Le cadrage étant fermé, l'ossature est déjà décidée : ce geste est une recopie mécanique, sans
arbitrage — c'est pourquoi il s'exécute **en ligne par la commande appelante, jamais par un
sous-agent** (le déléguer coûte un agent et une vague entière, et sérialise tout le premier
ticket derrière lui). Le résultat qui compte : les contrats sur disque **avant** le découpage,
ce qui permet à backend et frontend de partir ensemble en vague 1.

## Ce qui est écrit, et rien d'autre

- le **manifeste** du gestionnaire de paquets du cadrage, avec les scripts exacts de la
  section `Commandes` de `CLAUDE.md` — aucun script en plus ;
- les **dépendances** de la stack, installées par la commande d'installation du cadrage. Les
  versions sont celles que le gestionnaire résout : aucune épinglée que l'utilisateur n'ait
  choisie ;
- les **dossiers** de l'arborescence de `docs/architecture.md` ;
- les **fichiers de contrats** — types partagés, schémas, constantes d'interface — **recopiés
  tels quels** depuis la section Contrats de `docs/architecture.md` : un contrat posé sur
  disque est un contrat que deux agents parallèles ne peuvent plus inventer chacun de leur
  côté ;
- la **configuration de build et d'outillage** — compilateur, bundler, style, ports, proxy, et
  le **harness de test** du cadrage (config posée, commande de test dans les scripts du
  manifeste ; les tests eux-mêmes viendront avec les sous-tâches) ;
- le **point d'entrée** de chaque exécutable, réduit à ce qui le fait démarrer ;
- le `.gitignore` : au minimum artefacts de build, dépendances installées et
  `.sohub-claude-plugin/` ;
- le `README.md`, via la skill `generate-readme`.

## Ce qui n'est jamais écrit

Un fichier de l'arborescence qui porte un item du périmètre — vue, écran, composant, module
métier, endpoint. Pas même vide, pas même « provisoire » : un placeholder est payé deux fois
(écrit ici, réécrit par une sous-tâche) et met le même fichier dans les `fichiers_cibles` de
deux sous-tâches, ce qui interdit exactement le parallélisme que l'amorçage rend possible. La
règle de tri est mécanique : on pose ce dont `docs/` fixe la **forme**, on laisse ce dont il
ne fixe que le **rôle**.

## Build de fumée

Puis lancer **l'installation et le build** du cadrage. C'est le premier moment où il devient
falsifiable : une stack dont les briques ne s'installent pas ensemble tombe ici, en une
question à l'utilisateur, au lieu de tomber trois tentatives plus loin dans la boucle de
correction du premier ticket. Si ça casse, c'est un défaut du cadrage : le corriger avec
l'utilisateur et consigner l'arbitrage dans `docs/decisions.md` — jamais un contournement
silencieux glissé dans un fichier de configuration.

## Garde-fous

- **N'écrase aucun fichier existant** : un projet déjà amorcé se complète, il ne se
  réinitialise pas.
- Rendre le résultat du build en une ligne à la commande appelante, qui enchaîne.
