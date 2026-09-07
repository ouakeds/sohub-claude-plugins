# daily-dev-flow — conventions internes

Plugin autonome (roster d'agents propre, pas d'héritage d'un CLAUDE.md global) qui outille le
flux **ticket → analyse → développement → vérification de build**, générique multi-stack.

Voir `PLAN.md` (racine du dépôt) pour le cadrage complet. Ce plugin vit sous `plugins/daily-dev-flow/`
dans un dépôt qui héberge potentiellement plusieurs plugins (cf. `.claude-plugin/marketplace.json`
à la racine du dépôt).

## Structure des skills

`skills/` est organisé par catégorie (sous-dossiers déclarés explicitement et de façon
cumulative dans `.claude-plugin/plugin.json`, champ `skills` — cf. [doc officielle des
plugins](https://code.claude.com/docs/en/plugins-reference#plugin-directory-structure)) :

- `skills/flow/` — outillage interne consommé uniquement par `commands/ticket.md`
  (`detect-stack`, `build-check`). Jamais invoquées directement par l'utilisateur.
- `skills/documentation/` — génération/convention de documentation du projet cible
  (`generate-openapi`, `generate-readme`, `generate-changelog`).
- `skills/audit/` — détection + correction de non-conformités (`rgaa-check`,
  `security-audit`).

Toute nouvelle skill rejoint une catégorie existante ou en ouvre une nouvelle explicitement
déclarée dans `plugin.json` — jamais posée à plat directement sous `skills/`.

## Deux commandes, une couture

- `/new-project` — cadrage d'un projet neuf : conversation avec l'utilisateur pour qualifier le
  besoin métier, puis écriture de `docs/` et du `CLAUDE.md` du projet cible. Aucun code.
- `/ticket` — implémentation, sur un projet déjà cadré ou déjà existant.

La couture entre les deux est le `CLAUDE.md` du projet cible : `/ticket` lancé sans manifeste
mais avec un `CLAUDE.md` y lit la stack au lieu d'appeler `detect-stack`, et sa vague 1 amorce
le projet. Sans `CLAUDE.md`, il s'arrête et renvoie vers `/new-project` plutôt que de deviner.
Conséquence voulue : le découpage, le plan, les vagues et la boucle de build n'existent qu'à un
seul endroit (`commands/ticket.md`), jamais dupliqués dans un chemin d'amorçage parallèle.

**Pourquoi une commande et pas un agent « chef de produit »** : un sous-agent est isolé, son
seul canal de retour est son rapport final — il ne peut pas poser de question à l'utilisateur.
Le plugin encode déjà cette contrainte (`researcher` renvoie `ambiguites`, c'est `/ticket` qui
les pose). Une qualification qui challenge réellement est adaptative : la question suivante
dépend de la réponse précédente. Elle ne peut vivre que dans la boucle principale.

## Deux niveaux de documentation du projet cible

- `docs/` (racine du projet cible, versionné) — le détail : `cadrage.md` (besoin, utilisateurs,
  périmètre), `architecture.md` (stack, arborescence, conventions), `decisions.md` (journal
  append-only des arbitrages). Lu à la demande.
- `CLAUDE.md` (racine du projet cible) — le résumé impératif, budget ~40 lignes. Il est
  rechargé dans le contexte de chaque agent à chaque tour : une ligne inutile s'y paie des
  centaines de fois sur la vie du projet. Le détail va dans `docs/`, le résumé dans
  `CLAUDE.md`, rien aux deux endroits.

`CLAUDE.md` pointe vers `docs/` en **liens markdown simples**, jamais avec la syntaxe d'import
`@chemin` : `@docs/cadrage.md` injecterait le fichier entier à chaque tour et annulerait tout
le bénéfice de la découpe.

`README.md` n'est pas produit au cadrage (rien à installer à ce stade) mais au scaffold, via
`skills/documentation/generate-readme`.

## Garde-fous (hooks)

`hooks/hooks.json` déclare des hooks `PreToolUse` (mécanisme documenté dans
[Hooks](https://code.claude.com/docs/en/hooks) — deterministe, contrairement à une instruction
CLAUDE.md qui reste indicative) qui bloquent, avec `exit 2` (blocage non négociable) :

- **Tout commit/push git** — `Bash(git commit *)` et `Bash(git push *)` : ce plugin ne committe
  ni ne pousse jamais à la place de l'utilisateur, y compris en flux `--auto`.
- **Toute lecture de fichier d'environnement privé** — outil `Read` sur `.env*` (motif
  gitignore, matche à toute profondeur), plus les idiomes Bash les plus courants
  (`cat`/`head`/`tail .env*`) et le dump complet des variables (`env`/`printenv` sans argument).

**Limite connue** : les règles Bash sont des correspondances de préfixe littérales, pas des
motifs de chemin — un accès détourné (`cat ./.env`, `python -c "open('.env').read()"`, un
script qui lit le fichier lui-même) peut contourner ces hooks. Pour une garantie au niveau OS,
utiliser le [sandboxing](https://code.claude.com/docs/en/sandboxing) de Claude Code en plus de
ces hooks, qui restent la première ligne de défense mais pas une garantie absolue.

## Dépendance MCP

`agents/researcher.md` s'appuie sur le MCP `code-review-graph`, déclaré dans `.mcp.json` de ce
plugin (`uvx code-review-graph serve`) — nécessite `uv`/`uvx` installé sur la machine. En son
absence ou en cas d'échec de connexion, `researcher` dégrade explicitement vers un fallback
grep/glob (cf. sa fiche), le flux `/ticket` reste utilisable sans ce MCP, avec une recherche
de cible technique moins précise.

## Principes transverses

- **Générique multi-stack** : aucune convention de langage/framework hardcodée dans un agent ou
  une skill. La stack est fixée une fois par ticket — détectée par `skills/flow/detect-stack`
  sur un projet existant, arbitrée avec l'utilisateur par `/new-project` et lue dans le
  `CLAUDE.md` sur un projet neuf — puis propagée telle quelle, jamais redevinée.
- **Contrats petits et filtrés** : un sous-agent ne reçoit jamais un digest complet quand un
  sous-ensemble filtré suffit. Pas de fichier de contrat intermédiaire sur disque entre
  sous-tâches dépendantes — la transmission se fait en mémoire par l'orchestrateur
  (`commands/ticket.md`).
- **Pas d'hypothèse silencieuse** : une cible technique ambiguë, un contrat backend manquant,
  une incohérence bloquante → l'agent s'arrête et remonte (`ambiguites`, `statut: failed`),
  jamais une implémentation approximative "pour rendre quelque chose".
- **Rien d'écrit qui ne soit sourcé** : dans le cadrage produit par `/new-project`, chaque
  affirmation est soit déclarée par l'utilisateur, soit vérifiée sur la machine, soit marquée
  comme hypothèse. Le « raisonnable » non sourcé n'est pas une source — c'est le vecteur
  d'hallucination principal d'un document de cadrage, où un chiffre, un persona ou un critère
  de succès inventé se lit exactement comme un fait et finit implémenté comme tel.
- **Devoir de contradiction borné** : `/new-project` challenge une demande bancale (périmètre
  surdimensionné, complexité disproportionnée, solution existante) en deux phrases avec une
  alternative — mais une objection fabriquée pour avoir l'air critique est une hallucination de
  plus, et un choix maintenu par l'utilisateur est appliqué intégralement, consigné dans
  `docs/decisions.md`, jamais rejoué.
- **Modèle par tâche, pas par défaut uniforme** : `sonnet` pour tout ce qui exige du jugement
  (recherche, code) ; `haiku` réservé aux tâches mécaniques répétées (`build-verifier`, rappelé
  jusqu'à 3 fois par ticket — l'écart de coût cumulé y compte le plus).
- **`tools` en liste explicite** dans chaque frontmatter d'agent, jamais de wildcard.

## Persistance dans le projet cible

Tout artefact généré par le plugin (plans, audits, doc OpenAPI) est écrit dans
`.sohub-claude-plugin/` à la racine du **projet cible** (jamais dans le plugin lui-même), sous
un sous-dossier par nature (`plans/`, `audit/`, `documentations/`), avec un numéro de version
`NNNN` auto-incrémenté par sous-dossier — jamais réutilisé, jamais écrasé.
`.sohub-claude-plugin/` est gitignoré automatiquement à la première exécution (ajout d'une
ligne au `.gitignore` du projet cible si elle n'y est pas déjà).

**Exception** : le cadrage écrit par `/new-project` (`CLAUDE.md` et `docs/`) est posé à la
racine du projet cible et versionné avec lui. Ce sont des artefacts du projet, pas des traces
d'exécution du plugin : ils doivent être lus par les agents, relus par l'utilisateur et suivis
en revue. Un `CLAUDE.md` existant n'est jamais écrasé, et `docs/decisions.md` est append-only.

## Hors scope v1

- Intégration Jira/Linear/GitHub Issues (ticket collé manuellement).
- Tests automatisés.
- Code review approfondie packagée dans le plugin (le skill `/code-review` global de
  l'utilisateur est suggéré en fin de flux, jamais dupliqué en interne).
