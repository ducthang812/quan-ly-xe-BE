#!/usr/bin/env bash
# Doi dich cua listener (HAProxy) sang node 1 hoac node 2.
#   bash scripts/set-listener.sh 2
source "$(dirname "$0")/lib.sh"

TARGET="${1:-}"; NO_RESTART="${2:-}"
[[ "$TARGET" =~ ^[12]$ ]] || { echo "Cach dung: bash scripts/set-listener.sh <1|2>" >&2; exit 1; }
TARGET_IP="$(node_ip "$TARGET")"

mkdir -p haproxy
cat > haproxy/haproxy.cfg <<EOF
# Sinh tu dong boi scripts/set-listener.sh, dung sua tay
global
    maxconn 2000

defaults
    mode tcp
    timeout connect 5s
    timeout client  8h
    timeout server  8h

frontend ${LSN}
    bind ${LSN_IP}:1433
    default_backend primary

backend primary
    # Primary hien tai: $(node_name "$TARGET")
    server primary ${TARGET_IP}:1433 check inter 3s
EOF

echo "Listener $LSN ($LSN_IP:1433) -> $(node_name "$TARGET") ($TARGET_IP:1433)"
if [[ "$NO_RESTART" != "--no-restart" ]] && docker ps -a --format '{{.Names}}' | grep -qx "$LSN"; then
  docker restart "$LSN" >/dev/null && echo "Da khoi dong lai $LSN"
fi
