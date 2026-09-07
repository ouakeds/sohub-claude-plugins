#!/bin/bash
# shellcheck source=lib/guard-config.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/guard-config.sh"

guard_is_enabled git || exit 0

echo "daily-dev-flow: commit git interdit (garde-fou 'git' actif). Ce plugin ne committe jamais a la place de l'utilisateur, meme en flux --auto. Demandez a l'utilisateur de committer lui-meme, ou desactivez le garde-fou avec \"guards\": {\"git\": false} dans .sohub-claude-plugin.json." >&2
exit 2
