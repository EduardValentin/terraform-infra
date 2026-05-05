#!/bin/sh
set -eu

log() {
  printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "missing command: $1"
    exit 1
  fi
}

main() {
  DOCKER_IMAGE_PRUNE_UNTIL=${DOCKER_IMAGE_PRUNE_UNTIL:-168h}
  DOCKER_BUILDER_PRUNE_UNTIL=${DOCKER_BUILDER_PRUNE_UNTIL:-168h}
  DOCKER_CLEANUP_DF_TIMEOUT=${DOCKER_CLEANUP_DF_TIMEOUT:-60s}
  DOCKER_CLEANUP_PRUNE_TIMEOUT=${DOCKER_CLEANUP_PRUNE_TIMEOUT:-300s}

  require_cmd docker
  require_cmd timeout

  log "docker disk usage before cleanup"
  if ! timeout "$DOCKER_CLEANUP_DF_TIMEOUT" docker system df; then
    log "docker system df did not complete within $DOCKER_CLEANUP_DF_TIMEOUT; continuing cleanup"
  fi

  log "pruning unused docker images older than ${DOCKER_IMAGE_PRUNE_UNTIL}"
  timeout "$DOCKER_CLEANUP_PRUNE_TIMEOUT" docker image prune -af --filter "until=${DOCKER_IMAGE_PRUNE_UNTIL}"

  log "pruning unused docker build cache older than ${DOCKER_BUILDER_PRUNE_UNTIL}"
  timeout "$DOCKER_CLEANUP_PRUNE_TIMEOUT" docker builder prune -af --filter "until=${DOCKER_BUILDER_PRUNE_UNTIL}"

  log "docker disk usage after cleanup"
  if ! timeout "$DOCKER_CLEANUP_DF_TIMEOUT" docker system df; then
    log "docker system df did not complete within $DOCKER_CLEANUP_DF_TIMEOUT after cleanup"
  fi
}

main "$@"
