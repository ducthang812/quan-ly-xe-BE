#!/usr/bin/env bash
# Xem nhanh trang thai site: vai tro AG, dong bo, listener dang tro dau, replication.
#   bash scripts/status.sh
source "$(dirname "$0")/lib.sh"

AGQ="SET NOCOUNT ON;
SELECT ar.replica_server_name AS node, ars.role_desc AS vai_tro,
       ars.connected_state_desc AS ket_noi, ars.synchronization_health_desc AS suc_khoe
FROM sys.dm_hadr_availability_replica_states ars
JOIN sys.availability_replicas ar ON ar.replica_id = ars.replica_id;
SELECT DB_NAME(database_id) AS csdl, synchronization_state_desc AS dong_bo
FROM sys.dm_hadr_database_replica_states WHERE is_local = 1;"

for n in 1 2; do
  echo "=== $(node_name $n) ($(node_ip $n)) ==="
  q "$(node_ip $n)" -W -Q "$AGQ" 2>/dev/null || echo "  (khong ket noi duoc)"
done

echo "=== Listener $LSN ($LSN_IP) dang tro toi: ==="
grep -E '^\s*server primary' haproxy/haproxy.cfg || true
sqlcmd -S "$LSN_IP" -U sa -P "$SA_PASSWORD" -C -l 3 -h -1 -W -Q "SET NOCOUNT ON; SELECT @@SERVERNAME" 2>/dev/null || echo "  (listener khong tra loi)"

if [[ "$(qval "$SQL1_IP" "SELECT COUNT(*) FROM sys.databases WHERE name='distribution'" 2>/dev/null)" == "1" ]]; then
  echo "=== Replication (distributor tren $SQL1) - lan chay gan nhat cua moi agent ==="
  q "$SQL1_IP" -W -Q "SET NOCOUNT ON;
  SELECT 'LogReader' AS agent, a.publisher_db AS csdl, h.time, LEFT(h.comments, 90) AS ghi_chu
  FROM distribution.dbo.MSlogreader_agents a
  OUTER APPLY (SELECT TOP 1 time, comments FROM distribution.dbo.MSlogreader_history WHERE agent_id = a.id ORDER BY time DESC) h
  UNION ALL
  SELECT 'Distrib', a.publication + ' -> ' + a.subscriber_db, h.time, LEFT(h.comments, 90)
  FROM distribution.dbo.MSdistribution_agents a
  OUTER APPLY (SELECT TOP 1 time, comments FROM distribution.dbo.MSdistribution_history WHERE agent_id = a.id ORDER BY time DESC) h;" 2>/dev/null || true
fi
