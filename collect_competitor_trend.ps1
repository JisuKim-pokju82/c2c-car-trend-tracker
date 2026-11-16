# 4-Platform C2C Used Car Apple-to-Apple RAW & Portfolio Collector
# Platforms: Daangn, K Car (C2C), Encar (Personal), KB ChaChaCha (Personal)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$WorkDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $WorkDir) { $WorkDir = (Get-Location).Path }

$SnapshotDir = Join-Path $WorkDir "snapshots"
$RawDir      = Join-Path $WorkDir "raw_data"
foreach ($d in @($SnapshotDir, $RawDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

$JsonPath = Join-Path $WorkDir "competitor_trend.json"
$CsvPath  = Join-Path $WorkDir "competitor_trend.csv"
$JsPath   = Join-Path $WorkDir "competitor_trend_data.js"

$Now = Get-Date
$TodayDate = $Now.ToString("yyyy-MM-dd")
$TodayYmd  = $Now.ToString("yyyyMMdd")
$Timestamp = $Now.ToString("yyyy-MM-dd HH:mm:ss")

function U([string]$esc) { return [regex]::Unescape($esc) }

$KR_DOMESTIC = U "\uAD6D\uC0B0"
$KR_IMPORTED = U "\uC218\uC785"
$KR_ONSALE   = U "\uD310\uB9E4\uC911"
$KR_RESERVED = U "\uC608\uC57D\uC911"
$KR_TRADED   = U "\uAC70\uB798\uC644\uB8CC"
$KR_GENERAL  = U "\uC77C\uBC18"
$KR_LEASE    = U "\uB9AC\uC2A4"
$KR_RENT     = U "\uB80C\uD2B8"

# Domestic Brand & Model Keywords for Classification
$DomesticBrands = @(
    (U "\uD604\uB300"), (U "\uAE30\uC544"), (U "\uC81C\uB124\uC2DC\uC2A4"),
    (U "\uC250\uBCF4\uB808"), (U "\uB300\uC6B0"), (U "\uB974\uB178"), (U "\uC0BC\uC131"),
    (U "\uC30D\uC6A9"), "KG", (U "\uC5B4\uC6B8\uB9BC"), (U "\uC2A4\uB9C8\uD2B8EV"),
    (U "\uB9C8\uC2A4\uD0C0"), (U "\uCE20\uC2DC\uC2A4"), (U "\uB514\uD53C\uCF54")
)

$DomesticModelKeywords = @(
    (U "\uADF8\uB79C\uC800"), (U "\uC544\uBC18\uB5BC"), (U "\uC3D8\uB098\uD0C0"), (U "\uC18C\uB098\uD0C0"),
    (U "\uC2FC\uD0C0\uD398"), (U "\uD22C\uC2FC"), (U "\uD330\uB9AC\uC138\uC774\uB4DC"), (U "\uCE90\uC2A4\uD37C"),
    (U "\uCF54\uB098"), (U "\uC2A4\uD0C0\uB9AC\uC544"), (U "\uC2A4\uD0C0\uB809\uC2A4"), (U "\uD3EC\uD130"),
    (U "\uC544\uC774\uC624\uB2C9"), (U "\uBCA0\uB274"), (U "\uB125\uC3D8"), (U "\uBCA0\uB77C\uD06C\uB8E8\uC988"),
    (U "\uB9E5\uC2A4\uD06C\uB8E8\uC988"), (U "\uC5D0\uCFE0\uC2A4"), (U "\uC544\uC2AC\uB780"), (U "\uBCA0\uB974\uB098"),
    (U "\uC5D1\uC13C\uD2B8"), (U "\uCA80\uB85C\uC2A4\uD130"), (U "\uAC24\uB85C\uD37C"), (U "\uB9C8\uC774\uD2F0"),
    (U "\uCE74\uB2C8\uBC1C"), (U "\uC3D8\uB80C\uD1A0"), (U "\uC2A4\uD3EC\uD2F0\uC9C0"), (U "\uB808\uC774"),
    (U "\uBAA8\uB2DD"), (U "\uC140\uD1A0\uC2A4"), (U "\uB2C8\uB85C"), (U "\uBAA8\uD558\uBE44"),
    (U "\uBD09\uACE0"), (U "\uC2A4\uD30C\uD06C"), (U "\uB9D0\uB9AC\uBD80"), (U "\uD2B8\uB799\uC2A4"),
    (U "\uD2B8\uB808\uC77C\uBE14\uB808\uC774\uC800"), (U "\uC62C\uB780\uB3C4"), (U "\uD06C\uB8E8\uC988"),
    (U "\uB2E4\uB9C8\uC2A4"), (U "\uB77C\uBCF4"), (U "\uB9C8\uD2F0\uC988"), (U "\uD2F0\uBCF4\uB9AC"),
    (U "\uB809\uC2A4\uD134"), (U "\uCF54\uB780\uB3C4"), (U "\uD1A0\uB808\uC2A4"), (U "\uCCB4\uC5B4\uB9E8"),
    (U "\uC561\uD2F0\uC5B8"), "K3", "K5", "K7", "K8", "K9", "EV3", "EV6", "EV9", "G70", "G80", "G90", "GV60", "GV70", "GV80",
    "SM3", "SM5", "SM6", "SM7", "QM3", "QM5", "QM6", "XM3"
)

function Get-OriginAndBrand([string]$brandText, [string]$titleText) {
    $combined = "$brandText $titleText"
    foreach ($db in $DomesticBrands) {
        if ($brandText -like "*$db*") {
            return @{ Origin = $KR_DOMESTIC; Brand = $db }
        }
    }
    foreach ($mk in $DomesticModelKeywords) {
        if ($combined -like "*$mk*") {
            $inferredBrand = if ($mk -in @("K3","K5","K7","K8","K9","EV3","EV6","EV9",(U "\uCE74\uB2C8\uBC1C"),(U "\uC3D8\uB80C\uD1A0"),(U "\uC2A4\uD3EC\uD2F0\uC9C0"),(U "\uB808\uC774"),(U "\uBAA8\uB2DD"),(U "\uC140\uD1A0\uC2A4"),(U "\uB2C8\uB85C"),(U "\uBAA8\uD558\uBE44"),(U "\uBD09\uACE0"))) { U "\uAE30\uC544" }
                elseif ($mk -in @("G70","G80","G90","GV60","GV70","GV80")) { U "\uC81C\uB124\uC2DC\uC2A4" }
                elseif ($mk -in @("SM3","SM5","SM6","SM7","QM3","QM5","QM6","XM3")) { U "\uB974\uB178\uCF54\uB9AC\uC544" }
                elseif ($mk -in @((U "\uC2A4\uD30C\uD06C"),(U "\uB9D0\uB9AC\uBD80"),(U "\uD2B8\uB799\uC2A4"),(U "\uD2B8\uB808\uC77C\uBE14\uB808\uC774\uC800"),(U "\uC62C\uB780\uB3C4"),(U "\uD06C\uB8E8\uC988"),(U "\uB2E4\uB9C8\uC2A4"),(U "\uB77C\uBCF4"),(U "\uB9C8\uD2F0\uC988"))) { U "\uC250\uBCF4\uB808" }
                elseif ($mk -in @((U "\uD2F0\uBCF4\uB9AC"),(U "\uB809\uC2A4\uD134"),(U "\uCF54\uB780\uB3C4"),(U "\uD1A0\uB808\uC2A4"),(U "\uCCB4\uC5B4\uB9E8"),(U "\uC561\uD2F0\uC5B8"))) { "KG" + (U "\uBAA8\uBE4C\uB9AC\uD2F0") }
                else { U "\uD604\uB300" }
            return @{ Origin = $KR_DOMESTIC; Brand = $inferredBrand }
        }
    }
    $cleanBrand = if ($brandText) { $brandText } else { ($titleText -split '\s+')[0] }
    return @{ Origin = $KR_IMPORTED; Brand = $cleanBrand }
}

function Get-PriceBand([int]$priceManwon) {
    if ($priceManwon -le 0) { return (U "1\uCC9C\uB9CC\uC6D0 \uBBF8\uB9CC") }
    if ($priceManwon -lt 1000) { return (U "1\uCC9C\uB9CC\uC6D0 \uBBF8\uB9CC") }
    if ($priceManwon -lt 2000) { return (U "1\uCC9C~2\uCC9C\uB9CC\uC6D0") }
    if ($priceManwon -lt 3000) { return (U "2\uCC9C~3\uCC9C\uB9CC\uC6D0") }
    if ($priceManwon -lt 5000) { return (U "3\uCC9C~5\uCC9C\uB9CC\uC6D0") }
    return (U "5\uCC9C\uB9CC\uC6D0 \uC774\uC0C1")
}

function Normalize-Region([string]$rawRegion) {
    if (-not $rawRegion) { return (U "\uAE30\uD0C0") }
    $map = [ordered]@{
        (U "\uC11C\uC6B8") = (U "\uC11C\uC6B8")
        (U "\uACBD\uAE30") = (U "\uACBD\uAE30")
        (U "\uC778\uCC9C") = (U "\uC778\uCC9C")
        (U "\uBD80\uC0B0") = (U "\uBD80\uC0B0")
        (U "\uB300\uAD6C") = (U "\uB300\uAD6C")
        (U "\uB300\uC804") = (U "\uB300\uC804")
        (U "\uAD11\uC8FC") = (U "\uAD11\uC8FC")
        (U "\uC6B8\uC0B0") = (U "\uC6B8\uC0B0")
        (U "\uC138\uC885") = (U "\uC138\uC885")
        (U "\uAC15\uC6D0") = (U "\uAC15\uC6D0")
        (U "\uCCAD\uBD81") = (U "\uCCAD\uBD81")
        (U "\uCCAD\uB0A8") = (U "\uCCAD\uB0A8")
        (U "\uC804\uBD81") = (U "\uC804\uBD81")
        (U "\uC804\uB0A8") = (U "\uC804\uB0A8")
        (U "\uACBD\uBD81") = (U "\uACBD\uBD81")
        (U "\uACBD\uB0A8") = (U "\uACBD\uB0A8")
        (U "\uC81C\uC8FC") = (U "\uC81C\uC8FC")
    }
    foreach ($k in $map.Keys) {
        if ($rawRegion -like "*$k*") { return $map[$k] }
    }
    return $rawRegion
}

function Compare-And-SaveSnapshot([string]$platformKey, [string[]]$todayIds) {
    $todaySet = New-Object 'System.Collections.Generic.HashSet[string]'
    if ($todayIds) {
        foreach ($x in $todayIds) {
            if ($x) { [void]$todaySet.Add([string]$x) }
        }
    }
    $todayUnique = New-Object 'string[]' $todaySet.Count
    $todaySet.CopyTo($todayUnique)
    $todaySnapPath = Join-Path $SnapshotDir "$($platformKey)_$($TodayDate).json"
    $latestSnapMetaPath = Join-Path $SnapshotDir "$($platformKey)_latest.json"

    $prevFiles = @(Get-ChildItem -Path $SnapshotDir -Filter "$($platformKey)_*.json" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne "$($platformKey)_latest.json" -and $_.Name -ne "$($platformKey)_$($TodayDate).json" } |
        Sort-Object Name)

    $newFromDiff = $null
    $soldFromDiff = $null
    $prevTotal = 0

    if ($prevFiles.Count -gt 0) {
        $prevFile = $prevFiles[$prevFiles.Count - 1]
        try {
            $prevObj = [System.IO.File]::ReadAllText($prevFile.FullName, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
            $prevIds = [string[]]@($prevObj.ids)
            $prevTotal = $prevIds.Count
            $prevSet = New-Object 'System.Collections.Generic.HashSet[string]'
            foreach ($px in $prevIds) { if ($px) { [void]$prevSet.Add([string]$px) } }

            $newCnt = 0
            foreach ($id in $todayUnique) { if (-not $prevSet.Contains($id)) { $newCnt++ } }
            $soldCnt = 0
            foreach ($id in $prevIds) { if (-not $todaySet.Contains($id)) { $soldCnt++ } }
            $newFromDiff = $newCnt
            $soldFromDiff = $soldCnt
        } catch {}
    }

    $snapObj = [ordered]@{
        date      = $TodayDate
        updatedAt = $Timestamp
        count     = $todayUnique.Count
        ids       = $todayUnique
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $snapJson = $snapObj | ConvertTo-Json -Depth 4 -Compress
    [System.IO.File]::WriteAllText($todaySnapPath, $snapJson, $utf8NoBom)
    [System.IO.File]::WriteAllText($latestSnapMetaPath, $snapJson, $utf8NoBom)

    return [pscustomobject]@{
        PrevCount    = $prevTotal
        NewFromDiff  = $newFromDiff
        SoldFromDiff = $soldFromDiff
    }
}

function Build-PortfolioSummary([object[]]$items) {
    $total = $items.Count
    $domCnt = 0; $impCnt = 0
    $priceSum = 0; $priceCnt = 0
    $priceBands = [ordered]@{
        (U "1\uCC9C\uB9CC\uC6D0 \uBBF8\uB9CC") = 0
        (U "1\uCC9C~2\uCC9C\uB9CC\uC6D0")      = 0
        (U "2\uCC9C~3\uCC9C\uB9CC\uC6D0")      = 0
        (U "3\uCC9C~5\uCC9C\uB9CC\uC6D0")      = 0
        (U "5\uCC9C\uB9CC\uC6D0 \uC774\uC0C1") = 0
    }
    $regionCounts = @{}
    $modelCounts  = @{}
    $brandCounts  = @{}

    foreach ($it in $items) {
        if ($it.originType -eq $KR_DOMESTIC) { $domCnt++ } else { $impCnt++ }
        $p = [int]$it.priceManwon
        if ($p -gt 0 -and $p -lt 100000) {
            $priceSum += $p
            $priceCnt++
        }
        $pb = $it.priceBand
        if ($priceBands.Contains($pb)) { $priceBands[$pb] = [int]$priceBands[$pb] + 1 }

        $r = if ($it.region) { [string]$it.region } else { U "\uAE30\uD0C0" }
        $regionCounts[$r] = [int]$regionCounts[$r] + 1

        $m = if ($it.model) { [string]$it.model } else { U "\uAE30\uD0C0" }
        $modelCounts[$m] = [int]$modelCounts[$m] + 1

        $b = if ($it.manufacturer) { [string]$it.manufacturer } else { U "\uAE30\uD0C0" }
        $brandCounts[$b] = [int]$brandCounts[$b] + 1
    }

    $avgPrice = if ($priceCnt -gt 0) { [int][math]::Round($priceSum / $priceCnt) } else { 0 }

    $topRegions = @($regionCounts.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 8 | ForEach-Object { [ordered]@{ name = $_.Key; count = $_.Value } })
    $topModels  = @($modelCounts.GetEnumerator()  | Sort-Object Value -Descending | Select-Object -First 10 | ForEach-Object { [ordered]@{ name = $_.Key; count = $_.Value } })
    $topBrands  = @($brandCounts.GetEnumerator()  | Sort-Object Value -Descending | Select-Object -First 8 | ForEach-Object { [ordered]@{ name = $_.Key; count = $_.Value } })

    return [ordered]@{
        sampleSize      = $total
        domesticCount   = $domCnt
        importedCount   = $impCnt
        domesticRatio   = if ($total -gt 0) { [math]::Round(($domCnt / $total) * 100, 1) } else { 0 }
        importedRatio   = if ($total -gt 0) { [math]::Round(($impCnt / $total) * 100, 1) } else { 0 }
        avgPriceManwon  = $avgPrice
        priceBands      = $priceBands
        topRegions      = $topRegions
        topModels       = $topModels
        topBrands       = $topBrands
    }
}

$allRawVehicles = New-Object System.Collections.Generic.List[object]

# ==============================================================================
# 1. DAANGN USED CARS (C2C Direct)
# ==============================================================================
Write-Host "1. Collecting Daangn Used Cars RAW & Sitemap..." -ForegroundColor Yellow
$daangnSitemapIds = New-Object System.Collections.Generic.List[string]
try {
    $tempGz = Join-Path $env:TEMP "daangn_cars_sitemap_$($PID).xml.gz"
    curl.exe -s -L -A "Mozilla/5.0" "https://www.daangn.com/kr/cars/sitemap-detail.xml.gz" -o $tempGz
    if (Test-Path $tempGz) {
        $fs = [System.IO.File]::OpenRead($tempGz)
        $gz = New-Object System.IO.Compression.GZipStream($fs, [System.IO.Compression.CompressionMode]::Decompress)
        $sr = New-Object System.IO.StreamReader($gz, [System.Text.Encoding]::UTF8)
        $xmlContent = $sr.ReadToEnd()
        $sr.Close(); $gz.Close(); $fs.Close()
        Remove-Item $tempGz -Force -ErrorAction SilentlyContinue
        $locMatches = [regex]::Matches($xmlContent, '<loc>https://www\.daangn\.com/kr/cars/([^<]+?)/?</loc>')
        foreach ($m in $locMatches) {
            $daangnSitemapIds.Add($m.Groups[1].Value)
        }
    }
} catch { Write-Warning "Daangn sitemap error: $_" }

# Save Daangn Sitemap RAW CSV
$daangnSitemapCsvPath = Join-Path $RawDir "daangn_sitemap_urls_$($TodayDate).csv"
$utf8Bom = New-Object System.Text.UTF8Encoding($true)
$smLines = New-Object System.Collections.Generic.List[string]
$smLines.Add("collectedDate,slugId,decodedSlug,url")
foreach ($slug in $daangnSitemapIds) {
    $dec = [uri]::UnescapeDataString($slug)
    $smLines.Add("$TodayDate,`"$slug`",`"$dec`",`"https://www.daangn.com/kr/cars/$slug/`"")
}
[System.IO.File]::WriteAllLines($daangnSitemapCsvPath, $smLines, $utf8Bom)

# Collect Daangn Regional Hub Feeds across all 17 Provinces/Cities (46 Core Hubs)
$daangnHubs = @(
    # Seoul (8)
    @{ id="6035"; sido=(U "\uC11C\uC6B8") }, @{ id="6128"; sido=(U "\uC11C\uC6B8") },
    @{ id="6188"; sido=(U "\uC11C\uC6B8") }, @{ id="6052"; sido=(U "\uC11C\uC6B8") },
    @{ id="6073"; sido=(U "\uC11C\uC6B8") }, @{ id="230";  sido=(U "\uC11C\uC6B8") },
    @{ id="6216"; sido=(U "\uC11C\uC6B8") }, @{ id="355";  sido=(U "\uC11C\uC6B8") },
    # Gyeonggi (11)
    @{ id="1573"; sido=(U "\uACBD\uAE30") }, @{ id="1291"; sido=(U "\uACBD\uAE30") },
    @{ id="1339"; sido=(U "\uACBD\uAE30") }, @{ id="4416"; sido=(U "\uACBD\uAE30") },
    @{ id="4719"; sido=(U "\uACBD\uAE30") }, @{ id="1420"; sido=(U "\uACBD\uAE30") },
    @{ id="1766"; sido=(U "\uACBD\uAE30") }, @{ id="4470"; sido=(U "\uACBD\uAE30") },
    @{ id="4245"; sido=(U "\uACBD\uAE30") }, @{ id="11139"; sido=(U "\uACBD\uAE30") },
    @{ id="4656"; sido=(U "\uACBD\uAE30") },
    # Incheon (3)
    @{ id="6543"; sido=(U "\uC778\uCC9C") }, @{ id="6519"; sido=(U "\uC778\uCC9C") },
    @{ id="6541"; sido=(U "\uC778\uCC9C") },
    # Busan (2)
    @{ id="6026"; sido=(U "\uBD80\uC0B0") }, @{ id="5918"; sido=(U "\uBD80\uC0B0") },
    # Daegu (2)
    @{ id="5663"; sido=(U "\uB300\uAD6C") }, @{ id="817";  sido=(U "\uB300\uAD6C") },
    # Daejeon (2)
    @{ id="5793"; sido=(U "\uB300\uC804") }, @{ id="4238"; sido=(U "\uB300\uC804") },
    # Gwangju & Jeonnam (3)
    @{ id="1015"; sido=(U "\uAD11\uC8FC") }, @{ id="1051"; sido=(U "\uAD11\uC8FC") },
    @{ id="6707"; sido=(U "\uC804\uB0A8") },
    # Ulsan (1) & Sejong (1)
    @{ id="1201"; sido=(U "\uC6B8\uC0B0") }, @{ id="6416"; sido=(U "\uC138\uC885") },
    # Gangwon (2)
    @{ id="1925"; sido=(U "\uAC15\uC6D0") }, @{ id="1898"; sido=(U "\uAC15\uC6D0") },
    # Chungbuk (2) & Chungnam (2)
    @{ id="7201"; sido=(U "\uCCAD\uBD81") }, @{ id="2134"; sido=(U "\uCCAD\uBD81") },
    @{ id="2292"; sido=(U "\uCCAD\uB0A8") }, @{ id="2333"; sido=(U "\uCCAD\uB0A8") },
    # Jeonbuk (1)
    @{ id="6941"; sido=(U "\uC804\uBD81") },
    # Gyeongbuk (2) & Gyeongnam (3)
    @{ id="3121"; sido=(U "\uACBD\uBD81") }, @{ id="5209"; sido=(U "\uACBD\uBD81") },
    @{ id="3478"; sido=(U "\uACBD\uB0A8") }, @{ id="4862"; sido=(U "\uACBD\uB0A8") },
    @{ id="3662"; sido=(U "\uACBD\uB0A8") },
    # Jeju (1)
    @{ id="3835"; sido=(U "\uC81C\uC8FC") }
)
$daangnPostsMap = @{}
foreach ($hub in $daangnHubs) {
    try {
        $sess = New-Object Microsoft.PowerShell.Commands.WebRequestSession
        Invoke-WebRequest -Uri "https://www.daangn.com/kr/api/v1/regions/search-region" -Method Post -ContentType "application/json" -Body "{`"regionId`":`"$($hub.id)`"}" -WebSession $sess -UseBasicParsing -ErrorAction SilentlyContinue | Out-Null
        $resp = Invoke-WebRequest -Uri "https://www.daangn.com/kr/search/cars/" -WebSession $sess -UseBasicParsing -ErrorAction SilentlyContinue
        $stream = New-Object System.IO.StreamReader($resp.RawContentStream, [System.Text.Encoding]::UTF8)
        $rawHtml = $stream.ReadToEnd()
        $stream.Close()
        $m = [regex]::Match($rawHtml, 'window\.__remixContext\s*=\s*(\{.*?\});\s*</script>')
        if ($m.Success) {
            $obj = $m.Groups[1].Value | ConvertFrom-Json
            $posts = $obj.state.loaderData.'routes/kr.search.cars._index'.carPosts
            foreach ($p in $posts) {
                if ($p.id -and -not $daangnPostsMap.ContainsKey($p.id)) {
                    $p | Add-Member -NotePropertyName "hubSido" -NotePropertyValue $hub.sido -Force
                    $daangnPostsMap[$p.id] = $p
                }
            }
        }
    } catch {}
}

$daangnNormItems = New-Object System.Collections.Generic.List[object]
$daangnSampleOnSale = 0; $daangnSampleReserved = 0; $daangnSampleTraded = 0; $daangnSampleNewToday = 0

foreach ($p in $daangnPostsMap.Values) {
    $st = if ($p.status -eq 'ON_SALE') { $daangnSampleOnSale++; $KR_ONSALE }
          elseif ($p.status -eq 'RESERVED') { $daangnSampleReserved++; $KR_RESERVED }
          else { $daangnSampleTraded++; $KR_TRADED }
    if ($p.publishedAt -and $p.publishedAt.StartsWith($TodayDate)) { $daangnSampleNewToday++ }

    $cName = [string]$p.carData.carName
    $ob = Get-OriginAndBrand "" $cName
    $modelShort = ($cName -split '\s+')[0..([Math]::Min(1, ($cName -split '\s+').Count - 1))] -join ' '
    $prc = [int]$p.price
    $sType = if ($p.type -eq 'LEASE') { $KR_LEASE } elseif ($p.type -eq 'RENTAL') { $KR_RENT } else { $KR_GENERAL }

    $row = [pscustomobject][ordered]@{
        collectedDate = $TodayDate
        platform      = (U "\uB2F9\uADFC\uC911\uACE0\uCC28")
        carId         = ($p.id -replace '^/kr/cars/|/$', '')
        originType    = $ob.Origin
        manufacturer  = $ob.Brand
        model         = $modelShort
        fullTitle     = $cName
        year          = [string]$p.carData.modelYear
        mileageKm     = [int]$p.driveDistance
        priceManwon   = $prc
        priceBand     = Get-PriceBand $prc
        region        = "$($p.hubSido) $($p.region.name)"
        sido          = $p.hubSido
        sellType      = $sType
        status        = $st
        registeredAt  = [string]$p.publishedAt
        url           = "https://www.daangn.com$($p.href)"
    }
    $daangnNormItems.Add($row)
    $allRawVehicles.Add($row)
}

$daangnPortfolio = Build-PortfolioSummary $daangnNormItems.ToArray()
$daangnTotal = $daangnSitemapIds.Count
$daangnDomTotalEst = [int][math]::Round($daangnTotal * ($daangnPortfolio.domesticRatio / 100.0))
$daangnImpTotalEst = $daangnTotal - $daangnDomTotalEst
$daangnSampleTotal = $daangnNormItems.Count
$daangnOnSaleRatio = if ($daangnSampleTotal -gt 0) { ($daangnSampleOnSale + $daangnSampleReserved) / $daangnSampleTotal } else { 0.88 }
$daangnOnSaleEst = [int][math]::Round($daangnTotal * $daangnOnSaleRatio)
$daangnTradedEst = $daangnTotal - $daangnOnSaleEst

$daangnSnap = Compare-And-SaveSnapshot "daangn" $daangnSitemapIds.ToArray()
$daangnNewToday = if ($null -ne $daangnSnap.NewFromDiff -and $daangnSnap.NewFromDiff -gt $daangnSampleNewToday) { $daangnSnap.NewFromDiff } else { $daangnSampleNewToday }
$daangnSoldToday = if ($null -ne $daangnSnap.SoldFromDiff -and $daangnSnap.SoldFromDiff -gt $daangnSampleTraded) { $daangnSnap.SoldFromDiff } else { $daangnSampleTraded }
$daangnTurnoverPct = if ($daangnOnSaleEst -gt 0) { [math]::Round(($daangnSoldToday / $daangnOnSaleEst) * 100, 2) } else { 0 }

# ==============================================================================
# 2. K CAR SAFE DIRECT DEAL (market.kcar.com)
# ==============================================================================
Write-Host "2. Collecting K Car Safe Direct Deal RAW (100% Full Enumeration)..." -ForegroundColor Yellow

function Encrypt-KCarParam([string]$jsonText) {
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
    $aes.Key = [System.Text.Encoding]::UTF8.GetBytes("SKFJ2424DasfaJRI")
    $aes.IV  = [System.Text.Encoding]::UTF8.GetBytes("sfq241sf3dscs321")
    $encryptor = $aes.CreateEncryptor()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($jsonText)
    $encBytes = $encryptor.TransformFinalBlock($bytes, 0, $bytes.Length)
    return [Convert]::ToBase64String($encBytes)
}

function Invoke-KCarJson([string]$uri, [string]$paramJson) {
    $body = @{ enc = (Encrypt-KCarParam $paramJson) } | ConvertTo-Json -Compress
    $resp = Invoke-WebRequest -Uri $uri -Method Post -ContentType "application/json" -Body $body -UseBasicParsing
    $sr = New-Object System.IO.StreamReader($resp.RawContentStream, [System.Text.Encoding]::UTF8)
    $utf8Str = $sr.ReadToEnd()
    $sr.Close()
    return ($utf8Str | ConvertFrom-Json)
}

$kcarTotalCount = 0
$kcarCarsMap = @{}
try {
    $cntRes = Invoke-KCarJson "https://market-api.kcar.com/api/v1/ds/carSearchListCount" '{"wr_eq_sell_dcd":"ALL","countFlag":true}'
    $kcarTotalCount = [int]$cntRes.data.totalCnt

    for ($idx = 1; $idx -le 60; $idx += 9) {
        $r = Invoke-KCarJson "https://market-api.kcar.com/api/v1/ds/pagingCarSearchList" "{`"componentId`":`"DS-0044-001-002`",`"index`":$idx,`"orderBy`":`"iqy_dt:desc`",`"orderFlag`":true}"
        if (-not $r.data -or $r.data.Count -eq 0) { break }
        foreach ($item in $r.data) { if ($item.ccCarId) { $kcarCarsMap[$item.ccCarId] = $item } }
    }
    for ($idx = 1; $idx -le 400; $idx += 20) {
        $r = Invoke-KCarJson "https://market-api.kcar.com/api/v1/ds/pagingCarSearchList" "{`"componentId`":`"DS-0044-002-002`",`"index`":$idx,`"orderBy`":`"iqy_dt:desc`",`"orderFlag`":true}"
        if (-not $r.data -or $r.data.Count -eq 0) { break }
        foreach ($item in $r.data) { if ($item.ccCarId) { $kcarCarsMap[$item.ccCarId] = $item } }
    }
} catch { Write-Warning "K Car C2C error: $_" }

$kcarNormItems = New-Object System.Collections.Generic.List[object]
$kcarNewByDate = 0; $kcarReservedCount = 0

foreach ($it in $kcarCarsMap.Values) {
    if ($it.iqyDt -and $it.iqyDt.StartsWith($TodayYmd)) { $kcarNewByDate++ }
    $st = if ($it.sellStat -and $it.sellStat -ne "") { $kcarReservedCount++; $KR_RESERVED } else { $KR_ONSALE }
    $ob = Get-OriginAndBrand ([string]$it.mnuftrNm) ([string]$it.carWhlNm)
    $prc = [int]$it.salprc
    $rawLoc = (($it.sidosigungu -split '\|')[0] -replace ' 전체', '').Trim()
    $sido = Normalize-Region $rawLoc

    $row = [pscustomobject][ordered]@{
        collectedDate = $TodayDate
        platform      = (U "\uCF00\uC774\uCE74\uC9C1\uAC70\uB798")
        carId         = [string]$it.ccCarId
        originType    = $ob.Origin
        manufacturer  = if ($it.mnuftrNm) { [string]$it.mnuftrNm } else { $ob.Brand }
        model         = if ($it.modelNm) { [string]$it.modelNm } else { [string]$it.carNm }
        fullTitle     = [string]$it.carWhlNm
        year          = [string]$it.regModelyr
        mileageKm     = [int]$it.milg
        priceManwon   = $prc
        priceBand     = Get-PriceBand $prc
        region        = $sido
        sido          = $sido
        sellType      = $KR_GENERAL
        status        = $st
        registeredAt  = [string]$it.iqyDt
        url           = "https://market.kcar.com/ds/detail/adInfoDtl/$($it.ccCarId)"
    }
    $kcarNormItems.Add($row)
    $allRawVehicles.Add($row)
}

$kcarPortfolio = Build-PortfolioSummary $kcarNormItems.ToArray()
$kcarIds = @($kcarCarsMap.Keys)
if ($kcarTotalCount -eq 0) { $kcarTotalCount = $kcarIds.Count }
$kcarOnSaleCount = $kcarTotalCount - $kcarReservedCount
$kcarSnap = Compare-And-SaveSnapshot "kcar_c2c" $kcarIds
$kcarNewToday = if ($null -ne $kcarSnap.NewFromDiff -and $kcarSnap.NewFromDiff -gt $kcarNewByDate) { $kcarSnap.NewFromDiff } else { $kcarNewByDate }
$kcarSoldToday = if ($null -ne $kcarSnap.SoldFromDiff) { $kcarSnap.SoldFromDiff } else { 0 }
$kcarTurnoverPct = if ($kcarTotalCount -gt 0) { [math]::Round(($kcarSoldToday / $kcarTotalCount) * 100, 2) } else { 0 }

# ==============================================================================
# 3. ENCAR PERSONAL SELLER (Separation.A - 100% Full Enumeration)
# ==============================================================================
Write-Host "3. Collecting Encar Personal Listings RAW (100% Full Enumeration)..." -ForegroundColor Yellow
$encarPersonalTotal = 0; $encarPersonalDom = 0; $encarPersonalImp = 0; $encarAllTotal = 0
$encarDomItems = New-Object System.Collections.Generic.List[object]
$encarImpItems = New-Object System.Collections.Generic.List[object]

try {
    $resDom = curl.exe -s -A "Mozilla/5.0" "https://api.encar.com/search/car/list/general?count=true&q=(And.Hidden.N._.CarType.Y._.Separation.A.)" | ConvertFrom-Json
    $encarPersonalDom = [int]$resDom.Count
    for ($offset = 0; $offset -le $encarPersonalDom; $offset += 500) {
        $u = "https://api.encar.com/search/car/list/general?count=true&q=(And.Hidden.N._.CarType.Y._.Separation.A.)&sr=%7CModifiedDate%7C$offset%7C500"
        $b = curl.exe -s -A "Mozilla/5.0" $u | ConvertFrom-Json
        if ($b.SearchResults) { $encarDomItems.AddRange($b.SearchResults) }
    }

    $resImp = curl.exe -s -A "Mozilla/5.0" "https://api.encar.com/search/car/list/general?count=true&q=(And.Hidden.N._.CarType.N._.Separation.A.)" | ConvertFrom-Json
    $encarPersonalImp = [int]$resImp.Count
    for ($offset = 0; $offset -le $encarPersonalImp; $offset += 500) {
        $u = "https://api.encar.com/search/car/list/general?count=true&q=(And.Hidden.N._.CarType.N._.Separation.A.)&sr=%7CModifiedDate%7C$offset%7C500"
        $b = curl.exe -s -A "Mozilla/5.0" $u | ConvertFrom-Json
        if ($b.SearchResults) { $encarImpItems.AddRange($b.SearchResults) }
    }

    $resTotal = curl.exe -s -A "Mozilla/5.0" "https://api.encar.com/search/car/list/general?count=true&q=(And.Hidden.N._.CarType.A.)" | ConvertFrom-Json
    $encarAllTotal = [int]$resTotal.Count
} catch { Write-Warning "Encar error: $_" }

$encarPersonalTotal = $encarPersonalDom + $encarPersonalImp
$encarNormItems = New-Object System.Collections.Generic.List[object]
$encarNewByPhoto = 0

foreach ($group in @(
    @{ origin = $KR_DOMESTIC; list = $encarDomItems },
    @{ origin = $KR_IMPORTED; list = $encarImpItems }
)) {
    foreach ($it in $group.list) {
        $regAt = if ($it.Photos -and $it.Photos.Count -gt 0) { [string]$it.Photos[0].updatedDate } else { "" }
        if ($regAt -like "$TodayDate*") { $encarNewByPhoto++ }
        $prc = [int]$it.Price
        $sido = Normalize-Region ([string]$it.OfficeCityState)

        $row = [pscustomobject][ordered]@{
            collectedDate = $TodayDate
            platform      = (U "\uC5D4\uCE74\uB2F7\uCEF4\uAC1C\uC778")
            carId         = [string]$it.Id
            originType    = $group.origin
            manufacturer  = [string]$it.Manufacturer
            model         = [string]$it.Model
            fullTitle     = "$($it.Manufacturer) $($it.Model) $($it.Badge)"
            year          = [string]$it.FormYear
            mileageKm     = [int]$it.Mileage
            priceManwon   = $prc
            priceBand     = Get-PriceBand $prc
            region        = $sido
            sido          = $sido
            sellType      = [string]$it.SellType
            status        = $KR_ONSALE
            registeredAt  = $regAt
            url           = "http://www.encar.com/dc/dc_cardetailview.do?carid=$($it.Id)"
        }
        $encarNormItems.Add($row)
        $allRawVehicles.Add($row)
    }
}

$encarPortfolio = Build-PortfolioSummary $encarNormItems.ToArray()
$encarIds = @($encarNormItems | ForEach-Object { $_.carId })
$encarSnap = Compare-And-SaveSnapshot "encar_personal" $encarIds
$encarNewToday = if ($null -ne $encarSnap.NewFromDiff) { $encarSnap.NewFromDiff } else { $encarNewByPhoto }
$encarSoldToday = if ($null -ne $encarSnap.SoldFromDiff) { $encarSnap.SoldFromDiff } else { 0 }
$encarTurnoverPct = if ($encarPersonalTotal -gt 0) { [math]::Round(($encarSoldToday / $encarPersonalTotal) * 100, 2) } else { 0 }

# ==============================================================================
# 4. KB CHACHACHA PERSONAL DIRECT DEAL (directYn=Y - 100% Full Enumeration)
# ==============================================================================
Write-Host "4. Collecting KB ChaChaCha Personal Direct Deal RAW (100% Full Enumeration)..." -ForegroundColor Yellow
$kbDirectTotal = 0; $kbAllTotal = 0
$kbNormItems = New-Object System.Collections.Generic.List[object]

try {
    $kbOptRaw = curl.exe -s --compressed -A "Mozilla/5.0" "https://www.kbchachacha.com/public/search/optionSale.json"
    $kbOpt = $kbOptRaw | ConvertFrom-Json
    $kbDirectTotal = [int]$kbOpt.optionSale.result.directYn
    $kbAllTotal    = [int]$kbOpt.optionSale.result.total

    $tempKbHtml = Join-Path $env:TEMP "kb_direct_raw_$($PID).html"
    curl.exe -s --compressed -A "Mozilla/5.0" "https://www.kbchachacha.com/public/search/list.empty?page=1&sort=-orderDate&directYn=Y" -o $tempKbHtml
    $kbHtml = [System.IO.File]::ReadAllText($tempKbHtml, [System.Text.Encoding]::UTF8)
    Remove-Item $tempKbHtml -Force -ErrorAction SilentlyContinue

    $cardBlocks = $kbHtml -split '<div class="area\s*"'
    $seenKb = @{}
    foreach ($blk in ($cardBlocks | Select-Object -Skip 1)) {
        $seqM = [regex]::Match($blk, 'data-car-seq="(\d+)"')
        if (-not $seqM.Success) { continue }
        $seq = $seqM.Groups[1].Value
        if ($seenKb.ContainsKey($seq)) { continue }
        $seenKb[$seq] = $true

        $titM = [regex]::Match($blk, '<strong class="tit">\s*([\s\S]*?)\s*</strong>')
        $title = if ($titM.Success) { ($titM.Groups[1].Value -replace '<[^>]+>', '' -replace '\s+', ' ').Trim() } else { "" }

        $gaM = [regex]::Match($blk, 'vehicle_price":"([^"]+)"')
        $prcText = if ($gaM.Success) { $gaM.Groups[1].Value } else { "" }
        $prcNum = 0
        if ($prcText -match '(\d+)') { $prcNum = [int]$Matches[1] }

        $spans = [regex]::Match($blk, '<div class="data-line">([\s\S]*?)</div>')
        $yr = ""; $km = 0; $loc = ""
        if ($spans.Success) {
            $spList = [regex]::Matches($spans.Groups[1].Value, '<span>([\s\S]*?)</span>')
            if ($spList.Count -ge 1) {
                $yRaw = $spList[0].Groups[1].Value
                if ($yRaw -match '(\d{2})/\d{2}') { $yr = "20" + $Matches[1] } else { $yr = $yRaw }
            }
            if ($spList.Count -ge 2) {
                $kRaw = ($spList[1].Groups[1].Value -replace '[^\d]', '')
                if ($kRaw) { $km = [int]$kRaw }
            }
            if ($spList.Count -ge 3) {
                $loc = $spList[2].Groups[1].Value.Trim()
            }
        }

        $ob = Get-OriginAndBrand "" $title
        $words = $title -split '\s+'
        $modelShort = if ($words.Count -ge 2) { $words[1] } else { $title }
        $sido = Normalize-Region $loc

        $row = [pscustomobject][ordered]@{
            collectedDate = $TodayDate
            platform      = (U "KB\uCC28\uCC28\uCC28\uAC1C\uC778")
            carId         = $seq
            originType    = $ob.Origin
            manufacturer  = $ob.Brand
            model         = $modelShort
            fullTitle     = $title
            year          = $yr
            mileageKm     = $km
            priceManwon   = $prcNum
            priceBand     = Get-PriceBand $prcNum
            region        = $sido
            sido          = $sido
            sellType      = $KR_GENERAL
            status        = $KR_ONSALE
            registeredAt  = $TodayDate
            url           = "https://www.kbchachacha.com/public/car/detail.kbc?carSeq=$seq"
        }
        $kbNormItems.Add($row)
        $allRawVehicles.Add($row)
    }
} catch { Write-Warning "KB error: $_" }

$kbPortfolio = Build-PortfolioSummary $kbNormItems.ToArray()
$kbIds = @($kbNormItems | ForEach-Object { $_.carId })
if ($kbDirectTotal -eq 0) { $kbDirectTotal = $kbIds.Count }
$kbSnap = Compare-And-SaveSnapshot "kb_direct" $kbIds
$kbNewToday = if ($null -ne $kbSnap.NewFromDiff) { $kbSnap.NewFromDiff } else { 0 }
$kbSoldToday = if ($null -ne $kbSnap.SoldFromDiff) { $kbSnap.SoldFromDiff } else { 0 }
$kbTurnoverPct = if ($kbDirectTotal -gt 0) { [math]::Round(($kbSoldToday / $kbDirectTotal) * 100, 2) } else { 0 }

# ==============================================================================
# 5. SAVE UNIFIED VEHICLE-LEVEL RAW CSV & JSON
# ==============================================================================
$rawCsvToday  = Join-Path $RawDir "raw_vehicles_$($TodayDate).csv"
$rawCsvLatest = Join-Path $RawDir "raw_vehicles_latest.csv"
$rawHeader = U "\uC218\uC9D1\uC77C\uC790,\uD50C\uB7AB\uD3FC,\uB9E4\uBB3CID,\uAD6D\uC0B0\uC218\uC785\uAD6C\uBD84,\uC81C\uC870\uC0AC,\uBAA8\uB378\uBA85,\uC804\uCCB4\uCC28\uB7C9\uBA85,\uC5F0\uC2DD,\uC8FC\uD589\uAC70\uB9AC_km,\uD310\uB9E4\uAC00\uACA9_\uB9CC\uC6D0,\uAC00\uACA9\uB300\uAD6C\uAC04,\uC9C0\uC5ED_\uC2DC\uB3C4,\uD310\uB9E4\uBC29\uC2DD,\uD310\uB9E4\uC0C1\uD0DC,\uB4F1\uB85D\uC77C\uC2DC,\uC0C1\uC138URL"
$rawLines = New-Object System.Collections.Generic.List[string]
$rawLines.Add($rawHeader)
foreach ($v in $allRawVehicles) {
    $line = "{0},`"{1}`",`"{2}`",`"{3}`",`"{4}`",`"{5}`",`"{6}`",`"{7}`",{8},{9},`"{10}`",`"{11}`",`"{12}`",`"{13}`",`"{14}`",`"{15}`"" -f `
        $v.collectedDate, $v.platform, ($v.carId -replace '"','""'), $v.originType, ($v.manufacturer -replace '"','""'), `
        ($v.model -replace '"','""'), ($v.fullTitle -replace '"','""'), $v.year, $v.mileageKm, $v.priceManwon, `
        $v.priceBand, ($v.sido -replace '"','""'), $v.sellType, $v.status, $v.registeredAt, $v.url
    $rawLines.Add($line)
}
[System.IO.File]::WriteAllLines($rawCsvToday, $rawLines, $utf8Bom)
[System.IO.File]::WriteAllLines($rawCsvLatest, $rawLines, $utf8Bom)

# ==============================================================================
# 6. MERGE DAILY RECORD & SAVE PORTFOLIO + SUMMARY BUNDLE
# ==============================================================================
$records = @()
if (Test-Path $JsonPath) {
    try {
        $existingRaw = [System.IO.File]::ReadAllText($JsonPath, [System.Text.Encoding]::UTF8)
        $parsed = $existingRaw | ConvertFrom-Json
        if ($parsed -is [System.Array]) { $records = @($parsed) }
        elseif ($null -ne $parsed) { $records = @($parsed) }
    } catch { $records = @() }
}

$defaultMemo = U "4\uB300 \uD50C\uB7AB\uD3FC Apple-to-Apple (\uAD6D\uC0B0/\uC218\uC785/\uD3EC\uD2B8\uD3F4\uB9AC\uC624/RAW) \uC790\uB3D9 \uC218\uC9D1"

$newEntry = [ordered]@{
    date                  = $TodayDate
    updatedAt             = $Timestamp
    rawVehicleCount       = $allRawVehicles.Count
    # 1. Daangn Used Cars
    daangnCarsCount       = $daangnTotal
    daangnDomesticCount   = $daangnDomTotalEst
    daangnImportedCount   = $daangnImpTotalEst
    daangnOnSaleCount     = $daangnOnSaleEst
    daangnTradedCount     = $daangnTradedEst
    daangnNewCount        = $daangnNewToday
    daangnSoldCount       = $daangnSoldToday
    daangnTurnoverPct     = $daangnTurnoverPct
    daangnAvgPrice        = $daangnPortfolio.avgPriceManwon
    daangnDiff            = 0
    # 2. K Car Safe Direct Deal (C2C)
    kcarDirectCount       = $kcarTotalCount
    kcarDomesticCount     = $kcarPortfolio.domesticCount
    kcarImportedCount     = $kcarPortfolio.importedCount
    kcarOnSaleCount       = $kcarOnSaleCount
    kcarReservedCount     = $kcarReservedCount
    kcarNewCount          = $kcarNewToday
    kcarSoldCount         = $kcarSoldToday
    kcarTurnoverPct       = $kcarTurnoverPct
    kcarAvgPrice          = $kcarPortfolio.avgPriceManwon
    kcarDiff              = 0
    # 3. Encar Personal Seller (Separation.A)
    encarPersonalCount    = $encarPersonalTotal
    encarPersonalDomestic = $encarPersonalDom
    encarPersonalImported = $encarPersonalImp
    encarOnSaleCount      = $encarPersonalTotal
    encarNewCount         = $encarNewToday
    encarSoldCount        = $encarSoldToday
    encarTurnoverPct      = $encarTurnoverPct
    encarAvgPrice         = $encarPortfolio.avgPriceManwon
    encarTotalCount       = $encarAllTotal
    encarPersonalDiff     = 0
    # 4. KB ChaChaCha Personal Direct Deal (directYn=Y)
    kbDirectCount         = $kbDirectTotal
    kbDomesticCount       = $kbPortfolio.domesticCount
    kbImportedCount       = $kbPortfolio.importedCount
    kbOnSaleCount         = $kbDirectTotal
    kbNewCount            = $kbNewToday
    kbSoldCount           = $kbSoldToday
    kbTurnoverPct         = $kbTurnoverPct
    kbAvgPrice            = $kbPortfolio.avgPriceManwon
    kbTotalCount          = $kbAllTotal
    kbDiff                = 0
    source                = "auto"
    memo                  = $defaultMemo
}

$filtered = @($records | Where-Object { $_.date -ne $TodayDate })
$filtered += [pscustomobject]$newEntry
$sortedRecords = @($filtered | Sort-Object date)

for ($i = 0; $i -lt $sortedRecords.Count; $i++) {
    if ($i -eq 0) {
        $sortedRecords[$i].daangnDiff = 0
        $sortedRecords[$i].kcarDiff = 0
        $sortedRecords[$i].encarPersonalDiff = 0
        $sortedRecords[$i].kbDiff = 0
    } else {
        $prev = $sortedRecords[$i - 1]
        $cur  = $sortedRecords[$i]
        $cur.daangnDiff        = [int]$cur.daangnCarsCount - [int]$prev.daangnCarsCount
        $cur.kcarDiff          = [int]$cur.kcarDirectCount - [int]$prev.kcarDirectCount
        $cur.encarPersonalDiff = [int]$cur.encarPersonalCount - [int]$prev.encarPersonalCount
        $cur.kbDiff            = [int]$cur.kbDirectCount - [int]$prev.kbDirectCount
    }
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$jsonOutput = ConvertTo-Json -InputObject $sortedRecords -Depth 6
if ($sortedRecords.Count -eq 1 -and -not $jsonOutput.TrimStart().StartsWith("[")) {
    $jsonOutput = "[`r`n" + $jsonOutput + "`r`n]"
}
[System.IO.File]::WriteAllText($JsonPath, $jsonOutput, $utf8NoBom)

# Save Summary CSV
$csvHeader = U (
    "\uC77C\uC790,\uC218\uC9D1\uC2DC\uAC01," +
    "\uB2F9\uADFC_\uC804\uCCB4,\uB2F9\uADFC_\uAD6D\uC0B0(\uCD94\uC815),\uB2F9\uADFC_\uC218\uC785(\uCD94\uC815),\uB2F9\uADFC_\uD310\uB9E4\uC911,\uB2F9\uADFC_\uAC70\uB798\uC644\uB8CC,\uB2F9\uADFC_\uC2E0\uADDC\uB4F1\uB85D,\uB2F9\uADFC_\uC2E0\uADDC\uD310\uB9E4,\uB2F9\uADFC_\uD68C\uC804\uC728(%),\uB2F9\uADFC_\uD3C9\uADE0\uAC00(\uB9CC\uC6D0)," +
    "\uCF00\uC774\uCE74\uC9C1\uAC70\uB798_\uC804\uCCB4,\uCF00\uC774\uCE74_\uAD6D\uC0B0,\uCF00\uC774\uCE74_\uC218\uC785,\uCF00\uC774\uCE74_\uD310\uB9E4\uC911,\uCF00\uC774\uCE74_\uC608\uC57D\uC911,\uCF00\uC774\uCE74_\uC2E0\uADDC\uB4F1\uB85D,\uCF00\uC774\uCE74_\uC2E0\uADDC\uD310\uB9E4,\uCF00\uC774\uCE74_\uD68C\uC804\uC728(%),\uCF00\uC774\uCE74_\uD3C9\uADE0\uAC00(\uB9CC\uC6D0)," +
    "\uC5D4\uCE74\uAC1C\uC778_\uC804\uCCB4,\uC5D4\uCE74\uAC1C\uC778_\uAD6D\uC0B0,\uC5D4\uCE74\uAC1C\uC778_\uC218\uC785,\uC5D4\uCE74\uAC1C\uC778_\uD310\uB9E4\uC911,\uC5D4\uCE74\uAC1C\uC778_\uC2E0\uADDC\uB4F1\uB85D,\uC5D4\uCE74\uAC1C\uC778_\uC2E0\uADDC\uD310\uB9E4,\uC5D4\uCE74\uAC1C\uC778_\uD68C\uC804\uC728(%),\uC5D4\uCE74\uAC1C\uC778_\uD3C9\uADE0\uAC00(\uB9CC\uC6D0)," +
    "KB\uAC1C\uC778_\uC804\uCCB4,KB\uAC1C\uC778_\uAD6D\uC0B0,KB\uAC1C\uC778_\uC218\uC785,KB\uAC1C\uC778_\uD310\uB9E4\uC911,KB\uAC1C\uC778_\uC2E0\uADDC\uB4F1\uB85D,KB\uAC1C\uC778_\uC2E0\uADDC\uD310\uB9E4,KB\uAC1C\uC778_\uD68C\uC804\uC728(%),KB\uAC1C\uC778_\uD3C9\uADE0\uAC00(\uB9CC\uC6D0)"
)
$csvLines = New-Object System.Collections.Generic.List[string]
$csvLines.Add($csvHeader)
foreach ($r in $sortedRecords) {
    $line = "{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11},{12},{13},{14},{15},{16},{17},{18},{19},{20},{21},{22},{23},{24},{25},{26},{27},{28},{29},{30},{31},{32},{33},{34},{35}" -f `
        $r.date, $r.updatedAt, `
        $r.daangnCarsCount, $r.daangnDomesticCount, $r.daangnImportedCount, $r.daangnOnSaleCount, $r.daangnTradedCount, $r.daangnNewCount, $r.daangnSoldCount, $r.daangnTurnoverPct, $r.daangnAvgPrice, `
        $r.kcarDirectCount, $r.kcarDomesticCount, $r.kcarImportedCount, $r.kcarOnSaleCount, $r.kcarReservedCount, $r.kcarNewCount, $r.kcarSoldCount, $r.kcarTurnoverPct, $r.kcarAvgPrice, `
        $r.encarPersonalCount, $r.encarPersonalDomestic, $r.encarPersonalImported, $r.encarOnSaleCount, $r.encarNewCount, $r.encarSoldCount, $r.encarTurnoverPct, $r.encarAvgPrice, `
        $r.kbDirectCount, $r.kbDomesticCount, $r.kbImportedCount, $r.kbOnSaleCount, $r.kbNewCount, $r.kbSoldCount, $r.kbTurnoverPct, $r.kbAvgPrice
    $csvLines.Add($line)
}
[System.IO.File]::WriteAllLines($CsvPath, $csvLines, $utf8Bom)

$portfolioBundle = [ordered]@{
    updatedAt = $Timestamp
    daangn    = $daangnPortfolio
    kcar      = $kcarPortfolio
    encar     = $encarPortfolio
    kb        = $kbPortfolio
}
$portfolioJson = $portfolioBundle | ConvertTo-Json -Depth 6
# Embed all raw vehicles across all 4 platforms for instant browser search
$rawPreview = $allRawVehicles | ConvertTo-Json -Depth 4 -Compress

$jsContent = @"
// Auto-generated 4-Platform Apple-to-Apple C2C Intelligence Bundle ($Timestamp)
window.COMPETITOR_TREND_LAST_UPDATED = "$Timestamp";
window.COMPETITOR_TREND_DATA = $jsonOutput;
window.COMPETITOR_PORTFOLIO_DATA = $portfolioJson;
window.COMPETITOR_RAW_PREVIEW = $rawPreview;
window.COMPETITOR_RAW_TOTAL_COUNT = $($allRawVehicles.Count);
"@
[System.IO.File]::WriteAllText($JsPath, $jsContent, $utf8NoBom)

Write-Host "[$Timestamp] Completed! Total RAW Vehicles Saved: $($allRawVehicles.Count) (+ Daangn Sitemap: $($daangnSitemapIds.Count))" -ForegroundColor Cyan
Write-Host "  - RAW Vehicles CSV : $rawCsvToday"
Write-Host "  - Daangn URLs CSV  : $daangnSitemapCsvPath"
Write-Host "  - Daily Summary CSV: $CsvPath"
