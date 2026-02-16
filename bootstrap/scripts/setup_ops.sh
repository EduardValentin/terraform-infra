#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/lib.sh"

set_context() {
  APP_NAME_VALUE=${APP_NAME:-courseplatform}
  HOST_LABEL_VALUE=${HOST_LABEL:-$(hostname -f 2>/dev/null || hostname)}
  LOW_RESOURCE_MODE_VALUE=${LOW_RESOURCE_MODE:-false}
  TEST_HOSTS_VALUE=${TEST_HOSTS:-courseplatform-test.longhair-eagle.ts.net}
  PROD_HOSTS_VALUE=${PROD_HOSTS:-}
  OPS_GRAFANA_ADMIN_PASSWORD_VALUE=${OPS_GRAFANA_ADMIN_PASSWORD:-admin-change-me}
}

prepare_directories() {
  install -d -m 0755 /srv/ops
  install -d -m 0755 /srv/ops/grafana
  install -d -m 0755 /srv/ops/grafana/data
  install -d -m 0755 /srv/ops/prometheus
  install -d -m 0755 /srv/ops/prometheus/data
  install -d -m 0755 /srv/ops/prometheus/targets
  install -d -m 0755 /srv/ops/alertmanager
  install -d -m 0755 /srv/ops/alertmanager/data
  install -d -m 0755 /srv/ops/loki
  install -d -m 0755 /srv/ops/loki/data
  install -d -m 0755 /srv/ops/tempo
  install -d -m 0755 /srv/ops/tempo/data
}

copy_static_files() {
  cp "$SCRIPT_DIR/../compose/ops/docker-compose.yml" /srv/ops/docker-compose.yml

  install -d -m 0755 /srv/ops/grafana/provisioning/datasources
  install -d -m 0755 /srv/ops/grafana/provisioning/dashboards
  install -d -m 0755 /srv/ops/grafana/dashboards/TEST
  install -d -m 0755 /srv/ops/grafana/dashboards/PROD

  cp "$SCRIPT_DIR/../compose/ops/grafana/provisioning/datasources/datasources.yml" /srv/ops/grafana/provisioning/datasources/datasources.yml
  cp "$SCRIPT_DIR/../compose/ops/grafana/provisioning/dashboards/dashboards.yml" /srv/ops/grafana/provisioning/dashboards/dashboards.yml
  for env_folder in TEST PROD; do
    src_dir="$SCRIPT_DIR/../compose/ops/grafana/dashboards/$env_folder"
    dst_dir="/srv/ops/grafana/dashboards/$env_folder"
    find "$dst_dir" -maxdepth 1 -type f -name '*.json' -delete
    for dashboard in "$src_dir"/*.json; do
      [ -f "$dashboard" ] || continue
      cp "$dashboard" "$dst_dir/$(basename "$dashboard")"
    done
  done

  cp "$SCRIPT_DIR/../compose/ops/prometheus/prometheus.yml" /srv/ops/prometheus/prometheus.yml
  cp "$SCRIPT_DIR/../compose/ops/prometheus/alerts.yml" /srv/ops/prometheus/alerts.yml

  cp "$SCRIPT_DIR/../compose/ops/alertmanager/alertmanager.yml" /srv/ops/alertmanager/alertmanager.yml

  if [ "$LOW_RESOURCE_MODE_VALUE" = "true" ]; then
    cp "$SCRIPT_DIR/../compose/ops/loki/config-low-resource.yml" /srv/ops/loki/config.yml
    cp "$SCRIPT_DIR/../compose/ops/tempo/config-low-resource.yml" /srv/ops/tempo/config.yml
  else
    cp "$SCRIPT_DIR/../compose/ops/loki/config.yml" /srv/ops/loki/config.yml
    cp "$SCRIPT_DIR/../compose/ops/tempo/config.yml" /srv/ops/tempo/config.yml
  fi
}

write_env_file() {
  cat > /srv/ops/.env <<__OPS_ENV__
APP_NAME=${APP_NAME_VALUE}
HOST_LABEL=${HOST_LABEL_VALUE}
OPS_GRAFANA_ADMIN_PASSWORD=${OPS_GRAFANA_ADMIN_PASSWORD_VALUE}
LOW_RESOURCE_MODE=${LOW_RESOURCE_MODE_VALUE}
TEST_HOSTS=${TEST_HOSTS_VALUE}
PROD_HOSTS=${PROD_HOSTS_VALUE}
__OPS_ENV__
}

generate_targets() {
  env_name="$1"
  hosts_csv="$2"
  out_file="$3"

  first=1
  printf '[\n' > "$out_file"

  old_ifs=$IFS
  IFS=','
  for host in $hosts_csv; do
    host_trimmed=$(printf '%s' "$host" | sed 's/^ *//;s/ *$//')
    if [ -z "$host_trimmed" ]; then
      continue
    fi

    for service in node-exporter cadvisor; do
      if [ "$service" = "node-exporter" ]; then
        port=9100
      else
        port=8080
      fi

      if [ "$first" -eq 0 ]; then
        printf ',\n' >> "$out_file"
      fi

      printf '  {"targets":["%s:%s"],"labels":{"env":"%s","app":"%s","service":"%s","host":"%s"}}' \
        "$host_trimmed" "$port" "$env_name" "$APP_NAME_VALUE" "$service" "$host_trimmed" >> "$out_file"
      first=0
    done
  done
  IFS=$old_ifs

  printf '\n]\n' >> "$out_file"
}

write_targets() {
  generate_targets test "$TEST_HOSTS_VALUE" /srv/ops/prometheus/targets/test.json
  generate_targets prod "$PROD_HOSTS_VALUE" /srv/ops/prometheus/targets/prod.json
}

start_stack() {
  docker compose --env-file /srv/ops/.env -f /srv/ops/docker-compose.yml up -d
}

main() {
  require_root
  set_context
  prepare_directories
  copy_static_files
  write_env_file
  write_targets
  start_stack
}

main "$@"
