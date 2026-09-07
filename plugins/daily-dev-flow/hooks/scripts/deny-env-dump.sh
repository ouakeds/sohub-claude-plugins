#!/bin/bash
# Refuse le dump complet des variables d'environnement (`env` / `printenv` sans argument).
#
# Le script analyse lui-meme la commande soumise au lieu de faire confiance au filtre `if`
# de hooks.json : une correspondance exacte du type `Bash(env)` se declenche sur des
# commandes qui ne contiennent aucun `env` (une boucle `for … in … ; do … done`, par
# exemple), et un garde-fou qui refuse au hasard finit par etre desactive.

# shellcheck source=lib/guard-config.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/guard-config.sh"

# Aucune expansion de glob pendant l'analyse : on inspecte la commande telle qu'ecrite.
set -f

command_line=$(ddf_tool_command) || exit 0
[ -n "$command_line" ] || exit 0

# Mots qui precedent une commande sans en changer la nature : on les retire avant de
# regarder le nom reel, sinon `for x in 1; do env; done` passerait sur son `do`.
_strip_prefix_words() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      do|then|else|elif|time|exec|command|builtin|nohup|sudo|'!') shift ;;
      *) break ;;
    esac
  done
  printf '%s\n' "$@"
}

while IFS= read -r segment; do
  [ -n "$segment" ] || continue

  words=()
  while IFS= read -r word; do
    [ -n "$word" ] && words[${#words[@]}]="$word"
  done <<EOF
$(_strip_prefix_words $segment)
EOF

  [ "${#words[@]}" -gt 0 ] || continue

  case "${words[0]}" in
    env|printenv) ;;
    *) continue ;;
  esac

  # `env FOO=bar cmd` ne dumpe rien : seul un appel sans argument (ou avec de seuls
  # drapeaux, `env -0`) affiche l'environnement complet.
  dump=1
  index=1
  while [ "$index" -lt "${#words[@]}" ]; do
    case "${words[$index]}" in
      -*) ;;
      *) dump=0 ;;
    esac
    index=$((index + 1))
  done

  if [ "$dump" -eq 1 ]; then
    echo "daily-dev-flow: commande de dump d'environnement interdite (env/printenv sans argument). Les variables d'environnement privees ne doivent pas etre exposees." >&2
    exit 2
  fi
done <<EOF
$(ddf_command_segments "$command_line")
EOF

exit 0
