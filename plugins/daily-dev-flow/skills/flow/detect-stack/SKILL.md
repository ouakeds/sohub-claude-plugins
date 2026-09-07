---
name: detect-stack
description: >
  Détecte langage, framework, outil de build et gestionnaire de paquets du projet cible (ou
  d'un sous-projet en monorepo) à partir de ses fichiers manifestes. Utilisée en interne par la
  commande /ticket, une seule fois par ticket — jamais invoquée directement par l'utilisateur.
user-invocable: false
---

# detect-stack

Détecte la stack technique à partir des fichiers manifestes du projet, sans dépendre d'un
hardcode de projet particulier. Exécutée une seule fois par ticket, en amont du découpage en
sous-tâches — son résultat (`contexte_stack`) est ensuite propagé tel quel par `/ticket` à
toutes les sous-tâches `backend-dev`/`frontend-dev` et réutilisé par `build-check`.

## Sortie (`contexte_stack`)

Objet plat :

```json
{
  "langage": "typescript",
  "framework": "nextjs",
  "outil_build": "tsc --noEmit && next build",
  "gestionnaire_paquets": "pnpm",
  "fichier_manifeste": "package.json"
}
```

- `langage` : toujours renseigné.
- `framework` : `null` si aucun framework identifiable.
- `outil_build` : la commande shell exacte à lancer pour valider une compilation/build — c'est
  ce que `build-check` exécute tel quel.
- `gestionnaire_paquets` : `null` si non applicable (ex. Go).
- `fichier_manifeste` : chemin relatif ayant servi à la détection.

## Manifestes reconnus (v1)

`package.json` (+ `tsconfig.json` pour distinguer JS/TS), `pom.xml`, `build.gradle`/
`build.gradle.kts`, `go.mod`, `requirements.txt`/`pyproject.toml`, `Cargo.toml`,
`composer.json`. Liste non exhaustive, à étendre à l'usage.

## Heuristique

1. **Monorepo / manifestes multiples** : privilégier le manifeste le plus proche des
   `fichiers_cibles` identifiés par `researcher`, pas systématiquement celui à la racine.
2. Priorité : manifeste explicite > extension de fichier > convention de nommage, en cas de
   signaux contradictoires.
3. **Deux stacks légitimes dans le même repo** (ex. `backend/` en Go + `frontend/` en
   TypeScript) : renvoyer un objet indexé par répertoire racine de sous-projet plutôt qu'un
   objet unique :
   ```json
   {
     "backend/": { "langage": "go", "framework": null, "outil_build": "go build ./...", "gestionnaire_paquets": null, "fichier_manifeste": "backend/go.mod" },
     "frontend/": { "langage": "typescript", "framework": "react", "outil_build": "npm run build", "gestionnaire_paquets": "npm", "fichier_manifeste": "frontend/package.json" }
   }
   ```
   Dans ce cas, `/ticket` choisit la clé pertinente par sous-tâche selon `fichiers_cibles`.

## Utilisation

Cette skill est purement analytique (lecture de fichiers manifestes + heuristique) — pas de
`Bash`, pas d'installation de dépendances. Elle ne relance jamais de build ; c'est le rôle de
`build-check`.
