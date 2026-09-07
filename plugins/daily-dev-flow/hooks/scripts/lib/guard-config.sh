#!/bin/bash
# Resolution de l'etat d'un garde-fou daily-dev-flow.
#
# Ordre de priorite, premier trouve gagne :
#   1. Variable DAILY_DEV_FLOW_GUARD_<NOM> exportee dans la session (on/off, 1/0, true/false)
#   2. Config du projet cible : .sohub-claude-plugin.json, cherche depuis le cwd de la
#      session puis en remontant jusqu'a la racine du systeme de fichiers
#   3. Config utilisateur : ~/.claude/sohub-claude-plugin.json
#   4. Defaut : garde-fou actif (securise par defaut)
#
# Format du fichier de config :
#   { "guards": { "git": false, "env": true } }

DDF_CONFIG_NAME=".sohub-claude-plugin.json"
DDF_USER_CONFIG="${HOME}/.claude/sohub-claude-plugin.json"

# Repere le repertoire de travail de la session. Le payload du hook PreToolUse arrive sur
# stdin et porte le champ `cwd` ; a defaut, on retombe sur le repertoire courant du process.
_ddf_session_cwd() {
  local payload="" cwd=""
  if [ ! -t 0 ]; then
    payload=$(cat 2>/dev/null)
  fi
  if [ -n "$payload" ]; then
    if command -v jq >/dev/null 2>&1; then
      cwd=$(printf '%s' "$payload" | jq -r 'if type == "object" then (.cwd // empty) else empty end' 2>/dev/null)
    else
      # Sans jq, extraction textuelle du champ : suffisant pour un chemin, qui ne contient
      # ni guillemet ni echappement JSON dans les cas reels.
      cwd=$(printf '%s' "$payload" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
    fi
  fi
  if [ -z "$cwd" ]; then
    cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
  fi
  printf '%s' "$cwd"
}

# Lit .guards.<nom> dans un fichier de config. Renvoie 1 si le fichier ou la cle est absent,
# pour distinguer « non configure » de « configure a false ».
_ddf_config_value() {
  local file="$1" guard="$2" value=""
  [ -f "$file" ] || return 1
  if command -v jq >/dev/null 2>&1; then
    # `// empty` est inutilisable ici : jq y traite `false` comme une absence, or `false`
    # est justement la valeur qui desactive un garde-fou. On teste donc la presence de la cle.
    value=$(jq -r --arg g "$guard" \
      'if (type == "object" and (.guards | type) == "object" and (.guards | has($g)))
       then (.guards[$g] | tostring) else empty end' "$file" 2>/dev/null)
  else
    # Repli sans jq. Pas d'alternance `\(true\|false\)` ici : le sed BSD de macOS ne la
    # supporte pas en regex basique. On extrait le token brut, puis on le valide.
    value=$(sed -n "s/.*\"${guard}\"[[:space:]]*:[[:space:]]*\([A-Za-z0-9]*\).*/\1/p" "$file" | head -1)
    case "$value" in
      true|false) ;;
      *) return 1 ;;
    esac
  fi
  [ -n "$value" ] || return 1
  printf '%s' "$value"
}

_ddf_is_falsy() {
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    false|0|off|no) return 0 ;;
    *) return 1 ;;
  esac
}

# guard_is_enabled <nom> -> 0 si le garde-fou doit bloquer, 1 s'il est desactive.
guard_is_enabled() {
  local guard="$1" upper var_name value dir

  upper=$(printf '%s' "$guard" | tr '[:lower:]-' '[:upper:]_')
  var_name="DAILY_DEV_FLOW_GUARD_${upper}"
  value="${!var_name-}"
  if [ -n "$value" ]; then
    _ddf_is_falsy "$value" && return 1
    return 0
  fi

  dir=$(_ddf_session_cwd)
  while [ -n "$dir" ] && [ "$dir" != "/" ]; do
    if value=$(_ddf_config_value "${dir}/${DDF_CONFIG_NAME}" "$guard"); then
      _ddf_is_falsy "$value" && return 1
      return 0
    fi
    dir=$(dirname "$dir")
  done

  if value=$(_ddf_config_value "$DDF_USER_CONFIG" "$guard"); then
    _ddf_is_falsy "$value" && return 1
    return 0
  fi

  return 0
}
