#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
usage: edit_runtime_secret_set.sh <command> <environment> <app_name>

commands:
  prepare   decrypt encrypted runtime secrets into gitignored work folder
  apply     encrypt work folder files back into repository encrypted files
  cleanup   remove work folder for environment/app

examples:
  ./scripts/secrets/edit_runtime_secret_set.sh prepare test courseplatform
  ./scripts/secrets/edit_runtime_secret_set.sh apply test courseplatform
  ./scripts/secrets/edit_runtime_secret_set.sh cleanup test courseplatform
USAGE
}

if [[ $# -ne 3 ]]; then
  usage
  exit 1
fi

COMMAND="$1"
ENVIRONMENT="$2"
APP_NAME="$3"

if [[ "$ENVIRONMENT" != "test" && "$ENVIRONMENT" != "prod" ]]; then
  echo "environment must be test or prod"
  exit 1
fi

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
DECRYPT_SCRIPT="$ROOT_DIR/scripts/secrets/decrypt_runtime_secret_set.sh"
ENCRYPT_SCRIPT="$ROOT_DIR/scripts/secrets/encrypt_runtime_secret_set.sh"
WORK_DIR="$ROOT_DIR/secrets/runtime/work/${ENVIRONMENT}-${APP_NAME}"
APP_WORK_FILE="$WORK_DIR/${APP_NAME}.app.env"
POSTGRES_WORK_FILE="$WORK_DIR/${APP_NAME}.postgres.env"

case "$COMMAND" in
  prepare)
    mkdir -p "$WORK_DIR"
    "$DECRYPT_SCRIPT" "$ENVIRONMENT" "$APP_NAME" "$WORK_DIR"
    chmod 600 "$APP_WORK_FILE" "$POSTGRES_WORK_FILE"
    echo "decrypted files ready for editing:"
    echo "  $APP_WORK_FILE"
    echo "  $POSTGRES_WORK_FILE"
    ;;
  apply)
    if [[ ! -f "$APP_WORK_FILE" ]]; then
      echo "missing work file: $APP_WORK_FILE"
      exit 1
    fi

    if [[ ! -f "$POSTGRES_WORK_FILE" ]]; then
      echo "missing work file: $POSTGRES_WORK_FILE"
      exit 1
    fi

    "$ENCRYPT_SCRIPT" "$ENVIRONMENT" "$APP_NAME" "$APP_WORK_FILE" "$POSTGRES_WORK_FILE"
    echo "encrypted files updated under secrets/runtime/${ENVIRONMENT}/"
    echo "next step: git add secrets/runtime/${ENVIRONMENT}/${APP_NAME}.app.env.enc secrets/runtime/${ENVIRONMENT}/${APP_NAME}.postgres.env.enc"
    ;;
  cleanup)
    rm -rf "$WORK_DIR"
    echo "removed $WORK_DIR"
    ;;
  *)
    usage
    exit 1
    ;;
esac
