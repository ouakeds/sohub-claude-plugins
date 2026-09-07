# Java

Complète `code-quality.md` et gagne sur lui en cas de conflit.

Sources : [Google Java Style Guide](https://google.github.io/styleguide/javaguide.html),
*Effective Java* (J. Bloch).

## Types et immuabilité

- **Champs `final` par défaut** ; une classe dont aucun champ ne bouge n'a pas d'état à
  protéger.
- **`record` pour les objets de valeur** (données transportées, résultats), classe pour ce qui
  porte un comportement.
- **Composition avant héritage.** Une hiérarchie ne s'ouvre que si elle est voulue : `sealed`
  pour un ensemble fermé de sous-types, `final` sinon.
- `equals` et `hashCode` sont écrits ensemble, ou pas du tout — l'un sans l'autre casse
  silencieusement toute collection à base de hachage.
- Types précis dans les signatures publiques : `List<Commande>` et non `Object`, l'interface
  (`List`, `Map`) en paramètre et non l'implémentation (`ArrayList`, `HashMap`).

## Absence et erreurs

- **Pas de `null` en retour d'API publique** : `Optional` pour une valeur qui peut manquer,
  collection vide pour une collection vide — jamais `null` pour dire « rien ».
- **`Optional` ne va ni en champ, ni en paramètre** : il sert à typer un retour, pas à modéliser
  un état.
- **Pas de `catch (Exception e)` fourre-tout** ni de bloc `catch` vide. Ce qui est rattrapé est
  traité ou renvoyé enrichi, la cause d'origine étant toujours conservée.
- **`try`-with-resources** pour tout ce qui se ferme ; aucune fermeture manuelle en `finally`.
- Les préconditions d'une méthode publique sont vérifiées à l'entrée, avec un message qui nomme
  l'argument fautif.

## Écriture

- **Injection par constructeur**, pas par champ : l'objet est utilisable dès sa construction et
  testable sans conteneur.
- Les `Stream` servent la lisibilité, pas la démonstration : pas de flux imbriqué, pas d'effet
  de bord dans un `forEach` qui aurait dû être une boucle.
- Pas de concaténation de `String` dans une boucle (`StringBuilder`, ou une jointure).
- La documentation Javadoc couvre les API publiques : ce que fait la méthode, ce qu'elle attend,
  ce qu'elle lève — pas la paraphrase de son corps.
- **Le formatage suit le formateur configuré dans le projet** (indentation, largeur, ordre des
  imports). Ne le reformate pas à la main et ne le remplace pas par tes préférences.
