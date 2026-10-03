#!/bin/bash
# Stage the minimal engine subset needed to build HordeServer into build/horde-context.
# Mirrors StagePaths / Dockerfile.dockerignore from BuildHorde.xml so the docker build
# context stays small even though the engine checkout is huge.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENGINE="${ENGINE:-$REPO/../UnrealEngine}"
CTX="$REPO/build/horde-context"

# Engine checkout root contains an Engine/ subfolder where all the paths live
if [ ! -d "$ENGINE/Engine/Source/Programs/Horde" ]; then
    echo "ERROR: UnrealEngine checkout not found at: $ENGINE" >&2
    echo "       Set ENGINE=/path/to/UnrealEngine and re-run." >&2
    exit 1
fi

echo "Staging Horde build context from: $ENGINE"
mkdir -p "$CTX"

stage() {
    local src="$ENGINE/Engine/$1" dest="$CTX/$1"
    mkdir -p "$(dirname "$dest")"
    rsync -a --delete --exclude '.vs/' --exclude 'bin/' --exclude 'obj/' \
        --exclude 'uatbin/' --exclude 'uatobj/' "$src/" "$dest/"
}

stage Binaries/DotNET/EpicGames.Perforce.Native
stage Source/Programs/Shared
stage Source/Programs/Horde

echo "Staged $(du -sh "$CTX" | cut -f1) -> $CTX"
