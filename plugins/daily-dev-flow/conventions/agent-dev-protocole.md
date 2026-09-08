# Protocole commun des agents de développement

Tronc commun de `backend-dev` et `frontend-dev` : contrats d'entrée/sortie et règles de
conduite d'une sous-tâche. Chaque fiche d'agent référence ce fichier et n'ajoute que ce qui
est propre à sa couche. **Un champ de payload ne se définit qu'ici** — une clé décrite en deux
endroits est une clé qui diverge.

## Avant d'écrire une ligne de code

- **Lis d'abord les conventions de qualité du plugin** :
  `${CLAUDE_PLUGIN_ROOT}/conventions/code-quality.md` (socle universel), le fichier de ta
  couche (`backend.md` ou `frontend.md`), puis le fichier de langage que le tableau en fin de
  `code-quality.md` associe à `contexte_stack.langage`, s'il en désigne un. Ces règles
  tranchent là où le projet ne dit rien et **cèdent devant lui partout où il dit quelque
  chose** ; elles portent sur le code que tu écris, jamais sur une passe de nettoyage du code
  alentour.
- La stack n'est pas à redeviner : elle arrive dans `contexte_stack`, détectée une seule fois
  en amont. Ne relance jamais cette détection — tu divergerais du résultat que la vérification
  de build utilise.
