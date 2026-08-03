#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

PROJECT_NAME="requestflow-net"

BASE_COMPOSE="$REPO_ROOT/docker-compose.prod-local.yml"
LAB_COMPOSE="$SCRIPT_DIR/docker-compose.network-lab.yml"
TOPOLOGY="$SCRIPT_DIR/requestflow.clab.yml"
VERIFY_SCRIPT="$SCRIPT_DIR/verify-network-lab.sh"

FRONTEND_CONTAINER="requestflow-net-frontend"
BACKEND_CONTAINER="requestflow-net-backend"
POSTGRES_CONTAINER="requestflow-net-postgres"

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

show_diagnostics() {
  local exit_code=$?

  set +e

  printf '\n============================================================\n'
  printf ' RequestFlow network lab deployment failed — diagnostics\n'
  printf '============================================================\n'

  "${COMPOSE[@]}" ps -a

  printf '\nBackend logs:\n'
  docker logs --tail 80 "$BACKEND_CONTAINER" 2>&1 || true

  printf '\nPostgreSQL logs:\n'
  docker logs --tail 80 "$POSTGRES_CONTAINER" 2>&1 || true

  printf '\nContainerlab state:\n'
  sudo containerlab inspect -t "$TOPOLOGY" 2>&1 || true

  printf '\nThe failed environment has been left running for debugging.\n'
  printf 'Run %s/destroy-network-lab.sh when finished.\n' "$SCRIPT_DIR"

  exit "$exit_code"
}

trap show_diagnostics ERR

require_command() {
  local command_name="$1"

  command -v "$command_name" >/dev/null 2>&1 ||
    fail "Required command not found: $command_name"
}

wait_for_running() {
  local container="$1"
  local timeout_seconds="${2:-60}"
  local elapsed=0
  local state=""

  while (( elapsed < timeout_seconds )); do
    if docker inspect "$container" >/dev/null 2>&1; then
      state="$(docker inspect --format '{{.State.Status}}' "$container")"

      case "$state" in
        running)
          log "$container is running."
          return 0
          ;;
        exited | dead)
          docker logs --tail 80 "$container" 2>&1 || true
          fail "$container stopped unexpectedly with state: $state"
          ;;
      esac
    fi

    sleep 2
    elapsed=$((elapsed + 2))
  done

  fail "Timed out waiting for $container to start."
}

wait_for_health() {
  local container="$1"
  local timeout_seconds="${2:-120}"
  local elapsed=0
  local container_state=""
  local health_state=""

  while (( elapsed < timeout_seconds )); do
    if docker inspect "$container" >/dev/null 2>&1; then
      container_state="$(
        docker inspect --format '{{.State.Status}}' "$container"
      )"

      if [[ "$container_state" == "exited" ||
            "$container_state" == "dead" ]]; then
        docker logs --tail 80 "$container" 2>&1 || true
        fail "$container stopped before becoming healthy."
      fi

      health_state="$(
        docker inspect \
          --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' \
          "$container"
      )"

      if [[ "$health_state" == "healthy" ]]; then
        log "$container is healthy."
        return 0
      fi
    fi

    sleep 2
    elapsed=$((elapsed + 2))
  done

  docker logs --tail 80 "$container" 2>&1 || true
  fail "Timed out waiting for $container to become healthy."
}

wait_for_migration() {
  local timeout_seconds="${1:-120}"
  local elapsed=0
  local migration_id=""
  local state=""
  local exit_code=""

  while (( elapsed < timeout_seconds )); do
    migration_id="$(
      "${COMPOSE[@]}" ps -a -q migrate 2>/dev/null | head -n 1
    )"

    if [[ -n "$migration_id" ]]; then
      state="$(
        docker inspect --format '{{.State.Status}}' "$migration_id"
      )"

      if [[ "$state" == "exited" ]]; then
        exit_code="$(
          docker inspect --format '{{.State.ExitCode}}' "$migration_id"
        )"

        if [[ "$exit_code" == "0" ]]; then
          log "Alembic migration completed successfully."
          return 0
        fi

        docker logs "$migration_id" 2>&1 || true
        fail "Alembic migration failed with exit code $exit_code."
      fi
    fi

    sleep 2
    elapsed=$((elapsed + 2))
  done

  fail "Timed out waiting for the Alembic migration."
}

log "Checking prerequisites."

for command_name in docker sudo containerlab; do
  require_command "$command_name"
done

docker info >/dev/null 2>&1 ||
  fail "Docker is not running or is not accessible."

sudo -v

[[ -f "$BASE_COMPOSE" ]] ||
  fail "Missing Compose file: $BASE_COMPOSE"

[[ -f "$LAB_COMPOSE" ]] ||
  fail "Missing network-lab Compose file: $LAB_COMPOSE"

[[ -f "$TOPOLOGY" ]] ||
  fail "Missing Containerlab topology: $TOPOLOGY"

[[ -x "$VERIFY_SCRIPT" ]] ||
  fail "Verification script is missing or not executable: $VERIFY_SCRIPT"

log "Validating Docker Compose configuration."

"${COMPOSE[@]}" config -q

log "Validating shell scripts."

bash -n "$VERIFY_SCRIPT"
bash -n "$SCRIPT_DIR/destroy-network-lab.sh"

log "Removing any existing Containerlab deployment."

if ! sudo containerlab destroy \
  -t "$TOPOLOGY" \
  --cleanup >/dev/null 2>&1; then
  echo "No existing Containerlab deployment was removed."
fi

log "Removing existing Compose containers while preserving volumes."

"${COMPOSE[@]}" down --remove-orphans

log "Building and starting the RequestFlow application containers."

"${COMPOSE[@]}" up -d --build

wait_for_health "$POSTGRES_CONTAINER" 120
wait_for_migration 120
wait_for_running "$FRONTEND_CONTAINER" 60
wait_for_running "$BACKEND_CONTAINER" 60

log "Deploying the routed Containerlab topology."

sudo containerlab deploy -t "$TOPOLOGY"

log "Waiting for FastAPI to become healthy after eth1 is attached."

wait_for_health "$BACKEND_CONTAINER" 120

log "Running the complete Network Lab verification."

"$VERIFY_SCRIPT"

log "Final Compose status."

"${COMPOSE[@]}" ps -a

log "Final Containerlab status."

sudo containerlab inspect -t "$TOPOLOGY"

printf '\n============================================================\n'
printf ' RequestFlow network lab deployment completed successfully\n'
printf '============================================================\n'
printf 'Application URL inside the lab: http://requestflow.test\n'
printf 'Verification script: %s\n' "$VERIFY_SCRIPT"
