#!/bin/bash
set -euo pipefail

# Configure git credentials if a GitHub token is provided
if [ -n "${GITHUB_TOKEN:-}" ]; then
  git config --global credential.helper store
  echo "https://oauth2:${GITHUB_TOKEN}@github.com" > ~/.git-credentials
  git config --global url."https://github.com/".insteadOf "git@github.com:"
fi

exec /bin/bash loop.sh "$@"
