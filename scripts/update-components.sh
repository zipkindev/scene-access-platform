#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if [ -n "$(git -C "$root" status --porcelain)" ]; then
  echo "platform repository must be clean before updating components" >&2
  exit 1
fi
for component in gateway wolf3d; do
  if [ -n "$(git -C "$root/$component" status --porcelain)" ]; then
    echo "$component submodule must be clean before updating" >&2
    exit 1
  fi
  git -C "$root/$component" switch main
  git -C "$root/$component" pull --ff-only origin main
done
"$root/scripts/test.sh"
echo "components passed integration tests; review and commit the submodule pointers"

