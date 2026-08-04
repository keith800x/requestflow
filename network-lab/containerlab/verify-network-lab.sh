#!/usr/bin/env bash
set -uo pipefail

USER_CLIENT="clab-requestflow-app-user-client"
ADMIN_CLIENT="clab-requestflow-app-admin-client"
DNS_SERVER="clab-requestflow-app-dns-server"
ROUTER="clab-requestflow-app-router"

FRONTEND="requestflow-net-frontend"
BACKEND="requestflow-net-backend"
POSTGRES="requestflow-net-postgres"

FRONTEND_IP="10.10.30.10"
BACKEND_IP="10.10.50.10"
DATABASE_IP="10.10.60.10"
DNS_IP="10.10.40.53"

PASS_COUNT=0
FAIL_COUNT=0
TMP_OUTPUT="$(mktemp)"

cleanup() {
  rm -f "$TMP_OUTPUT"
}

trap cleanup EXIT

required_running_containers=(
  "$FRONTEND"
  "$BACKEND"
  "$POSTGRES"
  "$USER_CLIENT"
  "$ADMIN_CLIENT"
  "$DNS_SERVER"
  "$ROUTER"
)

for container in "${required_running_containers[@]}"; do
  if ! docker inspect "$container" >/dev/null 2>&1; then
    echo "ERROR: Required container does not exist: $container"
    echo "Run ./network-lab/containerlab/deploy-network-lab.sh first."
    exit 1
  fi

  state="$(docker inspect --format '{{.State.Status}}' "$container")"

  if [[ "$state" != "running" ]]; then
    echo "ERROR: Required container is not running: $container"
    echo "Current state: $state"
    echo "Run ./network-lab/containerlab/deploy-network-lab.sh first."
    exit 1
  fi
done

pass() {
  printf 'PASS: %s\n' "$1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  printf 'FAIL: %s\n' "$1"
  sed 's/^/      /' "$TMP_OUTPUT"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

check() {
  local description="$1"
  shift

  if "$@" >"$TMP_OUTPUT" 2>&1; then
    pass "$description"
  else
    fail "$description"
  fi
}

expect_blocked() {
  local description="$1"
  shift

  if "$@" >"$TMP_OUTPUT" 2>&1; then
    printf 'FAIL: %s\n' "$description"
    printf '      The connection unexpectedly succeeded.\n'
    FAIL_COUNT=$((FAIL_COUNT + 1))
  else
    pass "$description"
  fi
}

echo "============================================================"
echo " RequestFlow Network Lab Verification"
echo "============================================================"
echo

check "Backend container is healthy" \
  bash -c \
  "[[ \"\$(docker inspect --format '{{.State.Health.Status}}' '$BACKEND')\" == 'healthy' ]]"

check "PostgreSQL container is healthy" \
  bash -c \
  "[[ \"\$(docker inspect --format '{{.State.Health.Status}}' '$POSTGRES')\" == 'healthy' ]]"

check "Frontend has 10.10.30.10/24 on eth1" \
  docker exec "$FRONTEND" sh -c \
  "ip -4 address show dev eth1 | grep -q '$FRONTEND_IP/24'"

check "Backend has 10.10.50.10/24 on eth1" \
  docker exec "$BACKEND" sh -c \
  "ip -4 address show dev eth1 | grep -q '$BACKEND_IP/24'"

check "PostgreSQL has 10.10.60.10/24 on eth1" \
  docker exec "$POSTGRES" sh -c \
  "ip -4 address show dev eth1 | grep -q '$DATABASE_IP/24'"

check "DNS resolves requestflow.test to the Frontend" \
  bash -c \
  "[[ \"\$(docker exec '$USER_CLIENT' dig +short requestflow.test | tail -n 1)\" == '$FRONTEND_IP' ]]"

check "Frontend can reach Backend health endpoint" \
  docker exec "$FRONTEND" \
  curl -fsS "http://$BACKEND_IP:8000/health"

check "Backend readiness confirms PostgreSQL access" \
  docker exec "$BACKEND" \
  curl -fsS "http://127.0.0.1:8000/ready"

check "User can reach the complete application path" \
  docker exec "$USER_CLIENT" \
  curl -fsS "http://requestflow.test/api/ready"

check "Admin can reach the complete application path" \
  docker exec "$ADMIN_CLIENT" \
  curl -fsS "http://requestflow.test/api/ready"

check "User uses DNS instead of a manual hosts entry" \
  docker exec "$USER_CLIENT" sh -c \
  "! grep -Eqi 'requestflow\.(test|local)' /etc/hosts"

check "Admin uses DNS instead of a manual hosts entry" \
  docker exec "$ADMIN_CLIENT" sh -c \
  "! grep -Eqi 'requestflow\.(test|local)' /etc/hosts"

expect_blocked "User cannot access Admin subnet directly" \
  docker exec "$USER_CLIENT" \
  ping -c 1 -W 1 10.10.20.21

expect_blocked "Admin cannot access User subnet directly" \
  docker exec "$ADMIN_CLIENT" \
  ping -c 1 -W 1 10.10.10.21
expect_blocked "User cannot access Backend directly" \
  docker exec "$USER_CLIENT" \
  curl -fsS --connect-timeout 2 --max-time 2 \
  "http://$BACKEND_IP:8000/health"

expect_blocked "Admin cannot access Backend directly" \
  docker exec "$ADMIN_CLIENT" \
  curl -fsS --connect-timeout 2 --max-time 2 \
  "http://$BACKEND_IP:8000/health"

expect_blocked "User cannot access PostgreSQL directly" \
  docker exec "$USER_CLIENT" \
  nc -z -w 2 "$DATABASE_IP" 5432

expect_blocked "Admin cannot access PostgreSQL directly" \
  docker exec "$ADMIN_CLIENT" \
  nc -z -w 2 "$DATABASE_IP" 5432

expect_blocked "Frontend cannot bypass Backend and access PostgreSQL" \
  docker exec "$FRONTEND" \
  nc -z -w 2 "$DATABASE_IP" 5432

check "Firewall default forwarding policy is DROP" \
  docker exec "$ROUTER" sh -c \
  "iptables -S FORWARD | head -n 1 | grep -q -- '-P FORWARD DROP'"

check "Firewall permits Frontend to Backend on TCP 8000" \
  docker exec "$ROUTER" iptables -C FORWARD \
  -s "$FRONTEND_IP" \
  -d "$BACKEND_IP" \
  -p tcp \
  --dport 8000 \
  -m conntrack \
  --ctstate NEW \
  -j ACCEPT

check "Firewall permits Backend to PostgreSQL on TCP 5432" \
  docker exec "$ROUTER" iptables -C FORWARD \
  -s "$BACKEND_IP" \
  -d "$DATABASE_IP" \
  -p tcp \
  --dport 5432 \
  -m conntrack \
  --ctstate NEW \
  -j ACCEPT

echo
echo "Firewall counters:"
docker exec "$ROUTER" \
  iptables -L FORWARD -n -v -x --line-numbers

echo
echo "============================================================"
printf 'Passed: %d\n' "$PASS_COUNT"
printf 'Failed: %d\n' "$FAIL_COUNT"
echo "============================================================"

if (( FAIL_COUNT > 0 )); then
  exit 1
fi

echo "Network lab verification completed successfully."

