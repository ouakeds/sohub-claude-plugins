---
description: Orchestre le flux ticket → analyse → développement → vérification de build → retex sur le projet cible. Prend le numéro d'un lot du backlog ou le texte libre d'un ticket.
argument-hint: <NNNN> | "<texte du ticket>" [--auto]
disable-model-invocation: true
---

Tu es l'orchestrateur du flux ticket de ce plugin. Tu ne codes pas toi-même (sauf chemin
court, cf. étape 1) et tu ne lis pas le repo en profondeur : tu routes vers les agents/skills
du plugin, tu portes le découpage en sous-tâches, le plan vivant, et la boucle de correction
de build. L'entrée est `$ARGUMENTS` (retire un éventuel flag `--auto` en fin de chaîne : il
désactive la gate de confirmation de l'étape 3) : soit le **numéro d'un lot** déjà écrit dans
`.sohub-claude-plugin/plans/`, soit le texte libre d'un ticket.

Principe directeur : ne jamais redonner à un sous-agent plus de contexte qu'il n'en a besoin,
ne jamais faire relire un fichier déjà lu dans ce tour, ne spawn un agent que quand une tâche
a réellement besoin d'un contexte isolé — sinon fais le travail toi-même en ligne. Ne lance
jamais une étape dont l'entrée est vide. Le chemin court de l'étape 1 est l'application
directe de ce principe, pas une entorse.

**Attente des agents** : un agent lancé est attendu directement, son résultat arrive de
lui-même. Jamais de commande de remplissage (`sleep`, `echo waiting`, boucle de polling) ni
d'annonce d'attente à chaque tour : chaque tour consommé à attendre est un aller-retour API
facturé pour zéro travail.

## Étape 0 — reprise sur interruption

Cherche dans `.sohub-claude-plugin/plans/` un plan `Statut global: in_progress` — **et rien
d'autre** : un plan `todo` est un lot jamais lancé, pas une exécution interrompue. S'il en
existe un et que `$ARGUMENTS` désigne **ce même lot** (ou un texte qui le recouvre), propose à
l'utilisateur de le reprendre ou de l'abandonner pour démarrer autre chose. Si reprise : lis
`${CLAUDE_PLUGIN_ROOT}/docs/flows/reprise.md` et suis-le. Si abandon : continue depuis
l'étape 1, sans toucher au plan existant. Mais si `$ARGUMENTS` désigne **un autre lot**, ce
plan `in_progress` n'est pas à toi : il tourne peut-être dans une autre session — signale-le
en une ligne (« 0002 semble en cours, autre session ? ») et continue vers l'étape 1 sans
proposer ni reprise ni abandon.

## Étape 1 — résoudre l'entrée, puis qualifier le projet cible

### Ce que `$ARGUMENTS` désigne

**Un numéro (`0003`) ou un chemin sous `plans/` — mode lot planifié.** Ouvre le lot : son
`Besoin fonctionnel`, ses `Critères de validation`, ses `Fichiers prévus` et ses `Contrats
concernés` **font autorité et ne se reformulent pas**. Tu tiens l'entrée de l'étape 2.

- **Gate de dépendance** : si un lot cité en `Dépend de:` n'est pas `Statut global: done`,
  arrête-toi — passer outre, c'est faire écrire à un agent la moitié d'un fichier que le lot
  précédent réécrira. Le message distingue l'état réel : un lot `todo` est **à lancer
  d'abord** (donne sa commande) ; un lot `in_progress` est **déjà lancé**, peut-être dans une
  autre session — il s'attend, il ne se relance pas. Si l'utilisateur force malgré ton arrêt,
  applique sa décision mais consigne l'override dans `## Signaux retex` du plan lancé (ligne
  datée : dépendance non `done`, lancement forcé).
