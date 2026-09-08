---
name: create-pr
description: >
  Prépare une pull request de bout en bout : met à jour README.md et CHANGELOG.md d'après le
  diff réel (conventions generate-readme / generate-changelog), découpe et rédige les commits
  selon Conventional Commits, pousse la branche courante vers le remote, puis produit le titre
  et le corps de PR prêts à coller. À utiliser quand un travail est terminé et doit partir en
  revue. N'ouvre jamais la PR elle-même — aucun appel à `gh`, `glab` ou une API de forge.
---

# create-pr

Sources : [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/),
[Pro Git — Commit Guidelines](https://git-scm.com/book/en/v2/Distributed-Git-Contributing-to-a-Project),
[GitHub Docs — About pull requests](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests)
et [Linking a pull request to an issue](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue).

## Prérequis bloquant : le garde-fou git

Ce plugin interdit `git commit` et `git push` par défaut (`hooks/hooks.json`). Cette skill
**commit et pousse** : elle ne peut donc s'exécuter que si le garde-fou `git` est explicitement
désactivé pour le projet cible.

Vérifier avant toute autre chose la présence d'un `"guards": { "git": false }` résolu (cf.
`hooks/scripts/lib/guard-config.sh` : variable de session → `.sohub-claude-plugin.json` du
projet → `~/.claude/sohub-claude-plugin.json` → défaut actif). Si le hook refuse le commit
(`exit 2`), **s'arrêter et le dire** : donner à l'utilisateur les deux façons de l'autoriser
(fichier `.sohub-claude-plugin.json` versionné, ou `DAILY_DEV_FLOW_GUARD_GIT=off` pour la
session), et attendre sa décision.

Interdit absolu : contourner le garde-fou. Ni `git -c`, ni alias, ni script wrapper, ni
`GIT_DIR` détourné. Un garde-fou contourné une fois ne protège plus jamais personne.

## Convention de commit

### Structure

```
<type>[(scope)][!]: <description>

[corps]

[footers]
```

- **type** — obligatoire, en minuscules, dans la liste ci-dessous.
- **scope** — optionnel, entre parenthèses : la zone touchée (module, package, commande), pas
  un nom de fichier. Un scope inventé pour faire joli vaut mieux absent.
- **`!`** — placé avant le `:` pour signaler un breaking change (cumulable avec le footer
  `BREAKING CHANGE:`, qui, lui, en donne la raison).
- **description** — impératif présent (« ajoute », et non « ajouté » ni « ajout de »), pas de
  majuscule initiale, **pas de point final**, ≤ 50 caractères (72 maximum).
- **corps** — optionnel, séparé par une ligne vide, lignes coupées à 72 caractères. Il explique
  **quoi et pourquoi**, jamais comment : le comment est déjà dans le diff.
- **footers** — `BREAKING CHANGE: <raison>`, `Refs: #123`, `Co-Authored-By: ...`. N'ajouter
  que des trailers déjà en usage dans l'historique du dépôt, et **jamais d'identifiant de
  session, d'URL de conversation ou de lien vers un outil interne** : le message de commit est
  public et immuable, il ne transporte que ce qui aide à relire le code dans dix ans.

### Types

| Type       | Usage                                                              |
|------------|--------------------------------------------------------------------|
| `feat`     | nouvelle fonctionnalité (MINOR en SemVer)                          |
| `fix`      | correction de bug (PATCH en SemVer)                                |
| `docs`     | documentation seule                                                |
| `style`    | formatage sans effet sur le comportement (espaces, points-virgules)|
| `refactor` | réécriture sans changement de comportement ni de fonctionnalité    |
| `perf`     | amélioration de performance                                        |
| `test`     | ajout ou correction de tests                                       |
| `build`    | système de build, dépendances                                      |
| `ci`       | configuration d'intégration continue                               |
| `chore`    | tâche de maintenance sans impact sur le code de production         |
| `revert`   | annulation d'un commit précédent                                   |

`feat` et `fix` sont les seuls types dont la sémantique est normalisée par la spécification ;
les autres viennent de la convention Angular, très largement adoptée. **Toujours vérifier
d'abord l'historique du dépôt** (`git log --oneline -30`) : si le projet utilise déjà une autre
liste de types, une autre langue de description ou des trailers particuliers, c'est sa
convention qui gagne, pas celle-ci.

