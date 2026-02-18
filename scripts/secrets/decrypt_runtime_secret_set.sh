#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
usage: decrypt_runtime_secret_set.sh <environment> <app_name> <output_dir>

Decrypt encrypted runtime env files into output_dir:
  <output_dir>/<app_name>.app.env
  <output_dir>/<app_name>.postgres.env
USAGE
}

if [[ $# -ne 3 ]]; then
  usage
  exit 1
fi

ENVIRONMENT="$1"
APP_NAME="$2"
OUTPUT_DIR="$3"

if ! command -v sops >/dev/null 2>&1; then
  echo "sops is required but not installed"
  exit 1
fi

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
APP_ENC="$ROOT_DIR/secrets/runtime/$ENVIRONMENT/$APP_NAME.app.env.enc"
POSTGRES_ENC="$ROOT_DIR/secrets/runtime/$ENVIRONMENT/$APP_NAME.postgres.env.enc"

if [[ ! -f "$APP_ENC" ]]; then
  echo "missing encrypted app env file: $APP_ENC"
  exit 1
fi

if [[ ! -f "$POSTGRES_ENC" ]]; then
  echo "missing encrypted postgres env file: $POSTGRES_ENC"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

sops --decrypt --input-type dotenv --output-type dotenv "$APP_ENC" > "$OUTPUT_DIR/$APP_NAME.app.env"
sops --decrypt --input-type dotenv --output-type dotenv "$POSTGRES_ENC" > "$OUTPUT_DIR/$APP_NAME.postgres.env"

echo "wrote $OUTPUT_DIR/$APP_NAME.app.env"
echo "wrote $OUTPUT_DIR/$APP_NAME.postgres.env"
