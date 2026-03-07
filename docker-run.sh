#!/usr/bin/env bash
# =============================================================================
# ralph/docker-run.sh
# Builds the sandbox image and runs the loop inside it.
# Your project directory is mounted read-write into the container.
#
# Security model:
#   - Claude can only read/write the mounted project directory
#   - Your SSH keys, credentials, other projects are not reachable
#   - Outbound network is allowed (Claude Code requires api.anthropic.com)
#   - No ports are exposed inbound
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="ralph-loop"

if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  echo "ERROR: ANTHROPIC_API_KEY is not set."
  echo "Export it first:  export ANTHROPIC_API_KEY=sk-ant-..."
  exit 1
fi

if [ ! -f "$SCRIPT_DIR/PRD.md" ]; then
  echo "ERROR: PRD.md not found."
  echo "Copy PRD.example.md to PRD.md and fill it out first."
  exit 1
fi

echo "Building sandbox image..."
docker build -q -t "$IMAGE_NAME" "$SCRIPT_DIR"

echo "Starting Ralph Loop in Docker sandbox..."
echo "Project: $SCRIPT_DIR"
echo "Press Ctrl+C to stop."
echo ""

docker run \
  --rm \
  --name ralph-loop \
  \
  `# Mount your project directory — this is the isolation boundary` \
  `# Claude can only touch what is under this path` \
  -v "$SCRIPT_DIR:/home/ralph/project" \
  \
  `# API key passed at runtime, never baked into the image` \
  -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
  \
  `# Tuning` \
  -e MAX_ITERATIONS="${MAX_ITERATIONS:-100}" \
  -e PAUSE_SECONDS="${PAUSE_SECONDS:-10}" \
  \
  `# No inbound ports exposed` \
  `# Outbound is allowed — Claude Code requires api.anthropic.com` \
  \
  "$IMAGE_NAME" "$@"
