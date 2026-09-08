# Plan — claude-dev-plugin

## Objectif

Plugin Claude Code autonome (roster d'agents propre, générique multi-stack) qui outille le flux :
**ticket → analyse → développement → vérification de build.**

## Décisions de cadrage

- **Source ticket** : texte collé manuellement (pas d'intégration Jira/Linear en v1).
- **Portée** : générique multi-stack — détection automatique de la stack cible, pas de hardcode projet.
- **Roster d'agents** : autonome, packagé dans le plugin (n'utilise pas le Jarvis du CLAUDE.md global).
- **Vérification finale** : compilation/build + tests des critères de validation — chaque
  critère du plan est traduit en test par l'agent dev, et `build-check` lance build **et**
  tests (évolution du 2026-09-08 ; le cadrage initial se limitait au build, ce qui laissait
  « fini = ça compile »). Pas de lint en v1.
- **Retries de correction build** : 3 tentatives max avant remontée à l'utilisateur.
- **Ticket ambigu (cible technique non identifiable)** : **tranché** — le `planner`/la commande `/ticket`
  bloque et pose des questions précises à l'utilisateur avant de continuer (pas d'hypothèse silencieuse).
- **Persistance des plans/rapports** : tout artefact généré (plan de ticket, audit sécurité, doc OpenAPI)
  est écrit dans un dossier unique `.sohub-claude-plugin/` à la racine du **projet cible**, sous un
  sous-dossier par nature d'analyse (`plans/`, `audit/`, `documentations/`), avec un numéro de version
  auto-incrémenté **par sous-dossier**  (jamais réutilisé, jamais écrasé). `.sohub-claude-plugin/` est
  entièrement gitignoré — ajouté automatiquement au `.gitignore` du projet cible à la première exécution
  d'un skill/de la commande si l'entrée n'y est pas déjà (lecture du fichier, ajout d'une ligne si absente).

## Flux cible : `/ticket "<texte du ticket>"`

La commande `/ticket` est l'orchestrateur : elle ne code pas, elle route et enchaîne les étapes.
Elle absorbe elle-même la logique de découpage/ordonnancement (ex-`task-router`) et le lancement
du build (via la skill `build-check`) — pas besoin d'un agent isolé pour du pur enchaînement sans
outillage ni bruit à contenir.

