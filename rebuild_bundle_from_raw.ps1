$ErrorActionPreference = "Stop"
$WorkDir = "c:\Users\KCAR24N20051\Desktop\당근"
$RawDir  = Join-Path $WorkDir "raw_data"
$DbDir   = Join-Path $WorkDir "database"
$JsonPath = Join-Path $WorkDir "competitor_trend.json"
$CsvPath  = Join-Path $WorkDir "competitor_trend.csv"
$JsPath   = Join-Path $WorkDir "competitor_trend_data.js"

function U([string]$esc) { return [regex]::Unescape($esc) }

$PAT_SUV     = U "SUV|RV|\uC3D8\uB80C\uD1A0|\uC2FC\uD0C0\uD398|\uC2A4\uD3EC\uD2F0\uC9C0|\uD22C\uC2FC|\uCE74\uB2C8\uBC1C|\uD330\uB9AC\uC138\uC774\uB4DC|\uC140\uD1A0\uC2A4|\uB2C8\uB85C|\uCF54\uB098|\uBAA8\uD558\uBE44|\uD2F0\uBCF4\uB9AC|\uD1A0\uB808\uC2A4|\uB809\uC2A4\uD134|\uCF54\uB780\uB3C4|QM6|XM3|\uD2B8\uB799\uC2A4|\uD2B8\uB808\uC77C\uBE14\uB808\uC774\uC800|\uC62C\uB780\uB3C4|\uBCA0\uB274|GV70|GV80|GV60|\uC544\uC774\uC624\uB2C95|\uC544\uC774\uC624\uB2C9 5|EV6|EV9|EV3|\uBAA8\uB378Y|\uBAA8\uB378 Y|\uBAA8\uB378X|\uBAA8\uB378 X|\uCE74\uC774\uC5D4|\uB9C8\uCE78|X3|X4|X5|X6|X7|GLC|GLE|GLA|GLB|GLS|Q3|Q5|Q7|Q8|\uD2F0\uAD6C\uC548|\uD22C\uC544\uB809|XC60|XC90|XC40|\uB808\uB2C8\uAC8C\uC774\uB4DC|\uCCB4\uB85C\uD0A4|\uB7AD\uAE00\uB7EC|\uB514\uC2A4\uCEE4\uBC84\uB9AC|\uB808\uC778\uC9C0\uB85C\uBC84|\uC775\uC2A4\uD50C\uB85C\uB7EC|\uCEFF\uD2B8\uB9AC\uB9E8"
$PAT_SMALL   = U "\uBAA8\uB2DD|\uC2A4\uD30C\uD06C|\uB808\uC774|\uCE90\uC2A4\uD37C|\uB9C8\uD2F0\uC988|\uB2E4\uB9C8\uC2A4|\uB77C\uBCF4|\uC5D1\uC13C\uD2B8|\uD504\uB77C\uC774\uB4DC|\uD074\uB9AD|\uBCA0\uB974\uB098|\uBBF8\uB2C8|\uCFE0\uD37C"
$PAT_COMPACT = U "\uC544\uBC18\uB5BC|K3|\uD3EC\uB974\uD14C|\uD06C\uB8E8\uC988|\uB77C\uC138\uD2F0|SM3|\uBCA8\uB85C\uC2A4\uD130|I30|\uACE8\uD504|\uC81C\uD0C0|A3|1\uC2DC\uB9AC\uC988|2\uC2DC\uB9AC\uC988|\uC2DC\uBE45|\uD504\uB9AC\uC6B0\uC2A4"
$PAT_MID     = U "\uC3D8\uB098\uD0C0|\uC18C\uB098\uD0C0|K5|\uB9D0\uB9AC\uBD80|SM6|SM5|I40|G70|3\uC2DC\uB9AC\uC988|320|4\uC2DC\uB9AC\uC988|C\uD074\uB798\uC2A4|C200|C220|A4|A5|\uD30C\uC0AC\uD2B8|\uC544\uD14C\uC628|S60|\uCE20\uB9AC|\uC5B4\uCF54\uB4DC|\uBAA8\uB3783|\uBAA8\uB378 3|\uC544\uC774\uC624\uB2C96|\uC544\uC774\uC624\uB2C9 6"
$PAT_LARGE   = U "\uADF8\uB79C\uC800|K7|K8|K9|G80|G90|\uC81C\uB124\uC2DC\uC2A4|\uC5D0\uCFE0\uC2A4|\uCCB4\uC5B4\uB9E8|\uC624\uD53C\uB7EC\uC2A4|\uC544\uC2AC\uB780|\uC54C\uD398\uC628|\uC784\uD314\uB77C|SM7|5\uC2DC\uB9AC\uC988|520|530|6\uC2DC\uB9AC\uC988|7\uC2DC\uB9AC\uC988|E\uD074\uB798\uC2A4|E200|E220|E250|E300|E350|S\uD074\uB798\uC2A4|CLS|A6|A7|A8|\uD30C\uB098\uBA54\uB77C|\uD0C0\uC774\uCE78|911|\uBC15\uC2A4\uD130|\uCE74\uC774\uB9E8|\uBAA8\uB378S|\uBAA8\uB378 S|S90"
$PAT_VAN     = U "\uC2A4\uD0C0\uB9AC\uC544|\uC2A4\uD0C0\uB809\uC2A4|\uD3EC\uD130|\uBD09\uACE0|\uB9C8\uC2A4\uD130|\uC3E0\uB77C\uD2F0|\uCE74\uC6B4\uD2F0|\uB9C8\uC774\uD2F0|\uD2B8\uB7ED|\uD654\uBB3C|\uCE20\uD551\uCE74|\uBC34"