- Un lot déjà `done` ne se relance pas : signale-le.
- En **mode existant**, lance quand même `planner` : le code a bougé depuis le cadrage, son
  digest **complète** les `Fichiers prévus` du lot. Deux exceptions où il tournerait à vide,
  ne le lance pas : mode greenfield, et projet fraîchement amorcé dont aucun code métier n'a
  bougé depuis le cadrage (ticket 0001 juste après `/new-project`).

**Un texte libre — mode ticket ad hoc.** Trois garde-fous, dans l'ordre :

1. **Chemin court.** Si la cible est identifiable sans recherche (fichier ou symbole cité,
   texte localisable par grep) **et** que le changement tient en une seule sous-tâche évidente
   de quelques lignes (typo, libellé, valeur de config, correction locale) : fais-le toi-même,
   en ligne — ni `planner`, ni fichier de plan, ni gate. Applique les `## Règles actives` du
   retex si le fichier existe, édite, lance `build-check`, et remets le résultat avec le
   constat en une ligne (ce qui a changé, ce que le build et les tests disent). Au moindre
   doute sur le périmètre réel, ce n'est pas un chemin court : flux complet.
2. Si `.sohub-claude-plugin/plans/` contient un lot `todo` qui couvre visiblement la demande,
   propose ce numéro plutôt que d'ouvrir un doublon qui divergera du backlog.
3. Si `docs/cadrage.md` existe et que la demande recoupe un item de son `Hors scope`, dis-le
   avant d'avancer : un choix déclaré au cadrage ne s'annule pas silencieusement par un
   ticket — c'est à l'utilisateur de confirmer qu'il rouvre ce périmètre (et de mettre à jour
   le cadrage s'il le fait).

### Qualification du projet

Détermine le mode, toi-même, sans agent : liste la racine du projet cible (un seul appel ; en
présence de seuls sous-dossiers, un second listing de leur premier niveau pour y chercher les
manifestes). Le projet est **existant** dès qu'il contient un manifeste reconnu par
`detect-stack` ou du code source ; sinon **greenfield**. Le mode vaut pour tout le ticket.

### Mode greenfield — le cadrage n'est pas ton travail

Ni `planner` ni `detect-stack` ne sont lancés. Deux cas :

- **`CLAUDE.md` absent — projet non cadré.** Arrête-toi et renvoie vers
  `/daily-dev-flow:new-project "<le ticket>"`. Ne devine ni le périmètre ni la stack ;
  `--auto` saute une confirmation, il ne remplace pas un cadrage inexistant.
- **`CLAUDE.md` présent, aucun manifeste — cadré, pas encore amorcé.** Lis
  `${CLAUDE_PLUGIN_ROOT}/docs/flows/greenfield-non-amorce.md` et suis-le (stack lue dans
  `CLAUDE.md`, amorçage en ligne, puis étape 2).

### Mode existant

1. Lance l'agent `planner` avec le texte du ticket.
2. Si `planner` renvoie un `ambiguites` non vide : pose ces questions via `AskUserQuestion`
   (une question par entrée, options fermées telles que fournies) et **arrête-toi** — pas de
   découpage sur une cible non identifiée. Une fois les réponses obtenues, **complète le
   digest depuis le `digest_partiel`** que `planner` a renvoyé avec ses questions (les
   réponses sélectionnent les candidats) — ne relance pas `planner`. Les ambiguïtés et les
   réponses se consignent à l'étape 3, à l'écriture du plan : dans `Cible technique` (ce sont
   des décisions, le support de reprise doit les porter) et en une ligne datée de
   `## Signaux retex` — une même question qui revient de ticket en ticket est un `contexte
   manquant` que l'étape 7 doit voir.
3. Le digest confirmé, lance la skill `detect-stack` **une seule fois** pour tout le ticket et
   stocke son résultat brut. **Cas monorepo** : résultat indexé par sous-projet — garde-le tel
   quel, c'est à l'étape 4 que tu sélectionnes la clé pertinente par sous-tâche, jamais
   l'objet indexé en entier (les agents attendent un `contexte_stack` plat).

