#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
failed=0

fail() {
  echo "workspace check: $*" >&2
  failed=1
}

if [ ! -f "$root/.gitmodules" ]; then
  fail "missing platform .gitmodules"
fi

for component in gateway wolf3d; do
  if ! git -C "$root/$component" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    fail "$component is not an initialized Git worktree"
  fi
done

gateway_url=$(git -C "$root" config --file .gitmodules --get submodule.gateway.url || true)
wolf_url=$(git -C "$root" config --file .gitmodules --get submodule.wolf3d.url || true)
[ "$gateway_url" = "https://github.com/zipkindev/scene-access-gateway.git" ] || \
  fail "unexpected gateway submodule URL: ${gateway_url:-missing}"
[ "$wolf_url" = "https://github.com/zipkindev/scene-access-gateway-wolf3d.git" ] || \
  fail "unexpected wolf3d submodule URL: ${wolf_url:-missing}"

check_ignored() {
  repository=$1
  path=$2
  if ! git -C "$repository" check-ignore -q --no-index "$path"; then
    fail "$repository does not ignore protected path $path"
  fi
}

check_ignored "$root" .env
check_ignored "$root" .local/compose.override.yaml
check_ignored "$root/gateway" .env
check_ignored "$root/gateway" .local/audio-source/probe.mp3
check_ignored "$root/gateway" frontend/artwork/audio/probe.mp3
check_ignored "$root/wolf3d" runtime/GAMEMAPS.WL6
check_ignored "$root/wolf3d" runtime/GAMEMAPS.SOD

if git -C "$root/gateway" ls-files --error-unmatch .env >/dev/null 2>&1; then
  fail "gateway/.env is tracked"
fi
if git -C "$root/gateway" ls-files | grep -E '(^|/)\.local(/|$)|frontend/artwork/audio/.*\.mp3$|\.(WL1|WL3|WL6|SOD|SD1|SD2|SD3)$' >/dev/null; then
  fail "gateway tracks a protected local-data path"
fi
if git -C "$root/wolf3d" ls-files | grep -E '\.(WL1|WL3|WL6|SOD|SD1|SD2|SD3)$' >/dev/null; then
  fail "wolf3d tracks commercial game data"
fi

if [ "$failed" -ne 0 ]; then
  exit 1
fi

echo "workspace boundaries verified"
git -C "$root" submodule status
