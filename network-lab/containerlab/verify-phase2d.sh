#!/usr/bin/env bash
set -euo pipefail

ROUTER="clab-requestflow-app-router"
USER_CLIENT="clab-requestflow-app-user-client"
ADMIN_CLIENT="clab-requestflow-app-admin-client"

USER_SUBNET="10.10.10.0/24"
ADMIN_SUBNET="10.10.20.0/24"

USER_IP="10.10.10.21"
ADMIN_IP="10.10.20.21"

APP_HOST="requestflow.test"
APP_ALIAS="www.requestflow.test"
APP_IP="10.10.30.10"

echo "=== RequestFlow Phase 2D Firewall Verification ==="
echo

echo "Checking User-to-Admin route..."
docker exec "$USER_CLIENT" sh -c \
  "ip route show 10.10.20.0/24 | grep -q 'via 10.10.10.1 dev eth1'"

echo "Checking Admin-to-User route..."
docker exec "$ADMIN_CLIENT" sh -c \
  "ip route show 10.10.10.0/24 | grep -q 'via 10.10.20.1 dev eth1'"

echo "Checking IP forwarding..."
FORWARDING=$(docker exec "$ROUTER" \
  sysctl -n net.ipv4.ip_forward)

if [[ "$FORWARDING" != "1" ]]; then
    echo "ERROR: IPv4 forwarding is not enabled."
    exit 1
fi

echo "Checking default-deny FORWARD policy..."
FORWARD_POLICY=$(docker exec "$ROUTER" \
  iptables -S FORWARD | sed -n '1p')

if [[ "$FORWARD_POLICY" != "-P FORWARD DROP" ]]; then
    echo "ERROR: Unexpected FORWARD policy: $FORWARD_POLICY"
    exit 1
fi

echo "Checking User-to-Admin DROP rule..."
docker exec "$ROUTER" iptables -C FORWARD \
  -s "$USER_SUBNET" \
  -d "$ADMIN_SUBNET" \
  -j DROP

echo "Checking Admin-to-User DROP rule..."
docker exec "$ROUTER" iptables -C FORWARD \
  -s "$ADMIN_SUBNET" \
  -d "$USER_SUBNET" \
  -j DROP

echo "Resetting firewall counters..."
docker exec "$ROUTER" iptables -Z FORWARD

echo "Checking DNS from User subnet..."
USER_DNS=$(docker exec "$USER_CLIENT" \
  dig "$APP_HOST" A +short | tail -n 1)

if [[ "$USER_DNS" != "$APP_IP" ]]; then
    echo "ERROR: User DNS returned '$USER_DNS', expected '$APP_IP'."
    exit 1
fi

echo "Checking DNS from Admin subnet..."
ADMIN_DNS=$(docker exec "$ADMIN_CLIENT" \
  dig "$APP_HOST" A +short | tail -n 1)

if [[ "$ADMIN_DNS" != "$APP_IP" ]]; then
    echo "ERROR: Admin DNS returned '$ADMIN_DNS', expected '$APP_IP'."
    exit 1
fi

echo "Checking User application health..."
USER_HEALTH=$(docker exec "$USER_CLIENT" \
  curl --fail --silent --show-error --max-time 5 \
  "http://$APP_HOST/api/health")

echo "Checking User application readiness..."
USER_READY=$(docker exec "$USER_CLIENT" \
  curl --fail --silent --show-error --max-time 5 \
  "http://$APP_HOST/api/ready")

echo "Checking Admin application health..."
ADMIN_HEALTH=$(docker exec "$ADMIN_CLIENT" \
  curl --fail --silent --show-error --max-time 5 \
  "http://$APP_HOST/api/health")

echo "Checking Admin application readiness through DNS alias..."
ADMIN_READY=$(docker exec "$ADMIN_CLIENT" \
  curl --fail --silent --show-error --max-time 5 \
  "http://$APP_ALIAS/api/ready")

echo "Testing blocked User-to-Admin traffic..."
if docker exec "$USER_CLIENT" \
  ping -c 2 -W 1 "$ADMIN_IP" >/dev/null 2>&1; then
    echo "ERROR: User client reached the Admin subnet."
    exit 1
fi

echo "Testing blocked Admin-to-User traffic..."
if docker exec "$ADMIN_CLIENT" \
  ping -c 2 -W 1 "$USER_IP" >/dev/null 2>&1; then
    echo "ERROR: Admin client reached the User subnet."
    exit 1
fi

USER_DROP_PACKETS=$(docker exec "$ROUTER" \
  iptables -L FORWARD -n -v -x --line-numbers |
  awk '$1 == 1 {print $2}')

ADMIN_DROP_PACKETS=$(docker exec "$ROUTER" \
  iptables -L FORWARD -n -v -x --line-numbers |
  awk '$1 == 2 {print $2}')

if [[ ! "$USER_DROP_PACKETS" =~ ^[0-9]+$ ]] ||
   (( USER_DROP_PACKETS < 1 )); then
    echo "ERROR: User-to-Admin DROP counter did not increase."
    exit 1
fi

if [[ ! "$ADMIN_DROP_PACKETS" =~ ^[0-9]+$ ]] ||
   (( ADMIN_DROP_PACKETS < 1 )); then
    echo "ERROR: Admin-to-User DROP counter did not increase."
    exit 1
fi

echo
echo "User DNS result:              $USER_DNS"
echo "Admin DNS result:             $ADMIN_DNS"
echo "User health:                  $USER_HEALTH"
echo "User readiness:               $USER_READY"
echo "Admin health:                 $ADMIN_HEALTH"
echo "Admin readiness:              $ADMIN_READY"
echo "User-to-Admin dropped packets: $USER_DROP_PACKETS"
echo "Admin-to-User dropped packets: $ADMIN_DROP_PACKETS"
echo
echo "RequestFlow Phase 2D firewall verification passed."
