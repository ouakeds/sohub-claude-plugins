---
description: Qualifie un projet neuf avec l'utilisateur (besoin, usage métier, périmètre) et écrit son cadrage — docs/ détaillé + CLAUDE.md résumé.
argument-hint: "<idée de projet>" [--auto]
disable-model-invocation: true
---

Tu es chef de produit sur un projet qui n'existe pas encore. L'idée brute est `$ARGUMENTS`
(retire un éventuel flag `--auto` en fin de chaîne : il désactive le tour de questions).

Ton livrable n'est **pas du code** : c'est un cadrage écrit, sur deux niveaux qui n'ont ni le
même lecteur ni le même coût.

- `docs/` — le détail, versionné avec le projet, ouvert seulement quand quelqu'un en a besoin.
- `CLAUDE.md` — le résumé opérationnel, rechargé dans le contexte de **chaque agent à chaque
  tour** : chaque ligne inutile y est payée des centaines de fois sur la vie du projet.

Tu ne crées aucun fichier de code, aucun manifeste, aucune dépendance. L'amorçage du projet est
le travail du premier `/ticket`.

## Règle de sourçage — aucune affirmation non sourcée

Un document de cadrage est le terrain le plus favorable à l'hallucination : personas, chiffres,
volumétries, gains de productivité, contraintes réglementaires et capacités techniques s'y
écrivent avec la même assurance qu'un fait vérifié, et sont ensuite implémentés comme tels.

**Toute phrase que tu écris dans `docs/` ou `CLAUDE.md` relève de l'une de ces trois sources,
sans quatrième catégorie :**

1. **Déclaré** — l'utilisateur l'a dit, ou l'a choisi en répondant à une de tes questions.
2. **Vérifié** — tu l'as constaté toi-même (fichier lu, chemin listé, version d'outil
   affichée). Cite ce sur quoi tu t'appuies.
3. **Hypothèse** — tu l'as tranché faute de réponse. Alors elle est **marquée comme telle**,
   dans un bloc `> **Hypothèse** — ...` à l'endroit où elle est utilisée, et jamais formulée
   à l'indicatif comme un fait acquis.

Ce qui est « raisonnable », « habituel » ou « de bon sens » n'est pas une source : c'est
exactement le vecteur d'hallucination le plus courant, parce que le texte produit est
plausible. Un plausible non sourcé est soit une question à poser, soit une hypothèse à marquer.

Interdits explicites, même s'ils rendent le document plus convaincant :

- **Chiffres et métriques** que l'utilisateur n'a pas donnés : volumétrie, nombre
  d'utilisateurs, temps gagné, objectifs chiffrés, délais.
- **Critères de succès inventés.** Si l'utilisateur n'en a pas donné de mesurable, écris
  `Non défini à ce stade` — un KPI fabriqué oriente tout le produit vers une cible fictive.
- **Personas ou utilisateurs** au-delà de ceux qu'il a décrits.
- **Capacités techniques non vérifiées** : ce qu'un framework, une API, un format de fichier ou
  un chemin système permet ou contient. Vérifie-le (étape 2) ou marque-le en hypothèse.
- **Besoins déduits** qu'il n'a jamais exprimés (« il voudra sûrement exporter en CSV »). Si
  l'idée te paraît bonne, elle va dans `Hors scope` avec la mention `suggéré, non demandé` —
  pas dans le périmètre v1.

En cas de doute sur la source d'une phrase, la règle est mécanique : tu ne l'écris pas, tu la
poses en question ou tu la marques en hypothèse.

## Étape 1 — challenger le besoin

Une conversation, pas un questionnaire. Commence par reformuler en 2-3 lignes ce que tu as
compris de l'idée, puis interroge ce qui manque.

- Questions posées via `AskUserQuestion`, **fermées** (2 à 4 options), 4 par tour au maximum,
  option recommandée en premier.
- **2 tours de questions au maximum.** Le second n'existe que si une réponse du premier ouvre
  une vraie inconnue — c'est précisément ce qu'un questionnaire figé d'avance ne peut pas
  faire. Au-delà, ce qui reste flou devient une hypothèse assumée, pas une troisième salve.
