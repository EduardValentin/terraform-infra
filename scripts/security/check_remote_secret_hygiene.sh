#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "usage: $0 <ssh-target> [--cleanup]"
  exit 1
fi

SSH_TARGET="$1"
CLEANUP_MODE="${2:-}"

if [[ -n "$CLEANUP_MODE" && "$CLEANUP_MODE" != "--cleanup" ]]; then
  echo "invalid flag: $CLEANUP_MODE"
  exit 1
fi

cleanup_flag="false"
if [[ "$CLEANUP_MODE" == "--cleanup" ]]; then
  cleanup_flag="true"
fi

ssh "$SSH_TARGET" "sudo CLEANUP_MODE='$cleanup_flag' bash -s" <<'REMOTE'
set -euo pipefail

echo "== candidate env files =="
find /tmp /var/tmp /srv /root -maxdepth 5 -type f \
  \( -name '*.env' -o -name '*.app.env' -o -name '*.postgres.env' \) \
  2>/dev/null | sort

echo "== expected secret file permissions =="
for file in /root/bootstrap/bootstrap-*.env /srv/apps/*/.env /srv/postgres/*.env /srv/ops/.env /etc/course-platform-backup.env; do
  [[ -f "$file" ]] || continue
  chmod 600 "$file"
  stat -c '%a %n' "$file"
done

if [[ "$CLEANUP_MODE" == "true" ]]; then
  find /tmp /var/tmp -maxdepth 4 -type f \
    \( -name '*.app.env' -o -name '*.postgres.env' -o -name 'age.key' \) \
    -delete 2>/dev/null || true
  find /tmp /var/tmp -maxdepth 4 -type d \
    \( -name 'runtime-secrets' -o -name 'runtime-secrets-*' \) \
    -exec rm -rf {} + 2>/dev/null || true
  echo "cleanup applied"
fi

echo "== temp secret residue check =="
residue="$(find /tmp /var/tmp -maxdepth 4 -type f \
  \( -name '*.app.env' -o -name '*.postgres.env' -o -name 'age.key' \) \
  2>/dev/null || true)"

if [[ -n "$residue" ]]; then
  echo "$residue"
  echo "residual plaintext temp files remain"
  exit 1
fi

echo "no residual plaintext temp secret files detected in /tmp or /var/tmp"
REMOTE
