#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
gateway="$root/gateway"
wolf="$root/wolf3d"
export SAG_WOLF3D_EXTENSION_DIR="$wolf"

if [ -f "$root/.local/compose.override.yaml" ]; then
  exec docker compose --project-directory "$gateway" --env-file "$gateway/.env" \
    -f "$gateway/compose.yaml" -f "$wolf/compose.extension.yaml" \
    -f "$root/.local/compose.override.yaml" "$@"
fi
exec docker compose --project-directory "$gateway" --env-file "$gateway/.env" \
  -f "$gateway/compose.yaml" -f "$wolf/compose.extension.yaml" "$@"
