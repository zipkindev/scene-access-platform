#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
git -C "$root" submodule update --init --recursive
mkdir -p "$root/.local/geoip"
if [ ! -e "$root/.env" ]; then
  cp "$root/.env.example" "$root/.env"
  echo "created .env from .env.example; review it before launch"
else
  echo "kept existing .env"
fi
"$root/gateway/scripts/check-prerequisites.sh"

