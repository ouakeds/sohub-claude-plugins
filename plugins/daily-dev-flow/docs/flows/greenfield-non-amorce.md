# Flux : projet cadré, pas encore amorcé

Cas déclencheur (étape 1 de `/ticket`) : `CLAUDE.md` présent, aucun manifeste. L'étape 11 de
`/new-project` amorce normalement le projet ; ce cas est donc celui d'un cadrage interrompu
avant elle, ou d'un projet cadré par une version antérieure du plugin. Ni `planner` ni
`detect-stack` ne sont lancés — il n'y a rien à chercher ni à lire.

1. **La stack est déjà écrite** : lis-la dans `CLAUDE.md` (section `Stack` + `Commandes`) et
   reconstitue le `contexte_stack` plat attendu par la suite du flux — `outil_build` est la
   commande de build qui y figure, `outil_test` la commande de test (ou `null` si le cadrage
   n'en fixe pas), `fichier_manifeste` celui qui **sera créé**. N'appelle pas `detect-stack`
   pour la retrouver, il n'a rien à lire.
2. **Le digest se réduit au besoin du ticket** : `fichiers_cibles = []`, `symboles = []`, tout
   est à créer. Sur ce premier ticket, `docs/` **est** la matière du découpage, pas une
   lecture optionnelle : ouvre une fois `docs/architecture.md` (modules, contrats,
   arborescence au fichier près) et `docs/cadrage.md` (section `Critères de validation`).
   C'est le seul endroit où vit ce que `CLAUDE.md` ne résume pas, et ce qui évite que deux
   agents parallèles inventent deux versions divergentes du même contrat. Aux tickets
   suivants, le projet ayant un code source, ces fichiers redeviennent une lecture à la
   demande. **En mode lot planifié**, le besoin, les critères et les fichiers prévus sont déjà
   dans le lot : tu n'ouvres `docs/architecture.md` que pour recopier les contrats qu'il
   référence, et pas `docs/cadrage.md` du tout.
3. **Amorce le projet avant le découpage** : invoque la skill `bootstrap-project` et exécute
   sa procédure toi-même, en ligne, sans agent — elle porte ce qui s'écrit, ce qui ne s'écrit
   jamais, le build de fumée et les garde-fous, à un seul endroit, partagé avec l'étape 11 de
   `/new-project`. Le contrat étant sur disque avant le découpage, **backend et frontend
   partent ensemble en vague 1** ; il ne reste de dépendance qu'entre sous-tâches qui se
   touchent réellement.
4. **Le périmètre n'est pas orphelin** : le cadrage existe mais l'étape 12 de `/new-project`
   (le backlog) n'a jamais tourné. Invoque `generate-backlog` en mode **génération** — ses
   seules entrées sont `docs/cadrage.md` et `docs/architecture.md`, elles sont là — puis
   propose à l'utilisateur le numéro du lot qui couvre sa demande au lieu de continuer en
   ticket ad hoc. Sans cette projection, les autres items du `Dans` n'auraient ni fichier, ni
   numéro, ni statut, et chaque ticket suivant re-dériverait le même découpage.
5. **L'étape 2 s'applique ensuite** (sur le lot retenu), avec trois différences :
   - le `contexte_planner` filtré par `fichiers_cibles` n'a pas lieu d'être — transmets les
     seules contraintes propres à la sous-tâche ;
   - **les contrats de `docs/architecture.md` traversent le découpage** : une sous-tâche qui
     produit ou consomme un contrat le reçoit dans son payload, recopié tel quel, jamais
     reformulé. Chaque sous-tâche porte le critère de validation de l'item de périmètre
     qu'elle sert (`criteres_validation`) — c'est lui qui dit quand elle est finie ;
   - **hors ces contrats et ces critères, ne recopie rien de `CLAUDE.md` ni de `docs/`** :
     `CLAUDE.md` est chargé automatiquement par chaque sous-agent, et les `docs/` sont à sa
     portée s'il en a besoin — les redonner en bloc, c'est payer deux fois le même contexte.
