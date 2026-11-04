# =============================================================================
# Cap nhat 3 CSDL local (docker-compose: sql_hn, sql_dn, sql_hcm) cho giong ban AWS.
# Chay trong PowerShell, tai thu muc database/patches, khi 3 container dang chay:
#
#   .\apply-local.ps1 -MigrationDir "D:\duong-dan\repo-be\src\main\resources\db\migration"
#
# Thu tu: (1) gia tri mac dinh cua Ve/PhanCong  (2) thu tuc/trigger module B ban VARCHAR(15)
#         (3) tuy chon Linked Server              (4) kiem tra
# Moi file deu chay lai nhieu lan duoc.
# =============================================================================
param(
    [Parameter(Mandatory = $true)][string]$MigrationDir,
    [string]$SaPassword = "Abc@123456"
)
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

$sites = @(
    @{ Container = "sql_hn";  Db = "QLXeKhach_HN"  },
    @{ Container = "sql_dn";  Db = "QLXeKhach_DN"  },
    @{ Container = "sql_hcm"; Db = "QLXeKhach_HCM" }
)
$steps = @(
    @{ File = (Join-Path $MigrationDir "V202611031001__B_compat_defaults.sql");   Db = "branch" },
    @{ File = (Join-Path $MigrationDir "V202611031000__B_fix_varchar_params.sql"); Db = "branch" },
    @{ File = (Join-Path $here "linked_server_options.sql");                     Db = "master" },
    @{ File = (Join-Path $here "check_local.sql");                               Db = "branch" }
)
foreach ($st in $steps) { if (-not (Test-Path $st.File)) { throw "Khong thay file: $($st.File)" } }

foreach ($s in $sites) {
    $c = $s.Container
    Write-Host "`n===== $c ($($s.Db)) =====" -ForegroundColor Cyan

    # sqlcmd trong image SQL Server 2022: /opt/mssql-tools18 (ban moi) hoac /opt/mssql-tools (ban cu)
    $tool = (docker exec $c sh -c "ls /opt/mssql-tools18/bin/sqlcmd /opt/mssql-tools/bin/sqlcmd 2>/dev/null | head -n 1")
    if (-not $tool) { throw "Khong tim thay sqlcmd trong container $c (container co dang chay khong?)" }
    $tool = $tool.Trim()
    docker exec $c mkdir -p /tmp/pa1 | Out-Null

    foreach ($st in $steps) {
        $name = Split-Path -Leaf $st.File
        $db = if ($st.Db -eq "master") { "master" } else { $s.Db }
        docker cp $st.File "${c}:/tmp/pa1/$name" | Out-Null

        # -I: bat QUOTED_IDENTIFIER. sqlcmd (ODBC) trong container mac dinh TAT; trigger/thu tuc tao
        # khi TAT se loi 1934 luc ghi vao Ve (co filtered index UX_Ve_GheDangBan).
        $cmd = @($c, $tool, "-S", "localhost", "-U", "sa", "-P", $SaPassword, "-d", $db,
                  "-b", "-I", "-f", "65001", "-i", "/tmp/pa1/$name")
        if ($tool -like "*tools18*") { $cmd += "-C" }   # tin chung chi tu ky cua container

        Write-Host "--> $name  (CSDL: $db)" -ForegroundColor Yellow
        docker exec @cmd
        if ($LASTEXITCODE -ne 0) { throw "Loi khi chay $name tren $c" }
    }
}
Write-Host "`nXong. Xem ket qua kiem tra o tren: muc 3 (tham so CHAR) phai rong." -ForegroundColor Green
