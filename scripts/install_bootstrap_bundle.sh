#!/bin/sh
set -eu

if [ "$#" -lt 4 ]; then
  echo "usage: $0 <repo> <version> <role> <environment> [tailscale_auth_key] [tailscale_tags]"
  exit 1
fi

REPO="$1"
VERSION="$2"
ROLE="$3"
ENVIRONMENT="$4"
TAILSCALE_AUTH_KEY="${5:-}"
TAILSCALE_TAGS="${6:-}"

if [ "$ENVIRONMENT" = "prod" ]; then
  echo "manual PROD bootstrap is disabled; use Terraform/cloud-init path"
  exit 1
fi

TMP_TGZ="/tmp/bootstrap-bundle-$VERSION.tar.gz"
INSTALL_DIR="/opt/bootstrap"

curl -fsSL -o "$TMP_TGZ" "https://github.com/$REPO/releases/download/$VERSION/bootstrap-bundle-$VERSION.tar.gz"
mkdir -p "$INSTALL_DIR"
tar -xzf "$TMP_TGZ" -C "$INSTALL_DIR" --strip-components=1
ROLE="$ROLE" ENVIRONMENT="$ENVIRONMENT" TAILSCALE_AUTH_KEY="$TAILSCALE_AUTH_KEY" TAILSCALE_TAGS="$TAILSCALE_TAGS" "$INSTALL_DIR/scripts/bootstrap.sh"
