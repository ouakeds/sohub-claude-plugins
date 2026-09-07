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
  (`openapi-doc`, `readme-convention`, `changelog-convention`).
- `skills/audit/` — détection + correction de non-conformités (`rgaa-check`,
  `security-audit`).

Toute nouvelle skill rejoint une catégorie existante ou en ouvre une nouvelle explicitement
déclarée dans `plugin.json` — jamais posée à plat directement sous `skills/`.

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
  une skill. La stack est détectée une fois par ticket (`skills/flow/detect-stack`) et propagée, pas
  redevinée.
- **Contrats petits et filtrés** : un sous-agent ne reçoit jamais un digest complet quand un
  sous-ensemble filtré suffit. Pas de fichier de contrat intermédiaire sur disque entre
  sous-tâches dépendantes — la transmission se fait en mémoire par l'orchestrateur
  (`commands/ticket.md`).
- **Pas d'hypothèse silencieuse** : une cible technique ambiguë, un contrat backend manquant,
  une incohérence bloquante → l'agent s'arrête et remonte (`ambiguites`, `statut: failed`),
  jamais une implémentation approximative "pour rendre quelque chose".
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

## Hors scope v1

- Intégration Jira/Linear/GitHub Issues (ticket collé manuellement).
- Tests automatisés.
- Code review approfondie packagée dans le plugin (le skill `/code-review` global de
  l'utilisateur est suggéré en fin de flux, jamais dupliqué en interne).
