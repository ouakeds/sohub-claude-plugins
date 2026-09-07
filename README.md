# sohub-claude-plugins

Marketplace de plugins Claude Code pour outiller le développement logiciel. Contient
actuellement un plugin : **daily-dev-flow**.

## Prérequis

- [Claude Code](https://claude.com/claude-code) installé.
- `uv`/`uvx` sur la machine, si vous voulez le MCP `code-review-graph` utilisé par l'agent
  `researcher` de `daily-dev-flow` (dégradation automatique en fallback grep/glob sinon).

## Installation

Ajoutez ce dépôt comme marketplace dans Claude Code :

```
/plugin marketplace add ouakeds/sohub-claude-plugins
```

Puis installez le plugin `daily-dev-flow` :

```
/plugin install daily-dev-flow
```

## Plugins

### daily-dev-flow

Flux **ticket → analyse → développement → vérification de build**, générique multi-stack
(aucune convention de langage/framework hardcodée : la stack est détectée une fois par ticket
puis propagée aux agents).

#### Usage

```
/ticket "<texte du ticket>" [--auto]
```

- Sans `--auto` : une gate de confirmation intervient avant le lancement des développements.
- Avec `--auto` : le flux s'exécute de bout en bout sans interruption.

L'orchestrateur route vers les agents (`researcher`, `backend-dev`, `frontend-dev`,
`build-verifier`) et les skills du plugin, organisées par catégorie :

| Catégorie | Skills | Rôle |
| --- | --- | --- |
| `skills/flow/` | `detect-stack`, `build-check` | outillage interne du flux `/ticket` |
| `skills/documentation/` | `generate-openapi`, `generate-readme`, `generate-changelog` | génération/convention de la doc du projet cible |
| `skills/audit/` | `rgaa-check`, `security-audit` | détection + correction de non-conformités |

... sans jamais redonner à un sous-agent plus de contexte qu'il n'en a besoin.

#### Garde-fous

Le plugin refuse systématiquement (hooks `PreToolUse`, cf. `plugins/daily-dev-flow/CLAUDE.md`) :
- tout commit ou push git ;
- toute lecture des variables d'environnement privées du projet cible (`.env*`, `env`,
  `printenv`).

#### Artefacts générés

Tout artefact produit par `daily-dev-flow` (plans, audits, doc OpenAPI) est écrit dans
`.sohub-claude-plugin/` à la racine du **projet cible** (jamais dans le plugin), sous un
sous-dossier par nature, versionné et jamais écrasé. Ce dossier est gitignoré automatiquement à
la première exécution.

#### Hors scope (v1)

- Intégration Jira/Linear/GitHub Issues (ticket collé manuellement).
- Tests automatisés.
- Code review approfondie packagée dans le plugin (le skill `/code-review` global de
  l'utilisateur est suggéré en fin de flux).

Voir `plugins/daily-dev-flow/CLAUDE.md` pour les conventions internes et `PLAN.md` pour le cadrage
complet.

## Contribuer

Convention de commit : [Conventional Commits](https://www.conventionalcommits.org/) (cf. skill
`commit-convention` du plugin). Chaque plugin embarque son propre `CHANGELOG.md`.

## Changelog

Voir [`plugins/daily-dev-flow/CHANGELOG.md`](plugins/daily-dev-flow/CHANGELOG.md).

## Licence

Non définie pour l'instant.
