#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
git -C "$root" submodule update --init --recursive
"$root/gateway/scripts/bootstrap.sh"
"$root/gateway/scripts/check-prerequisites.sh"
