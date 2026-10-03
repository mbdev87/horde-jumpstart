#!/bin/bash
# One-command bring-up: stage engine sources, build images, start the sandbox.
# Usage: scripts/up.sh            (full stack)
#        scripts/up.sh horde-server  (rebuild just one service)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$REPO/scripts/stage-context.sh"

docker compose -f "$REPO/docker/docker-compose.yml" up -d --build "$@"

echo
echo "Sandbox starting. Dashboard: http://localhost:${HORDE_HTTP_PORT:-13340}"
echo "Follow server logs: docker compose -f docker/docker-compose.yml logs -f horde-server"
