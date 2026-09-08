---
name: generate-backlog
description: >
  Projette le cadrage d'un projet (docs/cadrage.md + docs/architecture.md) en lots de travail
  numérotés dans .sohub-claude-plugin/plans/, un fichier par lot, et régénère la vue
  d'ensemble BACKLOG.md. Invoquée par /new-project à la fin du cadrage, par /ticket à chaque
  changement de statut, et directement par l'utilisateur après une évolution du périmètre.
user-invocable: true
---

# generate-backlog

Le cadrage décrit déjà tout le travail : chaque item du `Dans` de `docs/cadrage.md` porte son
critère de validation observable, et l'arborescence de `docs/architecture.md` dit quel fichier
sert quel item. Tant que ce travail n'existe que dans une prose, l'utilisateur n'a rien à
suivre et chaque `/ticket` re-dérive le même découpage depuis les mêmes fichiers.

Cette skill fait la projection une fois : **un fichier par lot**, numéroté, avec son statut et
ses dépendances, dans `.sohub-claude-plugin/plans/` du projet cible.

**Le fichier de plan *est* le ticket.** Il n'y a pas de dossier `tickets/` à côté : le même
fichier est écrit ici à l'état `todo` (besoin, critères, fichiers prévus), puis complété par
`/ticket` au lancement (découpage, vagues) et pendant l'exécution (résultats). Un artefact, un
numéro, un cycle de vie.

## Deux modes

| Mode | Déclencheur | Ce qu'il fait |
|---|---|---|
| **Génération** | `/new-project` en fin de cadrage ; l'utilisateur après une évolution du périmètre | Lit le cadrage, constitue les lots, écrit les fichiers manquants, rend la vue |
| **Rafraîchissement** | `/ticket` à chaque changement de `Statut global` | Relit les en-têtes des plans et réécrit `BACKLOG.md` uniquement |

Le rafraîchissement est un mode à part entière pour que la forme de la vue n'existe qu'à un
seul endroit : `/ticket` ne rend jamais ce tableau lui-même.

## Mode génération

### Entrées — le cadrage, rien d'autre

- `docs/cadrage.md` : la liste `Dans` et, pour chaque item, son critère de validation.
- `docs/architecture.md` : la section Contrats et l'arborescence au fichier près.

Si l'un des deux manque, **arrête-toi** : sans périmètre ou sans arborescence, les lots seraient
inventés. Renvoie vers `/daily-dev-flow:new-project`.

Tu ne lis pas le code du projet et tu ne lances aucun agent : la matière est dans ces deux
fichiers.

### Constitution des lots

Un lot regroupe **1 à 3 items** du `Dans` — jamais plus. Deux items vont ensemble quand ils
**partagent des fichiers** dans l'arborescence, ou quand l'un ne se valide pas sans l'autre.
Sinon ils restent séparés.

- Un lot porte **tous** les critères de validation des items qu'il couvre, **recopiés mot pour
  mot** depuis `docs/cadrage.md`. Aucune reformulation : deux formulations du même critère font
  deux critères, et un critère réécrit est un critère qu'on peut affaiblir sans s'en rendre
  compte. Un item sans critère au cadrage n'en reçoit pas un inventé ici — c'est un défaut du
  cadrage, à signaler.
- `Dépend de` se déduit de deux faits seulement, jamais d'une intuition d'ordre : un **fichier
  commun** à deux lots, ou un **contrat** que l'un produit et l'autre consomme. Un lot qu'on
  « ferait plutôt après » sans l'une de ces deux raisons n'a pas de dépendance : il est juste
  plus bas dans la liste.
- **Aucun fichier de l'arborescence n'apparaît dans deux lots** sans que le recouvrement soit
  inscrit en dépendance. C'est la règle qui rend les lots lançables sans se marcher dessus, et
  c'est la même qu'à l'étape 2 de `/ticket` pour les sous-tâches.
