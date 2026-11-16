# Register Windows Scheduled Task with StartWhenAvailable (Runs at 09:00 AM daily, or immediately upon next PC boot/logon if PC was off at 09:00 AM)
$ErrorActionPreference = 'Stop'
$TaskName = "CompetitorCarTrend_DailyCollector"
$ScriptPath = "c:\Users\KCAR24N20051\Desktop\당근\collect_competitor_trend.ps1"

$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`"" -WorkingDirectory "c:\Users\KCAR24N20051\Desktop\당근"
$TriggerDaily = New-ScheduledTaskTrigger -Daily -At 9:00AM
$Settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -WakeToRun

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $TriggerDaily -Settings $Settings -Description "Daily 09:00 AM 4-Platform C2C Used Car RAW & Trend Collector (Runs on boot if PC was off)" -Force | Out-Null
Write-Host "Windows Scheduled Task '$TaskName' registered successfully (StartWhenAvailable + WakeToRun enabled)." -ForegroundColor Green