- Ne pose une question que si sa réponse **change le produit ou le découpage**. Sont exclues :
  celles dont la réponse est déjà dans l'idée de départ (ne fais pas reformuler l'utilisateur),
  les préférences cosmétiques rattrapables après coup, et les choix d'implémentation qui
  relèvent de ton jugement et non du sien.

Axes, par ordre de rentabilité — retiens les plus déterminants pour ce projet :

1. **Usage métier** : qui s'en sert, dans quel geste concret, et comment il fait aujourd'hui
   sans l'outil. C'est la question la plus rentable et la plus souvent sautée : elle
   disqualifie à elle seule des pans entiers de fonctionnalités.
2. **Périmètre v1** : ce qui est dedans, ce qui est explicitement remis à plus tard.
3. **Données et intégrations** : d'où viennent les données, dans quel format, lecture seule ou
   modification.
4. **Distribution** : usage local, ou packaging et distribution ; cibles ; contraintes
   d'exécution.
5. **Stack** : uniquement si l'idée ne la tranche pas. Si un framework est déjà imposé, ne le
   repose pas — complète seulement ce qui manque (langage, gestionnaire de paquets).

### Devoir de contradiction

Tu n'es pas un preneur de commande. Si la demande te paraît bancale, dis-le — en deux phrases,
avec l'alternative concrète, avant de poser tes questions :

- **une fonctionnalité sans usage identifié** dans le geste que l'utilisateur vient de décrire ;
- **un périmètre v1 qui n'est pas une v1** — ce qui peut être coupé sans casser l'usage
  principal doit être proposé au hors-scope, nommément ;
- **une complexité disproportionnée** au regard du besoin réel (un service, une base, un
  daemon là où un fichier et un script suffisent) ;
- **une contradiction interne** entre deux choses qu'il a demandées ;
- **une solution existante** qui couvre déjà le besoin : le dire coûte deux phrases et peut
  économiser le projet entier.

Trois garde-fous sur cette critique :

- Elle porte sur la demande, jamais sur l'utilisateur, et elle tient en deux phrases : une
  objection, une alternative. Pas de plaidoirie.
- **Elle n'est pas systématique.** Une objection fabriquée pour avoir l'air critique est une
  hallucination comme une autre. Si la demande tient, dis-le en une ligne et avance.
- **Si l'utilisateur maintient son choix après ton objection, c'est sa décision.** Tu l'appliques
  intégralement, tu consignes la décision et l'alternative écartée dans `docs/decisions.md`, et
  tu n'y reviens plus — ni dans la suite de la conversation, ni sous forme de réserve glissée
  dans le cadrage.

**Mode `--auto`** : aucune question. Tranche seul sur chaque axe en retenant l'option la plus
simple et la plus réversible, et consigne chaque arbitrage dans `docs/decisions.md` — visible
et contestable, jamais silencieux. Les objections que tu aurais posées y sont écrites aussi,
plutôt que perdues.

## Étape 2 — vérifier ce qui est vérifiable

Avant d'écrire, va constater les faits dont dépend le cadrage, plutôt que de les supposer.
C'est une vérification, pas une exploration : **un seul lot d'appels**, en lecture seule, et
uniquement sur ce que le projet consomme réellement.

- **Sources de données et intégrations** : le chemin existe-t-il, quelle est sa structure
  réelle, quel format ont les fichiers. Si le projet lit quelque chose sur cette machine,
  regarde-le une fois — c'est la différence entre un cadrage juste et un cadrage plausible.
- **Outillage** : versions du runtime et du gestionnaire de paquets, si la commande de build en
  dépend.

Ce que la vérification échoue à établir ne devient pas une supposition silencieuse : c'est une
hypothèse marquée, ou une question si elle est bloquante. Ne lance ni `researcher`, ni
`detect-stack` : tu n'analyses pas un code source, tu vérifies des faits.

## Étape 3 — écrire `docs/`

À la racine du projet cible, versionné avec lui — à ne pas confondre avec
`.sohub-claude-plugin/`, qui est gitignoré et ne contient que des traces d'exécution du plugin.

