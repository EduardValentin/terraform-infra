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
APP_ENC_FILE="$ROOT_DIR/secrets/runtime/${ENVIRONMENT}/${APP_NAME}.app.env.enc"
POSTGRES_ENC_FILE="$ROOT_DIR/secrets/runtime/${ENVIRONMENT}/${APP_NAME}.postgres.env.enc"
APP_TEMPLATE_FILE="$ROOT_DIR/secrets/runtime/templates/${APP_NAME}.app.env.example"
POSTGRES_TEMPLATE_FILE="$ROOT_DIR/secrets/runtime/templates/${APP_NAME}.postgres.env.example"

case "$COMMAND" in
  prepare)
    mkdir -p "$WORK_DIR"

    if [[ -f "$APP_ENC_FILE" && -f "$POSTGRES_ENC_FILE" ]]; then
      "$DECRYPT_SCRIPT" "$ENVIRONMENT" "$APP_NAME" "$WORK_DIR"
      chmod 600 "$APP_WORK_FILE" "$POSTGRES_WORK_FILE"
      echo "decrypted files ready for editing:"
      echo "  $APP_WORK_FILE"
      echo "  $POSTGRES_WORK_FILE"
      exit 0
    fi

    if [[ -f "$APP_ENC_FILE" ]]; then
      if ! command -v sops >/dev/null 2>&1; then
        echo "sops is required to decrypt existing file: $APP_ENC_FILE"
        exit 1
      fi
      sops --decrypt --input-type dotenv --output-type dotenv "$APP_ENC_FILE" > "$APP_WORK_FILE"
    elif [[ -f "$APP_TEMPLATE_FILE" ]]; then
      cp "$APP_TEMPLATE_FILE" "$APP_WORK_FILE"
    else
      echo "missing encrypted or template file for app env:"
      echo "  $APP_ENC_FILE"
      echo "  $APP_TEMPLATE_FILE"
      exit 1
    fi

    if [[ -f "$POSTGRES_ENC_FILE" ]]; then
      if ! command -v sops >/dev/null 2>&1; then
        echo "sops is required to decrypt existing file: $POSTGRES_ENC_FILE"
        exit 1
      fi
      sops --decrypt --input-type dotenv --output-type dotenv "$POSTGRES_ENC_FILE" > "$POSTGRES_WORK_FILE"
    elif [[ -f "$POSTGRES_TEMPLATE_FILE" ]]; then
      cp "$POSTGRES_TEMPLATE_FILE" "$POSTGRES_WORK_FILE"
    else
      echo "missing encrypted or template file for postgres env:"
      echo "  $POSTGRES_ENC_FILE"
      echo "  $POSTGRES_TEMPLATE_FILE"
      exit 1
    fi

    chmod 600 "$APP_WORK_FILE" "$POSTGRES_WORK_FILE"
    echo "work files ready for editing:"
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