### Découpage

- Un commit = **un changement cohérent**, relisible seul et réversible seul. Un `refactor` et
  la `feat` qu'il prépare sont deux commits, pas un.
- Jamais de `git add -A` aveugle : inspecter `git status --porcelain` puis stager
  explicitement les chemins voulus.
- Ne jamais committer : un fichier d'environnement privé ou tout autre secret, les artefacts de
  build, `.sohub-claude-plugin/` (gitignoré), les fichiers de plan ou de scratch. En cas de
  doute sur un fichier non suivi, demander plutôt que de l'inclure.
- Si le travail en cours ne tient pas en un message honnête, c'est le découpage qui est
  mauvais, pas le message : re-stager par lots (`git add -p`) plutôt qu'écrire un
  `chore: divers`.

## Flux d'exécution

### 1. État du dépôt

```bash
git branch --show-current
git status --porcelain
git log --oneline -30
```

- **Branche par défaut (`main`/`master`) → arrêt.** Ne jamais committer ni pousser dessus.
  Proposer un nom de branche dérivé du travail (`<type>/<description-kebab>`, ex.
  `feat/export-csv`) et laisser l'utilisateur valider ou la créer.
- Rien à committer **et** rien à pousser (arbre propre, branche à jour) → le dire et
  s'arrêter, sans commit vide.

### 2. Revue du diff avant de rédiger

`git diff` et `git diff --staged` sur l'intégralité des changements — le message se déduit du
diff réel, jamais d'un souvenir de ce qui a été fait dans la session. Relire aussi les fichiers
non suivis apparus (lignes `??` de `git status --porcelain`) : ce sont eux qui font entrer un
secret ou un artefact dans l'historique.

### 3. Documentation embarquée (CHANGELOG.md, README.md)

La PR part avec sa documentation : une entrée de changelog écrite plus tard, dans une autre
session, se rédige de mémoire ; celle écrite ici se déduit du diff qu'on vient de relire.

- **CHANGELOG.md** — si le diff porte un changement notable pour l'utilisateur du projet,
  ajouter les entrées sous `## [Unreleased]` selon la convention
  `skills/documentation/generate-changelog` : structure Keep a Changelog, mapping type de
  commit → catégorie (`feat` → Added, ou Changed si extension d'existant ; `fix` → Fixed ;
  breaking → Changed avec mention explicite ; `refactor`/`style`/`chore`/`test` n'y entrent
  pas). Reformuler l'impact du point de vue de l'utilisateur du projet, jamais coller un
  message de commit. Fichier absent et changement notable → le créer depuis la structure de la
  convention.
