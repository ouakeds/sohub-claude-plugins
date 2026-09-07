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
- `skills/git/` — livraison du travail (`create-pr`) : commits conventionnels, push de la
  branche courante, rédaction du titre et du corps de PR. Seule famille de skills qui écrit
  dans l'historique Git, donc la seule soumise au garde-fou `git` (elle s'arrête si le hook
  refuse, ne le contourne jamais). L'ouverture de la PR reste un geste de l'utilisateur : pas
  d'appel `gh`/`glab`, une publication sous l'identité de quelqu'un n'est pas automatisable
  sans son geste.

Toute nouvelle skill rejoint une catégorie existante ou en ouvre une nouvelle explicitement
déclarée dans `plugin.json` — jamais posée à plat directement sous `skills/`.

## Gabarits du cadrage

`templates/` porte la forme des quatre fichiers écrits par `/new-project` dans le projet cible :
`cadrage.md`, `architecture.md`, `decisions.md`, `CLAUDE.template.md`. Ce sont des **squelettes
nus** — titres, ordre des sections, forme des tableaux, marqueurs `<…>` — sans consigne de
remplissage : les consignes vivent dans `commands/new-project.md`, à un seul endroit.

Deux raisons à ces fichiers plutôt qu'un exemple recopié dans la commande. D'abord la
**structure identique d'un projet à l'autre** : un agent qui ouvre n'importe quel
`docs/architecture.md` sait où trouver les contrats sans lire le fichier en entier. Ensuite le
**coût de contexte** : la forme n'occupe la fenêtre que du fichier qu'on écrit, au lieu d'être
rechargée avec la commande à chaque invocation.

`CLAUDE.template.md` ne s'appelle pas `CLAUDE.md` **exprès** : un fichier de ce nom dans
l'arborescence du plugin serait chargé comme mémoire de répertoire dès qu'on travaille dedans.

Un gabarit se remplit, il ne s'étend pas : les sections déclarées optionnelles se suppriment
quand elles sont vides, aucune section n'est ajoutée. Changer la forme, c'est changer le
gabarit — pas l'improviser dans un projet.

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
  périmètre, **critères de validation**), `architecture.md` (stack, modules, **contrats**,
  arborescence au fichier près, conventions), `decisions.md` (journal append-only des
  arbitrages). Lu à la demande — **sauf au premier `/ticket`** sur un projet cadré et non
  amorcé, où `architecture.md` et les critères de validation sont la matière même du découpage.
  `architecture.md` est un plan d'implémentation, pas un survol : tout ce qui traverse une
  frontière de module (types partagés, endpoints, événements, format de fichier) y est écrit en
  dur, sans quoi deux agents lancés en parallèle inventent deux versions du même échange.
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
CLAUDE.md qui reste indicative) qui bloquent, avec `exit 2` :

- **Tout commit/push git** — `Bash(git commit *)` et `Bash(git push *)` : par défaut, ce plugin
  ne committe ni ne pousse jamais à la place de l'utilisateur, y compris en flux `--auto`.
  Seul garde-fou **désactivable** (cf. section suivante).
- **Toute lecture de fichier d'environnement privé** — outil `Read` sur un `.env*`, les idiomes
  Bash de lecture (`cat`/`head`/`tail`/`less`/`more`/`od`/`xxd`… sur un `.env*`) et le dump
  complet des variables (`env`/`printenv` sans argument, y compris en substitution ou dans un
  corps de boucle). **Non désactivable** : une fuite de secret est irréversible et ne se
  rattrape pas par un `git revert`, contrairement à un commit de trop.

**Les deux hooks d'environnement n'ont pas de filtre `if`** : ils analysent eux-mêmes la
commande ou le chemin du payload `PreToolUse`. C'est délibéré. Une règle de correspondance ne
sait pas faire ce travail : `Bash(cat .env*)` est un préfixe littéral qui rate
`cat config/.env.local`, et une règle **exacte sans joker** comme `Bash(env)` se déclenche sur
des commandes qui ne contiennent aucun `env` — toute boucle `for … in … ; do … done` était
refusée. Un garde-fou qui refuse au hasard finit désactivé ; celui-ci décide sur la commande
réelle. Les scripts découpent la ligne sur `;`, `&&`, `||`, `|`, `&` et les ouvertures de
sous-shell, retirent les mots qui précèdent une commande sans en changer la nature (`do`,
`then`, `sudo`, `time`…), puis testent le nom réel et le *basename* de chaque argument — d'où
`env FOO=bar cmd` autorisé (il ne dumpe rien) et `cat config/.env.local` refusé.

### Configuration des garde-fous

Le garde-fou git est optionnel parce qu'un garde-fou qu'on ne peut que contourner ne protège
plus personne — il apprend juste à le contourner (`git -c ...`, un script wrapper). Sur
l'outillage interne ou un dépôt solo, l'utilisateur veut explicitement que le flux aille
jusqu'au commit ; mieux vaut un interrupteur déclaré, versionné et relisible en revue.

