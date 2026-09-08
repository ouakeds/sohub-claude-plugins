# Changelog

Toutes les modifications notables du plugin `daily-dev-flow` sont documentées ici.
Le format suit [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
et ce projet respecte le [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- **`create-pr` embarque la documentation dans la PR.** Nouvelle étape 3 « Documentation
  embarquée » : avant les commits, la skill déduit du diff réel les mises à jour de
  `CHANGELOG.md` (entrées sous `Unreleased`, convention `generate-changelog`, mapping type de
  commit → catégorie) et de `README.md` (seulement sur changement structurant — installation,
  commande, API publique, configuration — convention `generate-readme`). Les plans de
  `.sohub-claude-plugin/plans/` servent à formuler l'impact utilisateur, jamais à affirmer ce
  que le diff ne montre pas. La mise à jour de doc rejoint le commit du changement qu'elle
  documente ; une refonte plus large fait son propre commit `docs:`.
- **Le flux `/ticket` apprend de ses accrocs : étape 7 « retex ».** Pendant l'exécution,
  l'orchestrateur consigne les signaux au fil de l'eau dans une nouvelle section
  `## Signaux retex` du fichier de plan (découpage modifié à la gate, sous-tâche `failed`,
  chaque tentative de la boucle de build, consigne corrective de l'utilisateur) — au même geste
  d'écriture que les statuts, et rien du tout sur un ticket sans accroc. En fin de ticket
  (`done` comme `failed`), si des signaux existent, l'étape 7 en déduit des suggestions typées
  (règle de convention, amélioration de découpage, contexte manquant), les propose une à une à
  l'utilisateur (`Accepter` / `Rejeter` / `Décider plus tard`) et les archive dans
  `.sohub-claude-plugin/retex.md` du projet cible. Une suggestion acceptée devient une ligne de
  `## Règles actives`, la seule section relue par l'étape 2 au découpage des tickets suivants —
  c'est ce qui ferme la boucle ; une rejetée reste dans `## Historique` pour ne pas être
  reproposée. Les enseignements portant sur le plugin lui-même ne sont pas stockés côté projet :
  ils sont signalés à l'utilisateur en une ligne. Rien n'est jamais appliqué automatiquement.
  Nouveau gabarit `templates/retex.template.md`.
- **Les agents de développement écrivent contre une convention de qualité, plus seulement contre
  le style du voisinage.** Nouveau dossier `conventions/` : `code-quality.md` (socle universel —
  nommage qui révèle l'intention, fonctions à un seul niveau d'abstraction et complexité
  cognitive ≤ 15, segmentation et sens des dépendances, état, erreurs, commentaires),
  `backend.md` et `frontend.md` (une couche chacune), et `lang/typescript.md`, `lang/java.md`,
  `lang/kotlin.md`. `backend-dev` et `frontend-dev` les lisent en tête de sous-tâche via
  `${CLAUDE_PLUGIN_ROOT}`, le fichier de langage étant choisi d'après `contexte_stack.langage`.
  Jusqu'ici, sur un projet neuf où il n'y a par définition aucun voisinage à imiter, « écris du
  code qu'un relecteur senior validerait » était la seule consigne de qualité disponible.
- Le dispositif est explicitement **subordonné au projet** : la préséance déclarée en tête du
  socle et rappelée dans les deux fiches d'agent est *code réel du voisinage > `docs/` et
  `CLAUDE.md` du projet cible > fichier de langage > socle*, et la convention porte sur le code
  qu'on écrit, jamais sur une passe de nettoyage du code alentour — un renommage opportuniste
  hors `fichiers_cibles` mettrait deux sous-tâches parallèles sur les mêmes fichiers. Un langage
  sans fichier `lang/` n'est pas un blocage. La section `## 6. Conventions` de
  `architecture.template.md` ne porte plus que ce qui est propre au projet, y compris ce qui
  contredit volontairement le socle.
- **Le backlog est généré au cadrage, et le fichier de plan devient le ticket.** Nouvelle skill
  `skills/flow/generate-backlog` : elle projette `docs/cadrage.md` et `docs/architecture.md` en
  **lots de travail** — un fichier numéroté par lot dans `.sohub-claude-plugin/plans/`, à l'état
  `todo`, portant le besoin, les critères de validation recopiés mot pour mot, les fichiers
  prévus et les dépendances — puis rend la vue `plans/BACKLOG.md`. `/new-project` l'invoque à
  son étape 12 et rend la main sur `/daily-dev-flow:ticket 0001`. Jusqu'ici, seule la
  fonctionnalité qu'on venait de taper existait sur disque : les autres items du périmètre
  n'avaient ni fichier, ni numéro, ni statut, et chaque `/ticket` re-dérivait le même découpage
  depuis les mêmes `docs/`.
- `/ticket` accepte un **numéro de lot** (`/daily-dev-flow:ticket 0003`) en plus du texte libre.
  En mode lot planifié, il ne crée pas de fichier : il **complète celui du lot** (cible
  technique, découpage, vagues, résultats) et fait passer son `Statut global` de `todo` à
  `in_progress` puis à `done`. Le besoin et les critères viennent du cadrage et ne sont jamais
  reformulés. Une **gate de dépendance** arrête le lancement d'un lot dont un `Dépend de:` n'est
  pas `done`, en nommant celui à faire d'abord.
- `todo` rejoint le vocabulaire de `Statut global` (`in_progress`, `done`, `failed`) : c'est le
  seul état qui signifie « écrit, jamais lancé ». L'étape 0 de `/ticket` ne le propose pas en
  reprise sur interruption.
- **Chaque lot déclare avec qui il est parallélisable.** Nouveau champ d'en-tête
  `Parallélisable avec:`, calculé par `generate-backlog` : deux lots qualifient quand aucun
  n'est ancêtre ou descendant de l'autre dans le graphe des `Dépend de` — la transitivité
  compte — **et** que leurs fichiers prévus sont disjoints. `Dépend de:` disait ce qui passe
  avant, jamais ce qui peut tourner en même temps ; cette relecture se refaisait de tête à
  chaque lancement. `BACKLOG.md` en tire une section **Vagues de lots** : ce qui est lançable
  ensemble, et ce que chaque vague débloque. Réserve énoncée dans la skill : le parallélisme
  porte sur les fichiers sources, pas sur l'outillage — deux `build-check` simultanés sur le
  même dossier peuvent se gêner.
- Nouveaux gabarits `templates/plan.template.md` — la forme d'un lot, écrite à deux mains
  (`generate-backlog` pour l'en-tête et le besoin, `/ticket` pour le découpage et les
  résultats) — et `templates/BACKLOG.template.md`, la forme de la vue d'ensemble : lots, vagues
  de lots, lots prêts à partir, items du périmètre pas encore couverts.

### Changed

- **L'agent `researcher` est renommé `planner`** (`agents/planner.md`), la clé de payload
  `contexte_researcher` devenant `contexte_planner` dans `backend-dev`, `frontend-dev` et
  `/ticket`. Le nom reflète son rôle réel en tête de flux — analyse et qualification du ticket
  (besoin fonctionnel, cible technique, ambiguïtés) — au-delà de la seule recherche. Le
  découpage et l'écriture du plan restent à l'orchestrateur `/ticket`, inchangés. Comportement
  et contrat de sortie identiques ; seuls le nom et la clé changent.

- **L'amorçage du projet passe de la vague 1 du premier `/ticket` à l'étape 11 de
  `/new-project`.** Poser le manifeste, les dépendances, les dossiers, les fichiers de contrats
  et la configuration de build ne demande aucun arbitrage : c'est la recopie de ce que le
  cadrage vient de fixer. En faire une sous-tâche coûtait un agent et une **vague entière**,
  derrière laquelle tout le reste du ticket était sérialisé. Le contrat partagé étant désormais
  sur disque avant le découpage, le premier ticket démarre directement avec ses sous-tâches
  backend et frontend **en parallèle en vague 1**. `/new-project` enchaîne l'installation et le
  build, ce qui rend le cadrage falsifiable au moment où il se ferme : une stack dont les
  briques ne s'installent pas ensemble tombe en une question, au lieu de tomber trois
  tentatives plus loin dans la boucle de correction du ticket 0001 sur un projet à moitié
  écrit.
- L'amorçage a maintenant une **règle de tri explicite** : il pose ce dont `docs/` fixe déjà la
  *forme* (manifeste, dossiers, contrats, configuration, point d'entrée), jamais un fichier
  portant un item du périmètre — « pas même vide, pas même provisoire ». Un plan réel avait fait
  écrire un `App.vue` provisoire par la sous-tâche d'amorçage puis réécrire par la sous-tâche
  frontend : travail payé deux fois, et surtout même fichier dans les `fichiers_cibles` de deux
  sous-tâches, ce qui interdit exactement le parallélisme recherché. L'étape 2 de `/ticket`
  traite désormais ce recouvrement comme un défaut de découpage, pas comme une dépendance à
  assumer.
- `/ticket`, mode greenfield : la règle « vague 1 = une unique sous-tâche d'amorçage » est
  remplacée par un amorçage **fait en ligne par l'orchestrateur** avant le découpage. Le cas ne
  se présente plus que sur un cadrage interrompu avant son étape 11 ou un projet cadré par une
  version antérieure du plugin — la couture par le `CLAUDE.md` du projet cible est inchangée.

- Gabarits de `templates/` : **le suffixe `.template.md` devient la règle pour les quatre**.
  `cadrage.md`, `architecture.md` et `decisions.md` deviennent `cadrage.template.md`,
  `architecture.template.md` et `decisions.template.md` ; `CLAUDE.template.md` ne change pas.
  Trois noms nus à côté d'un nom suffixé laissaient lire `templates/architecture.md` comme
  « l'architecture du plugin » alors que c'est un squelette à remplir, et forçaient à défendre
  le cas de `CLAUDE.template.md` comme une exception — à deux endroits. Le nom dit désormais
  seul qu'il s'agit d'une forme, et la raison du suffixe est énoncée une fois, dans le
  `CLAUDE.md` du plugin. Les fichiers **produits** dans le projet cible sont inchangés
  (`docs/cadrage.md`, `docs/architecture.md`, `docs/decisions.md`, `CLAUDE.md`) : aucun impact
  sur les projets déjà cadrés.

### Fixed

- `README.md` était confié à la skill `generate-readme` **depuis une sous-tâche** d'amorçage,
  alors que `backend-dev` et `frontend-dev` n'ont pas l'outil `Skill` dans leur frontmatter :
  la consigne était inexécutable par l'agent qui la recevait. Sur un run réel, l'orchestrateur
  l'a rattrapée à la main, au prix de deux recherches pour localiser la skill. Le README est
  désormais écrit par la commande elle-même, qui a l'outil.
- `/new-project`, étape 10 : la remise finale donnait la suite sous la forme `/ticket "<…>"`,
  qui ne résout pas telle quelle — une commande de plugin se tape préfixée de son plugin. La
  remise affiche désormais `/daily-dev-flow:ticket "<…>"` sur sa propre ligne, en bloc copiable,
  avec la fonctionnalité **écrite en clair** plutôt qu'un marqueur à remplacer, et une seule
  action à faire en clôture. Même correction dans `/ticket` en mode greenfield, qui renvoyait
  vers `/new-project` sans préfixe.

## [0.2.1] - 2026-09-07

### Changed
- `/new-project`, étape 3 : **une recherche qui ne renvoie rien n'établit plus une absence**.
  Un cadrage réel a conclu « aucune trace de sous-agent n'existe sur la machine » sur la foi
  d'un `grep` qui cherchait un motif espacé dans du JSON compact, un nom d'outil abandonné, et
  seulement à la racine des dossiers de session — alors que les traces existaient dans un
  sous-dossier, y compris pour le projet en cours de cadrage. Le résultat vide est monté en
  fait vérifié, puis en hypothèse structurante, puis en règle impérative dans le `CLAUDE.md`
  produit. Avant de conclure à une absence, l'étape 3 impose désormais deux gestes : faire
  ressortir un cas positif connu pour valider le motif, et élargir d'un cran (sous-dossiers,
  forme compacte d'un format sérialisé, nom actuel de l'outil ou du champ). Sans cas positif,
  la ligne redescend en question fermée plutôt qu'en constat.

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
