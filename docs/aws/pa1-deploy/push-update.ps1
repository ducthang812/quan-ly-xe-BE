# =============================================================================
# Chay tren may Windows: day ban cap nhat (03/11/2026) len 3 may EC2 roi (tuy chon) chay 60-update.sh.
#
#   # 1) Build BE trong repo (JDK 17):  .\mvnw.cmd clean package -DskipTests
#   # 2) Chi day file:
#   .\push-update.ps1 -DnHost <IP public pa1-dn> -HcmHost <IP public pa1-hcm>
#   # 3) Day file va chay luon theo thu tu DN -> HCM -> HN (HN thay jar):
#   .\push-update.ps1 -DnHost <IP> -HcmHost <IP> -Run
#
# IP cua pa1-dn, pa1-hcm doi moi lan stop/start may: xem tren EC2 Console. pa1-hn dung Elastic IP.
# =============================================================================
param(
    [string]$HnHost = "52.64.31.95",
    [Parameter(Mandatory = $true)][string]$DnHost,
    [Parameter(Mandatory = $true)][string]$HcmHost,
    [string]$Key = (Join-Path $PSScriptRoot "..\..\..\..\..\BusManagement.pem"),
    [string]$Jar = (Join-Path $PSScriptRoot "..\..\..\target\quan-ly-xe-0.0.1-SNAPSHOT.jar"),
    [string]$User = "ubuntu",
    [string]$RemoteDir = "~/pa1-deploy",
    [switch]$Run
)
$ErrorActionPreference = "Stop"
if (-not (Test-Path $Key)) { throw "Khong thay key: $Key (dung -Key <duong dan BusManagement.pem>)" }
if (-not (Test-Path $Jar)) { throw "Khong thay jar: $Jar. Build truoc: .\mvnw.cmd clean package -DskipTests (hoac dung -Jar)" }
$Key = (Resolve-Path $Key).Path
$Jar = (Resolve-Path $Jar).Path

# File thay doi so voi bo pa1-deploy dang co tren may (duong dan tuong doi trong pa1-deploy)
$files = @(
    "scripts/60-update.sh",
    "sql/check/after-update.sql",
    "sql/app/V202610251000__B_vanhanh_triggers_and_procs.sql",
    "sql/app/V202611031000__B_fix_varchar_params.sql",
    "sql/app/V202611031001__B_compat_defaults.sql"
)
foreach ($f in $files) { if (-not (Test-Path (Join-Path $PSScriptRoot $f))) { throw "Thieu file: $f" } }
$sshOpt = @("-i", $Key, "-o", "StrictHostKeyChecking=accept-new", "-o", "ConnectTimeout=15")

function Invoke-Remote([string]$h, [string]$cmd) {
    ssh @sshOpt "$User@$h" $cmd
    if ($LASTEXITCODE -ne 0) { throw "Loi tren ${h}: $cmd" }
}

$sites = [ordered]@{ dn = $DnHost; hcm = $HcmHost; hn = $HnHost }
foreach ($s in $sites.Keys) {
    $h = $sites[$s]
    Write-Host "`n===== Day file len $s ($h) =====" -ForegroundColor Cyan
    Invoke-Remote $h "test -f $RemoteDir/scripts/lib.sh || { echo 'Khong thay $RemoteDir/scripts/lib.sh (dung -RemoteDir)'; exit 1; }; mkdir -p $RemoteDir/sql/check"
    foreach ($f in $files) {
        scp @sshOpt (Join-Path $PSScriptRoot $f) "${User}@${h}:$RemoteDir/$f"
        if ($LASTEXITCODE -ne 0) { throw "scp loi: $f -> $h" }
    }
    # Bo CR neu file bi doi sang CRLF khi checkout tren Windows
    Invoke-Remote $h "sed -i 's/\r$//' $RemoteDir/scripts/60-update.sh"
    if ($s -eq "hn") {
        Write-Host "  jar -> ~/app-new.jar" -ForegroundColor Yellow
        scp @sshOpt $Jar "${User}@${h}:~/app-new.jar"
        if ($LASTEXITCODE -ne 0) { throw "scp jar loi" }
    }
}

if (-not $Run) {
    Write-Host "`nDa day file. Chay lan luot (SSH vao tung may):" -ForegroundColor Green
    Write-Host "  pa1-dn : cd $RemoteDir && bash scripts/60-update.sh"
    Write-Host "  pa1-hcm: cd $RemoteDir && bash scripts/60-update.sh"
    Write-Host "  pa1-hn : cd $RemoteDir && bash scripts/60-update.sh --jar ~/app-new.jar"
    Write-Host "Hoac chay lai script nay kem -Run."
    exit 0
}

foreach ($s in $sites.Keys) {
    $h = $sites[$s]
    $arg = if ($s -eq "hn") { "--jar ~/app-new.jar" } else { "" }
    Write-Host "`n===== 60-update.sh tren $s ($h) =====" -ForegroundColor Cyan
    Invoke-Remote $h "cd $RemoteDir && bash scripts/60-update.sh $arg"
}
Write-Host "`nXONG. Mo http://$HnHost de thu tren giao dien (tao chuyen, ban ve o /dn, /hcm)." -ForegroundColor Green
