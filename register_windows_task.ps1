# Register Windows Scheduled Task using Base64 EncodedCommand (immune to Korean folder path encoding issues)
# Includes automatic network-wait on wake/boot (up to 3 min), cloud-completion check, 3x retry, and audit log.
$ErrorActionPreference = 'Stop'
$TaskName = "CompetitorCarTrend_DailyCollector"
$WorkDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $WorkDir) { $WorkDir = (Get-Location).Path }

$InnerScript = @"
`$ErrorActionPreference = 'Stop'
Set-ExecutionPolicy Bypass -Scope Process -Force
Set-Location -LiteralPath '$WorkDir'
`$logDir = Join-Path '$WorkDir' 'logs'
if (-not (Test-Path `$logDir)) { New-Item -ItemType Directory -Path `$logDir -Force | Out-Null }
`$logFile = Join-Path `$logDir 'scheduler.log'
function Write-SchedLog([string]`$msg) {
    `$ts = ([DateTimeOffset]::UtcNow.ToOffset([TimeSpan]::FromHours(9))).ToString('yyyy-MM-dd HH:mm:ss')
    Add-Content -LiteralPath `$logFile -Value "[`$ts] `$msg" -Encoding UTF8
}

Write-SchedLog "Scheduled run triggered."

# 1. Wait up to 180s for network/DNS after PC boot or sleep wake-up
`$netReady = `$false
for (`$w = 1; `$w -le 36; `$w++) {
    try {
        `$null = [System.Net.Dns]::GetHostAddresses('api.github.com')
        `$netReady = `$true
        break
    } catch {
        Start-Sleep -Seconds 5
    }
}
if (-not `$netReady) {
    Write-SchedLog "ERROR: Network did not become ready within 180 seconds."
    exit 1
}

# 2. Check if GitHub Cloud already collected complete 4-platform data today
`$today = ([DateTimeOffset]::UtcNow.ToOffset([TimeSpan]::FromHours(9))).ToString('yyyy-MM-dd')
`$alreadyCompleteOnCloud = `$false
try {
    `$raw = Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/JisuKim-pokju82/c2c-car-trend-tracker/main/competitor_trend.json' -TimeoutSec 15
    foreach (`$r in @(`$raw)) {
        if (`$null -ne `$r -and `$r.date -eq `$today -and [int]`$r.daangnCarsCount -gt 0 -and [int]`$r.kcarDirectCount -gt 0 -and [int]`$r.encarPersonalCount -gt 0 -and [int]`$r.kbDirectCount -gt 0) {
            `$alreadyCompleteOnCloud = `$true
        }
    }
} catch {}

if (`$alreadyCompleteOnCloud) {
    Write-SchedLog "Cloud already has complete 4-platform data for `$today. Skipping local run."
    exit 0
}

# 3. Run collection + GitHub upload with up to 3 retries (30s interval)
for (`$attempt = 1; `$attempt -le 3; `$attempt++) {
    try {
        Write-SchedLog "Starting collection & upload (attempt `$attempt/3)..."
        & '$WorkDir\collect_competitor_trend.ps1'
        & '$WorkDir\upload_to_github.ps1'
        Write-SchedLog "SUCCESS: Completed collection & GitHub sync for `$today."
        exit 0
    } catch {
        Write-SchedLog "WARNING (attempt `$attempt/3 failed): `$(`$_.Exception.Message)"
        if (`$attempt -lt 3) { Start-Sleep -Seconds 30 } else { exit 1 }
    }
}
"@

$EncodedCmd  = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($InnerScript))
$CmdArgs     = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand $EncodedCmd"

$Action       = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $CmdArgs
$TriggerDaily = New-ScheduledTaskTrigger -Daily -At 8:00AM
$Settings     = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -WakeToRun -ExecutionTimeLimit (New-TimeSpan -Hours 2)

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $TriggerDaily -Settings $Settings -Description "Daily 08:00 AM 4-Platform C2C Used Car RAW & Trend Collector + GitHub Auto Sync (with wake network-wait & retry)" -Force | Out-Null
Write-Host "Windows Scheduled Task '$TaskName' registered with network-wait, cloud-check, and 3x retry for 08:00 AM daily." -ForegroundColor Green