- **README.md** — uniquement sur changement structurant visible dans le diff : nouveau
  prérequis ou étape d'installation, nouvelle commande, changement d'API publique ou de
  configuration. Mettre à jour les seules sections concernées, selon la convention
  `skills/documentation/generate-readme` ; un diff qui ne change pas l'usage ne touche pas au
  README. Fichier absent → le créer (c'est le cas « doit être créé » de la convention).
- **Les plans comme matière, le diff comme autorité** : si le travail vient d'un lot de
  `.sohub-claude-plugin/plans/` (le plan `in_progress`/`done` le plus récent), ses sections
  `Besoin fonctionnel` et `## Résultats` donnent la bonne formulation de l'impact utilisateur —
  mais rien ne s'écrit dans la doc que le diff ne montre pas : un plan annonce, le diff prouve.
- **Découpage** : la mise à jour de doc rejoint le commit du changement qu'elle documente —
  l'entrée de changelog rend le commit relisible seul. Une refonte documentaire plus large que
  le changement fait son propre commit `docs:`.

### 4. Commits

Un message multi-ligne s'écrit depuis un fichier ou l'entrée standard (`git commit -F`), jamais
par empilement de `-m` :

```
feat(export): ajoute l'export CSV des commandes

Le tableau de bord ne permettait qu'une lecture à l'écran, ce qui obligeait
les équipes support à ressaisir les données dans leur outil de facturation.

Refs: #412
```

Après chaque commit, vérifier le résultat (`git log -1 --stat`) et corriger un message fautif
tant qu'il n'est pas poussé (`git commit --amend`) — jamais après.

### 5. Push sur la branche courante

```bash
git push -u origin HEAD
```

- `HEAD` plutôt que le nom de la branche écrit à la main : impossible de pousser par erreur sur
  une autre branche que celle sur laquelle on est.
- `-u` fixe l'upstream au premier push ; il est sans effet ensuite.
- **Jamais** de `--force`. Si le push est rejeté (non-fast-forward), s'arrêter et remonter la
  divergence à l'utilisateur : rebaser ou merger est sa décision, pas celle de la skill.
- Pas de remote configuré → s'arrêter et le dire, ne pas en inventer un.

### 6. Rédaction de la PR

Si le dépôt fournit `.github/PULL_REQUEST_TEMPLATE.md` (ou
`.github/pull_request_template.md`, ou un fichier sous `.github/PULL_REQUEST_TEMPLATE/`),
**c'est ce gabarit qui est rempli**, pas celui ci-dessous.

**Titre** — même convention que le commit (`<type>[(scope)][!]: <description>`). Ce n'est pas
une coquetterie : en merge par squash, le titre de la PR devient le message du commit de merge,
donc l'historique de la branche par défaut.

**Corps** — gabarit par défaut :

```markdown
## Contexte

Pourquoi ce changement existe : le problème, la demande ou le ticket à l'origine.
Deux ou trois phrases, lisibles par quelqu'un qui découvre le sujet.

## Changements

- Ce qui change, du point de vue du comportement observable.
- Un point par changement significatif, pas un par fichier touché.

## Comment tester

1. Étapes reproductibles pour vérifier le comportement.
2. Commande de build/test à lancer, résultat attendu.

## Impact et risques

Migration, breaking change, effet de bord, configuration à ajouter, ou « aucun ».

Closes #412
```

Règles de rédaction :

- Le mot-clé de fermeture (`Closes`/`Fixes`/`Resolves #123`) est le seul moyen officiel de lier
  la PR à son issue ; il doit être dans le **corps**, pas dans le titre.
- Sections vides supprimées, pas laissées avec « N/A » — sauf « Impact et risques », qui reste
  et vaut alors « aucun » explicite.
- Un changement d'interface visible → captures ou courte vidéo avant/après.
- Une PR reste petite : au-delà de ~400 lignes de diff utile, proposer un découpage en
  plusieurs PR plutôt que de rédiger un corps qui compense.
- Travail incomplet → le signaler comme brouillon (draft) dans la remise, avec ce qui reste.
- Ne rien affirmer d'invérifié dans le corps : si les tests n'ont pas été lancés, la section
  « Comment tester » donne la commande, elle ne prétend pas qu'elle est passée.
- Aucun identifiant de session, URL de conversation ou lien vers un outil interne, ni dans le
  corps ni dans les commits que la PR embarque — même règle que pour les trailers.

### 7. Remise à l'utilisateur

Sortie finale, en un seul bloc :

1. Les commits créés (`git log --oneline <base>..HEAD`).
2. La branche poussée et son upstream.
3. Le **titre** de la PR, sur une ligne, copiable tel quel.
4. Le **corps** de la PR, dans un bloc de code markdown, copiable tel quel.
5. La base visée (branche de destination), si elle n'est pas la branche par défaut.

L'ouverture de la PR revient à l'utilisateur. Si l'URL du remote est lisible
(`git remote get-url origin`), la donner en clair pour lui épargner la navigation — sans jamais
appeler d'outil de forge pour créer quoi que ce soit.

## Ce que cette skill ne fait pas

- **N'ouvre pas la PR** : pas de `gh pr create`, pas de `glab mr create`, pas d'appel d'API.
  La création reste un geste de l'utilisateur, sous son identité.
- Ne fusionne rien, ne rebase rien, ne force aucun push, ne supprime aucune branche.
- Ne contourne jamais le garde-fou git ; en cas de refus du hook, elle s'arrête.
- Ne relit pas le code sur le fond (cf. `/code-review`) et ne lance pas les tests ni le build
  (cf. `skills/flow/build-check`) : elle rapporte leur état, elle ne le décrète pas.
- Ne porte pas les conventions de documentation : la forme du `CHANGELOG.md` et du `README.md`
  vit dans `skills/documentation/generate-changelog` et `generate-readme` — cette skill les
  applique, elle ne les duplique pas. Et elle ne documente rien que le diff ne montre pas.