$KR_DOMESTIC = U "\uAD6D\uC0B0"

function Get-CarTypeCategory([string]$title) {
    $t = $title.ToUpper()
    if ($t -match $PAT_SUV)     { return (U "SUV \u00B7 RV") }
    if ($t -match $PAT_SMALL)   { return (U "\uACBD\uCC28 \u00B7 \uC18C\uD615") }
    if ($t -match $PAT_COMPACT) { return (U "\uC900\uC911\uD615") }
    if ($t -match $PAT_MID)     { return (U "\uC911\uD615 \uC138\uB2E8") }
    if ($t -match $PAT_LARGE)   { return (U "\uC900\uB300\uD615 \u00B7 \uB300\uD615 \u00B7 \uACE0\uAE09") }
    if ($t -match $PAT_VAN)     { return (U "\uC0C1\uC6A9 \u00B7 \uC2B9\uD569 \u00B7 \uCE20\uD551") }
    return (U "\uC911\uD615 \u00B7 \uAE30\uD0C0\uC2B9\uC6A9")
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
    $carTypes = [ordered]@{
        (U "SUV \u00B7 RV")                      = 0
        (U "\uC900\uB300\uD615 \u00B7 \uB300\uD615 \u00B7 \uACE0\uAE09") = 0
        (U "\uC911\uD615 \uC138\uB2E8")          = 0
        (U "\uC900\uC911\uD615")                 = 0
        (U "\uACBD\uCC28 \u00B7 \uC18C\uD615")   = 0
        (U "\uC0C1\uC6A9 \u00B7 \uC2B9\uD569 \u00B7 \uCE20\uD551") = 0
        (U "\uC911\uD615 \u00B7 \uAE30\uD0C0\uC2B9\uC6A9") = 0
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

        $ct = Get-CarTypeCategory "$($it.model) $($it.fullTitle)"
        if ($carTypes.Contains($ct)) { $carTypes[$ct] = [int]$carTypes[$ct] + 1 }

        $r = if ($it.region) { ([string]$it.region -split '\s+')[0] } else { U "\uAE30\uD0C0" }
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
        carTypes        = $carTypes
        topRegions      = $topRegions
        topModels       = $topModels
        topBrands       = $topBrands
    }
}

function Parse-RawCsv([string]$csvPath) {
    $rows = Import-Csv -Path $csvPath -Encoding UTF8
    $list = New-Object System.Collections.Generic.List[object]
    foreach ($r in $rows) {
        $props = @($r.PSObject.Properties)
        $list.Add([pscustomobject][ordered]@{
            collectedDate = $props[0].Value
            platform      = $props[1].Value
            carId         = $props[2].Value
            originType    = $props[3].Value
            manufacturer  = $props[4].Value
            model         = $props[5].Value
            fullTitle     = $props[6].Value
            year          = $props[7].Value
            mileageKm     = [int]($props[8].Value -replace '[^\d]','')
            priceManwon   = [int]($props[9].Value -replace '[^\d]','')
            priceBand     = $props[10].Value
            region        = $props[11].Value
            sido          = ($props[11].Value -split '\s+')[0]
            sellType      = $props[12].Value
            status        = $props[13].Value
            registeredAt  = $props[14].Value
            url           = $props[15].Value
        })
    }
    return $list
}

Write-Host "1. Combining all raw_vehicles_20*.csv files into master DB..." -ForegroundColor Cyan
$masterDbPath = Join-Path $DbDir "c2c_vehicle_master_db.csv"
$rawFiles = @(Get-ChildItem -Path $RawDir -Filter "raw_vehicles_20*.csv" | Sort-Object Name)
$combinedLines = New-Object System.Collections.Generic.List[string]
for ($fIdx = 0; $fIdx -lt $rawFiles.Count; $fIdx++) {
    $lines = [System.IO.File]::ReadAllLines($rawFiles[$fIdx].FullName, [System.Text.Encoding]::UTF8)
    $startIdx = if ($fIdx -eq 0) { 0 } else { 1 }
    for ($i = $startIdx; $i -lt $lines.Length; $i++) { $combinedLines.Add($lines[$i]) }
}

