#!/usr/bin/env sh
set -eu

USER_SUBNET="10.10.10.0/24"
ADMIN_SUBNET="10.10.20.0/24"
FRONTEND_IP="10.10.30.10"
DNS_IP="10.10.40.53"

echo "Applying RequestFlow router firewall policy..."

# Start from a predictable FORWARD configuration.
iptables -F FORWARD

# Block direct communication between User and Admin networks.
# These explicit rules also provide useful packet counters.
iptables -A FORWARD \
  -s "$USER_SUBNET" \
  -d "$ADMIN_SUBNET" \
  -j DROP

iptables -A FORWARD \
  -s "$ADMIN_SUBNET" \
  -d "$USER_SUBNET" \
  -j DROP

# Permit reply traffic for previously allowed connections.
iptables -A FORWARD \
  -m conntrack \
  --ctstate ESTABLISHED,RELATED \
  -j ACCEPT

# Permit User and Admin DNS queries over UDP.
iptables -A FORWARD \
  -s "$USER_SUBNET" \
  -d "$DNS_IP" \
  -p udp \
  --dport 53 \
  -m conntrack \
  --ctstate NEW \
  -j ACCEPT

iptables -A FORWARD \
  -s "$ADMIN_SUBNET" \
  -d "$DNS_IP" \
  -p udp \
  --dport 53 \
  -m conntrack \
  --ctstate NEW \
  -j ACCEPT

# Permit DNS over TCP for large responses and fallback.
iptables -A FORWARD \
  -s "$USER_SUBNET" \
  -d "$DNS_IP" \
  -p tcp \
  --dport 53 \
  -m conntrack \
  --ctstate NEW \
  -j ACCEPT

iptables -A FORWARD \
  -s "$ADMIN_SUBNET" \
  -d "$DNS_IP" \
  -p tcp \
  --dport 53 \
  -m conntrack \
  --ctstate NEW \
  -j ACCEPT

# Permit access to the RequestFlow Nginx frontend.
iptables -A FORWARD \
  -s "$USER_SUBNET" \
  -d "$FRONTEND_IP" \
  -p tcp \
  --dport 80 \
  -m conntrack \
  --ctstate NEW \
  -j ACCEPT

iptables -A FORWARD \
  -s "$ADMIN_SUBNET" \
  -d "$FRONTEND_IP" \
  -p tcp \
  --dport 80 \
  -m conntrack \
  --ctstate NEW \
  -j ACCEPT

# Permit diagnostic ICMP only to DNS and the frontend.
iptables -A FORWARD \
  -s "$USER_SUBNET" \
  -d "$DNS_IP" \
  -p icmp \
  --icmp-type echo-request \
  -j ACCEPT

iptables -A FORWARD \
  -s "$ADMIN_SUBNET" \
  -d "$DNS_IP" \
  -p icmp \
  --icmp-type echo-request \
  -j ACCEPT

iptables -A FORWARD \
  -s "$USER_SUBNET" \
  -d "$FRONTEND_IP" \
  -p icmp \
  --icmp-type echo-request \
  -j ACCEPT

iptables -A FORWARD \
  -s "$ADMIN_SUBNET" \
  -d "$FRONTEND_IP" \
  -p icmp \
  --icmp-type echo-request \
  -j ACCEPT

# Deny anything that was not explicitly permitted above.
iptables -P FORWARD DROP

echo "RequestFlow router firewall policy applied."
