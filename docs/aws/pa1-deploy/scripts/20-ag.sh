#!/usr/bin/env bash
# Dung Always On AG cua site + tao CSDL + login. Chay tren may cua site:
#   bash scripts/20-ag.sh
source "$(dirname "$0")/lib.sh"

log "1/6 Chung chi endpoint (node 1 xuat, node 2 nap)"
q "$SQL1_IP" -i sql/ag/01-cert-primary.sql
q "$SQL2_IP" -i sql/ag/02-cert-secondary.sql

log "2/6 Endpoint cong 5022 tren ca 2 node"
q "$SQL1_IP" -i sql/ag/03-endpoint.sql
q "$SQL2_IP" -i sql/ag/03-endpoint.sql

log "3/6 Tao AG $AG tren $SQL1, $SQL2 tham gia"
q "$SQL1_IP" -i sql/ag/04-create-ag.sql
q "$SQL2_IP" -i sql/ag/05-join-ag.sql

log "4/6 Tao CSDL tren node 1 (schema + du lieu mau cua nhom, chi tao neu chua co)"
for db in $DBS; do
  if [[ "$(qval "$SQL1_IP" "SELECT COUNT(*) FROM sys.databases WHERE name = N'$db'")" == "0" ]]; then
    echo "  Tao $db tu sql/schema/$db.sql"
    q "$SQL1_IP" -i "sql/schema/$db.sql"
  else
    echo "  $db da co, bo qua"
  fi
done
echo "  Bo sung default cho module B (sql/schema/compat-B.sql) vao $BRANCH_DB"
q "$SQL1_IP" -i sql/schema/compat-B.sql

log "5/6 Login (ca 2 node) va user trong CSDL (node 1)"
q "$SQL1_IP" -i sql/security/logins.sql
q "$SQL2_IP" -i sql/security/logins.sql
for db in $DBS; do
  q "$SQL1_IP" -i sql/security/db-users.sql -v "DB=$db"
done

log "6/6 Dua CSDL vao AG (tu dong seeding sang node 2)"
for db in $DBS; do
  q "$SQL1_IP" -i sql/ag/06-add-db.sql -v "DB=$db"
done

log "Cho dong bo xong..."
for i in $(seq 1 30); do
  notsync="$(qval "$SQL1_IP" "SELECT COUNT(*) FROM sys.dm_hadr_database_replica_states WHERE synchronization_state_desc <> 'SYNCHRONIZED'")"
  total="$(qval "$SQL1_IP" "SELECT COUNT(*) FROM sys.dm_hadr_database_replica_states")"
  expected=$(( $(wc -w <<< "$DBS") * 2 ))
  if [[ "$notsync" == "0" && "$total" == "$expected" ]]; then echo "  Da dong bo"; break; fi
  sleep 5
done

bash scripts/status.sh
echo -e "\nXONG site $SITE. Lam buoc nay o ca 3 site truoc khi sang buoc 5 (replication)."
