#!/bin/bash
# Sandboxed Perforce client. Never touches the host's P4* env vars or running P4V:
# p4 runs inside the compose network container with its own ticket/cache.
# Usage: scripts/p4.sh <p4 args...>     e.g. scripts/p4.sh login
#        scripts/p4.sh sync //horde/main/...@..., p4 submit, p4 edit ...
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$REPO/.env"
set -a; source "$ENV_FILE"; set +a

# Scratch workspace for interactive use, persisted in ./build/p4-client
WS="$REPO/build/p4-client"
mkdir -p "$WS"

docker run --rm -it \
    --name horde-jumpstart-p4cli-$$ \
    --network horde-jumpstart_default \
    -v "$WS:/p4-client" \
    -e P4PORT=p4d:${P4_PORT:-1666} \
    -e P4CLIENT=p4-seeder \
    -e P4USER="${P4_SERVICE_USER:-horde.build}" \
    -w /p4-client \
    horde-jumpstart-p4d "$@"
