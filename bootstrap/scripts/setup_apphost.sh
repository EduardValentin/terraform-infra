#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/lib.sh"

set_app_context() {
  APP_NAME_VALUE=${APP_NAME:-courseplatform}
  HOST_LABEL_VALUE=${HOST_LABEL:-$(hostname -f 2>/dev/null || hostname)}
  OPS_LOKI_URL_VALUE=${OPS_LOKI_URL:-http://ops.longhair-eagle.ts.net:3100/loki/api/v1/push}
  DOLLAR='$'
}

prepare_directories() {
  install -d -m 0755 /srv/edge
  install -d -m 0755 /srv/edge/dynamic
  install -d -m 0755 /srv/apps/observability
  install -d -m 0755 /srv/apps/observability/promtail-positions
}

write_edge_env() {
  cat > /srv/edge/.env <<__EDGE_ENV__
ENVIRONMENT=${ENVIRONMENT}
APP_NAME=${APP_NAME_VALUE}
HOST_LABEL=${HOST_LABEL_VALUE}
__EDGE_ENV__
}

write_observability_env() {
  cat > /srv/apps/observability/.env <<__OBS_ENV__
ENVIRONMENT=${ENVIRONMENT}
APP_NAME=${APP_NAME_VALUE}
HOST_LABEL=${HOST_LABEL_VALUE}
OPS_LOKI_URL=${OPS_LOKI_URL_VALUE}
__OBS_ENV__
}

write_promtail_config() {
  cat > /srv/apps/observability/promtail.yml <<__PROMTAIL_CFG__
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /var/lib/promtail/positions.yaml

clients:
  - url: ${OPS_LOKI_URL_VALUE}

scrape_configs:
  - job_name: docker
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 10s
    relabel_configs:
      - source_labels: ['__meta_docker_container_name']
        regex: '/(.*)'
        target_label: service
        replacement: '${DOLLAR}1'
      - source_labels: ['__meta_docker_container_label_service']
        regex: '(.+)'
        target_label: service
        replacement: '${DOLLAR}1'
      - target_label: env
        replacement: '${ENVIRONMENT}'
      - target_label: app
        replacement: '${APP_NAME_VALUE}'
      - target_label: host
        replacement: '${HOST_LABEL_VALUE}'
      - source_labels: ['__meta_docker_container_label_env']
        regex: '(.+)'
        target_label: env
        replacement: '${DOLLAR}1'
      - source_labels: ['__meta_docker_container_label_app']
        regex: '(.+)'
        target_label: app
        replacement: '${DOLLAR}1'
      - source_labels: ['__meta_docker_container_label_host']
        regex: '(.+)'
        target_label: host
        replacement: '${DOLLAR}1'
      - source_labels: ['__meta_docker_container_name']
        regex: '/(.*)'
        target_label: container
        replacement: '${DOLLAR}1'
    pipeline_stages:
      - docker: {}
__PROMTAIL_CFG__
}

copy_observability_files() {
  cp "$SCRIPT_DIR/../compose/agents/docker-compose.yml" /srv/apps/observability/docker-compose.yml
}

copy_test_files() {
  cp "$SCRIPT_DIR/../compose/traefik/test/docker-compose.yml" /srv/edge/docker-compose.yml
  cp "$SCRIPT_DIR/../compose/traefik/test/traefik.yml" /srv/edge/traefik.yml
  cp "$SCRIPT_DIR/../compose/traefik/test/dynamic/middlewares.yml" /srv/edge/dynamic/middlewares.yml
  cp "$SCRIPT_DIR/../edge/hostnames.txt" /srv/edge/hostnames.txt
  install -m 0755 "$SCRIPT_DIR/setup_traefik_test_certs.sh" /usr/local/bin/setup_traefik_test_certs.sh
  cp "$SCRIPT_DIR/../systemd/tailscale-cert-renew.service" /etc/systemd/system/tailscale-cert-renew.service
  cp "$SCRIPT_DIR/../systemd/tailscale-cert-renew.timer" /etc/systemd/system/tailscale-cert-renew.timer
  systemctl daemon-reload
  systemctl enable tailscale-cert-renew.timer
  systemctl start tailscale-cert-renew.timer
  /usr/local/bin/setup_traefik_test_certs.sh
}

copy_prod_files() {
  cp "$SCRIPT_DIR/../compose/traefik/prod/docker-compose.yml" /srv/edge/docker-compose.yml
  cp "$SCRIPT_DIR/../compose/traefik/prod/traefik.yml" /srv/edge/traefik.yml
  cp "$SCRIPT_DIR/../compose/traefik/prod/dynamic/middlewares.yml" /srv/edge/dynamic/middlewares.yml
  touch /srv/edge/acme/acme.json
  chmod 600 /srv/edge/acme/acme.json
}

start_traefik() {
  docker compose --env-file /srv/edge/.env -f /srv/edge/docker-compose.yml up -d
}

start_observability_agents() {
  docker compose --env-file /srv/apps/observability/.env -f /srv/apps/observability/docker-compose.yml up -d
}

main() {
  require_root
  set_app_context
  prepare_directories
  write_edge_env
  write_observability_env
  write_promtail_config
  copy_observability_files

  case "${ENVIRONMENT:-}" in
    test)
      copy_test_files
      ;;
    prod)
      copy_prod_files
      ;;
    *)
      log "ENVIRONMENT must be test or prod"
      exit 1
      ;;
  esac

  start_traefik
  start_observability_agents
}

main "$@"
