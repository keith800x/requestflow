#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

PROJECT_NAME="requestflow-net"

BASE_COMPOSE="$REPO_ROOT/docker-compose.prod-local.yml"
LAB_COMPOSE="$SCRIPT_DIR/docker-compose.network-lab.yml"
TOPOLOGY="$SCRIPT_DIR/requestflow.clab.yml"

POSTGRES_VOLUME="requestflow-net_requestflow_postgres_prod_local_data"

COMPOSE=(
  docker compose
  -p "$PROJECT_NAME"
  -f "$BASE_COMPOSE"
  -f "$LAB_COMPOSE"
)

log() {
  printf '\n[%s] %s\n' "$(date '+%H:%M:%S')" "$*"
}

fail() {
  printf '\nERROR: %s\n' "$*" >&2
  exit 1
}

command -v docker >/dev/null 2>&1 ||
  fail "Docker is not installed or not available."

command -v sudo >/dev/null 2>&1 ||
  fail "sudo is not available."

command -v containerlab >/dev/null 2>&1 ||
  fail "Containerlab is not installed or not available."

docker info >/dev/null 2>&1 ||
  fail "Docker is not running or is not accessible."

sudo -v

log "Destroying the Containerlab topology."

if sudo containerlab destroy \
  -t "$TOPOLOGY" \
  --cleanup; then
  echo "Containerlab topology removed."
else
  echo "No active Containerlab topology was found, or it was already removed."
fi

log "Removing RequestFlow Compose containers and networks."

"${COMPOSE[@]}" down --remove-orphans

log "Checking for remaining RequestFlow and Containerlab containers."

remaining_containers="$(
  docker ps -a \
    --format '{{.Names}}' |
    grep -E '^(requestflow-net-|clab-requestflow-app-)' || true
)"

if [[ -n "$remaining_containers" ]]; then
  echo "Warning: these containers remain:"
  echo "$remaining_containers"
else
  echo "No RequestFlow or RequestFlow Containerlab containers remain."
fi

log "Checking PostgreSQL data volume."

if docker volume inspect "$POSTGRES_VOLUME" >/dev/null 2>&1; then
  echo "Preserved PostgreSQL volume: $POSTGRES_VOLUME"
else
  echo "Warning: expected PostgreSQL volume was not found:"
  echo "  $POSTGRES_VOLUME"
fi

printf '\n============================================================\n'
printf ' Phase 2G teardown completed\n'
printf '============================================================\n'
printf 'Application containers: removed\n'
printf 'Containerlab topology:   removed\n'
printf 'PostgreSQL data:         preserved\n'
