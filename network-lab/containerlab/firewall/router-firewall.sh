#!/usr/bin/env sh
set -eu

USER_SUBNET="10.10.10.0/24"
ADMIN_SUBNET="10.10.20.0/24"

FRONTEND_IP="10.10.30.10"
DNS_IP="10.10.40.53"
BACKEND_IP="10.10.50.10"
DATABASE_IP="10.10.60.10"

echo "Applying RequestFlow router firewall policy..."

# Start from a predictable, deny-by-default forwarding policy.
iptables -P FORWARD DROP
iptables -F FORWARD

# ---------------------------------------------------------------------------
# Explicitly blocked network paths
# ---------------------------------------------------------------------------

# Block direct communication between User and Admin networks.
iptables -A FORWARD \
  -s "$USER_SUBNET" \
  -d "$ADMIN_SUBNET" \
  -j DROP

iptables -A FORWARD \
  -s "$ADMIN_SUBNET" \
  -d "$USER_SUBNET" \
  -j DROP

# Users must access the application through the Frontend only.
iptables -A FORWARD \
  -s "$USER_SUBNET" \
  -d "$BACKEND_IP" \
  -j DROP

iptables -A FORWARD \
  -s "$ADMIN_SUBNET" \
  -d "$BACKEND_IP" \
  -j DROP

# Users must never connect directly to PostgreSQL.
iptables -A FORWARD \
  -s "$USER_SUBNET" \
  -d "$DATABASE_IP" \
  -j DROP

iptables -A FORWARD \
  -s "$ADMIN_SUBNET" \
  -d "$DATABASE_IP" \
  -j DROP

# Nginx may communicate with FastAPI, but not directly with PostgreSQL.
iptables -A FORWARD \
  -s "$FRONTEND_IP" \
  -d "$DATABASE_IP" \
  -j DROP

# Permit reply traffic for connections allowed below.
iptables -A FORWARD \
  -m conntrack \
  --ctstate ESTABLISHED,RELATED \
  -j ACCEPT

# ---------------------------------------------------------------------------
# DNS access
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# Application-tier access
# ---------------------------------------------------------------------------

# User and Admin clients may access only the Nginx frontend.
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

# Nginx may proxy API requests to FastAPI.
iptables -A FORWARD \
  -s "$FRONTEND_IP" \
  -d "$BACKEND_IP" \
  -p tcp \
  --dport 8000 \
  -m conntrack \
  --ctstate NEW \
  -j ACCEPT

# FastAPI may connect to PostgreSQL.
iptables -A FORWARD \
  -s "$BACKEND_IP" \
  -d "$DATABASE_IP" \
  -p tcp \
  --dport 5432 \
  -m conntrack \
  --ctstate NEW \
  -j ACCEPT

# ---------------------------------------------------------------------------
# Limited diagnostic ICMP
# ---------------------------------------------------------------------------

# Permit User and Admin ping tests only to DNS and Frontend.
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

echo "RequestFlow router firewall policy applied."