- Lis les fichiers cibles et leur voisinage immédiat pour relever les conventions fines du
  code réel (style, gestion d'erreurs, nommage, structure des couches). Tu n'imposes jamais
  ton style personnel à la place de celui du projet, et tu n'introduis pas de nouvelle
  dépendance si l'existant couvre le besoin.
- Si `contexte_planner` est incomplet ou incohérent avec ce que tu observes, fais confiance au
  code réel — **sauf si le payload porte `avertissement_reprise`** : le disque peut alors
  contenir le travail partiel d'une exécution interrompue, vérifie l'état réel de chaque
  fichier cible et réécris-le entièrement plutôt que d'imiter un contenu possiblement tronqué
  ou de le croire terminé.
- Si `contexte_dependance` est fourni, lis son `resume` — en particulier `contrats_produits` —
  pour connaître le contrat réel produit par la sous-tâche dont tu dépends, avant de t'appuyer
  dessus.

## Pendant l'implémentation

- Écris du code qu'un relecteur senior du projet validerait sans notes de style.
  Les erreurs attendues sont gérées explicitement ; les inattendues ne sont pas avalées.
- **Chaque critère de `criteres_validation` se traduit en un test**, écrit avec le harness du
  projet (`contexte_stack.outil_test`) et les conventions de test en place. Le test traduit le
  critère tel quel, sans l'affaiblir ni l'étendre. `outil_test` à `null` : ne mets pas de
  harness en place de ta propre initiative — signale-le dans `resume` et livre sans test.
  Aucun test au-delà des critères reçus.
- Reste dans le périmètre de `fichiers_cibles`. Toucher un fichier hors périmètre est une
  décision consciente, justifiée dans `resume` — jamais un effet de bord.
- Vérifications ponctuelles autorisées (compilation partielle, test ciblé existant), mais le
  build final ne t'appartient pas : c'est la vérification orchestrée par `/ticket`.
- Une sous-tâche dépendante : vérifie que le contrat que tu produis ou consommes est celui du
  contexte fourni — c'est le point de rupture silencieux entre sous-tâches parallèles.

## Cas particulier : premier ticket d'un projet neuf

Le projet est amorcé (manifeste, dossiers, contrats, configuration sur disque) mais aucune
fonctionnalité n'est écrite : tes `fichiers_cibles` n'existent pas encore, tu les crées. Dans
ce cas précis :

- un fichier cible inexistant n'est pas un blocage, c'est le travail — pas de `failed` pour
  cette raison ;
- ta référence de conventions est le `CLAUDE.md` du projet, complété par les `conventions/` du
  plugin — c'est tout ce qui existe tant qu'il n'y a pas de code ;
- **les fichiers de contrats posés à l'amorçage font autorité** : tu les importes, tu ne les
  réécris pas, tu n'en déclares pas de variante locale. Faux ou incomplets à tes yeux :
  blocage à remonter, pas divergence à créer ;
- tu installes les dépendances manquantes avec le `gestionnaire_paquets` de `contexte_stack`,
  pour que `outil_build` et `outil_test` passent en fin de sous-tâche ;
- pas de fonctionnalité prise d'avance sur les vagues suivantes, même triviale.

## Cas particulier : boucle de correction de build

Un payload portant `erreurs_build` est une relance de correction, pas une sous-tâche neuve :
corrige les erreurs listées, sur tes fichiers, sans élargir. `tentatives_precedentes` liste ce
qui a déjà été essayé et pourquoi ça a re-échoué — **ne rejoue jamais un fix déjà tenté** ; si
tout ce qui te semble plausible a déjà été essayé, renvoie `failed` avec ton diagnostic plutôt
qu'une variante cosmétique du même correctif.

## Quand tu bloques

Fichier cible inexistant (hors premier ticket), dépendance manquante, contrat manquant ou
incohérent avec le contexte fourni : arrête-toi, ne force pas une implémentation approximative
pour « rendre quelque chose ». Renvoie `statut: failed` avec une `raison_echec` assez précise
pour corriger sans deviner.

## Contrat d'entrée

```json
{
  "id": "string",
  "titre": "string",
  "description": "string",
  "fichiers_cibles": ["..."],
  "criteres_validation": ["critère observable recopié du plan, jamais reformulé — chacun se traduit en un test"],
  "contexte_planner": {
    "besoin_fonctionnel": "string",
    "notes": [ { "fichiers": ["..."], "note": "string" } ],
    "symboles": [ { "nom": "string", "fichiers": ["..."] } ]
  },
  "contexte_stack": { "langage": "...", "framework": "...", "outil_build": "...", "outil_test": "...", "gestionnaire_paquets": "...", "fichier_manifeste": "..." },
  "contexte_dependance": "optionnel — resume complet (contrats_produits inclus) de la sous-tâche productrice dont dépend celle-ci",
  "regles_retex": ["optionnel — règles actives du retex du projet qui recoupent cette sous-tâche, à appliquer telles quelles"],
  "avertissement_reprise": "optionnel — présent quand la sous-tâche est relancée après une interruption : l'état du disque peut être partiel, cf. § Avant d'écrire",
  "erreurs_build": "optionnel — boucle de correction uniquement : les erreurs de build/tests ciblées sur tes fichiers, jamais le log complet",
  "tentatives_precedentes": ["optionnel — boucle de correction, tentative 2+ : ce que chaque tentative a essayé et pourquoi ça a re-échoué"]
}
```

`contexte_planner` est absent sur un projet en amorçage (rien à extraire) ; toute clé
optionnelle absente ne s'invente pas.

## Contrat de sortie

```json
{
  "statut": "done | failed",
  "resume": {
    "texte": "string — 1 à 3 phrases de synthèse",
    "fichiers_modifies": [
      { "chemin": "chemin/relatif", "action": "created | modified", "description": "string courte" }
    ],
    "contrats_produits": [
      { "nature": "endpoint | type | evenement | format", "signature": "string — la signature réelle et complète : méthode+chemin+forme de réponse pour un endpoint, définition pour un type, forme du payload pour un événement" }
    ]
  },
  "raison_echec": "string — uniquement si statut = failed"
}
```

`contrats_produits` porte tout ce que ta sous-tâche expose et qu'une autre consommera — c'est
lui que `/ticket` transmet en `contexte_dependance` : trois phrases de `texte` ne transportent
pas un contrat d'API, la signature écrite en dur si. Vide si la sous-tâche n'expose rien.
