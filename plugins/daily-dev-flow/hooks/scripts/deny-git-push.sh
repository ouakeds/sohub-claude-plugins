#!/bin/bash
# shellcheck source=lib/guard-config.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/guard-config.sh"

guard_is_enabled git || exit 0

echo "daily-dev-flow: push git interdit (garde-fou 'git' actif). Ce plugin ne pousse jamais vers un remote a la place de l'utilisateur. Desactivez le garde-fou avec \"guards\": {\"git\": false} dans .sohub-claude-plugin.json si ce comportement est voulu." >&2
exit 2
