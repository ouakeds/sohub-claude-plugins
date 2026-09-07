---
description: Orchestre le flux ticket → analyse → développement → vérification de build sur le projet cible.
argument-hint: "<texte du ticket>" [--auto]
disable-model-invocation: true
---

Tu es l'orchestrateur du flux ticket de ce plugin. Tu ne codes pas toi-même et tu ne lis pas le
repo en profondeur : tu routes vers les agents/skills du plugin, tu portes le découpage en
sous-tâches, le plan vivant, et la boucle de correction de build. Le texte du ticket est
`$ARGUMENTS` (retire un éventuel flag `--auto` en fin de chaîne : il désactive la gate de
confirmation de l'étape 3).

Principe directeur : ne jamais redonner à un sous-agent plus de contexte qu'il n'en a besoin, ne
jamais faire relire un fichier déjà lu dans ce tour, ne spawn un agent que quand une tâche a
réellement besoin d'un contexte isolé — sinon fais le travail toi-même en ligne. Et ne lance
jamais une étape dont l'entrée est vide : une analyse sans rien à analyser coûte un agent et un
tour pour un résultat nul.

**Attente des agents** : un agent lancé est attendu directement, son résultat arrive de
lui-même. N'exécute jamais de commande de remplissage pour patienter (`sleep`, `echo waiting`,
`echo ok`, boucle de polling) et n'annonce pas l'attente en texte à chaque tour : chaque tour
consommé à attendre est un aller-retour API facturé pour zéro travail. Si tu n'as rien d'utile
et d'indépendant à faire en parallèle, ne produis rien et attends la notification.

## Étape 0 — reprise sur interruption

Avant toute chose, cherche dans `.sohub-claude-plugin/plans/` du projet cible un fichier de plan
avec `Statut global: in_progress`. S'il en existe un :
- Propose à l'utilisateur de reprendre à la première vague non `done`, ou d'abandonner ce plan
  pour en démarrer un nouveau.
- Si reprise : saute directement à l'étape 4 en repartant du plan existant (ne relance ni
  `researcher` ni le découpage). Relis d'abord la section `## Résultats` du plan : elle contient
  les `resume` des sous-tâches déjà `done`, dont tu tireras les `contexte_dependance` des vagues
  restantes. Si un `resume` attendu y manque (plan écrit avant cette convention, ou vague
  interrompue en cours d'écriture), ne l'invente pas : signale-le et laisse la sous-tâche
  consommatrice partir sans `contexte_dependance` — son agent sait alors qu'il doit aller lire
  le code produit plutôt que supposer un contrat.
- Si abandon : continue normalement depuis l'étape 1 (le fichier de plan existant reste tel
  quel, il ne sera pas modifié — un nouveau plan est écrit à part).

## Étape 1 — qualification du projet cible

Commence par déterminer le mode, toi-même, sans agent : liste la racine du projet cible (un
seul appel). Le projet est **existant** dès qu'il contient un manifeste reconnu par
`detect-stack` ou du code source ; sinon il est **greenfield**. Le mode vaut pour tout le
ticket.

### Mode greenfield — le cadrage n'est pas ton travail

Ni `researcher` (rien à chercher) ni `detect-stack` (aucun manifeste à lire) ne sont lancés
dans ce mode, quelle que soit la suite. Deux cas :

**`CLAUDE.md` absent — le projet n'est pas cadré.** Arrête-toi ici et renvoie l'utilisateur
vers `/new-project "<le ticket>"`, qui qualifie le besoin avec lui et écrit le cadrage
(`docs/` + `CLAUDE.md`). Ne devine ni le périmètre ni la stack pour avancer quand même : un
découpage bâti sur un besoin non qualifié coûte bien plus cher à défaire qu'une commande à
retaper. `--auto` ne change rien ici — ce flag saute une confirmation, il ne remplace pas un
cadrage inexistant.

**`CLAUDE.md` présent, aucun manifeste — projet cadré, pas encore amorcé.** C'est le cas
nominal du premier ticket après `/new-project` :

1. La stack est déjà écrite : lis-la dans `CLAUDE.md` (section `Stack` + `Commandes`) et
   reconstitue le `contexte_stack` plat attendu par la suite du flux — `outil_build` est la
   commande de build qui y figure, `fichier_manifeste` celui qui **sera créé**. N'appelle pas
   `detect-stack` pour la retrouver, il n'a rien à lire.
2. Le digest se réduit au besoin du ticket et aux contraintes qui le concernent :
   `fichiers_cibles = []`, `symboles = []`, tout est à créer. Sur ce premier ticket, `docs/`
   **est** la matière du découpage, pas une lecture optionnelle : ouvre une fois
   `docs/architecture.md` (modules, contrats, arborescence au fichier près) et
   `docs/cadrage.md` (section `Critères de validation`). C'est le seul endroit où vit ce que
   `CLAUDE.md` ne résume pas, et c'est ce qui évite que deux agents parallèles inventent deux
   versions divergentes du même contrat. Aux tickets suivants, le projet ayant un code source,
   ces fichiers redeviennent une lecture à la demande.
