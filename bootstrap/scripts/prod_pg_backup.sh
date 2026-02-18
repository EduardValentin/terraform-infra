#!/bin/sh
set -eu

log() {
  printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"
}

read_env_file_value() {
  file_path="$1"
  key="$2"
  awk -F= -v target="$key" '$1 == target {print substr($0, index($0, $2)); exit}' "$file_path"
}

strip_wrapping_quotes() {
  value="$1"
  value=$(printf '%s' "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
  case "$value" in
    \"*\")
      value=${value#\"}
      value=${value%\"}
      ;;
    \'*\')
      value=${value#\'}
      value=${value%\'}
      ;;
  esac
  printf '%s' "$value"
}

require_positive_number() {
  name="$1"
  value="$2"
  case "$value" in
    ''|*[!0-9]*)
      log "$name must be a positive number"
      exit 1
      ;;
    0)
      log "$name must be greater than zero"
      exit 1
      ;;
  esac
}

main() {
  APP_NAME_VALUE=${APP_NAME:-courseplatform}
  ENVIRONMENT_VALUE=${ENVIRONMENT:-prod}
  POSTGRES_CONTAINER_NAME_VALUE=${POSTGRES_CONTAINER_NAME:-${APP_NAME_VALUE}-${ENVIRONMENT_VALUE}-postgres}
  POSTGRES_ENV_FILE_VALUE=${POSTGRES_ENV_FILE:-/srv/postgres/${APP_NAME_VALUE}.env}
  LOCAL_BACKUP_DIR_VALUE=${LOCAL_BACKUP_DIR:-/srv/backups/postgres}
  LOCAL_RETENTION_DAYS_VALUE=${LOCAL_RETENTION_DAYS:-14}
  NAS_BACKUP_DIR_VALUE=${NAS_BACKUP_DIR:-}
  NAS_RETENTION_DAYS_VALUE=${NAS_RETENTION_DAYS:-14}

  require_positive_number "LOCAL_RETENTION_DAYS" "$LOCAL_RETENTION_DAYS_VALUE"
  require_positive_number "NAS_RETENTION_DAYS" "$NAS_RETENTION_DAYS_VALUE"

  if [ ! -f "$POSTGRES_ENV_FILE_VALUE" ]; then
    log "postgres env file not found; skipping backup file=$POSTGRES_ENV_FILE_VALUE"
    exit 0
  fi

  if ! docker ps --format '{{.Names}}' | grep -Fxq "$POSTGRES_CONTAINER_NAME_VALUE"; then
    log "postgres container not running; skipping backup container=$POSTGRES_CONTAINER_NAME_VALUE"
    exit 0
  fi

  POSTGRES_USER_VALUE=$(strip_wrapping_quotes "$(read_env_file_value "$POSTGRES_ENV_FILE_VALUE" POSTGRES_USER)")
  POSTGRES_DB_VALUE=$(strip_wrapping_quotes "$(read_env_file_value "$POSTGRES_ENV_FILE_VALUE" POSTGRES_DB)")

  if [ -z "$POSTGRES_USER_VALUE" ] || [ -z "$POSTGRES_DB_VALUE" ]; then
    log "POSTGRES_USER and POSTGRES_DB are required in $POSTGRES_ENV_FILE_VALUE"
    exit 1
  fi

  install -d -m 0700 "$LOCAL_BACKUP_DIR_VALUE"
  timestamp=$(date -u +%Y%m%dT%H%M%SZ)
  backup_name="${APP_NAME_VALUE}_${ENVIRONMENT_VALUE}_${timestamp}.sql.gz"
  local_backup_path="${LOCAL_BACKUP_DIR_VALUE}/${backup_name}"

  if ! docker exec -i "$POSTGRES_CONTAINER_NAME_VALUE" pg_dump -U "$POSTGRES_USER_VALUE" -d "$POSTGRES_DB_VALUE" | gzip -c > "$local_backup_path"; then
    rm -f "$local_backup_path"
    log "pg_dump failed"
    exit 1
  fi
  chmod 600 "$local_backup_path"

  if [ -n "$NAS_BACKUP_DIR_VALUE" ]; then
    if [ -d "$NAS_BACKUP_DIR_VALUE" ] && [ -w "$NAS_BACKUP_DIR_VALUE" ]; then
      nas_backup_path="${NAS_BACKUP_DIR_VALUE}/${backup_name}"
      cp "$local_backup_path" "$nas_backup_path"
      chmod 600 "$nas_backup_path"
      find "$NAS_BACKUP_DIR_VALUE" -type f -name "${APP_NAME_VALUE}_${ENVIRONMENT_VALUE}_*.sql.gz" -mtime +"$NAS_RETENTION_DAYS_VALUE" -delete
      log "backup copied to nas path=$nas_backup_path"
    else
      log "nas backup dir unavailable or not writable; skipping nas copy dir=$NAS_BACKUP_DIR_VALUE"
    fi
  fi

  find "$LOCAL_BACKUP_DIR_VALUE" -type f -name "${APP_NAME_VALUE}_${ENVIRONMENT_VALUE}_*.sql.gz" -mtime +"$LOCAL_RETENTION_DAYS_VALUE" -delete
  log "backup complete local_path=$local_backup_path"
}

main "$@"
