# claude-dev-plugin — conventions internes

Plugin autonome (roster d'agents propre, pas d'héritage d'un CLAUDE.md global) qui outille le
flux **ticket → analyse → développement → vérification de build**, générique multi-stack.

Voir `PLAN.md` (racine du dépôt du plugin) pour le cadrage complet et `agents-prep/` pour les
décisions de contrat détaillées derrière chaque agent/skill/commande.

## Principes transverses

- **Générique multi-stack** : aucune convention de langage/framework hardcodée dans un agent ou
  une skill. La stack est détectée une fois par ticket (`skills/detect-stack`) et propagée, pas
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
