# Flux : reprise d'un plan interrompu

Cas déclencheur (étape 0 de `/ticket`) : un plan `Statut global: in_progress` existe et
l'utilisateur choisit de le reprendre.

1. **Consigne la reprise** dans `## Signaux retex` du plan (ligne datée : reprise après
   interruption, vague relancée) — des reprises récurrentes sont un signal que le flux casse
   quelque part, matière de l'étape 7.
2. **Saute directement à l'étape 4** en repartant du plan existant : ne relance ni `planner`
   ni le découpage. Reprends à la première vague non `done`.
3. **Relis d'abord la section `## Résultats` du plan** : elle contient les `resume` des
   sous-tâches déjà `done`, dont tu tireras les `contexte_dependance` des vagues restantes. Si
   un `resume` attendu y manque (plan écrit avant cette convention, ou vague interrompue en
   cours d'écriture), ne l'invente pas : signale-le et laisse la sous-tâche consommatrice
   partir sans `contexte_dependance` — son agent sait alors qu'il doit aller lire le code
   produit plutôt que supposer un contrat.
4. **Méfie-toi du disque pour toute sous-tâche `in_progress`** (ou dont le statut est douteux
   — plan écrit avant que le lancement ne marque `in_progress`) : ses fichiers cibles peuvent
   porter le travail **partiel** de l'exécution interrompue, et un fichier partiel peut très
   bien compiler. Rien n'a été committé (le garde-fou git l'interdit au flux), donc pas de
   revert possible — mais `git status` et `git diff` (lecture seule, autorisée) donnent la
   liste exacte des fichiers touchés non committés : relève-la. Ajoute au payload de chaque
   sous-tâche relancée la clé `avertissement_reprise` (cf. protocole des agents) : l'agent
   vérifie alors l'état réel de chaque fichier cible et le réécrit entièrement plutôt que
   d'imiter un contenu tronqué ou de le croire terminé.
