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
- Skill `create-pr` (nouvelle catégorie `skills/git/`) : découpe et rédige les commits selon
  Conventional Commits 1.0.0 (+ règles de rédaction Pro Git : impératif, 50/72, quoi et
  pourquoi plutôt que comment), pousse la branche courante (`git push -u origin HEAD`, jamais
  `--force`, jamais sur la branche par défaut) et produit le titre et le corps de PR selon les
  conventions GitHub — gabarit `.github/PULL_REQUEST_TEMPLATE.md` du dépôt prioritaire sur le
  sien, mot-clé de fermeture dans le corps. Elle **n'ouvre pas** la PR (aucun appel `gh`,
  `glab` ou API) : la publication reste un geste de l'utilisateur, sous son identité. Elle
  s'arrête si le garde-fou `git` refuse le commit, sans jamais le contourner. Comble au passage
  les renvois de `README.md`, `generate-readme` et `generate-changelog` vers une skill
  `commit-convention` qui n'avait jamais été écrite. Les trailers de commit sont bornés à ceux
  déjà en usage dans le dépôt : ni identifiant de session, ni URL de conversation, ni lien vers
  un outil interne, ni dans les commits ni dans le corps de la PR.

### Fixed
- Reprise après interruption : le `resume` de chaque sous-tâche `done` est désormais écrit dans
  la section `## Résultats` du fichier de plan. Il n'existait qu'en mémoire de session, si bien
  qu'une reprise en vague 2 après un `/clear` repartait sans le `contexte_dependance` produit
  par la vague 1.
- Contrat `researcher` : `notes` passe d'une chaîne unique à une liste
  `{fichiers, note}` — le filtrage par `fichiers_cibles` demandé à `/ticket` était impossible
  sur un paragraphe, qui finissait renvoyé en entier à chaque sous-tâche. Chaque note doit
  désormais se rattacher à un fichier réellement consulté.
- Agents `backend-dev`/`frontend-dev` : section « projet en amorçage ». Leurs règles (lire le
  voisinage, réutiliser les dépendances en place, `failed` sur fichier cible inexistant)
  bloquaient la vague 1 d'un projet neuf, où tous les fichiers cibles sont à créer.
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
- Garde-fou git rendu **optionnel** : `hooks/scripts/lib/guard-config.sh` résout son état dans
  l'ordre variable de session `DAILY_DEV_FLOW_GUARD_GIT` → `.sohub-claude-plugin.json` du projet
  cible (cherché depuis le `cwd` puis en remontant l'arborescence, le plus proche gagne) →
  `~/.claude/sohub-claude-plugin.json` → défaut actif. Une clé absente, un fichier illisible ou
  un JSON cassé retombent sur « actif » : la désactivation ne peut être qu'explicite. Motif :
  un garde-fou qu'on ne peut que contourner n'en est plus un, et le flux `/ticket` doit pouvoir
  aller jusqu'au commit sur l'outillage interne ou un dépôt solo. Le garde-fou d'environnement
  reste non désactivable — une fuite de secret ne se rattrape pas par un `git revert`.
- `.sohub-claude-plugin.example.json` à la racine du dépôt : modèle commenté du fichier de
  configuration, à ne pas confondre avec le dossier `.sohub-claude-plugin/` des artefacts
  générés, lui gitignoré dans le projet cible.

## [0.1.0] - 2026-09-07

### Added
- Scaffold initial du plugin `daily-dev-flow` : commande `/ticket` orchestrant le flux
  ticket → analyse → développement → vérification de build.
- Agents `researcher`, `backend-dev`, `frontend-dev`, `build-verifier`.
- Skills `detect-stack`, `build-check`, `openapi-doc`, `rgaa-check`, `security-audit`.
- Intégration MCP `code-review-graph` pour l'agent `researcher`, avec fallback grep/glob.

[Unreleased]: https://github.com/ouakeds/sohub-claude-plugins/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/ouakeds/sohub-claude-plugins/releases/tag/v0.1.0
