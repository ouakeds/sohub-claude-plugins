---
name: generate-openapi
description: >
  Génère ou rafraîchit la documentation OpenAPI 3.1 à partir du code source, écrite en version
  dans .sohub-claude-plugin/documentations/. Skill autonome, invocable à tout moment — pas une
  étape automatique de /ticket.
disable-model-invocation: true
---

# generate-openapi

Adaptation du skill `generate-openapi` global de l'utilisateur (hors plugin), propre à ce
plugin : au lieu
d'un fichier unique écrasé à chaque génération, chaque exécution produit une nouvelle version
horodatée/numérotée dans le projet cible.

## Génération

Analyse le code source (routes, contrôleurs, schémas de validation déjà en place) pour produire
un document OpenAPI 3.1 complet : chemins, méthodes, paramètres, schémas de requête/réponse,
codes de statut. S'appuie sur les conventions déjà présentes dans le projet (annotations,
schémas de validation existants) plutôt que de redéfinir un format propre au plugin.

## Persistance

Même convention que `security-audit` (cf. `skills/audit/security-audit/SKILL.md`) :

1. Créer `.sohub-claude-plugin/` et l'entrée `.gitignore` correspondante si absentes (à la
   première exécution sur le projet cible).
2. Créer `.sohub-claude-plugin/documentations/` si absent.
3. Numéro de version `NNNN` : scan des fichiers existants dans ce sous-dossier, max + 1,
   zero-paddé sur 4 chiffres. Jamais réutilisé, jamais écrasé.
4. Écrire dans `.sohub-claude-plugin/documentations/NNNN-openapi.json`.

## Ce que cette skill ne fait pas

- N'importe pas directement dans un outil externe (Bruno/Postman) — produit le fichier
  `openapi.json`, l'utilisateur l'importe lui-même s'il le souhaite (cf. skill globale
  `generate-openapi` pour ce flux, si disponible côté utilisateur).
- Ne modifie jamais le code source pour "faire coller" la doc au format attendu — documente le
  code tel qu'il est, remonte les incohérences éventuelles plutôt que de les masquer.