$utf8Bom   = New-Object System.Text.UTF8Encoding($true)
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllLines($masterDbPath, $combinedLines, $utf8Bom)
Write-Host "   Master DB lines written: $($combinedLines.Count)" -ForegroundColor Green

Write-Host "2. Building date-specific and combined Portfolio objects..." -ForegroundColor Cyan
$PLAT_DAANGN = U "\uB2F9\uADFC\uC911\uACE0\uCC28"
$PLAT_KCAR   = U "\uCF00\uC774\uCE74\uC9C1\uAC70\uB798"
$PLAT_ENCAR  = U "\uC5D4\uCE74\uB2F7\uCEF4\uAC1C\uC778"
$PLAT_KB     = U "KB\uCC28\uCC28\uCC28\uAC1C\uC778"

function Build-FourPlatformPortfolio([object[]]$list, [string]$upd) {
    return [ordered]@{
        updatedAt = $upd
        daangn    = Build-PortfolioSummary @($list | Where-Object { $_.platform -eq $PLAT_DAANGN })
        kcar      = Build-PortfolioSummary @($list | Where-Object { $_.platform -eq $PLAT_KCAR })
        encar     = Build-PortfolioSummary @($list | Where-Object { $_.platform -eq $PLAT_ENCAR })
        kb        = Build-PortfolioSummary @($list | Where-Object { $_.platform -eq $PLAT_KB })
    }
}

$portfolioByDate = [ordered]@{}
$itemsAll = @()
$latestPf = $null
foreach ($rf in $rawFiles) {
    $dStr = ($rf.BaseName -replace '^raw_vehicles_', '')
    $dayItems = @(Parse-RawCsv $rf.FullName)
    $itemsAll += $dayItems
    $dayPf = Build-FourPlatformPortfolio $dayItems $dStr
    $portfolioByDate[$dStr] = $dayPf
    $latestPf = $dayPf
}
$pfAll = Build-FourPlatformPortfolio $itemsAll "ALL"
$portfolioByDate["ALL"] = $pfAll

