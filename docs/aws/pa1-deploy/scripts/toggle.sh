#!/usr/bin/env bash
# Bat/tat Replication va Linked Server tren CA 3 SITE, chay tu bat ky may nao.
#   bash scripts/toggle.sh repl off|on        # dung/chay lai cac agent replication (khong xoa cau hinh)
#   bash scripts/toggle.sh linked off|on      # tat/bat quyen dung linked server SERVER_* (khong xoa)
#   bash scripts/toggle.sh status             # xem dang bat hay tat
# Tat chi la TAM DUNG: bat lai thi replication tu day bu phan con thieu, linked server dung lai ngay.
source "$(dirname "$0")/lib.sh"

DIST_NODES=(10.10.1.11 10.10.2.11 10.10.3.11)   # node 1 moi site: distributor + noi chay agent
ALL_NODES=(10.10.1.11 10.10.1.12 10.10.2.11 10.10.2.12 10.10.3.11 10.10.3.12)
WHAT="${1:-}"; ACT="${2:-}"

repl() { # <0|1>
  local en="$1" ip
  for ip in "${DIST_NODES[@]}"; do
    echo "  $ip: $([[ $en == 1 ]] && echo 'bat' || echo 'tat') agent LogReader + Distribution"
    q "$ip" -Q "SET NOCOUNT ON;
      DECLARE @j sysname;
      DECLARE c CURSOR LOCAL FAST_FORWARD FOR
        SELECT j.name FROM msdb.dbo.sysjobs j JOIN msdb.dbo.syscategories k ON k.category_id = j.category_id
        WHERE k.name IN ('REPL-LogReader', 'REPL-Distribution');
      OPEN c; FETCH NEXT FROM c INTO @j;
      WHILE @@FETCH_STATUS = 0
      BEGIN
        EXEC msdb.dbo.sp_update_job @job_name = @j, @enabled = $en;
        BEGIN TRY
          IF $en = 1 EXEC msdb.dbo.sp_start_job @job_name = @j;
          ELSE       EXEC msdb.dbo.sp_stop_job  @job_name = @j;
        END TRY BEGIN CATCH END CATCH;   -- job da chay/da dung san thi bo qua
        FETCH NEXT FROM c INTO @j;
      END
      CLOSE c; DEALLOCATE c;" || echo "  (khong ket noi duoc $ip, bo qua)"
  done
}

linked() { # <true|false>
  local v="$1" ip
  for ip in "${ALL_NODES[@]}"; do
    echo "  $ip: linked server SERVER_* data access/rpc out = $v"
    q "$ip" -Q "SET NOCOUNT ON;
      DECLARE @s sysname;
      DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT name FROM sys.servers WHERE is_linked = 1 AND name LIKE 'SERVER[_]%';
      OPEN c; FETCH NEXT FROM c INTO @s;
      WHILE @@FETCH_STATUS = 0
      BEGIN
        EXEC sp_serveroption @server = @s, @optname = 'data access', @optvalue = '$v';
        EXEC sp_serveroption @server = @s, @optname = 'rpc out',     @optvalue = '$v';
        FETCH NEXT FROM c INTO @s;
      END
      CLOSE c; DEALLOCATE c;" || echo "  (khong ket noi duoc $ip, bo qua)"
  done
}

status() {
  echo "=== Replication (agent tren node 1 moi site) ==="
  for ip in "${DIST_NODES[@]}"; do
    q "$ip" -W -h -1 -Q "SET NOCOUNT ON;
      SELECT @@SERVERNAME + ' | ' + k.name + ' | ' + CASE j.enabled WHEN 1 THEN 'BAT' ELSE 'TAT' END
             + ' | ' + CASE WHEN a.start_execution_date IS NOT NULL AND a.stop_execution_date IS NULL THEN 'dang chay' ELSE 'dung' END
             + ' | ' + j.name
      FROM msdb.dbo.sysjobs j JOIN msdb.dbo.syscategories k ON k.category_id = j.category_id
      OUTER APPLY (SELECT TOP 1 start_execution_date, stop_execution_date FROM msdb.dbo.sysjobactivity x
                   WHERE x.job_id = j.job_id ORDER BY x.session_id DESC) a
      WHERE k.name IN ('REPL-LogReader', 'REPL-Distribution') ORDER BY k.name, j.name;" 2>/dev/null || echo "  $ip: khong ket noi duoc"
  done
  echo "=== Linked server (data access, rpc out) ==="
  for ip in "${ALL_NODES[@]}"; do
    q "$ip" -W -h -1 -Q "SET NOCOUNT ON;
      SELECT @@SERVERNAME + ' | ' + name + ' -> ' + data_source + ' | data access=' + CASE is_data_access_enabled WHEN 1 THEN 'BAT' ELSE 'TAT' END
             + ' | rpc out=' + CASE is_rpc_out_enabled WHEN 1 THEN 'BAT' ELSE 'TAT' END
      FROM sys.servers WHERE is_linked = 1 AND name LIKE 'SERVER[_]%';" 2>/dev/null || echo "  $ip: khong ket noi duoc"
  done
}

case "$WHAT $ACT" in
  "repl off")   log "TAT replication tren 3 site"; repl 0 ;;
  "repl on")    log "BAT lai replication tren 3 site (agent se day bu phan con thieu)"; repl 1 ;;
  "linked off") log "TAT linked server tren 6 node"; linked false ;;
  "linked on")  log "BAT lai linked server tren 6 node"; linked true ;;
  "status ")    status; exit 0 ;;
  *) sed -n '2,6p' "$0"; exit 1 ;;
esac
echo; status
