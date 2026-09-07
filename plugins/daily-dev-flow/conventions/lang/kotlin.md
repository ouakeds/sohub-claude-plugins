# Kotlin

Complète `code-quality.md` et gagne sur lui en cas de conflit.

Sources : [Kotlin coding conventions](https://kotlinlang.org/docs/coding-conventions.html),
[Kotlin style guide (Android)](https://developer.android.com/kotlin/style-guide).

## Nullabilité

- **`!!` est interdit** : il transforme une hypothèse en plantage à l'exécution. `?.`, `?:`,
  `requireNotNull(x) { "…" }` ou une garde `if (x == null) return` selon le cas.
- Un type nullable est un choix de modélisation, pas un défaut de conception à corriger plus
  tard : si la valeur ne peut pas manquer, le type ne porte pas `?`.
- `lateinit` seulement quand l'initialisation est réellement différée par le cycle de vie du
  framework — jamais pour contourner un `val` qu'on pouvait construire.

## Types et flux

- **`val` par défaut**, `var` justifié.
- **`data class` pour les valeurs**, `sealed class`/`sealed interface` pour un ensemble d'états
  exclusifs — le `when` devient exhaustif et se passe de branche `else`, donc un nouvel état
  casse la compilation au lieu de passer inaperçu.
- **Un `when` sur un type scellé n'a pas de `else`** : c'est tout l'intérêt.
- Les erreurs attendues remontent en type de retour (`Result`, type scellé) plutôt qu'en
  exception ; l'exception reste pour l'inattendu.
- Fonctions d'extension pour éviter des classes fourre-tout, mais pas au point qu'on ne sache
  plus d'où vient une méthode.
- **Arguments nommés** dès qu'un appel enchaîne des booléens ou des paramètres de même type.

## Coroutines

- **Jamais `GlobalScope`** : une coroutine appartient à un scope dont la durée de vie est celle
  de ce qui l'a lancée, sans quoi elle survit à son appelant.
- Le dispatcher est **injecté**, pas codé en dur dans la fonction suspendue.
- `runBlocking` reste au point d'entrée du programme ou au test, jamais dans le code applicatif.
- L'annulation est coopérative : ce qui boucle vérifie son état actif, ce qui s'ouvre se ferme.
