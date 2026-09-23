#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
for component in gateway wolf3d; do
  if ! git -C "$root/$component" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$root" submodule update --init --recursive
    break
  fi
done
"$root/gateway/scripts/bootstrap.sh"
"$root/gateway/scripts/check-prerequisites.sh"