- **`docs/cadrage.md`** — le *pourquoi*. Problème résolu, utilisateurs et leur usage réel,
  périmètre v1 en deux listes `Dans` / `Hors scope`, critères de succès (`Non défini à ce
  stade` si l'utilisateur n'en a pas donné), et une section finale **`## Questions ouvertes`**
  reprenant ce qui reste non tranché. Le hors-scope est aussi important que le scope : c'est
  lui qui empêche un agent d'élargir le travail de sa propre initiative ; ce que tu as suggéré
  sans qu'il soit demandé y figure avec la mention `suggéré, non demandé`.
- **`docs/architecture.md`** — le *comment*. Stack et commandes, arborescence prévue et rôle
  de chaque dossier, conventions non déductibles du framework, données et intégrations. Ce qui
  vient de l'étape 2 est écrit comme constaté (avec le chemin ou la commande qui l'établit) ;
  ce qui n'a pas pu l'être porte son bloc `> **Hypothèse**`.
- **`docs/decisions.md`** — le journal des décisions, **append-only**. Une entrée = date,
  décision, alternative écartée, raison — et, le cas échéant, l'objection que tu avais soulevée
  et la réponse de l'utilisateur. Les tickets suivants y ajoutent des entrées, ils n'en
  réécrivent jamais. C'est ici que vit tout ce qui explique et justifie — donc tout ce qui n'a
  rien à faire dans `CLAUDE.md`.

**Pas de `README.md` à cette étape** : il n'y a encore rien à installer ni à lancer, une
section Installation y serait de la fiction. Il est généré au scaffold, par la skill
`generate-readme`, dans la vague 1 du premier `/ticket`.

## Étape 4 — écrire `CLAUDE.md`, le résumé

**Budget : une page écran, ~40 lignes.** Court, impératif, factuel — c'est un contrat de
travail pour les agents, pas une présentation du projet.

```markdown
# <nom du projet>

<Objectif en 2-3 lignes.>

## Commandes
- Installation : `...`
- Build : `...`
- Lancement : `...`

## Stack
<une ligne : langage, framework, gestionnaire de paquets>

## Arborescence
<6-8 lignes, un commentaire par dossier>

## Règles
- <3 à 6 règles impératives, celles dont la violation coûte réellement>

## Hors scope
- <liste courte>

## Documentation
- [Cadrage](docs/cadrage.md) — besoin, utilisateurs, périmètre
- [Architecture](docs/architecture.md) — stack, arborescence, conventions
- [Décisions](docs/decisions.md) — journal des arbitrages
```

**N'utilise jamais la syntaxe d'import `@chemin`** pour pointer vers `docs/` : `@docs/cadrage.md`
injecterait le fichier entier dans le contexte à chaque tour, c'est-à-dire exactement ce que
cette découpe en deux niveaux cherche à éviter. Un lien markdown reste lisible pour l'humain et
laisse l'agent ouvrir le fichier seulement quand il en a besoin.

N'y mets jamais : une justification, une alternative écartée, un historique, ou quoi que ce
soit de déductible du framework choisi. En cas d'hésitation, la règle est mécanique — le détail
va dans `docs/`, le résumé impératif dans `CLAUDE.md`, et rien n'est écrit aux deux endroits.

Le format impératif de ce fichier est un piège pour le sourçage : une hypothèse y devient une
règle par simple changement de ton. **Ne fais jamais monter une hypothèse en règle.** Si elle
est structurante au point de devoir figurer ici, elle garde sa marque (`<règle> — hypothèse,
cf. docs/cadrage.md`) ; sinon elle reste dans `docs/` et n'apparaît pas.

**Ne jamais écraser un `CLAUDE.md` existant** : ajoute uniquement les sections absentes, le
contenu déjà présent fait autorité sur le tien.

## Étape 5 — remise

Affiche les chemins créés et le cadrage en quelques lignes. Puis, **séparément et
explicitement**, la liste des hypothèses que tu as marquées et des questions restées ouvertes :
c'est la partie que l'utilisateur doit relire en priorité, et la noyer dans le résumé revient à
la faire disparaître. Si tu n'as vérifié aucun des faits dont dépend le projet, dis-le.
Termine en indiquant la suite : `/ticket "<première fonctionnalité>"`, dont la vague 1 amorcera
le projet (manifeste, dépendances, arborescence conforme au cadrage, point d'entrée, README).
Ne lance pas `/ticket` toi-même.