L'état est résolu par `hooks/scripts/lib/guard-config.sh`, **premier trouvé gagne** :

1. Variable `DAILY_DEV_FLOW_GUARD_GIT` exportée dans la session (`on`/`off`, `1`/`0`,
   `true`/`false`) — échappatoire ponctuelle, ne survit pas à la session.
2. `.sohub-claude-plugin.json` du projet cible, cherché depuis le `cwd` de la session puis en
   remontant l'arborescence — la config la plus proche gagne. Fichier **versionné**, à ne pas
   confondre avec le dossier `.sohub-claude-plugin/` des artefacts, lui gitignoré.
3. `~/.claude/sohub-claude-plugin.json` — préférence utilisateur, tous projets confondus.
4. Défaut : **garde-fou actif**. Une clé absente vaut `true`, un fichier illisible ou un JSON
   cassé retombe sur le défaut : la seule façon de désactiver est de l'écrire explicitement.

```json
{ "guards": { "git": false } }
```

Le champ `guards` est le point d'extension : un nouveau garde-fou désactivable se branche avec
`guard_is_enabled <nom> || exit 0` en tête de son script, sans toucher à `hooks.json`.

**Piège jq** : `.guards[$g] // empty` est inutilisable pour lire ces clés — jq traite `false`
comme une absence, or `false` est justement la valeur qui désactive. La lib teste la présence
de la clé (`has($g)`). Le repli sans jq n'utilise pas non plus l'alternance `\(true\|false\)`,
absente du sed BSD de macOS.

**Limite connue** : l'analyse porte sur le texte de la commande, pas sur ce qu'elle fait
réellement. Un accès indirect (`python -c "open('.env').read()"`, un script qui lit le fichier
lui-même, une variable qui porte le chemin) passe encore. Sans `jq` sur la machine, la lecture
du payload retombe sur une extraction `sed` approximative : une commande contenant des
guillemets échappés peut échapper au garde-fou — installer `jq` est la façon la moins coûteuse
de fermer ce trou. Pour une garantie au niveau OS,
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
- **La stack n'est jamais tranchée seule** : dans `/new-project`, langage, framework front et
  back, librairie d'interface, gestionnaire de paquets et mode de lancement font chacun l'objet
  d'une question fermée. Le skill propose (options filtrées par ce qui est installé sur la
  machine, recommandation en premier avec sa raison), l'utilisateur tranche. « L'utilisateur
  n'ayant pas imposé de stack, j'arbitre » est la formule interdite : elle a produit un projet
  entier bâti sur un choix que personne n'avait validé.
- **Un cadrage se ferme, il ne se plafonne pas** : `/new-project` boucle sur une liste de sept
  lignes (usage, périmètre, données, stack, critères de validation, distribution, points
  d'architecture structurants) jusqu'à ce que chacune soit déclarée ou vérifiée. Un plafond de
  tours de questions ne fait pas gagner du temps, il déplace le coût sur `/ticket`, qui devine.
- **Chaque item du périmètre v1 porte un critère de validation observable** — un geste, un
  résultat constatable. Le skill les rédige à partir de l'usage décrit puis les fait valider en
  bloc, ce qui les rend *déclarés* au sens de la règle de sourçage. Sans eux, aucune sous-tâche
  de `/ticket` ne sait à quoi ressemble « fini ».
- **Zéro hypothèse structurante** : une hypothèse dont dépend un choix d'implémentation (seuil,
  transport, format d'échange, cible externe, comportement d'erreur) est vérifiée ou posée en
  question. Ne restent marquées `> Hypothèse` que les faits externes non vérifiables, et chacune
  porte sa **conduite à tenir** — sans quoi elle reste un trou que le premier agent bouchera
  seul.
- **Contrats petits et filtrés** : un sous-agent ne reçoit jamais un digest complet quand un
  sous-ensemble filtré suffit. Le filtrage doit rester **mécanique** — `researcher` rattache
  chaque note aux fichiers qu'elle concerne, `/ticket` intersecte avec les `fichiers_cibles` et
  transmet tel quel, sans reformuler (une paraphrase intermédiaire perd des contraintes et en
  invente).
- **Le plan est le support de reprise, donc il porte les `resume`** : les contrats produits par
  les sous-tâches `done` sont écrits dans le fichier de plan, pas seulement gardés en mémoire
  par l'orchestrateur. C'est la seule chose qui survit à un `/clear` ou à une fermeture de
  session ; sans elle, une reprise en vague 2 repart sans le contrat de la vague 1. Il n'y a
  pour autant pas de fichier de contrat *séparé* : c'est une section du plan, pas un artefact
  de plus.
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