- **Chaque item du `Dans` appartient à exactement un lot** : ni oublié, ni couvert deux fois.
  Vérifie-le explicitement avant d'écrire.
- **Rien qui ne vienne du cadrage.** Pas de lot « mise en place des tests », « CI »,
  « refactoring », « polish » que le périmètre ne demande pas : le hors-scope du cadrage vaut
  ici aussi.

`Fichiers prévus` reprend les chemins de l'arborescence **avec leur rôle tel qu'il y est
écrit**. `Contrats concernés` **référence** les sections de `docs/architecture.md` — ne les
recopie pas dans le fichier de lot : la source reste unique, et `/ticket` les recopiera dans le
payload des sous-tâches au moment de l'exécution.

### Le champ `Parallélisable avec`

`Dépend de` dit ce qui doit passer **avant**. Il ne dit pas ce qui peut tourner **en même
temps** : un lot sans dépendance directe peut très bien être en aval par transitivité, ou
partager un fichier avec un autre sans qu'aucun des deux ne produise ce que l'autre consomme.
Cette relecture se refait mentalement à chaque lancement, et elle se refait mal. Écris-la.

Deux lots sont parallélisables quand **les deux** conditions tiennent :

1. aucun des deux n'est ancêtre ou descendant de l'autre dans le graphe des `Dépend de` — la
   transitivité compte : `0004 → 0003 → 0002` rend `0004` et `0002` non parallélisables, alors
   qu'ils ne se citent pas ;
2. leurs `Fichiers prévus` sont **disjoints**. Ce second test doit rester même s'il paraît
   redondant avec la règle de non-recouvrement : c'est le filet qui rattrape un partage de
   fichier qu'on aurait oublié d'inscrire en dépendance.

Le champ est **structurel** : il décrit la forme du graphe, pas l'avancement. Il est donc écrit
une fois et ne se met jamais à jour — c'est la section `Prêts à partir` de la vue, régénérée,
qui porte le mouvant. `—` quand aucun autre lot ne qualifie : le lot est un passage obligé.

**Ce que le champ promet, et ce qu'il ne promet pas.** Il porte sur les **fichiers sources** :
deux lots parallélisables ne s'écraseront pas l'un l'autre. Il ne dit rien de l'outillage, qui
reste partagé — deux `/ticket` simultanés lancent deux `build-check` sur le même dossier, avec
les mêmes dépendances installées et le même répertoire de sortie, et peuvent échouer pour cette
seule raison. Dis-le à l'utilisateur quand tu proposes de lancer deux lots ensemble : le gain
est sur le développement, la vérification de build reste le point de sérialisation.

### Numérotation et idempotence

`NNNN` = plus haut numéro existant dans `.sohub-claude-plugin/plans/` + 1, zero-paddé sur 4
chiffres. Seuls les fichiers de forme `NNNN-<slug>.md` comptent — `BACKLOG.md` n'est pas un
plan. `<slug>` = kebab-case du titre du lot, tronqué à ~40 caractères. **Re-scanne `plans/`
juste avant d'écrire chaque fichier** : une autre session (`/ticket` ad hoc parallèle) a pu
créer un plan entre ton calcul et ton écriture, et une collision de numéro casse la
numérotation pour toujours.

**Aucun fichier existant n'est écrasé, jamais**, quel que soit son statut. Sur un projet qui a
déjà des plans :

- relève les items du `Dans` déjà couverts (en-tête `Couvre:`, et pour un plan antérieur à
  cette convention, son besoin fonctionnel) ;
- ne crée des lots que pour les items **non couverts**, à la suite des numéros existants ;
- dis à l'utilisateur ce que tu as considéré comme déjà couvert : c'est le seul endroit où une
  erreur de rattachement peut être vue.

### Validation avant écriture

