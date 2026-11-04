#!/usr/bin/env bash
# Thu vien dung chung. Cac script khac: source "$(dirname "$0")/lib.sh"
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ ! -f "$ROOT/.env" ]]; then
  echo "Chua co file .env. Chay truoc: sudo bash scripts/00-host-setup.sh <hn|dn|hcm>" >&2
  exit 1
fi
set -a; source "$ROOT/.env"; set +a

SQL1="sql-${SITE}-1"; SQL2="sql-${SITE}-2"; LSN="lsn-${SITE}"
SQL1_IP="${NET}.11";  SQL2_IP="${NET}.12";  LSN_IP="${NET}.20"

node_name() { [[ "$1" == "1" ]] && echo "$SQL1" || echo "$SQL2"; }
node_ip()   { [[ "$1" == "1" ]] && echo "$SQL1_IP" || echo "$SQL2_IP"; }

# Bien sqlcmd dung trong cac file .sql: $(TEN_BIEN)
SQLVARS=(
  -v "SITE=$SITE" -v "MACN=$MACN" -v "AG=$AG" -v "BRANCH_DB=$BRANCH_DB"
  -v "SQL1=$SQL1" -v "SQL2=$SQL2"
  -v "SA_PASSWORD=$SA_PASSWORD" -v "MK_PASSWORD=$MK_PASSWORD"
  -v "CERT_PASSWORD=$CERT_PASSWORD" -v "DBM_PASSWORD=$DBM_PASSWORD"
  -v "LINK_PASSWORD=$LINK_PASSWORD" -v "APP_PASSWORD=$APP_PASSWORD"
)

# q <ip> -Q "T-SQL"        : chay 1 cau lenh
# q <ip> -i file.sql [-v X=Y ...] : chay 1 file
q() {
  local ip="$1"; shift
  sqlcmd -S "$ip" -U sa -P "$SA_PASSWORD" -C -b "${SQLVARS[@]}" "$@"
}

# Tra ve 1 gia tri (khong tieu de)
qval() {
  local ip="$1"; shift
  sqlcmd -S "$ip" -U sa -P "$SA_PASSWORD" -C -b -h -1 -W -Q "SET NOCOUNT ON; $*" | tr -d '[:space:]'
}

wait_sql() {
  local ip="$1" i
  for i in $(seq 1 60); do
    if sqlcmd -S "$ip" -U sa -P "$SA_PASSWORD" -C -l 3 -Q "SELECT 1" >/dev/null 2>&1; then
      echo "  $ip san sang"; return 0
    fi
    sleep 5
  done
  echo "  $ip khong phan hoi sau 5 phut. Xem log: docker logs <ten container>" >&2
  return 1
}

log() { echo -e "\n==> $*"; }
