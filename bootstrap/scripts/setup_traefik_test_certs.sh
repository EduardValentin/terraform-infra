#!/bin/sh
set -eu

HOSTNAMES_FILE=/srv/edge/hostnames.txt
DYNAMIC_DIR=/srv/edge/dynamic
TLS_DYNAMIC_FILE=$DYNAMIC_DIR/tls-certs.yml

install -d -m 0755 "$DYNAMIC_DIR"

if [ ! -f "$HOSTNAMES_FILE" ]; then
  cat > "$TLS_DYNAMIC_FILE" <<'YAML'
tls:
  certificates: []
YAML
  exit 0
fi

valid_count=0
cat > "$TLS_DYNAMIC_FILE" <<'YAML'
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
  cat >> "$TLS_DYNAMIC_FILE" <<YAML
    - certFile: /srv/edge/certs/$hostname/cert.pem
      keyFile: /srv/edge/certs/$hostname/key.pem
YAML
  valid_count=$((valid_count + 1))
done < "$HOSTNAMES_FILE"

if [ "$valid_count" -eq 0 ]; then
  cat > "$TLS_DYNAMIC_FILE" <<'YAML'
tls:
  certificates: []
YAML
fi