1. **Recherche de contexte** (`planner`)
   Agent read-only. Extrait le besoin fonctionnel du ticket et localise la cible technique
   (fichiers/modules concernés) en interrogeant le **code-review-graph** (recherche sémantique,
   contexte minimal, overview d'architecture) plutôt qu'en grepant le repo à l'aveugle.
   Renvoie un digest : `{besoin_fonctionnel, fichiers_cibles, symboles, notes}`.

   Immédiatement après, la commande `/ticket` lance elle-même la skill **`detect-stack`** une
   seule fois pour tout le ticket (outil de build + langage/framework identifiés à partir des
   fichiers manifestes) et ajoute son résultat au digest sous `contexte_stack`. Ce résultat est
   ensuite propagé tel quel à toutes les sous-tâches de l'étape 4 (`backend-dev`/`frontend-dev`)
   et réutilisé par `build-check` à l'étape 5 — **une seule détection de stack pour tout le
   flux**, jamais redevinée en doublon par chaque agent.
2. **Découpe en tâches** (fait par la commande `/ticket` elle-même, à partir du digest `planner`)
   Pas d'agent dédié : c'est une décision d'orchestration, pas une tâche à isoler. Produit une liste
   de sous-tâches selon ce schéma :
   ```
   {id, titre, type: backend|frontend|mixte, description, fichiers_cibles: [...], depends_on: [id, ...]}
   ```
   `contexte_stack` (issu de `detect-stack`, cf. étape 1) n'est pas répété par sous-tâche dans le
   plan écrit — une seule fois dans l'en-tête `Cible technique` du fichier de plan — mais est bien
   inclus dans le payload transmis à chaque appel `backend-dev`/`frontend-dev` à l'étape 4.
   `depends_on` vient du digest `planner` (ex : un endpoint qu'un composant frontend doit consommer)
   et de recoupements évidents (deux sous-tâches touchant le même fichier/module → dépendance, pas
   parallélisme). Les sous-tâches sont ensuite regroupées en **vagues d'exécution** : vague 1 = toutes
   celles sans `depends_on`, vague 2 = celles dont les dépendances sont dans la vague 1, etc. — c'est
   ce regroupement qui pilote le parallélisme de l'étape 4.
3. **Écriture du plan + validation** (fait par la commande `/ticket`, avant toute implémentation)
   Écrit le plan technico-fonctionnel dans `.sohub-claude-plugin/plans/NNNN-<slug>.md` — **fichier
   vivant**, pas un simple compte-rendu figé (cf. reprise sur interruption, étape 4) :
   - `NNNN` = prochain numéro disponible dans le sous-dossier (scan des fichiers existants, max+1,
     zero-paddé sur 4 chiffres) ; `<slug>` = kebab-case dérivé du besoin fonctionnel, tronqué (~40 car).
   - Contenu du fichier : `Besoin fonctionnel`, `Cible technique` (fichiers/symboles du digest
     `planner`), `Découpage` (tableau des sous-tâches avec leur schéma **+ un champ `statut`**:
     `pending|in_progress|done|failed`), `Vagues d'exécution` (chaque vague porte aussi un `statut`),
     et `Questions` si le ticket était ambigu — la commande s'arrête à cette étape et attend les réponses
     de l'utilisateur avant de générer le découpage (cf. décision "Ticket ambigu" ci-dessus). Un en-tête
     `Statut global: in_progress|done|failed` résume l'avancement.
   - Première exécution sur un projet : crée `.sohub-claude-plugin/` et ajoute l'entrée au
     `.gitignore` s'il n'y est pas déjà.
   - **Gate** : la commande présente un résumé bref du plan (besoin + découpage + vagues) et attend
     confirmation de l'utilisateur avant de lancer l'étape 4. Évite d'implémenter sur une mauvaise
     interprétation du ticket. Skippable explicitement si l'utilisateur le demande (mode autonome).
4. **Développement** (`backend-dev` / `frontend-dev`)
   Implémentation par sous-tâche. La commande `/ticket` lance en **parallèle** (plusieurs appels
   Agent dans un même message) toutes les sous-tâches sans dépendance entre elles — typiquement
   `backend-dev` et `frontend-dev` sur des sous-tâches disjointes — et enchaîne en série uniquement
   celles qui dépendent du résultat d'une autre (ex : frontend qui consomme une API pas encore posée).
   L'ordre de dépendance vient du découpage de l'étape 2 ; pas de parallélisation "à l'aveugle" sur
   des sous-tâches qui se touchent (même fichier/module).
   - **Mise à jour du plan au fil de l'eau** : après chaque sous-tâche terminée, la commande met à
     jour son `statut` (`done`/`failed`) et celui de sa vague dans le fichier `.sohub-claude-plugin/
     plans/NNNN-<slug>.md`. Une vague n'est marquée `done` que quand toutes ses sous-tâches le sont.
   - **Reprise sur interruption** : au lancement de `/ticket`, si un fichier de plan avec
     `Statut global: in_progress` existe déjà dans `.sohub-claude-plugin/plans/` pour ce projet, la
     commande le détecte, propose de reprendre à la première vague non `done` (au lieu de relancer
     `planner` et le découpage depuis zéro), ou de l'abandonner pour démarrer un nouveau plan.
5. **Vérification build** (skill `build-check`, lancée par la commande)
   Détecte l'outil de build de la stack (package.json → tsc/eslint, pom.xml → mvn, go.mod → go build,
   etc.) et l'exécute directement en Bash. Boucle de correction (3 tentatives max) en re-déléguant
   à `backend-dev`/`frontend-dev` avec les erreurs. Si le log de build est trop volumineux pour le
   contexte principal, la commande peut escalader vers un agent `build-verifier` ponctuel dont le seul
   rôle est d'isoler ce bruit et de renvoyer un résumé des erreurs — pas de duplication de la logique
   de détection de stack (déjà dans la skill).
6. **Synthèse finale**
   Ce qui a été implémenté / statut du build et des tests / constat des critères de
   validation / suite recommandée (review — hors scope v1).

## Architecture cible

Le dépôt est un **marketplace multi-plugins** : la racine ne porte pas elle-même le plugin, elle
liste les plugins disponibles (`plugins/<nom>/`) via `.claude-plugin/marketplace.json`, pour
pouvoir en générer d'autres à terme sans réorganiser l'existant.

```
claude-dev-plugin/                          # dépôt = marketplace
├── .claude-plugin/marketplace.json         # liste des plugins du dépôt (name, source, description)
├── PLAN.md
└── plugins/
    └── daily-dev-flow/                           # le plugin décrit par ce document
        ├── .claude-plugin/plugin.json      # manifeste (nom, version, description)
        ├── .mcp.json                       # config MCP requise (code-review-graph : uvx code-review-graph serve)
        ├── agents/
        │   ├── planner.md               # read-only, code-review-graph : besoin fonctionnel + cible technique
        │   ├── backend-dev.md
        │   ├── frontend-dev.md
        │   └── build-verifier.md           # optionnel — isole un log de build volumineux, résume les erreurs
        │                                   # (pas d'agent code-reviewer packagé : /ticket suggère le skill
        │                                   #  /code-review global existant en fin de flux)
        ├── skills/
        │   ├── detect-stack/               # heuristique de détection de stack et d'outil de build
        │   ├── build-check/                # lance le build détecté, parse le résultat (utilisée par /ticket)
        │   ├── rgaa-check/                 # vérifie et corrige la conformité RGAA 4.1 sur les fichiers modifiés
        │   ├── security-audit/             # audit sécurité (diff courant ou repo complet), rapport versionné
        │   └── generate-openapi/           # génère/rafraîchit la doc OpenAPI, versionnée
        ├── commands/
        │   └── ticket.md                   # /ticket "<texte>" — orchestrateur : découpe, routage, boucle build
        └── CLAUDE.md                       # conventions internes du plugin daily-dev-flow

# généré dans le projet cible où /ticket est utilisé (pas dans ce dépôt) :
<projet-cible>/
├── .sohub-claude-plugin/           # tout artefact généré par le plugin, gitignored automatiquement
│   ├── plans/                      # plans technico-fonctionnels des tickets traités
│   │   ├── 0001-<slug>.md
│   │   └── 0002-<slug>.md
│   ├── audit/                      # rapports d'audit sécurité
│   │   └── 0001-<slug>.md
│   └── documentations/             # doc OpenAPI générée
│       └── 0001-openapi.json
└── .gitignore                      # entrée `.sohub-claude-plugin/` ajoutée automatiquement si absente
```

## Skills additionnels (à la demande, indépendants du flux `/ticket`)

Ces skills s'invoquent séparément (l'utilisateur les déclenche directement, ou la synthèse finale de
`/ticket` les suggère en suite recommandée) — ce ne sont pas des étapes automatiques du flux ticket.
Basés sur les skills globaux existants (`rgaa-compliance`, `security-review`, `generate-openapi`),
adaptés pour écrire leur sortie versionnée dans `.sohub-claude-plugin/`.