Write-Host "3. Updating competitor_trend.json and c2c_daily_summary_db.csv..." -ForegroundColor Cyan
$rawJson = [System.IO.File]::ReadAllText($JsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$records = @()
foreach ($elem in @($rawJson)) {
    if ($null -ne $elem -and $null -ne $elem.PSObject.Properties['value']) {
        foreach ($sub in @($elem.value)) { if ($null -ne $sub -and $sub.date) { $records += $sub } }
    } elseif ($null -ne $elem -and $elem.date) {
        $records += $elem
    }
}

$jsonOutput = $records | ConvertTo-Json -Depth 6
if (-not $jsonOutput.TrimStart().StartsWith("[")) {
    $jsonOutput = "[`r`n" + $jsonOutput + "`r`n]"
}
[System.IO.File]::WriteAllText($JsonPath, $jsonOutput, $utf8NoBom)

$csvHeader = U (
    "\uC77C\uC790,\uC218\uC9D1\uC2DC\uAC01," +
    "\uB2F9\uADFC_\uC804\uCCB4,\uB2F9\uADFC_\uAD6D\uC0B0(\uCD94\uC815),\uB2F9\uADFC_\uC218\uC785(\uCD94\uC815),\uB2F9\uADFC_\uD310\uB9E4\uC911,\uB2F9\uADFC_\uAC70\uB798\uC644\uB8CC,\uB2F9\uADFC_\uC2E0\uADDC\uB4F1\uB85D,\uB2F9\uADFC_\uC2E0\uADDC\uD310\uB9E4,\uB2F9\uADFC_\uD68C\uC804\uC728(%),\uB2F9\uADFC_\uD3C9\uADE0\uAC00(\uB9CC\uC6D0)," +
    "\uCF00\uC774\uCE74\uC9C1\uAC70\uB798_\uC804\uCCB4,\uCF00\uC774\uCE74_\uAD6D\uC0B0,\uCF00\uC774\uCE74_\uC218\uC785,\uCF00\uC774\uCE74_\uD310\uB9E4\uC911,\uCF00\uC774\uCE74_\uC608\uC57D\uC911,\uCF00\uC774\uCE74_\uC2E0\uADDC\uB4F1\uB85D,\uCF00\uC774\uCE74_\uC2E0\uADDC\uD310\uB9E4,\uCF00\uC774\uCE74_\uD68C\uC804\uC728(%),\uCF00\uC774\uCE74_\uD3C9\uADE0\uAC00(\uB9CC\uC6D0)," +
    "\uC5D4\uCE74\uAC1C\uC778_\uC804\uCCB4,\uC5D4\uCE74\uAC1C\uC778_\uAD6D\uC0B0,\uC5D4\uCE74\uAC1C\uC778_\uC218\uC785,\uC5D4\uCE74\uAC1C\uC778_\uD310\uB9E4\uC911,\uC5D4\uCE74\uAC1C\uC778_\uC2E0\uADDC\uB4F1\uB85D,\uC5D4\uCE74\uAC1C\uC778_\uC2E0\uADDC\uD310\uB9E4,\uC5D4\uCE74\uAC1C\uC778_\uD68C\uC804\uC728(%),\uC5D4\uCE74\uAC1C\uC778_\uD3C9\uADE0\uAC00(\uB9CC\uC6D0)," +
    "KB\uAC1C\uC778_\uC804\uCCB4,KB\uAC1C\uC778_\uAD6D\uC0B0,KB\uAC1C\uC778_\uC218\uC785,KB\uAC1C\uC778_\uD310\uB9E4\uC911,KB\uAC1C\uC778_\uC2E0\uADDC\uB4F1\uB85D,KB\uAC1C\uC778_\uC2E0\uADDC\uD310\uB9E4,KB\uAC1C\uC778_\uD68C\uC804\uC728(%),KB\uAC1C\uC778_\uD3C9\uADE0\uAC00(\uB9CC\uC6D0)"
)
$csvLines = New-Object System.Collections.Generic.List[string]
$csvLines.Add($csvHeader)
foreach ($r in $records) {
    $line = "{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11},{12},{13},{14},{15},{16},{17},{18},{19},{20},{21},{22},{23},{24},{25},{26},{27},{28},{29},{30},{31},{32},{33},{34},{35}" -f `
        $r.date, $r.updatedAt, `
        $r.daangnCarsCount, $r.daangnDomesticCount, $r.daangnImportedCount, $r.daangnOnSaleCount, $r.daangnTradedCount, $r.daangnNewCount, $r.daangnSoldCount, $r.daangnTurnoverPct, $r.daangnAvgPrice, `
        $r.kcarDirectCount, $r.kcarDomesticCount, $r.kcarImportedCount, $r.kcarOnSaleCount, $r.kcarReservedCount, $r.kcarNewCount, $r.kcarSoldCount, $r.kcarTurnoverPct, $r.kcarAvgPrice, `
        $r.encarPersonalCount, $r.encarPersonalDomestic, $r.encarPersonalImported, $r.encarOnSaleCount, $r.encarNewCount, $r.encarSoldCount, $r.encarTurnoverPct, $r.encarAvgPrice, `
        $r.kbDirectCount, $r.kbDomesticCount, $r.kbImportedCount, $r.kbOnSaleCount, $r.kbNewCount, $r.kbSoldCount, $r.kbTurnoverPct, $r.kbAvgPrice
    $csvLines.Add($line)
}
[System.IO.File]::WriteAllLines($CsvPath, $csvLines, $utf8Bom)
[System.IO.File]::WriteAllLines((Join-Path $DbDir "c2c_daily_summary_db.csv"), $csvLines, $utf8Bom)

Write-Host "4. Writing competitor_trend_data.js..." -ForegroundColor Cyan
$manifestJson = [System.IO.File]::ReadAllText((Join-Path $DbDir "db_manifest.json"), [System.Text.Encoding]::UTF8)
$pfLatestJson = $latestPf | ConvertTo-Json -Depth 6
$pfByDateJson = $portfolioByDate | ConvertTo-Json -Depth 7
$rawAllJson   = $itemsAll | ConvertTo-Json -Depth 4 -Compress

$jsContent = @"
// Auto-generated 4-Platform Apple-to-Apple C2C Intelligence Bundle (2026-11-17 09:16:22)
window.COMPETITOR_TREND_LAST_UPDATED = "2026-11-17 09:16:22";
window.COMPETITOR_TREND_DATA = $jsonOutput;
window.COMPETITOR_PORTFOLIO_DATA = $pfLatestJson;
window.COMPETITOR_PORTFOLIO_BY_DATE = $pfByDateJson;
window.COMPETITOR_RAW_PREVIEW = $rawAllJson;
window.COMPETITOR_RAW_TOTAL_COUNT = $($itemsAll.Count);
window.COMPETITOR_DB_ARCHIVE = $manifestJson;
"@
[System.IO.File]::WriteAllText($JsPath, $jsContent, $utf8NoBom)
Write-Host "Done! Total RAW items in JS bundle: $($itemsAll.Count)" -ForegroundColor Green
