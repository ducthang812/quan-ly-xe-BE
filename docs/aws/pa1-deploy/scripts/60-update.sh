#!/usr/bin/env bash
# Cap nhat he thong DANG CHAY tren AWS cho khop repo BE (03/11/2026). Khong dung lai AG/replication.
#   CSDL chi nhanh : sql/app/V202611031001__B_compat_defaults.sql
#                    sql/app/V202611031000__B_fix_varchar_params.sql
#                    (module B ban moi cua nhom - commit a8512d2 "fix nghiep vu": kiem tra gio/km,
#                     ThuLaoLai/ThuLaoPhu, thu tuc moi sp_LayDanhSachVeTheoChuyen - kem tham so VARCHAR(15))
#   Chi HN (--jar) : thay /opt/pa1-be/app.jar bang ban build moi, khoi dong lai pa1-be, thu goi API.
#
# THU TU: chay o DN, HCM truoc; cuoi cung o HN kem --jar (BE moi goi thu tuc moi o ca 3 site).
#   bash scripts/60-update.sh                       # tren may DN, HCM
#   bash scripts/60-update.sh --jar ~/app-new.jar   # tren may HN
# Tuy chon: --no-backup   bo qua sao luu COPY_ONLY truoc khi cap nhat
#           --force       van chay khi node 1 khong phai Primary (bo qua buoc tam tat replicate_ddl)
# Chay lai nhieu lan van an toan (cac file deu la CREATE OR ALTER / IF NOT EXISTS).
source "$(dirname "$0")/lib.sh"

JAR=""; BACKUP=1; FORCE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --jar)       JAR="${2:?Thieu duong dan file jar sau --jar}"; shift 2 ;;
    --no-backup) BACKUP=0; shift ;;
    --force)     FORCE=1; shift ;;
    *) echo "Tham so khong hop le: $1" >&2; exit 1 ;;
  esac
done
if [[ -n "$JAR" && "$SITE" != "hn" ]]; then echo "--jar chi dung tren may HN (BE chay o pa1-hn)" >&2; exit 1; fi
if [[ -n "$JAR" && ! -f "$JAR" ]]; then echo "Khong thay file jar: $JAR" >&2; exit 1; fi

FILES=(sql/app/V202611031001__B_compat_defaults.sql sql/app/V202611031000__B_fix_varchar_params.sql)
for f in "${FILES[@]}" sql/check/after-update.sql; do
  [[ -f "$f" ]] || { echo "Thieu $f - chep bo pa1-deploy moi len may chua?" >&2; exit 1; }
done
TS="$(date +%Y%m%d-%H%M%S)"
PUB="PUB_LEN_$MACN"

log "1/5 Kiem tra vai tro AG va listener $LSN"
ROLE1="$(qval "$SQL1_IP" "SELECT role_desc FROM sys.dm_hadr_availability_replica_states WHERE is_local = 1" || true)"
echo "  $SQL1: ${ROLE1:-khong ket noi duoc}"
qval "$LSN_IP" "SELECT @@SERVERNAME" >/dev/null || { echo "  Listener $LSN khong tra loi. Xem: bash scripts/status.sh" >&2; exit 1; }
if [[ "$ROLE1" != "PRIMARY" ]]; then
  if (( ! FORCE )); then
    echo "  Node 1 khong phai Primary (site dang chay tren node 2, replication tam dung)." >&2
    echo "  Nen chuyen ve node 1 truoc: bash scripts/failover.sh 1 ; hoac chay lai voi --force." >&2
    exit 1
  fi
  echo "  --force: cap nhat qua listener, bo qua buoc tam tat replicate_ddl."
fi

# Tam tat replicate_ddl cua PUB_LEN_xx: CREATE OR ALTER TRIGGER tren Ve/PhanCong/ChuyenXe (bang da publish)
# khong duoc chep sang TruSo (o do khong co cac trigger nay). Thu tuc/ham khong phai article nen khong anh huong.
DDL_OFF=0
restore_ddl() {
  if (( DDL_OFF )); then
    echo "  Bat lai replicate_ddl cho $PUB"
    q "$SQL1_IP" -d "$BRANCH_DB" -Q "EXEC sp_changepublication @publication = N'$PUB', @property = N'replicate_ddl', @value = N'1'" \
      || echo "!! Khong bat lai duoc. Chay tay tren $SQL1: EXEC [$BRANCH_DB].dbo.sp_changepublication N'$PUB', N'replicate_ddl', N'1'" >&2
    DDL_OFF=0
  fi
}
trap restore_ddl EXIT

if (( BACKUP )); then
  log "2/5 Sao luu COPY_ONLY $BRANCH_DB (vao thu muc shared/ cua bo pa1-deploy tren may nay)"
  q "$LSN_IP" -Q "BACKUP DATABASE [$BRANCH_DB] TO DISK = N'/var/opt/mssql/shared/$BRANCH_DB-before-update-$TS.bak' WITH COPY_ONLY, INIT, COMPRESSION, STATS = 50"
  echo "  -> $ROOT/shared/$BRANCH_DB-before-update-$TS.bak"
else
  log "2/5 Bo qua sao luu (--no-backup)"
fi

