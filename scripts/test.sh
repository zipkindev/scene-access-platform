#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
"$root/scripts/check-workspace.sh"
"$root/scripts/bootstrap.sh"
if [ ! -d "$root/gateway/backend/src/node_modules" ]; then
  npm ci --prefix "$root/gateway/backend/src"
fi
"$root/gateway/scripts/test.sh"
"$root/wolf3d/scripts/test.sh"
"$root/wolf3d/scripts/smoke-combined.sh" "$root/gateway"
