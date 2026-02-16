#!/bin/sh
set -eu

HOSTNAMES_FILE=/srv/edge/hostnames.txt
DYNAMIC_DIR=/srv/edge/dynamic
TLS_DYNAMIC_FILE=$DYNAMIC_DIR/tls-certs.yml
TLS_DYNAMIC_TMP_FILE=$DYNAMIC_DIR/tls-certs.yml.tmp
TRAEFIK_CONTAINER_NAME=${TRAEFIK_CONTAINER_NAME:-traefik-test}

write_empty_config() {
  cat > "$TLS_DYNAMIC_TMP_FILE" <<'YAML'
tls:
  certificates: []
YAML
}

finalize_config() {
  mv "$TLS_DYNAMIC_TMP_FILE" "$TLS_DYNAMIC_FILE"
}

reload_traefik() {
  if ! command -v docker >/dev/null 2>&1; then
    return
  fi
  if docker ps --format '{{.Names}}' | grep -Fx "$TRAEFIK_CONTAINER_NAME" >/dev/null 2>&1; then
    docker kill --signal=HUP "$TRAEFIK_CONTAINER_NAME" >/dev/null 2>&1 || true
  fi
}

install -d -m 0755 "$DYNAMIC_DIR"

if [ ! -f "$HOSTNAMES_FILE" ]; then
  write_empty_config
  finalize_config
  reload_traefik
  exit 0
fi

valid_count=0
cat > "$TLS_DYNAMIC_TMP_FILE" <<'YAML'
tls:
  certificates:
YAML

while IFS= read -r hostname; do
  hostname=$(printf '%s' "$hostname" | tr -d '[:space:]')
  if [ -z "$hostname" ]; then
    continue
  fi
  case "$hostname" in
    \#*)
      continue
      ;;
  esac

  install -d -m 0755 "/srv/edge/certs/$hostname"
  tailscale cert --cert-file "/srv/edge/certs/$hostname/cert.pem" --key-file "/srv/edge/certs/$hostname/key.pem" "$hostname"
  cat >> "$TLS_DYNAMIC_TMP_FILE" <<YAML
    - certFile: /srv/edge/certs/$hostname/cert.pem
      keyFile: /srv/edge/certs/$hostname/key.pem
YAML
  valid_count=$((valid_count + 1))
done < "$HOSTNAMES_FILE"

if [ "$valid_count" -eq 0 ]; then
  write_empty_config
fi

finalize_config
reload_traefik
