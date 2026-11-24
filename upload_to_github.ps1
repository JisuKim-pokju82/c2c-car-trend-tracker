$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$gh = "C:\Program Files\GitHub CLI\gh.exe"
$token = (& $gh auth token).Trim()
$headers = @{
    "Authorization"        = "Bearer $token"
    "Accept"               = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
    "User-Agent"           = "Antigravity-Agent"
}

$Owner = "JisuKim-pokju82"
$Repo  = "c2c-car-trend-tracker"
$WorkDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $WorkDir) { $WorkDir = (Get-Location).Path }
$TodayDate = ([DateTimeOffset]::UtcNow.ToOffset([TimeSpan]::FromHours(9))).ToString("yyyy-MM-dd")

# 1. Sync bulk data, scripts, and dashboard HTML via Git Data API (excluding competitor_trend.json, which is committed via Contents API PUT below to fire a real GitHub push event)
$refInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/git/ref/heads/main" -Headers $headers -Method Get
$baseCommitSha = $refInfo.object.sha
$commitInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/git/commits/$baseCommitSha" -Headers $headers -Method Get
$baseTreeSha = $commitInfo.tree.sha

$remoteBlobShas = @{}
try {
    $remTree = Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/git/trees/$($baseTreeSha)?recursive=1" -Headers $headers -Method Get
    foreach ($t in @($remTree.tree)) {
        if ($t.type -eq "blob" -and $t.path -and $t.sha) {
            $remoteBlobShas[[string]$t.path] = [string]$t.sha
        }
    }
} catch {}

function Get-GitBlobSha([byte[]]$fileBytes) {
    $prefix = [System.Text.Encoding]::ASCII.GetBytes("blob $($fileBytes.Length)`0")
    $combined = New-Object byte[] ($prefix.Length + $fileBytes.Length)
    [System.Buffer]::BlockCopy($prefix, 0, $combined, 0, $prefix.Length)
    [System.Buffer]::BlockCopy($fileBytes, 0, $combined, $prefix.Length, $fileBytes.Length)
    $sha1 = [System.Security.Cryptography.SHA1]::Create()
    $hash = $sha1.ComputeHash($combined)
    $sha1.Dispose()
    return ([System.BitConverter]::ToString($hash) -replace '-', '').ToLowerInvariant()
}

$candidateSet = New-Object 'System.Collections.Generic.HashSet[string]'
$staticFiles = @(
    "README.md",
    "collect_competitor_trend.ps1",
    "cloud_browser_fetch.py",
    "rebuild_bundle_from_raw.ps1",
    "register_windows_task.ps1",
    "run_scheduled_sync.ps1",
    "run_hidden.vbs",
    "upload_to_github.ps1",
    "competitor_trend.html",
    "competitor_trend.csv",
    "competitor_trend_data.js",
    "raw_data/raw_vehicles_latest.csv",
    "database/c2c_daily_summary_db.csv",
    "database/c2c_vehicle_master_db.csv",
    "database/c2c_vehicle_master_db.zip",
    "database/db_manifest.json",
    "snapshots/daangn_latest.json",
    "snapshots/kcar_c2c_latest.json",
    "snapshots/encar_personal_latest.json",
    "snapshots/kb_direct_latest.json"
)
foreach ($sf in $staticFiles) { [void]$candidateSet.Add($sf) }

# Include all dated raw_data and snapshots files so any previously unsynced day (e.g., if offline or retried) is synced automatically
foreach ($rf in @(Get-ChildItem -Path (Join-Path $WorkDir "raw_data") -File -ErrorAction SilentlyContinue)) {
    [void]$candidateSet.Add("raw_data/$($rf.Name)")
}
foreach ($snf in @(Get-ChildItem -Path (Join-Path $WorkDir "snapshots") -Filter "*.json" -File -ErrorAction SilentlyContinue)) {
    [void]$candidateSet.Add("snapshots/$($snf.Name)")
}

