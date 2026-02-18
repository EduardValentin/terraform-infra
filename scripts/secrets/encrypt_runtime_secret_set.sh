#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
usage: encrypt_runtime_secret_set.sh <environment> <app_name> <app_env_plain_file> <postgres_env_plain_file>

Encrypt plaintext runtime env files with SOPS and write repository-tracked encrypted files:
  secrets/runtime/<environment>/<app_name>.app.env.enc
  secrets/runtime/<environment>/<app_name>.postgres.env.enc
USAGE
}

if [[ $# -ne 4 ]]; then
  usage
  exit 1
fi

ENVIRONMENT="$1"
APP_NAME="$2"
APP_ENV_FILE="$3"
POSTGRES_ENV_FILE="$4"

if ! command -v sops >/dev/null 2>&1; then
  echo "sops is required but not installed"
  exit 1
fi

if [[ ! -f "$APP_ENV_FILE" ]]; then
  echo "missing app env file: $APP_ENV_FILE"
  exit 1
fi

if [[ ! -f "$POSTGRES_ENV_FILE" ]]; then
  echo "missing postgres env file: $POSTGRES_ENV_FILE"
  exit 1
fi

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
OUTPUT_DIR="$ROOT_DIR/secrets/runtime/$ENVIRONMENT"
mkdir -p "$OUTPUT_DIR"

APP_OUT="$OUTPUT_DIR/$APP_NAME.app.env.enc"
POSTGRES_OUT="$OUTPUT_DIR/$APP_NAME.postgres.env.enc"
APP_TMP="$(mktemp)"
POSTGRES_TMP="$(mktemp)"

cleanup() {
  rm -f "$APP_TMP" "$POSTGRES_TMP"
}
trap cleanup EXIT

sops --encrypt --input-type dotenv --output-type dotenv "$APP_ENV_FILE" > "$APP_TMP"
sops --encrypt --input-type dotenv --output-type dotenv "$POSTGRES_ENV_FILE" > "$POSTGRES_TMP"

mv "$APP_TMP" "$APP_OUT"
mv "$POSTGRES_TMP" "$POSTGRES_OUT"

echo "wrote $APP_OUT"
echo "wrote $POSTGRES_OUT"
