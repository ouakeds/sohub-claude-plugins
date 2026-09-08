# <NNNN> — <titre du lot>

Statut global: <todo|in_progress|done|failed>
Couvre: <items du périmètre couverts, ex. D1, D2 — ou `hors backlog`>
Dépend de: <NNNN, NNNN — ou `—`>
Parallélisable avec: <NNNN, NNNN — ou `—`>
Créé le: <AAAA-MM-JJ>

## Besoin fonctionnel

<Ce que le lot livre, du point de vue de l'usage, en 2 à 4 lignes.>

## Critères de validation

| Item | Validé par |
|------|------------|
| <D1 — libellé de l'item, ou `hors backlog`> | <critère — recopié mot pour mot de docs/cadrage.md ; pour un lot `hors backlog`, rédigé au lancement et validé à la gate> |

## Fichiers prévus

| Fichier | Rôle |
|---------|------|
| <chemin> | <rôle, repris de docs/architecture.md> |

## Contrats concernés

- <section de docs/architecture.md à recopier dans le payload des sous-tâches>

## Cible technique

<Rempli au lancement du lot.>

## Découpage

<Rempli au lancement du lot : id, titre, type, fichiers_cibles, criteres_validation,
depends_on, statut.>

## Vagues d'exécution

<Rempli au lancement du lot : composition et statut de chaque vague.>

## Résultats

<Rempli pendant l'exécution : une sous-section `### <id> — <titre>` par sous-tâche terminée,
portant son `resume` complet.>

## Signaux retex

<Rempli pendant l'exécution, seulement quand quelque chose accroche : une ligne datée par
signal — découpage modifié à la gate, sous-tâche `failed`, tentative de la boucle de build,
critère non rempli, consigne corrective de l'utilisateur, ambiguïtés posées (et réponses),
reprise après interruption, override de la gate de dépendance. Plus la ligne de compteurs de
l'étape 6 (agents, vagues, tentatives de build), qui ne compte pas comme un accroc. Reste
vide, compteurs exceptés, sur un ticket sans accroc.>
