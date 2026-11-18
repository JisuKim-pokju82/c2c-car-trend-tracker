Option Explicit
Dim fso, sh, dir, cmd, exitCode
Set fso = CreateObject("Scripting.FileSystemObject")
dir = fso.GetParentFolderName(WScript.ScriptFullName)
Set sh = CreateObject("WScript.Shell")
sh.CurrentDirectory = dir
cmd = "powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File """ & dir & "\run_scheduled_sync.ps1"""
exitCode = sh.Run(cmd, 0, True)
WScript.Quit exitCode
