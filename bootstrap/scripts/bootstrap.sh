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

enforce_prod_bootstrap_source() {
  if [ "${ENVIRONMENT:-}" = "prod" ] && [ "${BOOTSTRAP_SOURCE:-}" != "cloud-init" ]; then
    log "manual PROD bootstrap is disabled; use Terraform/cloud-init path"
    exit 1
  fi
}

main() {
  require_root
  enforce_prod_bootstrap_source
  run_common
  run_role
  "$SCRIPT_DIR/enforce_secret_hygiene.sh"
  log "bootstrap complete"
}

main "$@"