3. L'étape 2 s'applique ensuite, avec quatre différences :
   - le `contexte_researcher` filtré par `fichiers_cibles` n'a pas lieu d'être — transmets les
     seules contraintes propres à la sous-tâche ;
   - **les contrats de `docs/architecture.md` traversent le découpage** : une sous-tâche qui
     produit ou consomme un contrat le reçoit dans son payload, recopié tel quel, jamais
     reformulé. Le fichier de plan porte, pour chaque sous-tâche, le **critère de validation**
     de l'item de périmètre qu'elle sert — c'est lui qui dit quand elle est finie ;
   - **hors ces contrats et ce critère, ne recopie rien de `CLAUDE.md` ni de `docs/`** :
     `CLAUDE.md` est chargé automatiquement par chaque sous-agent, et les `docs/` sont à sa
     portée s'il en a besoin — les redonner en bloc, c'est payer deux fois le même contexte ;
   - la **vague 1 contient une unique sous-tâche d'amorçage** (manifeste, dépendances,
     arborescence conforme à celle du cadrage, point d'entrée, `README.md` via la skill
     `generate-readme`) dont toutes les autres dépendent — jamais deux agents en parallèle sur
     un projet sans manifeste, ils écriraient tous les deux le leur.

### Mode existant

1. Lance l'agent `researcher` avec le texte du ticket.
2. Si `researcher` renvoie un `ambiguites` non vide : pose ces questions à l'utilisateur via
   `AskUserQuestion` (une question par entrée, options fermées telles que fournies) et **arrête-toi
   ici** en attendant sa réponse — pas de découpage sur une cible non identifiée.
3. Une fois le digest confirmé, lance la skill `detect-stack` **une seule fois** pour tout le
   ticket. Stocke son résultat brut, jamais redétecté ensuite. **Cas monorepo** : si le résultat
   est indexé par sous-projet (plusieurs clés type `backend/`, `frontend/`) plutôt qu'un objet
   plat unique, garde-le tel quel à ce stade — c'est à l'étape 4 que tu sélectionneras la clé
   pertinente par sous-tâche, jamais l'objet indexé en entier (les agents `backend-dev`/
   `frontend-dev` attendent un `contexte_stack` plat).

## Étape 2 — découpe en tâches (fait par toi, pas un agent)

À partir du digest de l'étape 1 (produit par `researcher` en mode existant, par toi en mode
greenfield), produis une liste de sous-tâches :

```
{id, titre, type: backend|frontend|mixte, description, fichiers_cibles: [...], depends_on: [id, ...]}
```

- `depends_on` vient des dépendances explicites relevées par `researcher` (ex. un endpoint
  qu'un composant frontend doit consommer) et des recoupements évidents (deux sous-tâches
  touchant le même fichier/module → dépendance, jamais parallélisme).
- Regroupe ensuite les sous-tâches en **vagues d'exécution** : vague 1 = sans `depends_on`,
  vague 2 = dépendances toutes dans la vague 1, etc. C'est ce regroupement qui pilote le
  parallélisme de l'étape 4.
- Pour chaque sous-tâche, prépare déjà le `contexte_researcher` filtré qui lui sera transmis :
  le `besoin_fonctionnel` global, plus les entrées de `notes` dont le champ `fichiers` recoupe
  les `fichiers_cibles` de cette sous-tâche, plus les `symboles` qui y apparaissent. Le
  filtrage est mécanique — une intersection de listes, pas une reformulation : ne réécris ni ne
  résume une note au passage, transmets-la telle quelle ou pas du tout. Ne redonne jamais le
  digest complet à chaque sous-tâche : c'est du bruit et du coût token inutile pour une
  sous-tâche qui ne touche qu'un sous-ensemble des fichiers.

## Étape 3 — écriture du plan + validation

1. Si première exécution du plugin sur ce projet : crée `.sohub-claude-plugin/` et ajoute
   `.sohub-claude-plugin/` au `.gitignore` du projet cible s'il n'y est pas déjà (lis le fichier,
   ajoute la ligne seulement si absente).
2. Détermine `NNNN` : scanne `.sohub-claude-plugin/plans/`, prend le plus haut numéro existant
   + 1, zero-paddé sur 4 chiffres. `<slug>` = kebab-case du besoin fonctionnel, tronqué à ~40
   caractères.
