#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
"$root/scripts/bootstrap.sh"
"$root/wolf3d/scripts/test.sh"
"$root/gateway/scripts/build.sh" "$@"
