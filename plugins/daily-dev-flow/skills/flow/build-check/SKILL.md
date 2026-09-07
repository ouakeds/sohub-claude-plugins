---
name: build-check
description: >
  Lance l'outil de build détecté par detect-stack, parse le résultat, et décide si le log
  d'échec doit être traité en ligne ou délégué à l'agent build-verifier. Utilisée en interne
  par la commande /ticket en fin de flux et dans la boucle de correction (max 3 tentatives).
---

# build-check

Lance directement en Bash l'`outil_build` fourni par `contexte_stack` (jamais redétecté ici —
cf. `detect-stack`) et renvoie un résultat exploitable par `/ticket`.

## Entrée

`contexte_stack` tel que produit par `detect-stack` — objet plat, ou objet indexé par
sous-projet en cas de monorepo (cf. `skills/flow/detect-stack/SKILL.md`).

## Exécution

- Cas simple : lance `outil_build` tel quel.
- Cas monorepo (`contexte_stack` indexé par sous-projet) : lance **chaque** `outil_build`
  concerné par les sous-projets réellement touchés par les sous-tâches du ticket — pas
  systématiquement tous les sous-projets du repo. Le succès global est le ET logique de tous
  les sous-builds lancés ; en cas d'échec partiel, seuls les logs en échec sont transmis en
  aval (le sous-projet qui a réussi n'ajoute aucun bruit).

## Sortie

```json
{
  "succes": true,
  "log_brut": "string",
  "nb_lignes_log": 42,
  "outil_build_execute": "string — commande exacte lancée"
}
```

## Décision d'escalade vers `build-verifier`

Si `succes: false` :
- `nb_lignes_log` < 150 **et** `log_brut` < 8000 caractères → `/ticket` traite le résumé
  elle-même en ligne, sans spawn d'agent (coût fixe d'un appel agent plus cher qu'un traitement
  direct sur un log court).
- Au-delà de l'un des deux seuils → `/ticket` délègue à l'agent `build-verifier` avec
  `{log_brut, outil_build: outil_build_execute}`.

## Ce que cette skill ne fait pas

- Ne détecte pas la stack (déjà fait par `detect-stack`, en amont).
- Ne corrige rien elle-même — la correction est déléguée à `backend-dev`/`frontend-dev` par
  `/ticket`, avec au maximum 3 tentatives avant remontée à l'utilisateur.
- Timeout du process de build à calibrer par stack rencontrée (un premier build froid avec
  install de dépendances peut être long ; ne pas le confondre avec un blocage réel).
