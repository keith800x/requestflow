#!/usr/bin/env bash

set -euo pipefail

CLIENT="clab-requestflow-app-user-client"

echo "Checking client-to-router connectivity..."
docker exec "$CLIENT" ping -c 2 10.10.10.1 >/dev/null

echo "Checking routed server subnet..."
docker exec "$CLIENT" ping -c 2 10.10.30.1 >/dev/null

echo "Checking RequestFlow frontend..."
docker exec "$CLIENT" ping -c 2 10.10.30.10 >/dev/null

echo "Checking HTTP frontend..."
docker exec "$CLIENT" curl --fail --silent --head \
  http://10.10.30.10 >/dev/null

echo "Checking backend health through Nginx..."
HEALTH=$(docker exec "$CLIENT" \
  curl --fail --silent http://10.10.30.10/api/health)

echo "Checking database readiness through FastAPI..."
READY=$(docker exec "$CLIENT" \
  curl --fail --silent http://10.10.30.10/api/ready)

echo "Health response: $HEALTH"
echo "Readiness response: $READY"
echo
echo "RequestFlow routed network verification passed."