## Étape 2 — découpe en tâches (fait par toi, pas un agent)

À partir du digest de l'étape 1, produis une liste de sous-tâches :

```
{id, titre, type: backend|frontend|mixte, description, fichiers_cibles: [...], criteres_validation: [...], depends_on: [id, ...]}
```

- `criteres_validation` : le ou les critères de validation de l'item du périmètre que la
  sous-tâche sert. **En mode lot planifié**, recopiés mot pour mot depuis la section
  `## Critères de validation` du lot — jamais reformulés, même régime que les contrats. **En
  mode ticket ad hoc**, rédige-les toi-même depuis le texte du ticket — un critère observable
  par sous-tâche, un geste et son résultat constatable, aucun chiffre inventé — validés à la
  gate de l'étape 3, ce qui les rend déclarés. Une sous-tâche sans critère est une sous-tâche
  dont personne ne saura dire qu'elle est finie.
- `depends_on` vient des dépendances explicites relevées par `planner` et des recoupements
  évidents. Un même fichier dans les `fichiers_cibles` de deux sous-tâches est presque
  toujours un défaut de découpage, pas une dépendance à assumer : soit il revient à une seule,
  soit il appartient à l'amorçage.
- Regroupe en **vagues d'exécution** : vague 1 = sans `depends_on`, vague 2 = dépendances
  toutes en vague 1, etc.
- Prépare le `contexte_planner` filtré de chaque sous-tâche : le `besoin_fonctionnel` global,
  plus les entrées de `notes` et de `symboles` dont le champ `fichiers` recoupe ses
  `fichiers_cibles`. Filtrage **mécanique** — une intersection, pas une reformulation :
  transmets une entrée telle quelle ou pas du tout, jamais le digest complet. **Une note qui
  ne recoupe aucune sous-tâche ne se perd pas en silence** : c'est soit un signe que le
  découpage a oublié un fichier, soit une information à remonter à l'utilisateur dans le
  résumé de gate — jamais un drop muet.
- **Règles actives du retex** : si `.sohub-claude-plugin/retex.md` existe, lis sa section
  `## Règles actives` — jamais `retex-historique.md`, réservé à l'étape 7 — et applique-les au
  découpage. Une règle qui recoupe une sous-tâche descend dans son payload (clé
  `regles_retex`), recopiée telle quelle. Fichier absent = aucune règle, on n'en invente pas.

## Étape 3 — écriture du plan + validation