$MaxBlobBytes = 36 * 1024 * 1024
$treeItems = New-Object System.Collections.Generic.List[object]
foreach ($relPath in $candidateSet) {
    $fullPath = Join-Path $WorkDir ($relPath -replace '/', '\')
    if (-not (Test-Path $fullPath)) { continue }
    $fi = Get-Item -LiteralPath $fullPath
    if ($fi.Length -gt $MaxBlobBytes) {
        Write-Warning "Skipping $relPath ($([math]::Round($fi.Length / 1MB, 2)) MB > 36 MB GitHub REST API blob limit)."
        continue
    }
    $bytes = [System.IO.File]::ReadAllBytes($fullPath)
    $localSha = Get-GitBlobSha $bytes
    if ($remoteBlobShas.ContainsKey($relPath) -and $remoteBlobShas[$relPath] -eq $localSha) {
        continue
    }
    $b64 = [Convert]::ToBase64String($bytes)
    $blobBody = @{ content = $b64; encoding = "base64" } | ConvertTo-Json -Compress
    $blobRes = Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/git/blobs" -Headers $headers -Method Post -ContentType "application/json" -Body $blobBody
    $treeItems.Add([ordered]@{
        path = $relPath
        mode = "100644"
        type = "blob"
        sha  = $blobRes.sha
    })
}

$didBulkPatch = $false
if ($treeItems.Count -gt 0) {
    # Re-fetch latest HEAD right before committing to avoid non-fast-forward 422 if Cloud Actions pushed concurrently
    $refLatest = Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/git/ref/heads/main" -Headers $headers -Method Get
    $latestCommitSha = $refLatest.object.sha
    $latestCommitInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/git/commits/$latestCommitSha" -Headers $headers -Method Get
    $latestTreeSha = $latestCommitInfo.tree.sha

    $treeBody = @{ base_tree = $latestTreeSha; tree = $treeItems } | ConvertTo-Json -Depth 5 -Compress
    $newTree = Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/git/trees" -Headers $headers -Method Post -ContentType "application/json" -Body $treeBody

    if ($newTree.sha -ne $latestTreeSha) {
        $commitBody = @{
            message = "chore(data): sync daily C2C RAW & bundle ($TodayDate)"
            tree    = $newTree.sha
            parents = @($latestCommitSha)
        } | ConvertTo-Json -Compress
        $newCommit = Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/git/commits" -Headers $headers -Method Post -ContentType "application/json" -Body $commitBody

        $refUpdateBody = @{ sha = $newCommit.sha; force = $false } | ConvertTo-Json -Compress
        Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/git/refs/heads/main" -Headers $headers -Method Patch -ContentType "application/json" -Body $refUpdateBody | Out-Null
        $didBulkPatch = $true
        Write-Host "Synced ($TodayDate) $($treeItems.Count) changed file(s) to GitHub ($($newCommit.sha))!" -ForegroundColor Green
    }
}

# 2. Commit competitor_trend.json via official Contents API PUT so GitHub receives a standard push event
$jsonRel  = "competitor_trend.json"
$jsonFull = Join-Path $WorkDir $jsonRel
if (Test-Path $jsonFull) {
    $jBytes = [System.IO.File]::ReadAllBytes($jsonFull)
    $jB64   = [Convert]::ToBase64String($jBytes)
    $remJ   = $null
    try { $remJ = Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/contents/$jsonRel" -Headers $headers -Method Get } catch {}
    $remJB64 = if ($remJ -and $remJ.content) { ($remJ.content -replace '\s+', '') } else { "" }
    if ($remJB64 -ne $jB64) {
        $putJ = [ordered]@{
            message = "chore(data): update daily C2C summary JSON ($TodayDate)"
            content = $jB64
            branch  = "main"
        }
        if ($remJ -and $remJ.sha) { $putJ["sha"] = $remJ.sha }
        $resJ = Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/contents/$jsonRel" -Headers $headers -Method Put -ContentType "application/json" -Body ($putJ | ConvertTo-Json -Compress)
        Write-Host "Updated competitor_trend.json via Contents API ($($resJ.commit.sha))!" -ForegroundColor Green
    }
}

# 3. Ensure .github/workflows/daily_competitor_tracker.yml is registered via Contents API PUT
#    (Also re-touches workflow schedule registration if a low-level ref patch occurred above)
$wfRel  = ".github/workflows/daily_competitor_tracker.yml"
$wfFull = Join-Path $WorkDir ($wfRel -replace '/', '\')
if (Test-Path $wfFull) {
    $wfBytes = [System.IO.File]::ReadAllBytes($wfFull)
    $wfB64   = [Convert]::ToBase64String($wfBytes)
    $remoteWf = $null
    try { $remoteWf = Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/contents/$wfRel" -Headers $headers -Method Get } catch {}
    $remoteCleanB64 = if ($remoteWf -and $remoteWf.content) { ($remoteWf.content -replace '\s+', '') } else { "" }

    if ($remoteCleanB64 -ne $wfB64) {
        $putBody = [ordered]@{
            message = "ci(schedule): register daily 08:00 KST 4-platform cloud workflow"
            content = $wfB64
            branch  = "main"
        }
        if ($remoteWf -and $remoteWf.sha) { $putBody["sha"] = $remoteWf.sha }
        $putRes = Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/contents/$wfRel" -Headers $headers -Method Put -ContentType "application/json" -Body ($putBody | ConvertTo-Json -Compress)
        Write-Host "Registered workflow schedule via Contents API ($($putRes.commit.sha))!" -ForegroundColor Cyan
    }
}
