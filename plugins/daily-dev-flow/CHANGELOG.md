# Changelog

Toutes les modifications notables du plugin `daily-dev-flow` sont documentées ici.
Le format suit [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
et ce projet respecte le [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed
- Renommage du plugin `dev-flow` → `daily-dev-flow`.

### Security
- Hooks `PreToolUse` (`hooks/hooks.json`) interdisant tout commit/push git et toute lecture des
  variables d'environnement privées du projet cible (`.env*`, `env`, `printenv` sans argument).

### Added
- Skills `generate-readme` et `generate-changelog` : conventions de génération/mise à jour
  de README.md et CHANGELOG.md, basées respectivement sur Make a README / Standard Readme et
  Keep a Changelog / SemVer.

### Changed
- Réorganisation de `skills/` en trois catégories (`flow/`, `documentation/`, `audit/`),
  déclarées explicitement dans `plugin.json`, pour distinguer l'outillage interne du flux
  `/ticket` des skills de documentation et d'audit.

## [0.1.0] - 2026-09-07

### Added
- Scaffold initial du plugin `daily-dev-flow` : commande `/ticket` orchestrant le flux
  ticket → analyse → développement → vérification de build.
- Agents `researcher`, `backend-dev`, `frontend-dev`, `build-verifier`.
- Skills `detect-stack`, `build-check`, `openapi-doc`, `rgaa-check`, `security-audit`.
- Intégration MCP `code-review-graph` pour l'agent `researcher`, avec fallback grep/glob.

[Unreleased]: https://github.com/ouakeds/sohub-claude-plugins/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/ouakeds/sohub-claude-plugins/releases/tag/v0.1.0
