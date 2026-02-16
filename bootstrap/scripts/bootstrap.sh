#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/lib.sh"

run_common() {
  "$SCRIPT_DIR/setup_base.sh"
  "$SCRIPT_DIR/setup_layout.sh"
  "$SCRIPT_DIR/setup_tailscale.sh"
}

run_role() {
  case "${ROLE:-}" in
    apphost)
      "$SCRIPT_DIR/setup_apphost.sh"
      ;;
    ops)
      "$SCRIPT_DIR/setup_ops.sh"
      ;;
    *)
      log "ROLE must be apphost or ops"
      exit 1
      ;;
  esac
}

main() {
  require_root
  run_common
  run_role
  log "bootstrap complete"
}

main "$@"
