#!/usr/bin/env bash
set -euo pipefail

ROUTER_NS="clab-requestflow-app-router"
ROUTER_CONTAINER="clab-requestflow-app-router"
USER_CLIENT="clab-requestflow-app-user-client"

DNS_IP="10.10.40.53"
APP_IP="10.10.30.10"
ADMIN_IP="10.10.20.21"
USER_IP="10.10.10.21"

APP_HOST="requestflow.test"
CAPTURE_SECONDS=5

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVIDENCE_DIR="$SCRIPT_DIR/evidence/phase2e"
PCAP_DIR="$EVIDENCE_DIR/pcap"

DNS_PCAP="$PCAP_DIR/dns-user.pcap"
HTTP_PCAP="$PCAP_DIR/http-user.pcap"
BLOCKED_IN_PCAP="$PCAP_DIR/blocked-user-admin-ingress.pcap"
BLOCKED_OUT_PCAP="$PCAP_DIR/blocked-user-admin-egress.pcap"

mkdir -p "$PCAP_DIR"

packet_count() {
    local capture_output

    capture_output="$(tcpdump -nn -r "$1" 2>/dev/null || true)"

    if [[ -z "$capture_output" ]]; then
        echo 0
    else
        printf '%s\n' "$capture_output" |
            wc -l |
            tr -d ' '
    fi
}

echo "=== RequestFlow Phase 2E Packet Capture ==="
echo

if ! command -v tcpdump >/dev/null 2>&1; then
    echo "ERROR: tcpdump is not installed on the WSL host."
    exit 1
fi

if ! command -v timeout >/dev/null 2>&1; then
    echo "ERROR: timeout is not installed on the WSL host."
    exit 1
fi

echo "Requesting sudo access..."
sudo -v

echo "Checking the router network namespace..."
sudo ip netns exec "$ROUTER_NS" \
    ip link show eth1 >/dev/null

echo "Resetting firewall counters..."
docker exec "$ROUTER_CONTAINER" \
    iptables -Z FORWARD

# ---------------------------------------------------------------------------
# DNS capture
# ---------------------------------------------------------------------------

echo
echo "Capturing DNS traffic on router eth1..."

sudo rm -f "$DNS_PCAP"

sudo timeout --signal=INT "$CAPTURE_SECONDS" \
    ip netns exec "$ROUTER_NS" \
    tcpdump -U -nn -i eth1 -s 0 \
    -w "$DNS_PCAP" \
    "host $DNS_IP and port 53" \
    >/dev/null 2>&1 &

DNS_CAPTURE_PID=$!

sleep 1

DNS_RESULT=$(docker exec "$USER_CLIENT" \
    dig "$APP_HOST" A +short | tail -n 1)

wait "$DNS_CAPTURE_PID" || true

if [[ "$DNS_RESULT" != "$APP_IP" ]]; then
    echo "ERROR: DNS returned '$DNS_RESULT', expected '$APP_IP'."
    exit 1
fi

# ---------------------------------------------------------------------------
# HTTP capture
# ---------------------------------------------------------------------------

echo "Capturing HTTP and TCP traffic on router eth1..."

sudo rm -f "$HTTP_PCAP"

sudo timeout --signal=INT "$CAPTURE_SECONDS" \
    ip netns exec "$ROUTER_NS" \
    tcpdump -U -nn -i eth1 -s 0 \
    -w "$HTTP_PCAP" \
    "host $APP_IP and tcp port 80" \
    >/dev/null 2>&1 &

HTTP_CAPTURE_PID=$!

sleep 1

HTTP_RESULT=$(docker exec "$USER_CLIENT" \
    curl --fail \
    --silent \
    --show-error \
    --http1.1 \
    -H "Connection: close" \
    "http://$APP_HOST/api/ready")

wait "$HTTP_CAPTURE_PID" || true

if [[ "$HTTP_RESULT" != '{"status":"ready"}' ]]; then
    echo "ERROR: Unexpected readiness response: $HTTP_RESULT"
    exit 1
fi

# ---------------------------------------------------------------------------
# Blocked ICMP capture
# ---------------------------------------------------------------------------

echo "Capturing blocked User-to-Admin ICMP traffic..."

sudo rm -f "$BLOCKED_IN_PCAP" "$BLOCKED_OUT_PCAP"

