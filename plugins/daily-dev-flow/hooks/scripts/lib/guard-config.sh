#!/bin/bash
# Resolution de l'etat d'un garde-fou daily-dev-flow, et lecture du payload PreToolUse.
#
# Ordre de priorite d'un garde-fou, premier trouve gagne :
#   1. Variable DAILY_DEV_FLOW_GUARD_<NOM> exportee dans la session (on/off, 1/0, true/false)
#   2. Config du projet cible : .sohub-claude-plugin.json, cherche depuis le cwd de la
#      session puis en remontant jusqu'a la racine du systeme de fichiers
#   3. Config utilisateur : ~/.claude/sohub-claude-plugin.json
#   4. Defaut : garde-fou actif (securise par defaut)
#
# Format du fichier de config :
#   { "guards": { "git": false } }

DDF_CONFIG_NAME=".sohub-claude-plugin.json"
DDF_USER_CONFIG="${HOME}/.claude/sohub-claude-plugin.json"

# --- Payload du hook -------------------------------------------------------------------
#
# Le payload PreToolUse arrive sur stdin et ne peut etre lu qu'une seule fois : tout script
# qui a besoin a la fois du `cwd` et de `tool_input` doit passer par ce cache.

DDF_PAYLOAD=""
DDF_PAYLOAD_READ=0

ddf_payload() {
  if [ "$DDF_PAYLOAD_READ" -eq 0 ]; then
    DDF_PAYLOAD_READ=1
    if [ ! -t 0 ]; then
      DDF_PAYLOAD=$(cat 2>/dev/null)
    fi
  fi
  printf '%s' "$DDF_PAYLOAD"
}

# Amorcage du cache des le sourcage, dans le shell principal. Sans lui, le premier acces
# au payload se ferait depuis une substitution de commande — donc dans un sous-shell, qui
# viderait stdin sans rien remonter au parent : le deuxieme champ lu serait toujours vide.
ddf_payload >/dev/null 2>&1

# _ddf_payload_field <chemin jq> <cle pour le repli sed>
# Renvoie 1 si le champ est absent ou illisible.
_ddf_payload_field() {
  local payload value
  payload=$(ddf_payload)
  [ -n "$payload" ] || return 1
  if command -v jq >/dev/null 2>&1; then
    value=$(printf '%s' "$payload" | jq -r "$1 // empty" 2>/dev/null)
  else
    # Repli sans jq : extraction textuelle. Suffisante pour un chemin, approximative pour
    # une commande contenant des guillemets echappes (cf. « Limite connue » du CLAUDE.md).
    value=$(printf '%s' "$payload" | sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1)
  fi
  [ -n "$value" ] || return 1
  printf '%s' "$value"
}

# La commande Bash reellement soumise a l'outil.
ddf_tool_command() { _ddf_payload_field '.tool_input.command' 'command'; }

# Le chemin soumis a l'outil Read.
ddf_tool_file_path() { _ddf_payload_field '.tool_input.file_path' 'file_path'; }

# Decoupe une ligne de commande en sous-commandes, une par ligne. Les separateurs couvrent
# l'enchainement (`;` `&&` `||` `&`), le pipe, et les ouvertures de sous-shell / substitution
# (`(` `)` backquote `{` `}`) — sans quoi `echo $(env)` passerait entre les mailles.
ddf_command_segments() {
  printf '%s' "$1" \
    | tr '|;&(){}`\n' '\n\n\n\n\n\n\n\n' \
    | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
    | grep -v '^$'
}

# Repere le repertoire de travail de la session : champ `cwd` du payload, a defaut le
# repertoire courant du process.
_ddf_session_cwd() {
  local cwd=""
  cwd=$(_ddf_payload_field '.cwd' 'cwd') || cwd=""
  if [ -z "$cwd" ]; then
    cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
  fi
  printf '%s' "$cwd"
}

# --- Garde-fous ------------------------------------------------------------------------

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
  eval "value=\${${var_name}-}"
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
