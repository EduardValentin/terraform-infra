#!/bin/sh
set -eu

usage() {
  cat <<USAGE
usage: $0 <endpoint> <bucket> <access_key> <secret_key> [out_dir]

example:
  $0 http://susanoo-ops.longhair-eagle.ts.net:9000 terraform-state terraform-state 'super-secret' ./dist/backend-config
USAGE
}

if [ "$#" -lt 4 ] || [ "$#" -gt 5 ]; then
  usage
  exit 1
fi

endpoint="$1"
bucket="$2"
access_key="$3"
secret_key="$4"
out_dir="${5:-./dist/backend-config}"

mkdir -p "$out_dir"

write_backend_file() {
  env_name="$1"
  key_prefix="$2"
  file_path="$out_dir/${env_name}.backend.hcl"

  cat > "$file_path" <<BACKEND
bucket                      = "${bucket}"
key                         = "${key_prefix}/terraform.tfstate"
region                      = "us-east-1"
endpoints = {
  s3 = "${endpoint}"
}
access_key                  = "${access_key}"
secret_key                  = "${secret_key}"
skip_credentials_validation = true
skip_region_validation      = true
skip_metadata_api_check     = true
use_path_style              = true
BACKEND

  chmod 600 "$file_path"
  printf 'wrote %s\n' "$file_path"
}

write_backend_file controlplane controlplane
write_backend_file test test
write_backend_file ops ops
write_backend_file prod prod
