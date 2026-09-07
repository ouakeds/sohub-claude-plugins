# Conventions de qualité — couche backend

Complète `code-quality.md`, ne le remplace pas. Lu par `backend-dev`.

## Découpage en couches

- Le découpage du projet fait foi. À défaut (projet neuf, aucun voisinage à lire) : **transport**
  (route, contrôleur, handler) → **métier** (service, cas d'usage) → **persistance**
  (repository, DAO, client).
- **Le transport traduit, il ne décide pas** : il désérialise, valide, appelle, sérialise. Une
  règle métier écrite dans un contrôleur devient inatteignable depuis tout autre point d'entrée.
- **La couche métier ignore le transport** : pas d'objet requête/réponse HTTP, pas de code de
  statut, pas d'en-tête au-delà de la frontière.
- **La correspondance erreur métier → code de statut vit à un seul endroit.** Dispersée, elle
  produit deux réponses différentes pour la même erreur selon l'endpoint.

## Frontières et contrats

- Le contrat exposé (endpoint, événement, type partagé) est celui de `docs/architecture.md`,
  recopié tel quel. S'il te paraît faux ou incomplet, c'est un blocage à remonter — une
  sous-tâche parallèle travaille sur le même contrat.
- **Aucune donnée d'entrée n'est fiable** : type, format, bornes et autorisations sont vérifiés
  à la frontière, avec le mécanisme de validation déjà présent dans le projet.
- **Ce qui sort est choisi, pas déversé** : une entité de persistance n'est pas renvoyée telle
  quelle à l'appelant — c'est ainsi qu'un hash de mot de passe finit dans une réponse publique.

## Persistance et intégrations

- **Une transaction couvre une unité métier**, ouverte et fermée au même niveau — jamais une
  transaction par requête élémentaire dans une boucle.
- **Pas de N+1** : la requête qui rapporte les enfants est écrite une fois, pas par élément.
- Une **écriture rejouable** (webhook, message, retry) dit comment elle se comporte au deuxième
  passage. Le silence sur ce point est un doublon en production.
- Un appel externe porte un **délai d'expiration** et un comportement d'échec explicite ; il
  n'attend pas indéfiniment.

## Journalisation, secrets, temps

- Log **structuré**, au bon niveau, avec de quoi corréler une trace. Jamais de secret, de jeton
  ni de donnée personnelle — ni dans le message, ni dans le contexte joint.
- **Aucun secret en dur** : configuration ou variable d'environnement, résolue au démarrage.
- **Temps en UTC** au stockage et en transport ; la conversion locale appartient à l'affichage.
  L'horloge et l'aléa passent par un point injectable plutôt que d'être appelés au milieu de la
  logique.
