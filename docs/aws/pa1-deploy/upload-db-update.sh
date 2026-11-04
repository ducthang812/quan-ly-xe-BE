#!/usr/bin/env bash
# Chay tren may Windows (Git Bash): day ban cap nhat CSDL (03/11/2026) len ~/pa1-deploy cua 3 may EC2.
# KHONG chay cap nhat; sau do SSH vao tung may (DN -> HCM -> HN) va chay: bash scripts/60-update.sh
#   bash upload-db-update.sh <IP pa1-dn> <IP pa1-hcm> [IP pa1-hn, mac dinh 52.64.31.95]
# Truoc khi ghi de, sao luu sql/app cu tren may chu thanh sql/app.bak-<thoi diem>.
set -euo pipefail
DN="${1:?Thieu IP pa1-dn}"; HCM="${2:?Thieu IP pa1-hcm}"; HN="${3:-52.64.31.95}"
HERE="$(cd "$(dirname "$0")" && pwd)"
KEY="${KEY:-$HERE/../../../../../BusManagement.pem}"
[[ -f "$KEY" ]] || { echo "Khong thay key: $KEY (dat bien KEY=...)" >&2; exit 1; }
SSH_OPT=(-i "$KEY" -o StrictHostKeyChecking=accept-new -o ConnectTimeout=15 -o BatchMode=yes)

APP_FILES=(sql/app/V202610251000__B_vanhanh_triggers_and_procs.sql
           sql/app/V202611031000__B_fix_varchar_params.sql
           sql/app/V202611031001__B_compat_defaults.sql)
for f in scripts/60-update.sh sql/check/after-update.sql "${APP_FILES[@]}"; do
  [[ -f "$HERE/$f" ]] || { echo "Thieu file $f" >&2; exit 1; }
done

for h in "$DN" "$HCM" "$HN"; do
  echo "===== $h"
  ssh "${SSH_OPT[@]}" "ubuntu@$h" \
    'cd ~/pa1-deploy && TS=$(date +%Y%m%d-%H%M%S) && cp -a sql/app sql/app.bak-$TS && mkdir -p sql/check && echo "  site $(grep ^SITE= .env | cut -d= -f2), sao luu sql/app.bak-$TS"'
  scp "${SSH_OPT[@]}" -q "$HERE/scripts/60-update.sh" "ubuntu@$h:pa1-deploy/scripts/"
  scp "${SSH_OPT[@]}" -q "${APP_FILES[@]/#/$HERE/}" "ubuntu@$h:pa1-deploy/sql/app/"
  scp "${SSH_OPT[@]}" -q "$HERE/sql/check/after-update.sql" "ubuntu@$h:pa1-deploy/sql/check/"
  ssh "${SSH_OPT[@]}" "ubuntu@$h" \
    "cd ~/pa1-deploy && sed -i 's/\r\$//' scripts/60-update.sh && bash -n scripts/60-update.sh && echo \"  sql/app: \$(ls sql/app | wc -l) file, sql/check: \$(ls sql/check), 60-update.sh: OK\""
done
echo
echo "Xong. SSH vao tung may theo thu tu DN ($DN) -> HCM ($HCM) -> HN ($HN), chay:"
echo "  cd ~/pa1-deploy && bash scripts/60-update.sh"