Présente la table des lots — numéro, titre, items couverts, dépendances, nombre de fichiers —
et attends un OK. Le regroupement en lots est la seule partie de cette skill qui relève du
jugement : c'est là qu'une correction coûte une phrase plutôt qu'un fichier à supprimer. Gate
sautée quand l'appelant est en `--auto`.

### Écriture

Un fichier par lot, depuis `${CLAUDE_PLUGIN_ROOT}/templates/plan.template.md` : remplace les
marqueurs, `Statut global: todo`, laisse `Cible technique`, `Découpage`, `Vagues d'exécution`
et `Résultats` avec leur marqueur — ce sont les sections de `/ticket`, et un lot `todo` qui les
porterait déjà remplies mentirait sur son état.

Crée `.sohub-claude-plugin/` et ajoute la ligne au `.gitignore` du projet cible si elle n'y est
pas (lis le fichier, ajoute seulement si absente) — même geste que `/ticket`.

## Mode rafraîchissement de la vue

Relis l'en-tête de chaque `NNNN-*.md` et réécris `.sohub-claude-plugin/plans/BACKLOG.md` depuis
`${CLAUDE_PLUGIN_ROOT}/templates/BACKLOG.template.md`.

Le statut affiché est **lu** dans le fichier de lot, jamais tenu à jour ici : la vue est un
rendu, pas un second état. Un lot dont le fichier ne porte pas d'en-tête
`Couvre:`/`Dépend de:`/`Parallélisable avec:` (plan écrit avant cette convention) s'affiche avec
`—` dans ces colonnes plutôt que d'être omis.

Trois sections se recalculent à chaque rafraîchissement, et elles seules :

- **Vagues de lots** — le regroupement transitif : vague 1 = les lots sans dépendance, vague 2 =
  ceux dont toutes les dépendances sont en vague 1, etc. Une vague est un ensemble de lots
  lançables ensemble ; la colonne `Débloque` dit ce que sa fin rend disponible. C'est la lecture
  que le champ `Parallélisable avec` permet, vue d'en haut : le chemin le plus court du backlog
  au projet fini.
- **Prêts à partir** — les lots `todo` dont **toutes** les dépendances sont `done`, en commandes
  copiables. C'est la seule section qui bouge à chaque ticket terminé.
- **Reste à couvrir** — les items du `Dans` qui n'appartiennent à aucun lot. Pour la calculer,
  relis la liste `Dans` de `docs/cadrage.md` — c'est la **seule lecture hors fichiers de plans
  de ce mode**, et elle est indispensable : les en-têtes `Couvre:` ne peuvent pas dire ce
  qu'aucun lot ne couvre. Cadrage absent (projet sans `/new-project`, tickets tous ad hoc) :
  la section affiche `—`. Normalement vide ; non vide, c'est un périmètre étendu depuis la
  dernière génération — ou jamais projeté — donc un appel à relancer le mode génération,
  dis-le explicitement.

Quand plusieurs lots sont prêts en même temps, dis-le explicitement plutôt que de n'en proposer
qu'un — avec la réserve sur le build partagé énoncée plus haut.

**Une course est possible et sans gravité** : deux `/ticket` qui rafraîchissent la vue en même
temps peuvent produire un tableau momentanément en retard d'un statut. Il n'y a rien à
verrouiller — le rafraîchissement suivant relit les fichiers de lot, qui restent la source.

## Ce que cette skill ne fait jamais

- **Pas de découpage en sous-tâches ni de vagues** : c'est le travail de `/ticket` au lancement
  du lot, sur le code tel qu'il est à ce moment-là. Un découpage écrit six lots à l'avance
  serait périmé avant d'être lu.
- **Pas de date, d'estimation, de priorité, d'assignation** : le cadrage n'en porte pas, et les
  inventer est exactement ce que la règle de sourçage de `/new-project` interdit.
- **Pas de modification d'un fichier de lot existant** : ni statut, ni contenu. Le statut est
  écrit par `/ticket`, la vue est régénérée à partir de lui.
