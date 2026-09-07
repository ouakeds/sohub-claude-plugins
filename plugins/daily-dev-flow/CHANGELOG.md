# Changelog

Toutes les modifications notables du plugin `daily-dev-flow` sont documentées ici.
Le format suit [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
et ce projet respecte le [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.2.0] - 2026-09-07

### Added
- Commande `/new-project` : cadrage conversationnel d'un projet neuf, mené jusqu'à **cadrage
  fermé**. Une *liste de fermeture* de sept lignes (usage métier, périmètre, données, stack,
  critères de validation, distribution, points d'architecture structurants) pilote la
  conversation : on questionne tant qu'une ligne n'est ni déclarée par l'utilisateur ni
  vérifiée sur la machine, sans plafond de tours. Produit le cadrage sur deux niveaux —
  `docs/cadrage.md`, `docs/architecture.md`, `docs/decisions.md` pour le détail versionné, et un
  `CLAUDE.md` résumé sous budget (~40 lignes) puisqu'il est rechargé dans le contexte de chaque
  agent à chaque tour. Aucun code produit. Une commande et non un agent : un sous-agent isolé ne
  peut pas challenger l'utilisateur en conversation.
- Dossier `templates/` : gabarits des quatre fichiers de cadrage écrits dans le projet cible
  (`cadrage.md`, `architecture.md`, `decisions.md`, `CLAUDE.template.md`). Squelettes nus —
  titres, ordre des sections, forme des tableaux, marqueurs `<…>` — sans consigne de
  remplissage, celles-ci restant dans `commands/new-project.md` pour n'exister qu'à un seul
  endroit. Objectif : une structure identique d'un projet à l'autre, pour qu'un agent sache où
  regarder sans lire le fichier en entier. `CLAUDE.template.md` porte ce nom pour ne pas être
  chargé comme mémoire de répertoire depuis le plugin.
- Étape **stack** obligatoire dans `/new-project` : langage, framework front et outil de build,
  framework back, **librairie d'interface / graphique**, gestion d'état, gestionnaire de paquets
  et mode de lancement font chacun l'objet d'une question fermée. Le skill propose (options
  filtrées par ce qui est réellement installé, recommandation en premier avec sa raison),
  l'utilisateur tranche ; ce qui est structurellement contraint est présenté comme contrainte,
  avec sa raison, et ne se pose pas en question. Chaque brique donne une entrée dans
  `docs/decisions.md`.
- **Critères de validation** dans `/new-project` : chaque item du périmètre v1 porte un critère
  observable (un geste, un résultat constatable), rédigé à partir de l'usage décrit puis soumis
  en bloc à validation. `Non défini à ce stade` n'est plus recevable sur un item de périmètre —
  seulement sur les critères de succès produit, que seul l'utilisateur peut fixer. `/ticket`
  reprend ces critères dans son plan : c'est ce qui dit quand une sous-tâche est finie.
- **Gate de validation** avant écriture dans `/new-project` : fiche condensée (périmètre, stack,
  critères, contrats, hypothèses résiduelles, décisions différées) soumise à l'utilisateur, sur
  le modèle de la gate de plan de `/ticket`. `--auto` la saute et consigne chaque arbitrage.
- `docs/architecture.md` devient un **plan d'implémentation** : modules et responsabilités,
  **contrats** écrits en dur pour tout ce qui traverse une frontière de module (types partagés,
  endpoints, événements, formats de fichier), arborescence au fichier près, données et
  intégrations avec leur preuve de lecture. Sans cette section, deux agents lancés en parallèle
  par `/ticket` produisent deux versions divergentes du même échange.
- Règle de sourçage dans `/new-project` : toute affirmation du cadrage est déclarée, vérifiée
  ou marquée `> Hypothèse` — pas de quatrième catégorie. Une proposition rédigée par le skill
  et validée explicitement par l'utilisateur compte comme *déclarée*. Interdits explicites sur
  les chiffres, personas, capacités techniques, besoins déduits non demandés et choix de stack
  tranchés seul ; étape de vérification en lecture seule des sources de données avant écriture.
- **Zéro hypothèse structurante** dans `/new-project` : une hypothèse dont dépend un choix
  d'implémentation (seuil, transport, format d'échange, cible externe, comportement d'erreur)
  est vérifiée ou posée en question fermée. Ne subsistent en `> Hypothèse` que les faits
  externes non vérifiables, chacun portant sa **conduite à tenir**. La section « Questions
  ouvertes » du cadrage est remplacée par `## Décisions différées`, où chaque entrée porte son
  déclencheur et la garantie qu'elle ne bloque aucun item du périmètre v1.
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
- Garde-fous d'environnement : `deny-env-dump.sh` et `deny-env-read.sh` refusaient
  **inconditionnellement**, en faisant confiance au filtre `if` de `hooks.json`. Or une règle
  exacte sans joker comme `Bash(env)` se déclenche sur des commandes qui ne contiennent aucun
  `env` — toute boucle `for … in … ; do … done` était refusée — tandis que la règle de préfixe
  `Bash(cat .env*)` ratait `cat config/.env.local`. Les deux scripts analysent désormais
  eux-mêmes la commande (ou le `file_path` de l'outil `Read`) : découpe sur `;`, `&&`, `||`,
  `|`, `&` et ouvertures de sous-shell, retrait des mots qui ne changent pas la nature d'une
  commande (`do`, `then`, `sudo`, `time`…), test du nom réel et du *basename* de chaque
  argument. `env FOO=bar cmd` passe (il ne dumpe rien), `echo $(env)` et
  `cat config/.env.local` sont refusés. Le filtre `if` est retiré des entrées d'environnement
  de `hooks.json` : le script décide seul, sur la commande réelle. Moins de faux positifs *et*
  moins de faux négatifs — le garde-fou reste non désactivable.
- `hooks/scripts/lib/guard-config.sh` : le payload `PreToolUse` n'arrive qu'une fois sur stdin
  et était lu depuis une substitution de commande, donc dans un sous-shell qui le consommait
  sans rien remonter au parent — un script lisant deux champs n'obtenait le second jamais. Le
  payload est désormais mis en cache dès le sourçage, dans le shell principal, et exposé par
  `ddf_tool_command`, `ddf_tool_file_path` et `ddf_command_segments`.
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
- `/ticket`, mode greenfield sur projet cadré : `docs/architecture.md` et la section
  `Critères de validation` de `docs/cadrage.md` ne sont plus une lecture optionnelle mais la
  matière du découpage — lues une fois au premier ticket. Les contrats en sont recopiés tels
  quels dans le payload des sous-tâches qui les produisent ou les consomment, et le critère de
  validation de l'item servi entre dans le plan. L'interdiction de recopier `CLAUDE.md` et
  `docs/` en bloc reste, ces deux exceptions près.
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

[Unreleased]: https://github.com/ouakeds/sohub-claude-plugins/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/ouakeds/sohub-claude-plugins/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/ouakeds/sohub-claude-plugins/releases/tag/v0.1.0
