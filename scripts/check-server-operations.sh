#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
access_env="$root/gateway/.local/tnas-security-access.env"
production_env="$root/gateway/.local/production.env"
deploy_dir="$root/gateway/.local/deploy/truenas"
collector="$root/gateway/.local/collect-tnas-security.py"

fail() {
  printf '%s\n' "server operations check failed: $*" >&2
  exit 1
}

require_private_file() {
  path=$1
  test -f "$path" || fail "missing protected local file: $path"
  mode=$(stat -c '%a' "$path")
  case "$mode" in
    400|600) ;;
    *) fail "protected local file must use mode 400 or 600: $path" ;;
  esac
}

require_key() {
  file=$1
  key=$2
  awk -F= -v key="$key" '$1 == key && length($2) > 0 { found=1 } END { exit !found }' "$file" ||
    fail "missing required key $key in $file"
}

value_for() {
  awk -F= -v key="$2" '$1 == key { sub(/^[^=]*=/, ""); print; exit }' "$1"
}

require_private_file "$access_env"
require_private_file "$production_env"

for key in TNAS_HOST TNAS_PROJECT TNAS_PORTAL_SERVICE TNAS_PROXY_SERVICE \
  TNAS_CREDENTIAL_FILE TNAS_KNOWN_HOSTS TNAS_PROJECT_ROOT
do
  require_key "$access_env" "$key"
done

for key in SAG_PUBLIC_ORIGIN SAG_EDITOR_ORIGIN SAG_DATA_DIR SAG_TLS_DIR \
  SAG_SECRETS_DIR SAG_IMAGE_NAMESPACE SAG_IMAGE_TAG
do
  require_key "$production_env" "$key"
done

credential_file=$(value_for "$access_env" TNAS_CREDENTIAL_FILE)
known_hosts=$(value_for "$access_env" TNAS_KNOWN_HOSTS)
toolkit=$(value_for "$access_env" TNAS_PROJECT_ROOT)
management_host=$(value_for "$access_env" TNAS_HOST)

test "$management_host" = "192.168.3.230" || fail "configured TrueNAS management host does not match the established target"
test -f "$credential_file" || fail "configured credential file is missing"
test -f "$known_hosts" || fail "configured pinned known-hosts file is missing"
test -d "$toolkit" || fail "configured TrueNAS toolkit root is missing"
test -f "$toolkit/AGENTS.md" || fail "TrueNAS toolkit AGENTS.md is missing"
test -f "$toolkit/scripts/build-access-portal-image.py" || fail "portal image builder is missing"
test -f "$toolkit/scripts/stage-access-portal-images.py" || fail "portal image stager is missing"
test -f "$collector" || fail "bounded security evidence collector is missing"
test -d "$deploy_dir" || fail "local TrueNAS release directory is missing"

release_count=$(find "$deploy_dir" -maxdepth 1 -type f -name 'release-*.py' | wc -l)
runbook_count=$(find "$deploy_dir" -maxdepth 1 -type f -name 'RELEASE-*.md' | wc -l)
test "$release_count" -gt 0 || fail "no local TrueNAS release wrappers found"
test "$runbook_count" -gt 0 || fail "no local TrueNAS release runbooks found"

printf '%s\n' "server operations context verified"
printf '%s\n' "protected configuration: present with private modes"
printf '%s\n' "pinned credentials and known-hosts paths: present"
printf '%s\n' "shared TrueNAS toolkit and portal build/stage operations: present"
printf '%s\n' "Gateway collector and local guarded release history: present; live reconciliation required"