# eth1 is the router's User-facing interface.
sudo timeout --signal=INT "$CAPTURE_SECONDS" \
    ip netns exec "$ROUTER_NS" \
    tcpdump -U -nn -i eth1 -s 0 \
    -w "$BLOCKED_IN_PCAP" \
    "icmp and src host $USER_IP and dst host $ADMIN_IP" \
    >/dev/null 2>&1 &

BLOCKED_IN_PID=$!

# eth3 is the router's Admin-facing interface.
sudo timeout --signal=INT "$CAPTURE_SECONDS" \
    ip netns exec "$ROUTER_NS" \
    tcpdump -U -nn -i eth3 -s 0 \
    -w "$BLOCKED_OUT_PCAP" \
    "icmp and src host $USER_IP and dst host $ADMIN_IP" \
    >/dev/null 2>&1 &

BLOCKED_OUT_PID=$!

sleep 1

if docker exec "$USER_CLIENT" \
    ping -c 2 -W 1 "$ADMIN_IP" >/dev/null 2>&1; then
    echo "ERROR: User client unexpectedly reached Admin client."
    exit 1
fi

wait "$BLOCKED_IN_PID" || true
wait "$BLOCKED_OUT_PID" || true

sudo chown "$(id -u):$(id -g)" "$PCAP_DIR"/*.pcap

# ---------------------------------------------------------------------------
# Validate captures
# ---------------------------------------------------------------------------

DNS_PACKET_COUNT=$(packet_count "$DNS_PCAP")
HTTP_PACKET_COUNT=$(packet_count "$HTTP_PCAP")
BLOCKED_IN_COUNT=$(packet_count "$BLOCKED_IN_PCAP")
BLOCKED_OUT_COUNT=$(packet_count "$BLOCKED_OUT_PCAP")

if (( DNS_PACKET_COUNT < 2 )); then
    echo "ERROR: DNS capture contains too few packets."
    exit 1
fi

if (( HTTP_PACKET_COUNT < 4 )); then
    echo "ERROR: HTTP capture contains too few packets."
    exit 1
fi

if (( BLOCKED_IN_COUNT < 1 )); then
    echo "ERROR: Blocked traffic did not arrive on router eth1."
    exit 1
fi

if (( BLOCKED_OUT_COUNT != 0 )); then
    echo "ERROR: Blocked traffic appeared on router eth3."
    exit 1
fi

# ---------------------------------------------------------------------------
# Save human-readable evidence
# ---------------------------------------------------------------------------

tcpdump -nn -vv -r "$DNS_PCAP" \
    > "$EVIDENCE_DIR/dns-summary.txt" 2>&1

tcpdump -nn -A -r "$HTTP_PCAP" \
    > "$EVIDENCE_DIR/http-summary.txt" 2>&1

tcpdump -nn -r "$BLOCKED_IN_PCAP" \
    > "$EVIDENCE_DIR/blocked-ingress-summary.txt" 2>&1

{
    echo "Expected egress packet count: 0"
    echo "Actual egress packet count:   $BLOCKED_OUT_COUNT"
    echo
    tcpdump -nn -r "$BLOCKED_OUT_PCAP" 2>&1 || true
} > "$EVIDENCE_DIR/blocked-egress-summary.txt"

docker exec "$ROUTER_CONTAINER" \
    iptables -L FORWARD -n -v -x --line-numbers \
    > "$EVIDENCE_DIR/firewall-after-capture.txt"

sha256sum "$PCAP_DIR"/*.pcap \
    > "$EVIDENCE_DIR/pcap-sha256.txt"

{
    echo "DNS result:                     $DNS_RESULT"
    echo "HTTP readiness result:          $HTTP_RESULT"
    echo "DNS packet count:               $DNS_PACKET_COUNT"
    echo "HTTP packet count:              $HTTP_PACKET_COUNT"
    echo "Blocked ingress packet count:   $BLOCKED_IN_COUNT"
    echo "Blocked egress packet count:    $BLOCKED_OUT_COUNT"
} > "$EVIDENCE_DIR/capture-results.txt"

echo
echo "DNS result:                     $DNS_RESULT"
echo "HTTP readiness result:          $HTTP_RESULT"
echo "DNS packet count:               $DNS_PACKET_COUNT"
echo "HTTP packet count:              $HTTP_PACKET_COUNT"
echo "Blocked ingress packet count:   $BLOCKED_IN_COUNT"
echo "Blocked egress packet count:    $BLOCKED_OUT_COUNT"
echo
echo "RequestFlow Phase 2E packet capture passed."
