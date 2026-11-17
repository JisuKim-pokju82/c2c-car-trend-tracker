# Register Windows Scheduled Task using Base64 EncodedCommand (immune to Korean folder path encoding issues)
$ErrorActionPreference = 'Stop'
$TaskName = "CompetitorCarTrend_DailyCollector"
$WorkDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $WorkDir) { $WorkDir = (Get-Location).Path }

$InnerScript = "Set-ExecutionPolicy Bypass -Scope Process -Force; Set-Location -LiteralPath '$WorkDir'; & '$WorkDir\collect_competitor_trend.ps1'; & '$WorkDir\upload_to_github.ps1'"
$EncodedCmd  = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($InnerScript))
$CmdArgs     = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand $EncodedCmd"

$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $CmdArgs
$TriggerDaily = New-ScheduledTaskTrigger -Daily -At 8:00AM
$Settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -WakeToRun

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $TriggerDaily -Settings $Settings -Description "Daily 08:00 AM 4-Platform C2C Used Car RAW & Trend Collector + GitHub Auto Sync" -Force | Out-Null
Write-Host "Windows Scheduled Task '$TaskName' registered with Base64 EncodedCommand for 08:00 AM daily." -ForegroundColor Green
