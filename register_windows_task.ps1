# Register Windows Scheduled Task using wscript.exe + VBScript (100% invisible GUI-subsystem launch)
# Prevents any black terminal/console window from popping up on Windows 11 login (eliminating 0xC000013A console-close kills).
$ErrorActionPreference = 'Stop'
$TaskName = "CompetitorCarTrend_DailyCollector"
$WorkDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $WorkDir) { $WorkDir = (Get-Location).Path }

# Copy VBS launcher to pure-ASCII path under $env:LOCALAPPDATA so wscript.exe never has Korean path encoding issues,
# while pointing cleanly to the workspace's run_scheduled_sync.ps1 via UTF-16LE / Unicode WScript.
$LauncherDir = Join-Path $env:LOCALAPPDATA "CompetitorCarTrend"
if (-not (Test-Path $LauncherDir)) { New-Item -ItemType Directory -Path $LauncherDir -Force | Out-Null }
$LauncherVbs = Join-Path $LauncherDir "launch_car_tracker.vbs"

$SyncPs1 = Join-Path $WorkDir "run_scheduled_sync.ps1"
$EncodedCmd = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes("& '$SyncPs1'"))

$VbsLines = @(
    'Option Explicit',
    'Dim sh, cmd, exitCode',
    'Set sh = CreateObject("WScript.Shell")',
    "cmd = ""powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand $EncodedCmd""",
    'exitCode = sh.Run(cmd, 0, True)',
    'WScript.Quit exitCode'
)
[System.IO.File]::WriteAllLines($LauncherVbs, $VbsLines, [System.Text.Encoding]::ASCII)

$Action       = New-ScheduledTaskAction -Execute "C:\Windows\System32\wscript.exe" -Argument "//B //NoLogo `"$LauncherVbs`""
$TriggerDaily = New-ScheduledTaskTrigger -Daily -At 8:00AM
$TriggerLogon = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$Settings     = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -WakeToRun -ExecutionTimeLimit (New-TimeSpan -Hours 2)

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger @($TriggerDaily, $TriggerLogon) -Settings $Settings -Description "Daily 08:00 AM + AtLogOn Silent Background 4-Platform C2C Used Car Tracker (Zero-Window wscript)" -Force | Out-Null
Write-Host "Windows Scheduled Task '$TaskName' registered (08:00 AM + AtLogOn, 100% zero-window wscript launcher at $LauncherVbs)." -ForegroundColor Green
