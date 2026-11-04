#!/usr/bin/env bash
# Linked Server, tao tren ca 2 node cua site. Giu dung ten ma stored procedure cua BE dung
# (SERVER_HN/DN/HCM), tro qua listener, dang nhap bang link_user (doc + goi thu tuc).
# Moi site noi toi 2 site con lai, vi thu tuc cua BE o site nao cung co the goi sang site khac
# (vd sp_LayDanhSachTaiXe @MaCN='CN03' chay o DN se goi SERVER_HCM).
#   bash scripts/40-linked.sh
source "$(dirname "$0")/lib.sh"

add_link() { # <link> <listener> <db>
  for n in 1 2; do
    echo "  $(node_name $n): $1 -> $2 ($3)"
    q "$(node_ip $n)" -i sql/linked/add-link.sql -v "LINK=$1" -v "TARGET=$2" -v "TARGET_DB=$3"
  done
}

log "Tao linked server cho site $SITE"
if [[ "$SITE" != "hn"  ]]; then add_link SERVER_HN  lsn-hn  QLXeKhach_HN;  fi
if [[ "$SITE" != "dn"  ]]; then add_link SERVER_DN  lsn-dn  QLXeKhach_DN;  fi
if [[ "$SITE" != "hcm" ]]; then add_link SERVER_HCM lsn-hcm QLXeKhach_HCM; fi

if [[ "$SITE" == "hn" ]]; then
  bash scripts/35-truso-views.sh
fi

log "Thu doc qua linked server (qua listener cua site nay)"
if [[ "$SITE" == "hn" ]]; then
  q "$LSN_IP" -W -Q "SELECT * FROM OPENQUERY(SERVER_DN, 'SELECT @@SERVERNAME AS may_chu, COUNT(*) AS so_xe FROM QLXeKhach_DN.dbo.Xe')"
else
  q "$LSN_IP" -W -Q "SELECT * FROM OPENQUERY(SERVER_HN, 'SELECT CN_Nguon, COUNT(*) AS so_xe FROM TruSo.dbo.v_Xe GROUP BY CN_Nguon')"
fi
echo -e "\nXONG linked server site $SITE."
