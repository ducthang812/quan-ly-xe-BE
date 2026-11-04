#!/usr/bin/env bash
# Tai image va chay 2 container SQL Server + listener cua site.
#   bash scripts/10-up.sh
source "$(dirname "$0")/lib.sh"

log "Khoi dong container cua site $SITE"
docker compose up -d
docker compose ps

log "Cho SQL Server khoi dong (lan dau co the mat 1-2 phut)"
wait_sql "$SQL1_IP"
wait_sql "$SQL2_IP"

log "Kiem tra ten may chu (phai trung voi ten node)"
q "$SQL1_IP" -Q "SELECT @@SERVERNAME AS node1"
q "$SQL2_IP" -Q "SELECT @@SERVERNAME AS node2"

echo -e "\nXONG. Buoc tiep: bash scripts/20-ag.sh"
