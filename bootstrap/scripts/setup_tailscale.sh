#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/lib.sh"

install_tailscale() {
  if command -v tailscale >/dev/null 2>&1; then
    log "tailscale already installed"
    return
  fi
  curl -fsSL https://tailscale.com/install.sh | sh
}

connect_tailscale() {
  if tailscale status >/dev/null 2>&1; then
    log "tailscale already connected"
    return
  fi
  if [ -z "${TAILSCALE_AUTH_KEY:-}" ]; then
    log "TAILSCALE_AUTH_KEY not set; skipping tailscale up"
    return
  fi

  set -- --authkey "${TAILSCALE_AUTH_KEY}" --ssh
  if [ -n "${HOSTNAME_OVERRIDE:-}" ]; then
    set -- "$@" --hostname "${HOSTNAME_OVERRIDE}"
  fi
  if [ -n "${TAILSCALE_TAGS:-}" ]; then
    set -- "$@" --advertise-tags "${TAILSCALE_TAGS}"
  fi

  tailscale up "$@"
}

main() {
  require_root
  install_tailscale
  systemctl enable tailscaled
  systemctl start tailscaled
  connect_tailscale
}

main "$@"