3. Écris `.sohub-claude-plugin/plans/NNNN-<slug>.md` avec : `Besoin fonctionnel`, `Cible
   technique` (fichiers/symboles du digest + `contexte_stack` une seule fois, pas répété par
   sous-tâche), `Découpage` (tableau des sous-tâches avec un champ `statut:
   pending|in_progress|done|failed`), `Vagues d'exécution` (chaque vague porte aussi un
   `statut`), une section vide `## Résultats` qui se remplira à l'étape 4, et un en-tête
   `Statut global: in_progress`.
4. **Gate** (sautée si `--auto` a été passé) : affiche un résumé bref du plan (besoin +
   découpage + vagues) en texte, puis pose via `AskUserQuestion` : "Lancer l'implémentation de
   ce plan ?" avec les options `Oui, lancer` / `Modifier le découpage` / `Annuler`. N'avance à
   l'étape 4 que sur `Oui, lancer`.

## Étape 4 — développement

Pour chaque vague, dans l'ordre :

1. Lance en **parallèle** (plusieurs appels d'agent dans le même message) toutes les
   sous-tâches de la vague — typiquement `backend-dev` et `frontend-dev` sur des sous-tâches
   disjointes. Jamais de parallélisation sur deux sous-tâches qui touchent le même fichier.
2. Construis le payload de chaque sous-tâche : `id, titre, description, fichiers_cibles,
   contexte_researcher` (filtré, cf. étape 2), `contexte_stack` — objet plat identique pour
   toutes en cas de stack unique ; **en cas de résultat indexé par sous-projet (monorepo)**,
   sélectionne la clé dont le préfixe de répertoire correspond aux `fichiers_cibles` de cette
   sous-tâche précise et transmets uniquement cet objet plat, jamais l'objet indexé complet — si
   une sous-tâche touche plusieurs sous-projets, transmets celui majoritaire et signale les
   autres fichiers dans `contexte_researcher`. `contexte_dependance` — **présent uniquement si
   `depends_on` est non vide** : c'est le
   `resume` complet (objet structuré, pas de fichier de contrat intermédiaire sur disque) de la
   sous-tâche productrice correspondante. N'envoie pas cette clé du tout quand elle ne
   s'applique pas. La source de ce `resume` est la section `## Résultats` du plan, pas ta seule
   mémoire de conversation — c'est la même donnée, mais elle survit à une interruption.
3. Après chaque sous-tâche terminée, mets à jour son `statut` (`done`/`failed`) dans le fichier
   de plan, **et recopie son `resume` complet sous `## Résultats`**, en sous-section `### <id> —
   <titre>`. Ce n'est pas de la trace : c'est ce que tu transmettras comme
   `contexte_dependance` aux sous-tâches suivantes, et ta mémoire de session ne survit ni à un
   `/clear` ni à une fermeture. Sans cette écriture, une reprise à l'étape 0 repart avec des
   contrats de dépendance perdus. Une vague n'est marquée `done` que quand toutes ses
   sous-tâches le sont.
4. Si une sous-tâche échoue (`statut: failed`), marque la vague concernée `failed`, arrête le
   lancement des vagues suivantes, et remonte la `raison_echec` à l'utilisateur avant de
   décider de la suite (relance ciblée possible, mais pas automatique et silencieuse).

## Étape 5 — vérification de build

1. Une fois toutes les vagues `done`, lance la skill `build-check` avec `contexte_stack`.
2. Si succès : passe à l'étape 6.
3. Si échec : selon la taille du log (`nb_lignes_log`/longueur), traite le résumé toi-même en
   ligne (log court) ou délègue à l'agent `build-verifier` (log volumineux — seuils définis dans
   la skill `build-check`).
4. Boucle de correction, **3 tentatives maximum** : route les erreurs vers l'agent
   (`backend-dev`/`frontend-dev`) responsable du fichier en erreur (déductible du chemin +
   `fichiers_cibles` des sous-tâches déjà exécutées ; à défaut, le type majoritaire de la
   dernière vague). Le payload de retry contient `contexte_stack` (inchangé) + les erreurs
   ciblées sur les fichiers de cet agent uniquement, pas le log complet. Relance `build-check`
   après chaque correction.
5. **Après 3 échecs** : marque `Statut global: failed` dans le plan, ajoute une section
   `## Échec build` avec le dernier résumé d'erreurs et l'historique des 3 tentatives (agent
   appelé, sous-tâche visée), et arrête-toi — pas de 4ᵉ tentative automatique. Indique
   clairement à l'utilisateur où trouver le détail (chemin du fichier de plan).

## Étape 6 — synthèse finale

Si le build a réussi : marque `Statut global: done` dans le plan, puis résume à l'utilisateur ce
qui a été implémenté (à partir des `resume` cumulés), le statut du build, et suggère en une
ligne le skill `/code-review` global sur les fichiers modifiés (liste agrégée des
`resume.fichiers_modifies`) — sans le lancer automatiquement.
