#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/lib.sh"

main() {
  require_root
  install -d -m 0755 /srv
  install -d -m 0755 /srv/edge
  install -d -m 0755 /srv/edge/acme
  install -d -m 0755 /srv/edge/certs
  install -d -m 0755 /srv/apps
  install -d -m 0755 /srv/ops
  install -d -m 0755 /srv/postgres
}

main "$@"
