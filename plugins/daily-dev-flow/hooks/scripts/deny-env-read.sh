#!/bin/bash
# Refuse la lecture d'un fichier d'environnement prive (`.env*`), que ce soit par l'outil
# Read ou par un idiome Bash (`cat`, `head`, `tail`, `less`, `more`, …).
#
# Le script analyse lui-meme le payload au lieu de faire confiance au filtre `if` de
# hooks.json : une regle de prefixe `Bash(cat .env*)` rate `cat config/.env.local` et se
# declenche sur des commandes qui n'ont rien a voir. Ici, le nom de fichier est teste sur
# son basename, a n'importe quelle profondeur.

# shellcheck source=lib/guard-config.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/guard-config.sh"

# Aucune expansion de glob pendant l'analyse : on inspecte la commande telle qu'ecrite.
set -f

deny() {
  echo "daily-dev-flow: lecture de fichier d'environnement interdite. Les variables privees (.env*) du projet cible ne doivent jamais etre lues ou affichees par le plugin." >&2
  exit 2
}

# Un chemin designe-t-il un fichier d'environnement ? Test sur le basename, guillemets
# eventuels retires, pour attraper `./.env`, `config/.env.local`, `"$HOME/app/.env"`.
_is_env_path() {
  local path="$1" base
  path="${path%\"}"; path="${path#\"}"
  path="${path%\'}"; path="${path#\'}"
  base="${path##*/}"
  case "$base" in
    .env|.env.*|.env*) return 0 ;;
    *) return 1 ;;
  esac
}

# --- Outil Read ------------------------------------------------------------------------

file_path=$(ddf_tool_file_path) || file_path=""
if [ -n "$file_path" ]; then
  _is_env_path "$file_path" && deny
fi

# --- Outil Bash ------------------------------------------------------------------------

command_line=$(ddf_tool_command) || exit 0
[ -n "$command_line" ] || exit 0

# Mots qui precedent une commande sans en changer la nature.
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
    cat|head|tail|less|more|bat|nl|od|xxd|strings|source|.) ;;
    *) continue ;;
  esac

  index=1
  while [ "$index" -lt "${#words[@]}" ]; do
    _is_env_path "${words[$index]}" && deny
    index=$((index + 1))
  done
done <<EOF
$(ddf_command_segments "$command_line")
EOF

exit 0
