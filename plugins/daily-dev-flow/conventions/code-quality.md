# Conventions de qualité du code — socle universel

Lu par `backend-dev` et `frontend-dev` avant d'écrire du code, quel que soit le langage.

Sources : *Clean Code* (R. C. Martin, ch. 2 « Meaningful Names » et ch. 3 « Functions »),
[Cognitive Complexity](https://www.sonarsource.com/resources/cognitive-complexity/) (SonarSource),
[Style Guides and Rules](https://abseil.io/resources/swe-book/html/ch08.html)
(*Software Engineering at Google*, ch. 8).

## Préséance — qui gagne en cas de conflit

Du plus fort au plus faible :

1. **le code réel du voisinage** — les conventions effectivement pratiquées dans les fichiers
   que tu modifies et dans leur module ;
2. **`docs/architecture.md` § Conventions** et les règles du `CLAUDE.md` du projet cible ;
3. **le fichier de langage** (`conventions/lang/<langage>.md`, cf. dernière section) ;
4. **ce fichier**.

Le plus spécifique gagne toujours. Ce document ne tranche que là où les trois premiers sont
muets — typiquement un projet neuf, ou une question que personne n'a encore tranchée. Un
langage peut contredire frontalement une règle d'ici (en Go, un nom court en portée courte est
la convention, pas un défaut) : c'est le fichier de langage qui fait foi.

**Ces règles s'appliquent au code que tu écris, jamais en passe de nettoyage sur le code
alentour.** Renommer ou redécouper hors de tes `fichiers_cibles`, c'est sortir du périmètre,
noyer le diff, et risquer d'écrire dans un fichier qu'une sous-tâche parallèle tient déjà.

## Nommage

- **Un nom dit l'intention.** S'il faut un commentaire pour l'expliquer, c'est le nom qu'il faut
  refaire, pas le commentaire qu'il faut ajouter.
- **Pas de type ni de structure dans le nom** quand ce n'est pas le type réel : `accountList`
  sur autre chose qu'une liste est un mensonge qui survit à tous les refactorings suivants.
- **Pas de distinction creuse** — `data`, `info`, `tmp`, `obj`, `Manager`, `Helper`, `Utils`,
  `UserData` à côté de `UserInfo`. Si deux noms voisins ne disent pas ce qui les sépare, l'un
  des deux est de trop.
- **Longueur proportionnelle à la portée** : `i` dans une boucle de trois lignes est correct, `i`
  en champ d'objet ou en export de module ne l'est pas.
- **Un mot par concept sur tout le projet.** `get`, `fetch`, `retrieve` mélangés obligent à lire
  trois implémentations pour découvrir qu'elles font la même chose.
- **Formes grammaticales** : fonction = groupe verbal (`publishInvoice`), variable et type =
  groupe nominal, booléen = prédicat (`isActive`, `hasAccess`, `canPublish`). Un booléen nommé
  `status` ou `flag` force à remonter à son affectation pour savoir ce que `true` veut dire.
- **Aucun nombre ni chaîne magique dans une expression** : constante nommée, déclarée au plus
  près de son usage. `86400` n'est pas cherchable, `SECONDS_PER_DAY` l'est.
- **Vocabulaire du domaine d'abord.** Le nom métier employé par l'utilisateur et par le cadrage
  bat un synonyme technique ; un même concept ne porte pas deux noms selon la couche.
- **Abréviations** : uniquement celles du domaine ou universellement lues (`id`, `url`, `http`).

## Fonctions

- **Une fonction fait une chose**, à un seul niveau d'abstraction : une fonction qui orchestre
  n'ouvre pas aussi une connexion et ne concatène pas une chaîne d'affichage.
- **Taille** : le critère n'est pas un plafond de lignes mais la **complexité cognitive
  ≤ 15** (seuil par défaut SonarSource). En pratique : imbrication ≤ 3 niveaux, retours
  anticipés (*guard clauses*) plutôt qu'un `if` englobant tout le corps.
- **≤ 4 paramètres.** Au-delà, un objet/type nommé — une liste de paramètres qu'on ne peut pas
  lire sans compter est une liste dont on inversera deux arguments un jour.
- **Pas de paramètre-drapeau booléen** : `render(item, true)` est illisible sur l'appel. Deux
  fonctions nommées, ou un type explicite.
- **Pas de paramètre de sortie muté** : une fonction renvoie son résultat, elle ne le dépose pas
  dans un argument.
- **Commande ou requête, pas les deux** : une fonction qui répond *et* modifie l'état surprend
  son appelant, qui l'appellera deux fois.

## Segmentation et structure

- **Un fichier, une responsabilité.** Le signal d'alerte n'est pas la longueur, c'est le « et »
  dans la phrase qui décrit le fichier.
- **Colocalise ce qui change ensemble**, sépare ce qui change pour des raisons différentes.
- **Sens des dépendances** : le domaine ne dépend pas de l'infrastructure ni du transport.
  Aucun cycle entre modules.
- **Une frontière de module est un contrat explicite.** Ce qui la traverse est déclaré ; rien
  d'interne n'en sort par accident. Sur un projet cadré, ce contrat est déjà écrit dans
  `docs/architecture.md` — tu l'importes, tu n'en déclares pas une variante locale.
- **Duplication : extraire à la troisième occurrence.** Deux fragments qui se ressemblent
  aujourd'hui mais changeront pour des raisons différentes ne sont pas des doublons ; les
  fusionner crée un couplage plus cher que la copie.
- **Pas d'abstraction pour un besoin non demandé** : interface à implémentation unique, couche
  supplémentaire « au cas où », généricité spéculative. Le besoin est dans le ticket, pas dans
  l'anticipation.

## État et effets de bord

- **Immuable par défaut** ; une valeur mutable est un choix qui se justifie.
- **Portée minimale**, déclaration au plus près du premier usage.
- **Une variable, un rôle** : réutiliser la même variable pour deux choses successives est le
  défaut le plus coûteux à relire.
- **Une valeur calculable ne se stocke pas** — la dériver évite les deux sources de vérité qui
  divergent.
- **Effets de bord regroupés aux frontières** (E/S, réseau, horloge, aléa), pas dispersés au
  milieu de la logique. Pas d'état global mutable.

## Erreurs

- **Aucune erreur avalée** : pas de `catch` vide, pas de log-and-continue silencieux qui laisse
  le programme continuer sur une donnée absente.
- **Échouer tôt, à la frontière** : l'entrée est validée là où elle entre, pas trois couches
  plus bas où l'on ne sait plus quoi renvoyer à l'appelant.
- **Erreurs attendues et inattendues sont distinguées** (validation, ressource introuvable,
  conflit d'un côté ; bug et panne de l'autre) — l'appelant ne peut pas traiter ce qu'il ne
  peut pas différencier.
- **Message contextualisé** : ce qui échouait et sur quelle donnée. Jamais un secret, un jeton,
  un mot de passe ni une donnée personnelle dans un message d'erreur ou un log.
- **L'exception n'est pas du contrôle de flux.**

## Commentaires

- **Le pourquoi, jamais le quoi.** Un commentaire qui paraphrase la ligne suivante est une dette
  qui deviendra fausse au premier changement.
- **Pas de code commenté, pas de commentaire-journal** (`// modifié le 12/03 par …`) : c'est le
  rôle de Git.
- **Un `TODO` ne se pose qu'avec ce qui le débloque** ; sans ça, il devient décor.
- La documentation d'API publique suit l'idiome du langage (cf. fichier de langage).

## Fichier de langage à lire

D'après `contexte_stack.langage` :

| Langage détecté | Fichier |
|---|---|
| TypeScript, JavaScript (y compris TSX/JSX, Node) | `conventions/lang/typescript.md` |
| Java | `conventions/lang/java.md` |
| Kotlin | `conventions/lang/kotlin.md` |
| tout autre | *aucun* |

**Aucun fichier pour le langage détecté n'est pas un blocage** : tu t'appuies alors sur ce
socle et sur les conventions du code réel. Tu n'inventes pas d'idiome, et tu ne transposes pas
mécaniquement une règle d'un autre langage.
