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
