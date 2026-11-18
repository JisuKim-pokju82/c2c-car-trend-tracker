$ErrorActionPreference = 'Stop'
Set-ExecutionPolicy Bypass -Scope Process -Force

$WorkDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $WorkDir) { $WorkDir = (Get-Location).Path }
Set-Location -LiteralPath $WorkDir

$logDir = Join-Path $WorkDir 'logs'
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$logFile = Join-Path $logDir 'scheduler.log'

function Write-SchedLog([string]$msg) {
    $ts = ([DateTimeOffset]::UtcNow.ToOffset([TimeSpan]::FromHours(9))).ToString('yyyy-MM-dd HH:mm:ss')
    Add-Content -LiteralPath $logFile -Value "[$ts] $msg" -Encoding UTF8
}

Write-SchedLog "Scheduled background run triggered (zero-window wscript mode)."

# 1. Wait up to 180s for network/DNS after PC boot or sleep wake-up
$netReady = $false
for ($w = 1; $w -le 36; $w++) {
    try {
        $null = [System.Net.Dns]::GetHostAddresses('api.github.com')
        $netReady = $true
        break
    } catch {
        Start-Sleep -Seconds 5
    }
}
if (-not $netReady) {
    Write-SchedLog "ERROR: Network did not become ready within 180 seconds."
    exit 1
}

# 2. Check if GitHub Cloud already collected complete 4-platform data today (excluding geo-blocked fallback)
$today = ([DateTimeOffset]::UtcNow.ToOffset([TimeSpan]::FromHours(9))).ToString('yyyy-MM-dd')
$alreadyCompleteOnCloud = $false
try {
    $raw = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/JisuKim-pokju82/c2c-car-trend-tracker/main/competitor_trend.json?t=$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())" -TimeoutSec 15
    foreach ($r in @($raw)) {
        if ($null -ne $r -and $r.date -eq $today -and $r.source -ne 'cloud_geo_fallback' -and [int]$r.daangnCarsCount -gt 0 -and [int]$r.kcarDirectCount -gt 0 -and [int]$r.encarPersonalCount -gt 0 -and [int]$r.kbDirectCount -gt 0) {
            $alreadyCompleteOnCloud = $true
        }
    }
} catch {}

if ($alreadyCompleteOnCloud) {
    Write-SchedLog "Cloud already has complete verified 4-platform data for $today. Skipping local run."
    exit 0
}

# 3. Run collection + GitHub upload with up to 3 retries (30s interval)
for ($attempt = 1; $attempt -le 3; $attempt++) {
    try {
        Write-SchedLog "Starting collection & upload (attempt $attempt/3)..."
        & (Join-Path $WorkDir 'collect_competitor_trend.ps1')
        & (Join-Path $WorkDir 'upload_to_github.ps1')
        Write-SchedLog "SUCCESS: Completed collection & GitHub sync for $today."
        exit 0
    } catch {
        Write-SchedLog "WARNING (attempt $attempt/3 failed): $($_.Exception.Message)"
        if ($attempt -lt 3) { Start-Sleep -Seconds 30 } else { exit 1 }
    }
}
