---
name: rgaa-check
description: >
  Détecte et corrige la conformité RGAA 4.1 sur les fichiers HTML/JSX/TSX/Vue modifiés par la
  session en cours. Corrige directement les fichiers, pas de rapport versionné. Skill autonome,
  invocable à tout moment — pas une étape automatique de /ticket.
---

# rgaa-check

Adaptation du skill `rgaa-compliance` global de l'utilisateur, restreinte aux fichiers
modifiés (diff courante) plutôt qu'à l'ensemble du projet, pour rester rapide à invoquer en
suite d'un ticket.

## Portée

Fichiers HTML/JSX/TSX/Vue modifiés dans la session courante (ou la diff courante si invoquée
hors contexte `/ticket`) — jamais l'ensemble du projet sans que l'utilisateur le demande
explicitement.

## Vérifications et corrections

Applique les règles RGAA 4.1 pertinentes au balisage : labels de formulaires, alternatives
textuelles, contrastes, structure de titres, navigation au clavier, attributs ARIA corrects
(pas de sur-utilisation). Corrige directement le fichier plutôt que de se limiter à un
signalement — cohérent avec le comportement du skill global source.

## Pas de rapport versionné

Contrairement à `security-audit`/`openapi-doc`, cette skill ne produit pas de fichier dans
`.sohub-claude-plugin/` : les corrections sont directement dans le code, visibles via `git
diff`. Un rapport séparé serait une trace redondante avec l'historique git.
