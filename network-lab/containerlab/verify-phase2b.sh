#!/usr/bin/env bash
set -euo pipefail

USER_CLIENT="clab-requestflow-app-user-client"
ADMIN_CLIENT="clab-requestflow-app-admin-client"
FRONTEND_IP="10.10.30.10"

echo "=== RequestFlow Phase 2B Verification ==="
echo

echo "Checking User subnet gateway..."
docker exec "$USER_CLIENT" ping -c 2 10.10.10.1 >/dev/null

echo "Checking Admin subnet gateway..."
docker exec "$ADMIN_CLIENT" ping -c 2 10.10.20.1 >/dev/null

echo "Checking User-to-Server routing..."
docker exec "$USER_CLIENT" ping -c 2 "$FRONTEND_IP" >/dev/null

echo "Checking Admin-to-Server routing..."
docker exec "$ADMIN_CLIENT" ping -c 2 "$FRONTEND_IP" >/dev/null

echo "Checking frontend from User subnet..."
docker exec "$USER_CLIENT" \
  curl --fail --silent --show-error --head \
  "http://$FRONTEND_IP" >/dev/null

echo "Checking frontend from Admin subnet..."
docker exec "$ADMIN_CLIENT" \
  curl --fail --silent --show-error --head \
  "http://$FRONTEND_IP" >/dev/null

echo "Checking backend health from User subnet..."
USER_HEALTH=$(docker exec "$USER_CLIENT" \
  curl --fail --silent --show-error \
  "http://$FRONTEND_IP/api/health")

echo "Checking backend readiness from User subnet..."
USER_READY=$(docker exec "$USER_CLIENT" \
  curl --fail --silent --show-error \
  "http://$FRONTEND_IP/api/ready")

echo "Checking backend health from Admin subnet..."
ADMIN_HEALTH=$(docker exec "$ADMIN_CLIENT" \
  curl --fail --silent --show-error \
  "http://$FRONTEND_IP/api/health")

echo "Checking backend readiness from Admin subnet..."
ADMIN_READY=$(docker exec "$ADMIN_CLIENT" \
  curl --fail --silent --show-error \
  "http://$FRONTEND_IP/api/ready")

echo "Checking temporary hostname resolution..."
HOSTNAME_HEALTH=$(docker exec "$ADMIN_CLIENT" \
  curl --fail --silent --show-error \
  "http://requestflow.local/api/health")

echo
echo "User health:       $USER_HEALTH"
echo "User readiness:    $USER_READY"
echo "Admin health:      $ADMIN_HEALTH"
echo "Admin readiness:   $ADMIN_READY"
echo "Hostname health:   $HOSTNAME_HEALTH"
echo
echo "RequestFlow Phase 2B network verification passed."
