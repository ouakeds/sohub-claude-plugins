# Conventions de qualité — couche frontend

Complète `code-quality.md`, ne le remplace pas. Lu par `frontend-dev`.

## Composants

- **Un composant a une responsabilité d'affichage.** Le signal d'extraction n'est pas le nombre
  de lignes : c'est le composant qui rend *et* orchestre un appel réseau *et* dérive une règle
  métier.
- **La logique réutilisée sort du composant** — hook, composable, store ou fonction pure, selon
  ce que le projet pratique déjà. Deux composants ne partagent jamais une logique par copie.
- **Pas de logique dans le template/JSX** au-delà d'une condition ou d'une itération : une
  valeur calculée se nomme au-dessus du rendu.
- **Aucun composant défini à l'intérieur d'un autre** : il est recréé à chaque rendu, ce qui
  remonte l'état de son sous-arbre à zéro sans raison visible.

## État

- **L'état vit au plus près de son usage.** Il ne remonte que quand deux frères en dépendent
  réellement, et il ne devient global que quand il traverse des branches sans lien.
- **Une valeur dérivable ne se met pas en état** — deux sources de vérité pour la même donnée
  divergent toujours.
- **Les trois états d'un appel réseau sont traités** : chargement, erreur, succès. Un rendu qui
  suppose la donnée déjà là casse au premier appel lent. Le motif employé est celui déjà en
  place dans le projet, pas un motif local réinventé par composant.
- **Effets réservés à la synchronisation avec l'extérieur** : dépendances complètes, nettoyage
  écrit. Un effet qui ne fait que dériver une valeur n'a pas lieu d'être.
- **Clé de liste stable, issue de la donnée** — l'index ne convient que pour une liste qui ne
  change jamais d'ordre ni de taille.

## Rendu et accessibilité

- Élément interactif = élément interactif **natif** (`button`, `a`, `input`), pas un `div` avec
  un gestionnaire de clic : c'est ce qui donne gratuitement le focus, le clavier et le rôle.
- Champ de formulaire **lié à son label**, message d'erreur rattaché au champ qu'il concerne.
- Hiérarchie de titres continue, focus visible, contraste suffisant.
- Ce n'est pas une passe séparée : c'est le markup écrit correctement du premier coup. L'audit
  complet reste le rôle de la skill `rgaa-check`.

## Style et contenu

- **Pas de valeur de design en dur** (couleur, espacement, rayon) si le projet a des tokens, un
  thème ou une échelle : la valeur littérale échappe à tout changement de thème.
- Le texte affiché passe par le mécanisme d'internationalisation **s'il en existe un** ; sinon
  il reste au plus près du composant, jamais dupliqué entre deux vues.
