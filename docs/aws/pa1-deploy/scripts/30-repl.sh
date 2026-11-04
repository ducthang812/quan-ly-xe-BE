#!/usr/bin/env bash
# Replication cua site. Chi chay SAU KHI ca 3 site da xong 20-ag.sh.
# Thu tu: chay o HN truoc (cai thu tuc BE + day danh muc xuong), roi DN, roi HCM.
# O DN/HCM script cho danh muc ve (1-3 phut), cai thu tuc BE, roi tao dong bo len TruSo.
#   bash scripts/30-repl.sh
source "$(dirname "$0")/lib.sh"

log "Kiem tra listener 3 site deu tra loi"
for l in lsn-hn lsn-dn lsn-hcm; do
  sqlcmd -S "$l" -U sa -P "$SA_PASSWORD" -C -l 5 -h -1 -W -Q "SET NOCOUNT ON; SELECT '$l -> ' + @@SERVERNAME" \
    || { echo "  $l khong ket noi duoc. Kiem tra Security Group va 20-ag.sh o site do." >&2; exit 1; }
done

log "Tao thu muc snapshot trong $SQL1"
docker exec "$SQL1" mkdir -p /var/opt/mssql/data/ReplData

log "Distributor tren $SQL1"
q "$SQL1_IP" -i sql/repl/01-distributor.sql

if [[ "$SITE" == "hn" ]]; then
  # Cai stored procedure cua BE truoc: migration cua A tao bang LichLoaiNgay can day xuong chi nhanh
  bash scripts/25-sp.sh
  log "(2) Nhan ban xuong: PUB_DANHMUC (9 bang danh muc) tu QLXeKhach_HN toi DN, HCM"
  q "$SQL1_IP" -i sql/repl/10-pub-danhmuc.sql
else
  # Cho danh muc ve thanh bang that, roi moi cai stored procedure cua BE (khong tao SYNONYM)
  bash scripts/25-sp.sh
fi

log "(1) Dong bo len: PUB_LEN_$MACN (11 bang) tu $BRANCH_DB toi TruSo, schema ${MACN,,}"
q "$SQL1_IP" -i sql/repl/20-pub-len.sql

sleep 20
bash scripts/status.sh
echo -e "\nXONG replication site $SITE. Khi ca 3 site da chay xong buoc nay, doi 2 phut roi chay"
echo "bash scripts/40-linked.sh tren ca 3 may (o HN, script nay tao luon cac view tong hop trong TruSo)."
