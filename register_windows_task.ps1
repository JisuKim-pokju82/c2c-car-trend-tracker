# Register Windows Scheduled Task with StartWhenAvailable (Runs at 08:00 AM daily, collects & syncs to GitHub)
$ErrorActionPreference = 'Stop'
$TaskName = "CompetitorCarTrend_DailyCollector"
$WorkDir  = "c:\Users\KCAR24N20051\Desktop\당근"
$CmdArgs  = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command `"& '$WorkDir\collect_competitor_trend.ps1'; & '$WorkDir\upload_to_github.ps1'`""

$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $CmdArgs -WorkingDirectory $WorkDir
$TriggerDaily = New-ScheduledTaskTrigger -Daily -At 8:00AM
$Settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -WakeToRun

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $TriggerDaily -Settings $Settings -Description "Daily 08:00 AM 4-Platform C2C Used Car RAW & Trend Collector + GitHub Auto Sync" -Force | Out-Null
Write-Host "Windows Scheduled Task '$TaskName' registered for 08:00 AM daily with GitHub auto-sync." -ForegroundColor Green
