#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/lib.sh"

set_context() {
  APP_NAME_VALUE=${APP_NAME:-courseplatform}
  APP_METRICS_PATH_VALUE=${APP_METRICS_PATH:-/courseplatform/metrics}
  HOST_LABEL_VALUE=${HOST_LABEL:-$(hostname -f 2>/dev/null || hostname)}
  LOW_RESOURCE_MODE_VALUE=${LOW_RESOURCE_MODE:-false}
  TEST_HOSTS_VALUE=${TEST_HOSTS:-susanoo-test.longhair-eagle.ts.net}
  PROD_HOSTS_VALUE=${PROD_HOSTS:-}
  OPS_GRAFANA_ADMIN_PASSWORD_VALUE=${OPS_GRAFANA_ADMIN_PASSWORD:-admin-change-me}
  OPS_TAILSCALE_IPV4_VALUE=${OPS_TAILSCALE_IPV4:-$(tailscale ip -4 | sed -n '1p')}
  TERRAFORM_BACKEND_ENABLED_VALUE=${TERRAFORM_BACKEND_ENABLED:-true}
  TERRAFORM_BACKEND_BUCKET_VALUE=${TERRAFORM_BACKEND_BUCKET:-terraform-state}
  TERRAFORM_BACKEND_BIND_IP_VALUE=${TERRAFORM_BACKEND_BIND_IP:-$OPS_TAILSCALE_IPV4_VALUE}
  TERRAFORM_BACKEND_PORT_VALUE=${TERRAFORM_BACKEND_PORT:-9000}
  TERRAFORM_BACKEND_ACCESS_KEY_VALUE=${TERRAFORM_BACKEND_ACCESS_KEY:-terraform-state}
  TERRAFORM_BACKEND_SECRET_KEY_VALUE=${TERRAFORM_BACKEND_SECRET_KEY:-replace-me}
}

validate_context() {
  case "$APP_METRICS_PATH_VALUE" in
    /*)
      ;;
    *)
      log "APP_METRICS_PATH must start with /"
      exit 1
      ;;
  esac

  if [ -z "$OPS_TAILSCALE_IPV4_VALUE" ]; then
    log "failed to detect Tailscale IPv4 for OPS host"
    exit 1
  fi

  case "$TERRAFORM_BACKEND_ENABLED_VALUE" in
    true|false)
      ;;
    *)
      log "TERRAFORM_BACKEND_ENABLED must be true or false"
      exit 1
      ;;
  esac

  if [ "$TERRAFORM_BACKEND_ENABLED_VALUE" = "true" ]; then
    case "$TERRAFORM_BACKEND_SECRET_KEY_VALUE" in
      replace-me|replace-with-strong-secret|"")
        log "TERRAFORM_BACKEND_SECRET_KEY must be set when TERRAFORM_BACKEND_ENABLED=true"
        exit 1
        ;;
    esac
  fi
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
  install -d -m 0755 /srv/ops/terraform-backend
  install -d -m 0755 /srv/ops/terraform-backend/data
}

set_data_permissions() {
  chown -R 472:472 /srv/ops/grafana/data
  chown -R 65534:65534 /srv/ops/prometheus/data
  chown -R 65534:65534 /srv/ops/alertmanager/data
  chown -R 10001:10001 /srv/ops/loki/data
  chown -R 10001:10001 /srv/ops/tempo/data
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
APP_METRICS_PATH=${APP_METRICS_PATH_VALUE}
HOST_LABEL=${HOST_LABEL_VALUE}
OPS_GRAFANA_ADMIN_PASSWORD=${OPS_GRAFANA_ADMIN_PASSWORD_VALUE}
LOW_RESOURCE_MODE=${LOW_RESOURCE_MODE_VALUE}
TEST_HOSTS=${TEST_HOSTS_VALUE}
PROD_HOSTS=${PROD_HOSTS_VALUE}
OPS_TAILSCALE_IPV4=${OPS_TAILSCALE_IPV4_VALUE}
TERRAFORM_BACKEND_ENABLED=${TERRAFORM_BACKEND_ENABLED_VALUE}
TERRAFORM_BACKEND_BUCKET=${TERRAFORM_BACKEND_BUCKET_VALUE}
TERRAFORM_BACKEND_BIND_IP=${TERRAFORM_BACKEND_BIND_IP_VALUE}
TERRAFORM_BACKEND_PORT=${TERRAFORM_BACKEND_PORT_VALUE}
TERRAFORM_BACKEND_ACCESS_KEY=${TERRAFORM_BACKEND_ACCESS_KEY_VALUE}
TERRAFORM_BACKEND_SECRET_KEY=${TERRAFORM_BACKEND_SECRET_KEY_VALUE}
__OPS_ENV__
  chmod 600 /srv/ops/.env
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

    if [ "$first" -eq 0 ]; then
      printf ',\n' >> "$out_file"
    fi
    printf '  {"targets":["%s:9100"],"labels":{"env":"%s","app":"%s","service":"node-exporter","host":"%s"}}' \
      "$host_trimmed" "$env_name" "$APP_NAME_VALUE" "$host_trimmed" >> "$out_file"
    first=0

    printf ',\n' >> "$out_file"
    printf '  {"targets":["%s:8080"],"labels":{"env":"%s","app":"%s","service":"cadvisor","host":"%s"}}' \
      "$host_trimmed" "$env_name" "$APP_NAME_VALUE" "$host_trimmed" >> "$out_file"

    printf ',\n' >> "$out_file"
    printf '  {"targets":["%s:443"],"labels":{"env":"%s","app":"%s","service":"app-metrics","host":"%s","__scheme__":"https","__metrics_path__":"%s"}}' \
      "$host_trimmed" "$env_name" "$APP_NAME_VALUE" "$host_trimmed" "$APP_METRICS_PATH_VALUE" >> "$out_file"
  done
  IFS=$old_ifs

  printf '\n]\n' >> "$out_file"
}

write_targets() {
  generate_targets test "$TEST_HOSTS_VALUE" /srv/ops/prometheus/targets/test.json
  generate_targets prod "$PROD_HOSTS_VALUE" /srv/ops/prometheus/targets/prod.json
}

start_stack() {
  if [ "$TERRAFORM_BACKEND_ENABLED_VALUE" = "true" ]; then
    docker compose --profile tfstate --env-file /srv/ops/.env -f /srv/ops/docker-compose.yml up -d
    return
  fi

  docker compose --env-file /srv/ops/.env -f /srv/ops/docker-compose.yml up -d
}

main() {
  require_root
  set_context
  validate_context
  prepare_directories
  set_data_permissions
  copy_static_files
  write_env_file
  write_targets
  start_stack
}

main "$@"