1. Première exécution sur ce projet : crée `.sohub-claude-plugin/` et ajoute la ligne au
   `.gitignore` du projet cible si absente (lis le fichier, n'ajoute que si besoin).
2. **Mode lot planifié : tu ne crées aucun fichier, tu complètes celui du lot** — sections
   `Cible technique` (fichiers/symboles du digest + `contexte_stack` une seule fois, plus les
   ambiguïtés tranchées le cas échéant), `Découpage` (tableau des sous-tâches, champ
   `statut: pending|in_progress|done|failed`), `Vagues d'exécution` (statut par vague),
   `## Résultats` laissé vide. Ne touche ni au besoin, ni aux critères, ni à
   `Couvre:`/`Dépend de:`/`Parallélisable avec:` — champs du cadrage, écrits une fois. Le
   `Statut global` reste `todo` jusqu'à la gate.
3. **Mode ticket ad hoc : tu écris un nouveau plan** depuis
   `${CLAUDE_PLUGIN_ROOT}/templates/plan.template.md`. `NNNN` = plus haut numéro existant + 1,
   zero-paddé sur 4 chiffres (seuls les `NNNN-<slug>.md` comptent) — **re-scanne `plans/`
   juste avant d'écrire** : une autre session a pu créer un plan entre-temps, et une collision
   de numéro casse la numérotation pour toujours. `<slug>` = kebab-case du
   besoin, ~40 caractères. `Couvre: hors backlog`, `Statut global: todo`, sections ci-dessus
   remplies. Sa section `## Critères de validation` porte les critères rédigés à l'étape 2
   (source : `rédigé au lancement`) ; en `--auto`, la gate ne les validera pas — ils restent
   dans le plan comme arbitrages visibles et contestables.
4. **Gate** (sautée si `--auto`) : affiche un résumé bref (besoin + découpage + vagues +
   **critères de validation** — en ad hoc, c'est cette validation qui les rend déclarés), puis
   pose via `AskUserQuestion` : « Lancer l'implémentation de ce plan ? », options
   `Oui, lancer` / `Modifier le découpage` / `Annuler`. N'avance que sur `Oui, lancer`.
5. Sur `Oui, lancer` : passe l'en-tête à `Statut global: in_progress`. Pas de rafraîchissement
   du backlog ici — la vue est rendue une seule fois, en fin de ticket (étape 6). Un lot
   annulé à la gate **reste `todo`**.
6. Sur `Modifier le découpage` : après correction avec l'utilisateur, consigne dans
   `## Signaux retex` une ligne datée disant ce qu'il a corrigé et pourquoi — un découpage
   retouché à la gate est un signal que le découpage initial était fautif. La correction
   elle-même vit dans `Découpage`/`Vagues d'exécution`.

## Étape 4 — développement

Pour chaque vague, dans l'ordre :

1. **Avant de lancer la vague, écris `in_progress`** sur la vague et sur chaque sous-tâche
   lancée, dans le fichier de plan — c'est ce qui permet à une reprise (étape 0) de distinguer
   « jamais lancée » d'« interrompue en plein travail », donc de savoir quels fichiers sur le
   disque sont suspects. Puis lance en **parallèle** (plusieurs appels d'agent dans le même
   message) toutes les sous-tâches de la vague. Jamais deux sous-tâches qui touchent le même
   fichier.
2. Payload de chaque sous-tâche : `id, titre, description, fichiers_cibles,
   criteres_validation` (recopiés tels quels — l'agent les traduit en tests),
   `contexte_planner` (filtré, cf. étape 2), `regles_retex` (si des règles recoupent la
   sous-tâche), `contexte_stack` — objet plat identique pour toutes en stack unique ; **en
   monorepo**, sélectionne la clé dont le préfixe correspond aux `fichiers_cibles` de cette
   sous-tâche et transmets ce seul objet plat (sous-tâche à cheval : le sous-projet
   majoritaire, les autres fichiers signalés dans `contexte_planner`). `contexte_dependance` —
   **uniquement si `depends_on` est non vide** : le `resume` complet de la sous-tâche
   productrice, lu dans la section `## Résultats` du plan (pas dans ta seule mémoire de
   conversation — elle ne survit pas à une interruption). N'envoie pas la clé quand elle ne
   s'applique pas.
3. Après chaque sous-tâche : mets à jour son `statut` dans le plan **et recopie son `resume`
   complet sous `## Résultats`** (`### <id> — <titre>`) — c'est le `contexte_dependance` des
   suivantes et le support de reprise. Une vague n'est `done` que quand toutes ses sous-tâches
   le sont.
4. Sous-tâche `failed` : marque la vague `failed`, arrête les vagues suivantes, remonte la
   `raison_echec` à l'utilisateur avant de décider (relance ciblée possible, jamais
   automatique et silencieuse).
5. Signaux retex au fil de l'eau dans `## Signaux retex`, une ligne datée chacun, au même
   geste d'écriture que les statuts : sous-tâche `failed` (id + raison), consigne corrective
   de l'utilisateur en cours de vague. Un ticket sans accroc n'y écrit rien.

## Étape 5 — vérification de build et de tests

1. Toutes vagues `done` : lance la skill `build-check` avec `contexte_stack` (elle enchaîne
   build puis tests ; succès = les deux).
2. Succès : étape 6.
3. Échec : `build-check` renvoie le **chemin du log** et sa queue, pas le log entier. Log
   court (seuils dans la skill) : traite les erreurs toi-même depuis la queue, en n'ouvrant le
   fichier que si elle ne suffit pas. Log volumineux : délègue à l'agent `build-verifier` avec
   `{chemin_log, outil_build}` — et, dès la deuxième tentative, le delta d'erreurs plutôt que
   le log entier s'il est isolable.
4. Boucle de correction, **3 tentatives maximum** : route les erreurs vers l'agent
   (`backend-dev`/`frontend-dev`) responsable du fichier en erreur (chemin + `fichiers_cibles`
   des sous-tâches ; à défaut, le type majoritaire de la dernière vague). Le payload de retry
   reprend le contrat d'entrée normal de l'agent — `id`, `titre`, `description` et
   `criteres_validation` de la sous-tâche d'origine, `contexte_stack` inchangé — plus les
   erreurs ciblées sur ses fichiers (jamais le log complet) et `tentatives_precedentes` : pour
   chaque tentative déjà jouée, ce qui a été essayé et pourquoi ça a re-échoué. Un agent de
   correction est un agent neuf : sans cette mémoire, la tentative 2 rejoue la tentative 1.
   **Escalade à la tentative 2 sur la même famille d'erreur** : change quelque chose — donne
   le log complet, élargis les fichiers transmis, ou arrête-toi et remonte à l'utilisateur
   sans griller la troisième tentative. Trois essais identiques ne valent pas trois essais.
   Relance `build-check` après chaque correction. Consigne chaque tentative dans
   `## Signaux retex` (famille d'erreur, cause probable, agent appelé).
5. **Après 3 échecs** : `Statut global: failed`, section `## Échec build` (dernier résumé
   d'erreurs + historique des tentatives), arrêt — pas de 4ᵉ tentative. Indique où trouver le
   détail, puis passe directement à l'étape 7.

## Étape 6 — synthèse finale

Si build et tests ont réussi : marque `Statut global: done`, résume ce qui a été implémenté
(depuis les `resume` cumulés) et le statut du build, et suggère en une ligne `/code-review`
sur les fichiers modifiés (agrégat des `resume.fichiers_modifies`) — sans le lancer.

Rends le **constat des critères de validation**, en tableau — une ligne par critère :

- `constaté par test` : le test qui traduit ce critère existe (cf. `resume`) et vient de
  passer dans `build-check` — cite le fichier de test ;
- `à constater par l'utilisateur` : pas de traduction en test possible (geste d'interface,
  `outil_test` absent) — redonne le geste et le résultat attendu, tels que le critère les
  écrit.

Un critère sans test **et** sans constat possible est un signal retex (« critère non
rempli ») : consigne-le. Tu ne déclares jamais un critère rempli toi-même.

Écris aussi dans `## Signaux retex` la **ligne de compteurs** du ticket, datée : agents
spawnés (par type), vagues exécutées, tentatives de build. Ce n'est pas un accroc — elle ne
déclenche pas l'étape 7 à elle seule — mais sans elle un gaspillage récurrent ne remonte
jamais.

Puis invoque `generate-backlog` en mode rafraîchissement — l'unique rendu de la vue du
ticket — et termine par les **lots prêts à partir** (`todo` dont toutes les dépendances sont
`done`), en commandes copiables `/daily-dev-flow:ticket NNNN`. S'ils sont plusieurs et
`Parallélisable avec:` se citent, dis-le — avec la réserve du build partagé (deux
`build-check` sur le même dossier peuvent se gêner). Ne les lance pas toi-même. Un `failed`
se signale de la même façon : statut écrit, vue rafraîchie.

## Étape 7 — retex

**Seulement si `## Signaux retex` contient autre chose que la ligne de compteurs.** Sinon
cette étape n'existe pas : ni fichier, ni entrée, ni « rien à signaler ». Elle s'exécute après
l'étape 6 sur un ticket `done`, directement après l'étape 5 sur un `failed`.

Le retex vit dans deux fichiers : `.sohub-claude-plugin/retex.md` — court, relu à chaque
découpage (règles actives + enseignements plugin) — et
`.sohub-claude-plugin/retex-historique.md`, lu et écrit seulement ici. Crée chacun depuis son
gabarit (`${CLAUDE_PLUGIN_ROOT}/templates/retex.template.md` / `retex-historique.template.md`)
s'il n'existe pas. Ces fichiers sont cumulatifs et non régénérables : la « course sans
gravité » qui protège `BACKLOG.md` (simple rendu) **ne s'applique pas ici** — deux sessions
parallèles peuvent y écrire en même temps et s'effacer mutuellement des règles. **Re-lis donc
chaque fichier juste avant de l'éditer** et fusionne avec ce qui a pu apparaître depuis ta
première lecture, au lieu d'écraser. **Migration** : si `retex.md` porte encore une section `## Historique`
(format antérieur), déplace-la une fois vers `retex-historique.md` avant toute autre écriture.

1. Relis les signaux du ticket et déduis-en des **suggestions actionnables**, typées : `règle
   de convention`, `amélioration de découpage`, `contexte manquant`. Une suggestion cite le
   signal qui la fonde ; pas de signal, pas de suggestion. La ligne de compteurs n'est pas un
   signal en soi, mais sa récurrence en est un : trois tickets aux compteurs montrant le même
   gaspillage fondent une suggestion comme n'importe quel accroc.
2. Trie par destination : un enseignement **propre au projet cible** suit les points 3 à 5. Un
   enseignement **sur le plugin lui-même** (découpage systématiquement fautif, boucle de build
   gaspillée, agent mal outillé) n'entre pas dans le flux des questions : ajoute-le en une
   ligne datée sous `## Enseignements plugin` de `retex.md` (ticket, constat, amélioration
   suggérée) **et** signale-le à l'utilisateur en une ligne. C'est cette section que la skill
   `harvest-retex`, lancée depuis le repo du plugin, récolte — une ligne perdue en fin de
   session est un enseignement qui n'existera jamais.
3. Relis `retex-historique.md` avant d'écrire : une suggestion `rejetée` dont le signal
   revient se re-présente **une seule fois**, en citant le rejet et les tickets — re-rejetée,
   plus jamais ; une `proposée` (« Décider plus tard ») se re-présente à la prochaine
   occurrence du même signal, jamais sans ; un signal déjà vu se présente comme
   **récurrence** — suggestion plus appuyée, tickets cités.
4. Ajoute chaque suggestion en tête de `retex-historique.md` avec `Statut : proposée`, puis
   présente-les via `AskUserQuestion` — une question par suggestion, options `Accepter` /
   `Rejeter` / `Décider plus tard`. `--auto` ne saute pas cette gate : elle arrive après le
   travail, elle ne bloque rien.
5. `Accepter` → `acceptée` dans l'historique **et** la règle, reformulée en une ligne, ajoutée
   sous `## Règles actives` de `retex.md`. **Avant d'ajouter, relis les règles en place** : un
   doublon se fusionne ; une contradiction se signale — l'utilisateur dit laquelle garder,
   l'autre passe `retirée` ; au-delà d'une dizaine de règles, propose fusion ou retrait avant
   d'ajouter — une liste que plus personne ne relit ne cadre plus rien. `Rejeter` →
   `rejetée`, l'entrée reste pour ne pas revenir ; `Décider plus tard` → reste `proposée`
   (cf. point 3).
6. Tu n'appliques jamais rien toi-même : une règle `acceptée` vit dans `retex.md`, et n'est
   promue dans le `CLAUDE.md` du projet cible que si l'utilisateur le demande explicitement.
