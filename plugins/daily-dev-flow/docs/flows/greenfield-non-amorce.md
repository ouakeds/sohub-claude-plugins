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
3. **Amorce le projet toi-même, en ligne, avant le découpage** — manifeste et scripts du
   cadrage, dépendances installées, dossiers de l'arborescence, fichiers de contrats recopiés
   tels quels depuis `docs/architecture.md`, configuration de build et de test, point
   d'entrée, `.gitignore`, puis `README.md` via la skill `generate-readme` (les agents
   `backend-dev`/`frontend-dev` n'ont pas l'outil `Skill` : une sous-tâche ne peut pas
   invoquer une skill, toi si). C'est la recopie mécanique d'un cadrage déjà fermé, pas du
   développement : en faire une sous-tâche coûte un agent et une vague entière, et sérialise
   tout le ticket derrière elle. N'écris ici **aucun** fichier portant un item du périmètre,
   pas même provisoire — un fichier posé ici puis réécrit par une sous-tâche est payé deux
   fois et interdit de paralléliser celle-ci. N'écrase aucun fichier existant et n'épingle
   aucune version que le cadrage ne fixe pas — mêmes règles qu'à l'étape 11 de `/new-project`.
   **Lance ensuite l'installation et le build** : c'est le premier moment où le cadrage
   devient falsifiable, et une stack incohérente doit tomber ici, en une question à
   l'utilisateur, pas trois vagues plus loin dans la boucle de correction. Le contrat étant
   sur disque avant le découpage, **backend et frontend partent ensemble en vague 1** ; il ne
   reste de dépendance qu'entre sous-tâches qui se touchent réellement.
4. **L'étape 2 s'applique ensuite**, avec trois différences :
   - le `contexte_planner` filtré par `fichiers_cibles` n'a pas lieu d'être — transmets les
     seules contraintes propres à la sous-tâche ;
   - **les contrats de `docs/architecture.md` traversent le découpage** : une sous-tâche qui
     produit ou consomme un contrat le reçoit dans son payload, recopié tel quel, jamais
     reformulé. Chaque sous-tâche porte le critère de validation de l'item de périmètre
     qu'elle sert (`criteres_validation`) — c'est lui qui dit quand elle est finie ;
   - **hors ces contrats et ces critères, ne recopie rien de `CLAUDE.md` ni de `docs/`** :
     `CLAUDE.md` est chargé automatiquement par chaque sous-agent, et les `docs/` sont à sa
     portée s'il en a besoin — les redonner en bloc, c'est payer deux fois le même contexte.
