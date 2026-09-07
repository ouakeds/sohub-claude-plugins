#!/bin/bash
echo "daily-dev-flow: lecture de fichier d'environnement interdite. Les variables privees (.env*) du projet cible ne doivent jamais etre lues ou affichees par le plugin." >&2
exit 2
