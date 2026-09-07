# Changelog

Toutes les modifications notables du plugin `daily-dev-flow` sont documentées ici.
Le format suit [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
et ce projet respecte le [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Commande `/new-project` : cadrage conversationnel d'un projet neuf (usage métier, périmètre,
  données, distribution, stack), en 2 tours de questions fermées maximum. Produit le cadrage
  sur deux niveaux — `docs/cadrage.md`, `docs/architecture.md`, `docs/decisions.md` pour le
  détail versionné, et un `CLAUDE.md` résumé sous budget (~40 lignes) puisqu'il est rechargé
  dans le contexte de chaque agent à chaque tour. Aucun code produit. Une commande et non un
  agent : un sous-agent isolé ne peut pas challenger l'utilisateur en conversation.
- Règle de sourçage dans `/new-project` : toute affirmation du cadrage est déclarée, vérifiée
  ou marquée `> **Hypothèse**` — pas de quatrième catégorie. Interdits explicites sur les
  chiffres, critères de succès, personas, capacités techniques et besoins déduits non demandés ;
  étape de vérification en lecture seule des sources de données avant écriture ; hypothèses et
  questions ouvertes remontées séparément du résumé à la remise.
- Devoir de contradiction dans `/new-project` : objection en deux phrases avec alternative sur
  une demande bancale, non systématique (une objection fabriquée est une hallucination de
  plus), et abandonnée dès que l'utilisateur maintient son choix — consignée dans
  `docs/decisions.md`.
- Mode **greenfield** dans `/ticket` : ni `researcher` ni `detect-stack` (rien à analyser).
  Sans `CLAUDE.md`, la commande s'arrête et renvoie vers `/new-project` plutôt que de deviner
  un périmètre ; avec `CLAUDE.md`, la stack y est lue et la vague 1 se réduit à une unique
  sous-tâche d'amorçage (manifeste, arborescence, entrypoint, README).
- Skills `generate-readme` et `generate-changelog` : conventions de génération/mise à jour
  de README.md et CHANGELOG.md, basées respectivement sur Make a README / Standard Readme et
  Keep a Changelog / SemVer.

### Fixed
- `/ticket` n'occupe plus des tours à attendre un agent (`sleep`, `echo waiting`) : règle
  explicite d'attente sans commande de remplissage.
- Garde-fous symétriques dans `researcher` (sortie immédiate sur repo sans code) et
  `detect-stack` (`null` explicite en l'absence de manifeste, plutôt qu'une stack devinée).

### Changed
- Renommage du plugin `dev-flow` → `daily-dev-flow`.
- Réorganisation de `skills/` en trois catégories (`flow/`, `documentation/`, `audit/`),
  déclarées explicitement dans `plugin.json`, pour distinguer l'outillage interne du flux
  `/ticket` des skills de documentation et d'audit.

### Security
- Hooks `PreToolUse` (`hooks/hooks.json`) interdisant tout commit/push git et toute lecture des
  variables d'environnement privées du projet cible (`.env*`, `env`, `printenv` sans argument).

## [0.1.0] - 2026-09-07

### Added
- Scaffold initial du plugin `daily-dev-flow` : commande `/ticket` orchestrant le flux
  ticket → analyse → développement → vérification de build.
- Agents `researcher`, `backend-dev`, `frontend-dev`, `build-verifier`.
- Skills `detect-stack`, `build-check`, `openapi-doc`, `rgaa-check`, `security-audit`.
- Intégration MCP `code-review-graph` pour l'agent `researcher`, avec fallback grep/glob.

[Unreleased]: https://github.com/ouakeds/sohub-claude-plugins/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/ouakeds/sohub-claude-plugins/releases/tag/v0.1.0
