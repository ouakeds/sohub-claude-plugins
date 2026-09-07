---
name: security-audit
description: >
  Audit sécurité de la diff courante ou de l'application complète (au choix de l'utilisateur) :
  vulnérabilités OWASP, secrets exposés, injections, mauvaises configurations. Rédige un
  rapport versionné dans .sohub-claude-plugin/audit/ et propose d'appliquer les correctifs
  trouvés. Skill autonome, invocable à tout moment — pas une étape automatique de /ticket.
---

# security-audit

Adaptation du skill `security-review` global de l'utilisateur, propre à ce plugin : au lieu
d'appliquer les correctifs directement sans trace, elle écrit d'abord un rapport versionné dans
le projet cible avant de proposer les correctifs.

## Portée

Demande à l'utilisateur (s'il ne l'a pas précisé) : diff courante uniquement, ou application
complète. Cherche : vulnérabilités OWASP Top 10, secrets/identifiants en clair, injections
(SQL, commande, XSS...), mauvaises configurations (CORS trop permissif, headers de sécurité
absents, permissions excessives).

## Persistance du rapport

Convention partagée par les skills additionnels du plugin (`security-audit`, `openapi-doc`) :

1. **Première exécution sur le projet cible** : créer `.sohub-claude-plugin/` à la racine du
   projet cible s'il n'existe pas, et ajouter la ligne `.sohub-claude-plugin/` au `.gitignore`
   du projet cible si elle n'y est pas déjà (lire le fichier, ajouter la ligne seulement si
   absente — jamais de doublon, jamais d'écrasement du reste du `.gitignore`).
2. Créer `.sohub-claude-plugin/audit/` si absent.
3. Numéro de version `NNNN` : scanner les fichiers existants dans `.sohub-claude-plugin/audit/`,
   prendre le plus haut numéro trouvé + 1, zero-paddé sur 4 chiffres. Jamais réutilisé, jamais
   écrasé — chaque exécution produit un nouveau fichier.
4. Écrire le rapport dans `.sohub-claude-plugin/audit/NNNN-<slug>.md`, `<slug>` en kebab-case
   dérivé du périmètre audité (ex. `diff-courante`, `audit-complet`), tronqué à ~40 caractères.

## Contenu du rapport

- En-tête : périmètre audité (diff/branche ou repo complet), date, résumé en une ligne.
- Liste des findings, du plus critique au moins critique : fichier, ligne, catégorie de
  vulnérabilité, description, sévérité (`critique`/`élevée`/`moyenne`/`faible`).
- Section "Correctifs proposés" en fin de rapport.

## Après le rapport

Proposer explicitement à l'utilisateur d'appliquer les correctifs trouvés (pas d'application
automatique et silencieuse) — laisser le choix, notamment pour les findings à faux-positif
possible.
