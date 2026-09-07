# Architecture — <nom du projet>

<Sauf mention contraire, ce qui est décrit comme *constaté* a été lu sur cette machine le
<AAAA-MM-JJ>. Ce qui n'a pas pu l'être porte un bloc `> Hypothèse` et sa conduite à tenir.>

## 1. Stack et commandes

| Brique | Choix | Constaté / déclaré |
|--------|-------|--------------------|
| Langage | <choix> | déclaré |
| Framework front | <choix> | déclaré |
| Outil de build | <choix> | déclaré |
| Framework back | <choix ou `aucun`> | déclaré |
| Librairie d'interface | <choix> | déclaré |
| Gestion d'état | <choix ou `aucune`> | déclaré |
| Gestionnaire de paquets | <choix> | constaté : `<commande>` → `<version>` |

- **Installation** : `<commande>`
- **Build** : `<commande>`
- **Lancement** : `<commande>`

**Contraintes structurelles** — <ce qui était imposé et non choisi, avec sa raison en une ligne.
Supprimer si aucune.>

## 2. Modules

### `<module>`

- **Responsabilité** : <une phrase.>
- **Expose** : <ce que les autres modules peuvent en attendre>
- **Consomme** : <ce dont il dépend — module, fichier, service>

### `<module>`

- **Responsabilité** : <une phrase.>
- **Expose** : <…>
- **Consomme** : <…>

## 3. Contrats

<Tout ce qui traverse une frontière de module est écrit en dur ici, avec sa signature réelle :
types partagés, endpoints, événements, format des fichiers échangés. Une sous-tâche qui produit
ou consomme un contrat reçoit cette section telle quelle — c'est ce qui empêche deux agents
parallèles d'en écrire deux versions divergentes.>

### `<nom du contrat>` — <type partagé | endpoint | événement | format de fichier>

```<langage>
<signature réelle : type, interface, schéma>
```

- **Produit par** : `<module>`
- **Consommé par** : `<module>`
- **Cas limites** : <valeur absente, valeur inconnue, erreur — et ce qui est attendu alors>

## 4. Arborescence

<Au fichier près pour la v1, un rôle par fichier. Pas seulement les dossiers.>

```
<racine>/
├── <dossier>/
│   ├── <fichier>          <rôle>
│   └── <fichier>          <rôle>
├── <fichier>              <rôle>
└── docs/                  cadrage, architecture, décisions
```

## 5. Données et intégrations

| Source | Format | Accès | Établi par |
|--------|--------|-------|------------|
| `<chemin ou URL>` | <format réel> | lecture seule \| lecture/écriture | <la lecture ou la commande qui l'établit> |

<Champs réels relevés, pour ce que le projet consomme vraiment :>

- `<chemin>` — `<extrait ou liste de champs constatés>`

## 6. Conventions

<Ce qu'un agent ne peut pas retrouver seul, et dont la violation coûte. Rien de déductible du
framework.>

- **<convention>** — <la règle, à l'impératif, et ce qu'elle évite.>

## Hypothèses résiduelles

<Uniquement des faits externes et non vérifiables. Une hypothèse dont dépend un choix
d'implémentation devait être vérifiée ou posée en question avant d'écrire ce fichier.
Supprimer la section si elle est vide.>

> **Hypothèse** — <le fait, et pourquoi il n'est pas vérifiable ici.>
> **Conduite à tenir** — <ce que le code doit faire si l'hypothèse est fausse.>
