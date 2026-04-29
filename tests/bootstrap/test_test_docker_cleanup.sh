#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_file() {
  [ -f "$ROOT_DIR/$1" ] || fail "missing $1"
}

assert_executable() {
  [ -x "$ROOT_DIR/$1" ] || fail "$1 is not executable"
}

assert_contains() {
  file=$1
  pattern=$2
  grep -Eq "$pattern" "$ROOT_DIR/$file" || fail "$file does not contain pattern: $pattern"
}

assert_file "bootstrap/scripts/docker_image_cleanup.sh"
assert_executable "bootstrap/scripts/docker_image_cleanup.sh"
assert_contains "bootstrap/scripts/docker_image_cleanup.sh" "docker image prune"
assert_contains "bootstrap/scripts/docker_image_cleanup.sh" "docker builder prune"
assert_contains "bootstrap/scripts/docker_image_cleanup.sh" "timeout .*docker system df"

assert_file "bootstrap/systemd/docker-image-cleanup.service"
assert_contains "bootstrap/systemd/docker-image-cleanup.service" "ExecStart=/usr/local/bin/docker_image_cleanup.sh"

assert_file "bootstrap/systemd/docker-image-cleanup.timer"
assert_contains "bootstrap/systemd/docker-image-cleanup.timer" "OnCalendar=\\*-\\*-\\*"
assert_contains "bootstrap/systemd/docker-image-cleanup.timer" "Persistent=true"

assert_contains "bootstrap/scripts/setup_apphost.sh" "configure_test_docker_cleanup"
assert_contains "bootstrap/scripts/setup_apphost.sh" "docker-image-cleanup.timer"
assert_contains "AGENTS.md" "Linear project.*Infrastructure"

printf 'PASS: TEST Docker cleanup bootstrap contract is present\n'