log "3/5 Cap nhat ham/thu tuc/trigger module B trong $BRANCH_DB"
if [[ "$ROLE1" == "PRIMARY" ]]; then
  HAS_PUB="$(qval "$SQL1_IP" "SELECT COUNT(*) FROM sys.databases d WHERE d.name = N'$BRANCH_DB' AND d.is_published = 1" || echo 0)"
  if [[ "$HAS_PUB" == "1" ]] && [[ "$(qval "$SQL1_IP" "SELECT COUNT(*) FROM [$BRANCH_DB].dbo.syspublications WHERE name = N'$PUB'" || echo 0)" == "1" ]]; then
    echo "  Tam tat replicate_ddl cho $PUB"
    q "$SQL1_IP" -d "$BRANCH_DB" -Q "EXEC sp_changepublication @publication = N'$PUB', @property = N'replicate_ddl', @value = N'0'"
    DDL_OFF=1
  fi
fi
for f in "${FILES[@]}"; do
  echo "  $f"
  q "$LSN_IP" -d "$BRANCH_DB" -i "$f"
done
restore_ddl

log "4/5 Kiem tra $BRANCH_DB"
q "$LSN_IP" -d "$BRANCH_DB" -W -i sql/check/after-update.sql
B_IN="'fn_LoaiNgay','sp_TaoChuyenVaPhanCong','sp_XemTruocChuyen','sp_LayDanhSachChuyen','sp_LayChiTietChuyen','sp_LaySoDoGhe','sp_KetThucChuyen','sp_HuyChuyen','sp_BanVe','sp_HuyVe','sp_TraCuuVeTheoSDT','sp_LayDanhSachVeTheoChuyen'"
n_obj="$(qval "$LSN_IP" "SELECT COUNT(*) FROM [$BRANCH_DB].sys.objects WHERE name IN ($B_IN,'sp_KiemTraXeDuDieuKien') OR name LIKE 'trg[_]Ve[_]%' OR name LIKE 'trg[_]PhanCong[_]%' OR name LIKE 'trg[_]ChuyenXe[_]%'")"
n_char="$(qval "$LSN_IP" "SELECT COUNT(*) FROM [$BRANCH_DB].sys.parameters p JOIN [$BRANCH_DB].sys.types t ON t.user_type_id = p.user_type_id JOIN [$BRANCH_DB].sys.objects o ON o.object_id = p.object_id WHERE p.name LIKE '@Ma%' AND t.name IN ('char','nchar') AND o.name IN ($B_IN)")"
n_qi="$(qval "$LSN_IP" "SELECT COUNT(*) FROM [$BRANCH_DB].sys.sql_modules m JOIN [$BRANCH_DB].sys.objects o ON o.object_id = m.object_id WHERE (o.name IN ($B_IN) OR o.name LIKE 'trg[_]%') AND m.uses_quoted_identifier = 0")"
n_def="$(qval "$LSN_IP" "SELECT COUNT(*) FROM [$BRANCH_DB].sys.default_constraints WHERE name IN ('DF_Ve_MaVe','DF_Ve_LanBan','DF_PhanCong_ThuLao')")"
n_syn="$(qval "$LSN_IP" "SELECT COUNT(*) FROM [$BRANCH_DB].sys.synonyms")"
echo "  Doi tuong module B: $n_obj/19 | tham so @Ma CHAR: $n_char (phai 0) | module QUOTED_IDENTIFIER OFF: $n_qi (phai 0)"
echo "  Default Ve/PhanCong: $n_def/3 | SYNONYM: $n_syn (phai 0 tren AWS)"
if [[ "$n_obj" != "19" || "$n_char" != "0" || "$n_qi" != "0" || "$n_def" != "3" ]]; then
  echo "!! Kiem tra KHONG dat. Dung lai, chua thay BE." >&2; exit 1
fi
echo "  Dat."

if [[ -n "$JAR" ]]; then
  log "5/5 Thay BE: $JAR -> /opt/pa1-be/app.jar"
  if [[ -f /opt/pa1-be/app.jar ]]; then
    cp /opt/pa1-be/app.jar "/opt/pa1-be/app.jar.bak-$TS"
    echo "  Ban cu: /opt/pa1-be/app.jar.bak-$TS"
  fi
  cp "$JAR" /opt/pa1-be/app.jar
  sudo systemctl restart pa1-be
  ok=""
  for i in $(seq 1 40); do
    if curl -fsS -m 3 http://127.0.0.1:8080/health >/dev/null 2>&1; then ok=1; break; fi
    sleep 3
  done
  if [[ -z "$ok" ]]; then
    echo "!! BE khong len sau 2 phut. Xem: journalctl -u pa1-be -n 100" >&2
    echo "   Quay lai ban cu: cp /opt/pa1-be/app.jar.bak-$TS /opt/pa1-be/app.jar && sudo systemctl restart pa1-be" >&2
    exit 1
  fi
  echo "  BE da chay. Thu API xem truoc chuyen o 3 site:"
  for s in hn dn hcm; do
    r="$(curl -sS -m 20 "http://127.0.0.1:8080/$s/api/v1/vanhanh/chuyen-xe/xem-truoc?maTuyen=T01&gioKhoiHanh=2025-06-03T08:00:00" || true)"
    if [[ "$r" == *'"success":true'* ]]; then echo "    /$s: OK"; else echo "    /$s: LOI -> ${r:0:200}"; fi
  done
else
  log "5/5 Khong thay BE (khong co --jar)"
fi

echo
bash scripts/status.sh || true
echo -e "\nXONG cap nhat site $SITE."
