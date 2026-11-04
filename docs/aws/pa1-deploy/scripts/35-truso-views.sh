#!/usr/bin/env bash
# (Chi may HN) Tao/cap nhat view tong hop TruSo.dbo.v_<Bang> gop du lieu 3 chi nhanh.
# 40-linked.sh o HN tu goi script nay. Chay lai neu luc do snapshot cua DN/HCM chua ve.
#   bash scripts/35-truso-views.sh
source "$(dirname "$0")/lib.sh"
[[ "$SITE" == "hn" ]] || { echo "Chi chay tren may HN" >&2; exit 1; }

log "Tao view tong hop trong TruSo (qua listener $LSN)"
q "$LSN_IP" -i sql/truso/views.sql
