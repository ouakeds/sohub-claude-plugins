#!/bin/bash
echo "daily-dev-flow: commit git interdit. Ce plugin ne committe jamais a la place de l'utilisateur, meme en flux --auto. Demandez a l'utilisateur de committer lui-meme." >&2
exit 2
