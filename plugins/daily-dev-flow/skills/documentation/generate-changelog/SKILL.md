---
name: generate-changelog
description: >
  Convention de génération/mise à jour d'un CHANGELOG.md, basée sur Keep a Changelog et
  Semantic Versioning. À utiliser à chaque changement notable pour l'utilisateur du projet
  (nouvelle fonctionnalité, correction, breaking change) et au moment de tagger une version.
---

# Convention CHANGELOG.md

Source : [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/), combinée à
[Semantic Versioning](https://semver.org/) et à la skill `commit-convention` (Conventional
Commits) pour le mapping type de commit → catégorie de changelog.

## Principe

Un changelog est écrit **pour des humains**, pas généré brut depuis `git log`. Chaque entrée
explique l'impact pour l'utilisateur du projet, pas le détail d'implémentation.

## Structure du fichier

```markdown
# Changelog

Toutes les modifications notables de ce projet sont documentées ici.
Le format suit [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
et ce projet respecte le [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- ...

## [1.2.0] - 2026-09-07

### Added
- ...

### Fixed
- ...

## [1.1.0] - 2026-08-01

...

[Unreleased]: https://github.com/<org>/<repo>/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/<org>/<repo>/compare/v1.1.0...v1.2.0
```

- Version la plus récente **en premier** (ordre antéchronologique).
- Une section `[Unreleased]` en haut, alimentée au fil des changements, vidée/renommée en
  version au moment du tag.
- Dates au format ISO 8601 (`AAAA-MM-JJ`).
- Chaque version est liée en bas de fichier (lien de comparaison), pour rester navigable.

## Catégories (sous-titres de chaque version, dans cet ordre, omettre celles vides)

- `Added` — nouvelles fonctionnalités
- `Changed` — changements de comportement existant
- `Deprecated` — fonctionnalités en cours de dépréciation
- `Removed` — fonctionnalités supprimées
- `Fixed` — corrections de bug
- `Security` — correctifs de vulnérabilité (toujours signalés, même en version patch)

## Mapping avec `commit-convention`

| Type de commit       | Catégorie changelog |
|-----------------------|---------------------|
| `feat`                | Added (ou Changed si extension d'existant) |
| `fix`                 | Fixed |
| `feat!` / `BREAKING CHANGE` | Changed (+ mention explicite breaking) |
| `perf`                | Changed |
| `refactor`, `style`, `chore`, `test` | absent du changelog (n'affecte pas l'utilisateur) |
| `docs`                | absent du changelog, sauf doc publique majeure |

## Règles

- Ne jamais coller un diff de commits bruts : reformuler du point de vue de l'utilisateur du
  projet (« Ajout de X » plutôt que le message de commit technique).
- Un breaking change est **toujours** mis en avant clairement (préfixe `[BREAKING]` ou
  paragraphe dédié), jamais noyé dans une liste `Changed` anodine.
- La version du changelog doit correspondre au tag Git / à la version publiée (SemVer :
  MAJOR = breaking, MINOR = feature rétrocompatible, PATCH = fix rétrocompatible).
- Ne pas historiser un changement déjà annulé avant release (ex. un `feat` ajouté puis retiré
  dans la même version `Unreleased`) — seul l'état final publié compte.

## Ce que cette skill ne fait pas

- Ne décide pas du numéro de version à publier (dépend du processus de release du projet, hors
  scope).
- Ne remplace pas les messages de commit (cf. `commit-convention`) — le changelog est un
  résumé à destination utilisateur, pas un miroir de l'historique Git.
