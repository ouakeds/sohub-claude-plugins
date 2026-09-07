# TypeScript / JavaScript

Complète `code-quality.md` et gagne sur lui en cas de conflit. S'applique aussi bien au code
navigateur qu'à Node, en `.ts`/`.tsx` comme en `.js`/`.jsx` — les règles marquées
*(TypeScript)* n'ont pas d'objet en JavaScript pur.

Sources : [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html),
[Google TypeScript Style Guide](https://google.github.io/styleguide/tsguide.html),
[Google JavaScript Style Guide](https://google.github.io/styleguide/jsguide.html).

## Types *(TypeScript)*

- **`any` est interdit.** Une valeur non typée entre en `unknown` et se réduit explicitement —
  `any` ne masque pas l'incertitude, il la propage à tout ce qui touche la valeur.
- **Pas de `as` pour faire taire le compilateur.** `as const` et `satisfies` sont légitimes ; une
  assertion de type qui contredit l'inférence est un bug reporté à l'exécution.
- **Modélise par union discriminée** plutôt que par champs optionnels corrélés :
  `{ statut: 'ok', donnee } | { statut: 'erreur', message }` rend impossible l'état incohérent
  que trois `?` autorisent.
- **Pas d'`enum`** : union de littéraux ou objet `as const`. L'`enum` TypeScript émet du code à
  l'exécution et se comporte mal à l'interopérabilité.
- `readonly` sur ce qui ne doit pas bouger ; aucun paramètre muté.
- `strict` est attendu activé. Pas de `@ts-ignore` — à défaut `@ts-expect-error` avec sa raison
  sur la même ligne.
- Types de retour explicites sur les fonctions exportées : l'inférence est un détail
  d'implémentation, pas un contrat.

## Valeurs et flux

- **`const` par défaut, `let` si nécessaire, jamais `var`.**
- **Un seul de `null` et `undefined`** dans le code du projet ; suis celui déjà employé.
- **Pas de promesse flottante** : tout appel asynchrone est `await`é ou sa gestion d'erreur est
  écrite. Ce qui est indépendant part en `Promise.all`, pas en `await` successifs.
- `async`/`await` plutôt que des chaînes de `.then()`.
- **`throw` d'une `Error`** (ou d'une sous-classe), jamais d'une chaîne ni d'un objet nu — sinon
  la pile d'appels est perdue.
- `===` systématiquement ; `== null` reste acceptable pour tester les deux vides d'un coup, à
  condition d'être le choix assumé du projet.
- Enchaînement optionnel et coalescence (`?.`, `??`) plutôt que des gardes `&&` en cascade —
  `??` et `||` ne traitent pas `0` et `''` de la même façon.

## Modules et nommage

- `camelCase` pour les valeurs et fonctions, `PascalCase` pour les types, classes et composants,
  `SCREAMING_SNAKE_CASE` pour les constantes de module.
- **Imports nommés** ; l'export par défaut ne s'emploie que si le projet le pratique déjà (il
  autorise un nom différent à chaque import, donc une recherche qui rate).
- Pas d'import de chemin profond dans les entrailles d'un autre module : on passe par ce qu'il
  expose.
- En JavaScript pur, les signatures publiques portent leur JSDoc — c'est le seul contrat de type
  disponible pour l'appelant.