- **`rgaa-check`** — détecte et corrige la conformité RGAA 4.1 sur les fichiers HTML/JSX/TSX/Vue modifiés.
  Corrige directement les fichiers ; pas de rapport versionné (comme le skill global source).
- **`security-audit`** — audit sécurité de la diff courante ou de l'applicatif complet (au choix de
  l'utilisateur) : vulnérabilités OWASP, secrets exposés, injections, mauvaises configs. Rédige un
  rapport dans `.sohub-claude-plugin/audit/NNNN-<slug>.md` (jamais écrasé) et propose d'appliquer les
  correctifs trouvés.
- **`generate-openapi`** — génère/rafraîchit la documentation OpenAPI 3.1 à partir du code source, écrite
  dans `.sohub-claude-plugin/documentations/NNNN-openapi.json`.

## Hors scope v1

- Intégration Jira / Linear / GitHub Issues (texte collé manuellement pour l'instant).
- Code review approfondie.
- Couverture de test générale (les tests écrits par le flux se limitent à la traduction des
  critères de validation — évolution du 2026-09-08, initialement « tests automatisés » tout
  entiers hors scope).

→ candidats pour une v2 si le besoin se confirme à l'usage.

## Prochaine étape

~~Scaffolder l'arborescence ci-dessus.~~ Fait. Arborescence en place (`.claude-plugin/`,
`agents/`, `skills/`, `commands/`, `CLAUDE.md`). Reste : tester `/ticket` sur un vrai ticket
dans un projet cible réel pour valider les contrats de bout en bout (notamment le mapping
`planner` → `contexte_planner` filtré, et la boucle de correction build).
