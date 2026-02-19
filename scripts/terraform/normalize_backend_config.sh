#!/usr/bin/env bash
set -euo pipefail

backend_file="${1:-}"
if [[ -z "$backend_file" ]]; then
  echo "usage: $0 <backend.hcl>"
  exit 1
fi

if [[ ! -f "$backend_file" ]]; then
  echo "backend config file not found: $backend_file"
  exit 1
fi

tmp_file="$(mktemp)"

endpoint_value="$(awk -F= '
  /^[[:space:]]*endpoint[[:space:]]*=/ {
    value=$0
    sub(/^[^=]*=[[:space:]]*/, "", value)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
    gsub(/^"/, "", value)
    gsub(/"$/, "", value)
    print value
    exit
  }
' "$backend_file")"

force_path_style_value="$(awk -F= '
  /^[[:space:]]*force_path_style[[:space:]]*=/ {
    value=$0
    sub(/^[^=]*=[[:space:]]*/, "", value)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
    print value
    exit
  }
' "$backend_file")"

awk '
  /^[[:space:]]*endpoint[[:space:]]*=/ { next }
  /^[[:space:]]*force_path_style[[:space:]]*=/ { next }
  { print }
' "$backend_file" > "$tmp_file"

if [[ -n "$endpoint_value" ]] && ! grep -Eq '^[[:space:]]*endpoints[[:space:]]*=' "$tmp_file"; then
  {
    printf '\n'
    printf 'endpoints = {\n'
    printf '  s3 = "%s"\n' "$endpoint_value"
    printf '}\n'
  } >> "$tmp_file"
fi

if [[ -n "$force_path_style_value" ]] && ! grep -Eq '^[[:space:]]*use_path_style[[:space:]]*=' "$tmp_file"; then
  printf 'use_path_style = %s\n' "$force_path_style_value" >> "$tmp_file"
fi

mv "$tmp_file" "$backend_file"
