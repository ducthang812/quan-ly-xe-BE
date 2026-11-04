#!/usr/bin/env bash
# Dua node vua song lai (sau failover --force) ve vai tro Secondary va noi lai dong bo.
#   bash scripts/rejoin.sh 1
source "$(dirname "$0")/lib.sh"

NODE="${1:-}"
[[ "$NODE" =~ ^[12]$ ]] || { echo "Cach dung: bash scripts/rejoin.sh <1|2>" >&2; exit 1; }
IP="$(node_ip "$NODE")"; NAME="$(node_name "$NODE")"
OTHER=$(( 3 - NODE )); O_IP="$(node_ip "$OTHER")"; O_NAME="$(node_name "$OTHER")"

log "Cho $NAME khoi dong"
wait_sql "$IP"

log "Ha $NAME xuong Secondary va noi lai dong bo"
# Node vua song lai van tuong minh la Primary: OFFLINE ngay, roi chuyen ve SECONDARY
q "$IP" -Q "ALTER AVAILABILITY GROUP [$AG] OFFLINE;" 2>/dev/null || true
q "$IP" -Q "ALTER AVAILABILITY GROUP [$AG] SET (ROLE = SECONDARY);" || true
sleep 3
for db in $DBS; do
  q "$IP"   -Q "ALTER DATABASE [$db] SET HADR RESUME;" 2>/dev/null || true
  q "$O_IP" -Q "ALTER DATABASE [$db] SET HADR RESUME;" 2>/dev/null || true
done
sleep 5
bash scripts/status.sh

role="$(qval "$IP" "SELECT role_desc FROM sys.dm_hadr_availability_replica_states WHERE is_local = 1" 2>/dev/null || echo "?")"
if [[ "$role" != "SECONDARY" ]]; then
  echo
  echo "$NAME chua ve duoc SECONDARY (vai tro hien tai: $role). Lam lai node nay theo huong dan cua Microsoft:"
  echo "  1. Tren $O_NAME:  ALTER AVAILABILITY GROUP [$AG] REMOVE REPLICA ON N'$NAME';"
  echo "  2. Tren $NAME:    DROP AVAILABILITY GROUP [$AG];  roi xoa cac CSDL: $DBS"
  echo "  3. Tren $O_NAME:  ALTER AVAILABILITY GROUP [$AG] ADD REPLICA ON N'$NAME' WITH (ENDPOINT_URL = N'tcp://$NAME:5022',"
  echo "                    AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, FAILOVER_MODE = MANUAL, SEEDING_MODE = AUTOMATIC,"
  echo "                    SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL));"
  echo "  4. Tren $NAME:    ALTER AVAILABILITY GROUP [$AG] JOIN WITH (CLUSTER_TYPE = NONE);"
  echo "                    ALTER AVAILABILITY GROUP [$AG] GRANT CREATE ANY DATABASE;"
  exit 1
fi
echo -e "\n$NAME da la Secondary. Muon dua no ve lai Primary: bash scripts/failover.sh $NODE"
