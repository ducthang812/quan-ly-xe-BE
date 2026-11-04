#!/usr/bin/env bash
# Chuyen Primary cua site sang node <1|2>, roi tro listener sang node do.
#   bash scripts/failover.sh 2            # co ke hoach: 2 node con song, khong mat du lieu
#   bash scripts/failover.sh 2 --force    # Primary cu da chet: ep node 2 len (co the mat giao dich chua dong bo)
source "$(dirname "$0")/lib.sh"

TARGET="${1:-}"; MODE="${2:-planned}"
[[ "$TARGET" =~ ^[12]$ ]] || { echo "Cach dung: bash scripts/failover.sh <1|2> [--force]" >&2; exit 1; }
OLD=$(( 3 - TARGET ))
T_IP="$(node_ip "$TARGET")"; T_NAME="$(node_name "$TARGET")"
O_IP="$(node_ip "$OLD")";    O_NAME="$(node_name "$OLD")"

role_of() { qval "$1" "SELECT ars.role_desc FROM sys.dm_hadr_availability_replica_states ars WHERE ars.is_local = 1" 2>/dev/null || echo "?"; }

if [[ "$(role_of "$T_IP")" == "PRIMARY" ]]; then
  echo "$T_NAME da la Primary. Chi tro lai listener."
  bash scripts/set-listener.sh "$TARGET"; exit 0
fi

if [[ "$MODE" == "--force" ]]; then
  log "Failover CUONG BUC sang $T_NAME"
  q "$T_IP" -Q "ALTER AVAILABILITY GROUP [$AG] FORCE_FAILOVER_ALLOW_DATA_LOSS;"
  q "$T_IP" -Q "ALTER AVAILABILITY GROUP [$AG] SET (REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT = 0);"
  echo "Khi $O_NAME song lai, chay: bash scripts/rejoin.sh $OLD   (de no thanh Secondary, tranh 2 Primary)"
else
  log "Failover CO KE HOACH: $O_NAME -> $T_NAME"
  q "$O_IP" -Q "ALTER AVAILABILITY GROUP [$AG] SET (REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT = 1);"
  echo "  Cho $T_NAME dong bo..."
  ok=""
  for i in $(seq 1 24); do
    n="$(qval "$O_IP" "SELECT COUNT(*) FROM sys.dm_hadr_database_replica_states drs
          JOIN sys.availability_replicas ar ON ar.replica_id = drs.replica_id
          WHERE ar.replica_server_name = '$T_NAME' AND drs.synchronization_state_desc <> 'SYNCHRONIZED'")"
    if [[ "$n" == "0" ]]; then ok=1; break; fi
    sleep 5
  done
  if [[ -z "$ok" ]]; then
    q "$O_IP" -Q "ALTER AVAILABILITY GROUP [$AG] SET (REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT = 0);"
    echo "$T_NAME chua dong bo sau 2 phut, huy failover. Xem: bash scripts/status.sh" >&2; exit 1
  fi
  # Theo trinh tu Microsoft cho AG CLUSTER_TYPE = NONE:
  # OFFLINE tren Primary cu -> FORCE_FAILOVER tren dich -> Primary cu SET ROLE = SECONDARY -> RESUME
  q "$O_IP" -Q "ALTER AVAILABILITY GROUP [$AG] OFFLINE;"
  q "$T_IP" -Q "ALTER AVAILABILITY GROUP [$AG] FORCE_FAILOVER_ALLOW_DATA_LOSS;"
  q "$T_IP" -Q "ALTER AVAILABILITY GROUP [$AG] SET (REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT = 0);"
  q "$O_IP" -Q "ALTER AVAILABILITY GROUP [$AG] SET (ROLE = SECONDARY);"
  sleep 3
  for db in $DBS; do
    q "$T_IP" -Q "ALTER DATABASE [$db] SET HADR RESUME;" 2>/dev/null || true
    q "$O_IP" -Q "ALTER DATABASE [$db] SET HADR RESUME;" 2>/dev/null || true
  done
fi

bash scripts/set-listener.sh "$TARGET"
sleep 3
bash scripts/status.sh
if [[ "$TARGET" == "2" ]]; then
  echo -e "\nLuu y: distributor nam tren $SQL1, nen dong bo LEN Tru so cua site nay tam dung"
  echo "cho den khi failback: bash scripts/failover.sh 1"
fi
