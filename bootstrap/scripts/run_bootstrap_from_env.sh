#!/bin/sh
set -eu

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo "usage: $0 <env-file> [bootstrap-script]"
  exit 1
fi

ENV_FILE="$1"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BOOTSTRAP_SCRIPT="${2:-$SCRIPT_DIR/bootstrap.sh}"

if [ ! -f "$ENV_FILE" ]; then
  echo "env file not found: $ENV_FILE"
  exit 1
fi

if [ ! -x "$BOOTSTRAP_SCRIPT" ]; then
  echo "bootstrap script not executable: $BOOTSTRAP_SCRIPT"
  exit 1
fi

set -a
. "$ENV_FILE"
set +a

exec "$BOOTSTRAP_SCRIPT"
