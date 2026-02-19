#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/lib.sh"

cleanup_temp_secret_files() {
  find /tmp /var/tmp -maxdepth 4 -type f \
    \( -name '*.app.env' -o -name '*.postgres.env' -o -name 'age.key' \) \
    -delete 2>/dev/null || true

  find /tmp /var/tmp -maxdepth 4 -type d \
    \( -name 'runtime-secrets' -o -name 'runtime-secrets-*' \) \
    -exec rm -rf {} + 2>/dev/null || true
}

secure_secret_file_permissions() {
  for file in /root/bootstrap/bootstrap-*.env /srv/apps/*/.env /srv/postgres/*.env /srv/ops/.env /etc/course-platform-backup.env; do
    [ -f "$file" ] || continue
    chmod 600 "$file"
  done
}

main() {
  require_root
  cleanup_temp_secret_files
  secure_secret_file_permissions
}

main "$@"
