#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
"$root/scripts/bootstrap.sh"
"$root/scripts/compose.sh" up -d --build "$@"

