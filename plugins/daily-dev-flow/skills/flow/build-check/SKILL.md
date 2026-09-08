---
name: build-check
description: >
  Lance l'outil de build puis l'outil de test détectés par detect-stack, parse le résultat, et
  décide si le log d'échec doit être traité en ligne ou délégué à l'agent build-verifier.
  Utilisée en interne par la commande /ticket en fin de flux et dans la boucle de correction
  (max 3 tentatives).
user-invocable: false
---

# build-check

Lance directement en Bash l'`outil_build` fourni par `contexte_stack` (jamais redétecté ici —
cf. `detect-stack`) et renvoie un résultat exploitable par `/ticket`.

## Entrée

`contexte_stack` tel que produit par `detect-stack` — objet plat, ou objet indexé par
sous-projet en cas de monorepo (cf. `skills/flow/detect-stack/SKILL.md`).

## Exécution

- Cas simple : lance `outil_build` tel quel, puis — si le build passe et que `outil_test`
  est non-`null` — lance `outil_test` tel quel. **Le succès global est build ET tests** : un
  build vert avec des tests rouges est un échec. `outil_test: null` = pas de tests à lancer,
  le succès se réduit au build (cas signalé en amont par les agents dev dans leur `resume`).
- Cas monorepo (`contexte_stack` indexé par sous-projet) : lance **chaque** `outil_build`
  (puis `outil_test`) concerné par les sous-projets réellement touchés par les sous-tâches du
  ticket — pas systématiquement tous les sous-projets du repo. Le succès global est le ET
  logique de tous les sous-builds et sous-tests lancés ; en cas d'échec partiel, seuls les
  logs en échec sont transmis en aval (le sous-projet qui a réussi n'ajoute aucun bruit).

## Sortie

Le log complet est **écrit dans un fichier**, jamais renvoyé inline : rediriger la sortie du
build vers `.sohub-claude-plugin/build-logs/<horodatage>.log` du projet cible (dossier créé au
besoin, gitignoré avec le reste de `.sohub-claude-plugin/`). Le contexte de l'orchestrateur ne
paie ainsi que ce qu'il traite réellement — un log de 400 lignes chargé puis délégué est payé
deux fois pour rien.

```json
{
  "succes": true,
  "chemin_log": "chemin/relatif/du/fichier.log",
  "queue_log": "string — les ~30 dernières lignes du log",
  "nb_lignes_log": 42,
  "outil_build_execute": "string — commande(s) exacte(s) lancée(s), tests compris"
}
```

Un log de tests en échec suit exactement le même régime qu'un log de build : mêmes champs,
mêmes seuils d'escalade ci-dessous.

## Décision d'escalade vers `build-verifier`

Si `succes: false` :
- `nb_lignes_log` < 150 → `/ticket` traite le résumé elle-même en ligne, sans spawn d'agent,
  depuis `queue_log`, en n'ouvrant `chemin_log` que si la queue ne suffit pas (coût fixe d'un
  appel agent plus cher qu'un traitement direct sur un log court).
- Au-delà → `/ticket` délègue à l'agent `build-verifier` avec
  `{chemin_log, outil_build: outil_build_execute}` ; à partir de la deuxième tentative de la
  boucle de correction, le delta d'erreurs plutôt que le log entier, s'il est isolable.

## Ce que cette skill ne fait pas

- Ne détecte pas la stack (déjà fait par `detect-stack`, en amont).
- Ne corrige rien elle-même — la correction est déléguée à `backend-dev`/`frontend-dev` par
  `/ticket`, avec au maximum 3 tentatives avant remontée à l'utilisateur.
- Timeout du process de build à calibrer par stack rencontrée (un premier build froid avec
  install de dépendances peut être long ; ne pas le confondre avec un blocage réel).
