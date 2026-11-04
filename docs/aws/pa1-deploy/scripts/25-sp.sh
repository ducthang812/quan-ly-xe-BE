#!/usr/bin/env bash
# Cai stored procedure / trigger / view cua BE (4 file migration trong sql/app/) vao CSDL chi nhanh,
# chay qua listener (vao Primary). 30-repl.sh tu goi script nay dung thu tu:
#   HN      : cai TRUOC khi tao replication (migration cua A tao bang LichLoaiNgay o HN,
#             bang nay can co de day xuong chi nhanh).
#   DN, HCM : cai SAU khi danh muc da duoc replication tao thanh bang that o chi nhanh.
#             Khi do migration se KHONG tao SYNONYM tro ve SERVER_HN ma doc ban sao tai cho.
#   bash scripts/25-sp.sh
source "$(dirname "$0")/lib.sh"

if [[ "$SITE" != "hn" ]]; then
  syn="$(qval "$LSN_IP" "SELECT COUNT(*) FROM [$BRANCH_DB].sys.synonyms WHERE name IN ('ThamSo','TuyenDuong','BangGiaVe','LichLoaiNgay')")"
  if [[ "$syn" != "0" ]]; then
    echo "$BRANCH_DB dang co SYNONYM danh muc (migration da chay truoc khi co replication)." >&2
    echo "Xoa chung roi chay lai 30-repl.sh:  bash scripts/25-sp.sh --drop-synonyms" >&2
    if [[ "${1:-}" == "--drop-synonyms" ]]; then
      q "$LSN_IP" -d "$BRANCH_DB" -Q "DECLARE @s nvarchar(max) = N''; SELECT @s += N'DROP SYNONYM dbo.' + QUOTENAME(name) + N';' FROM sys.synonyms; EXEC (@s);"
      echo "Da xoa synonym. Gio chay: bash scripts/30-repl.sh"
      exit 0
    fi
    exit 1
  fi
  log "Cho danh muc tu Tru so ve $BRANCH_DB (snapshot cua PUB_DANHMUC)"
  ok=""
  for i in $(seq 1 60); do
    n="$(qval "$LSN_IP" "SELECT COUNT(*) FROM [$BRANCH_DB].sys.tables WHERE name IN ('ThamSo','DoPhucTap','LoaiXe','LoaiNgay','LichNgay','LichLoaiNgay','TuyenDuong','BangGiaVe','ChiNhanh')")"
    if [[ "$n" == "9" ]]; then ok=1; echo "  Da co du 9 bang danh muc"; break; fi
    echo "  moi co $n/9 bang, cho them..."; sleep 10
  done
  if [[ -z "$ok" ]]; then
    echo "Sau 10 phut van chua co du danh muc. Kiem tra 30-repl.sh o HN da chay chua, va: bash scripts/status.sh tren may HN" >&2
    exit 1
  fi
fi

log "Cai stored procedure cua BE vao $BRANCH_DB"
for f in sql/app/V*.sql; do
  echo "  $f"
  q "$LSN_IP" -d "$BRANCH_DB" -i "$f"
done
n="$(qval "$LSN_IP" "SELECT COUNT(*) FROM [$BRANCH_DB].sys.procedures")"
echo "  $BRANCH_DB hien co $n stored procedure"
