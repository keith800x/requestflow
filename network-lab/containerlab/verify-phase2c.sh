#!/usr/bin/env bash
set -euo pipefail

USER_CLIENT="clab-requestflow-app-user-client"
ADMIN_CLIENT="clab-requestflow-app-admin-client"
DNS_SERVER="clab-requestflow-app-dns-server"

DNS_IP="10.10.40.53"
APP_IP="10.10.30.10"
APP_HOST="requestflow.test"
APP_ALIAS="www.requestflow.test"

echo "=== RequestFlow Phase 2C DNS Verification ==="
echo

echo "Checking User-to-DNS connectivity..."
docker exec "$USER_CLIENT" ping -c 2 "$DNS_IP" >/dev/null

echo "Checking Admin-to-DNS connectivity..."
docker exec "$ADMIN_CLIENT" ping -c 2 "$DNS_IP" >/dev/null

echo "Checking that the User client has no manual RequestFlow hosts entry..."
if docker exec "$USER_CLIENT" \
  grep -Eqi 'requestflow\.(test|local)' /etc/hosts; then
    echo "ERROR: User client still has a RequestFlow /etc/hosts entry."
    exit 1
fi

echo "Checking that the Admin client has no manual RequestFlow hosts entry..."
if docker exec "$ADMIN_CLIENT" \
  grep -Eqi 'requestflow\.(test|local)' /etc/hosts; then
    echo "ERROR: Admin client still has a RequestFlow /etc/hosts entry."
    exit 1
fi

echo "Checking direct CoreDNS resolution..."
DIRECT_RESULT=$(docker exec "$USER_CLIENT" \
  dig @"$DNS_IP" "$APP_HOST" A +short | tail -n 1)

if [[ "$DIRECT_RESULT" != "$APP_IP" ]]; then
    echo "ERROR: Direct DNS result was '$DIRECT_RESULT', expected '$APP_IP'."
    exit 1
fi

echo "Checking normal User client resolution..."
USER_RESULT=$(docker exec "$USER_CLIENT" \
  dig "$APP_HOST" A +short | tail -n 1)

if [[ "$USER_RESULT" != "$APP_IP" ]]; then
    echo "ERROR: User DNS result was '$USER_RESULT', expected '$APP_IP'."
    exit 1
fi

echo "Checking normal Admin client resolution..."
ADMIN_RESULT=$(docker exec "$ADMIN_CLIENT" \
  dig "$APP_HOST" A +short | tail -n 1)

if [[ "$ADMIN_RESULT" != "$APP_IP" ]]; then
    echo "ERROR: Admin DNS result was '$ADMIN_RESULT', expected '$APP_IP'."
    exit 1
fi

echo "Checking CNAME alias resolution..."
ALIAS_RESULT=$(docker exec "$USER_CLIENT" \
  dig "$APP_ALIAS" A +short | tail -n 1)

if [[ "$ALIAS_RESULT" != "$APP_IP" ]]; then
    echo "ERROR: Alias DNS result was '$ALIAS_RESULT', expected '$APP_IP'."
    exit 1
fi

echo "Checking User application health through DNS..."
USER_HEALTH=$(docker exec "$USER_CLIENT" \
  curl --fail --silent --show-error \
  "http://$APP_HOST/api/health")

echo "Checking User application readiness through DNS..."
USER_READY=$(docker exec "$USER_CLIENT" \
  curl --fail --silent --show-error \
  "http://$APP_HOST/api/ready")

echo "Checking Admin application health through DNS..."
ADMIN_HEALTH=$(docker exec "$ADMIN_CLIENT" \
  curl --fail --silent --show-error \
  "http://$APP_HOST/api/health")

echo "Checking Admin application readiness through the DNS alias..."
ADMIN_READY=$(docker exec "$ADMIN_CLIENT" \
  curl --fail --silent --show-error \
  "http://$APP_ALIAS/api/ready")

echo "Checking CoreDNS container..."
docker exec "$DNS_SERVER" \
  /usr/local/bin/coredns -version >/dev/null 2>&1

echo
echo "Direct DNS result:     $DIRECT_RESULT"
echo "User DNS result:       $USER_RESULT"
echo "Admin DNS result:      $ADMIN_RESULT"
echo "Alias DNS result:      $ALIAS_RESULT"
echo "User health:           $USER_HEALTH"
echo "User readiness:        $USER_READY"
echo "Admin health:          $ADMIN_HEALTH"
echo "Admin readiness:       $ADMIN_READY"
echo
echo "RequestFlow Phase 2C DNS verification passed."
