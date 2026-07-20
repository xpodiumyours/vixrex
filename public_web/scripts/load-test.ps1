# VixRex Public Web - Yerel HTTP Yuk Testi
# Test magazasi: load-test-loadtest-20260720132402-541913
#
# Gercek route yapisi:
#   /v/{slug}                   - magaza sayfasi (ilk 24 urun)
#   /v/{slug}?page=2            - ikinci sayfa
#   /v/{slug}?category=X        - kategori filtresi
#   /v/{slug}?q=X               - urun aramasi
#   /v/{slug}/urun/{slug}       - urun detay
#
# Kullanim:
#   .\scripts\load-test.ps1
#   .\scripts\load-test.ps1 -BaseUrl "http://localhost:3000"
#   .\scripts\load-test.ps1 -ConcurrentCount 50

param(
    [string]$BaseUrl = "http://localhost:3000",
    [string]$StoreSlug = "load-test-loadtest-20260720132402-541913",
    [string]$ProductSlug = "xml-test-urunu-9999",
    [string]$TestCategory = "c1db5c1c-b5e3-4875-a4f0-71d13af08359",
    [int]$ConcurrentCount = 20
)

$ErrorActionPreference = "Continue"
$allResults = @()
$totalStart = Get-Date

# --- .NET HttpClient ---

Add-Type -AssemblyName System.Net.Http

function New-HttpClient {
    $handler = [System.Net.Http.HttpClientHandler]::new()
    $handler.AutomaticDecompression = [System.Net.DecompressionMethods]::GZip -bor [System.Net.DecompressionMethods]::Deflate
    $client = [System.Net.Http.HttpClient]::new($handler)
    $client.Timeout = [TimeSpan]::FromSeconds(30)
    $client.DefaultRequestHeaders.Add("User-Agent", "VixRex-LoadTest/1.0")
    return $client
}

function Send-TimedRequest {
    param(
        [System.Net.Http.HttpClient]$Client,
        [string]$Url,
        [string]$Label
    )
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $response = $Client.GetAsync($Url).GetAwaiter().GetResult()
        $sw.Stop()
        $bytes = 0
        if ($response.Content) {
            $bytes = $response.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult().Length
        }
        $statusCode = [int]$response.StatusCode
        $isError = $statusCode -ge 400
        return [PSCustomObject]@{
            Label  = $Label
            Url    = $Url
            Status = $statusCode
            Ms     = [math]::Round($sw.Elapsed.TotalMilliseconds, 1)
            Size   = $bytes
            Error  = $isError
        }
    } catch {
        $sw.Stop()
        return [PSCustomObject]@{
            Label  = $Label
            Url    = $Url
            Status = "ERR"
            Ms     = [math]::Round($sw.Elapsed.TotalMilliseconds, 1)
            Size   = 0
            Error  = $true
        }
    }
}

function Invoke-ConcurrentRequests {
    param(
        [string]$Url,
        [int]$Count
    )
    $runspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $Count)
    $runspacePool.Open()
    $psInstances = @()

    for ($i = 1; $i -le $Count; $i++) {
        $ps = [PowerShell]::Create()
        $ps.RunspacePool = $runspacePool
        [void]$ps.AddScript({
            param($reqUrl, $label)
            Add-Type -AssemblyName System.Net.Http
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                $h = [System.Net.Http.HttpClientHandler]::new()
                $h.AutomaticDecompression = [System.Net.DecompressionMethods]::GZip -bor [System.Net.DecompressionMethods]::Deflate
                $c = [System.Net.Http.HttpClient]::new($h)
                $c.Timeout = [TimeSpan]::FromSeconds(30)
                $c.DefaultRequestHeaders.Add("User-Agent", "VixRex-LoadTest/1.0")
                $resp = $c.GetAsync($reqUrl).GetAwaiter().GetResult()
                $sw.Stop()
                $bts = 0
                if ($resp.Content) {
                    $bts = $resp.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult().Length
                }
                $sc = [int]$resp.StatusCode
                $c.Dispose()
                $h.Dispose()
                return [PSCustomObject]@{
                    Label = $label; Url = $reqUrl; Status = $sc
                    Ms = [math]::Round($sw.Elapsed.TotalMilliseconds, 1)
                    Size = $bts; Error = ($sc -ge 400)
                }
            } catch {
                $sw.Stop()
                return [PSCustomObject]@{
                    Label = $label; Url = $reqUrl; Status = "ERR"
                    Ms = [math]::Round($sw.Elapsed.TotalMilliseconds, 1)
                    Size = 0; Error = $true
                }
            }
        }).AddArgument($Url).AddArgument("eszamanli-" + $i)
        $psInstances += ,@{ Pipe = $ps; Handle = $ps.BeginInvoke() }
    }

    $results = @()
    foreach ($inst in $psInstances) {
        $data = $inst.Pipe.EndInvoke($inst.Handle)
        if ($data) { $results += $data }
        $inst.Pipe.Dispose()
    }
    $runspacePool.Close()
    $runspacePool.Dispose()
    return $results
}

function Show-TestResult {
    param(
        [string]$TestName,
        [array]$Items
    )
    if (-not $Items -or $Items.Count -eq 0) {
        Write-Host ("  " + $TestName + " - sonuc yok") -ForegroundColor DarkGray
        return
    }
    $times    = $Items | ForEach-Object { $_.Ms }
    $avg      = ($times | Measure-Object -Average).Average
    $min      = ($times | Measure-Object -Minimum).Minimum
    $max      = ($times | Measure-Object -Maximum).Maximum
    $okCount  = ($Items | Where-Object { -not $_.Error }).Count
    $errCount = ($Items | Where-Object { $_.Error }).Count

    Write-Host ("  " + $TestName) -ForegroundColor Yellow
    Write-Host ("    Istem sayisi:  " + $Items.Count) -ForegroundColor White
    Write-Host ("    Basarili:      " + $okCount) -ForegroundColor Green
    if ($errCount -gt 0) {
        Write-Host ("    Hata:          " + $errCount) -ForegroundColor Red
    } else {
        Write-Host ("    Hata:          " + $errCount) -ForegroundColor Green
    }
    Write-Host ("    En dusuk:      " + [math]::Round($min, 1) + "ms") -ForegroundColor White
    Write-Host ("    Ortalama:      " + [math]::Round($avg, 1) + "ms") -ForegroundColor White
    Write-Host ("    En yuksek:     " + [math]::Round($max, 1) + "ms") -ForegroundColor White
    $codes = ($Items | ForEach-Object { $_.Status } | Sort-Object -Unique) -join ", "
    Write-Host ("    Durum kodlari: " + $codes) -ForegroundColor Gray
}

# --- URL sabitleri ---

$storePage1  = $BaseUrl + "/v/" + $StoreSlug
$storePage2  = $BaseUrl + "/v/" + $StoreSlug + "?page=2"
$productUrl  = $BaseUrl + "/v/" + $StoreSlug + "/urun/" + $ProductSlug

if ($TestCategory) {
    $storeCategoryUrl = $BaseUrl + "/v/" + $StoreSlug + "?category=" + $TestCategory
} else {
    $storeCategoryUrl = ""
}
$storeSearchUrl = $BaseUrl + "/v/" + $StoreSlug + "?q=xml"

# --- Test basligi ---

Write-Host ""
Write-Host "=== VixRex Public Web Yuk Testi ===" -ForegroundColor Cyan
Write-Host ("Magaza:   " + $StoreSlug) -ForegroundColor Gray
Write-Host ("Urun:     " + $ProductSlug) -ForegroundColor Gray
Write-Host ("Base URL: " + $BaseUrl) -ForegroundColor Gray
Write-Host ("Kategori: " + $TestCategory) -ForegroundColor Gray
Write-Host ("Eslesmanli: " + $ConcurrentCount + " istek") -ForegroundColor Gray
Write-Host ""

# --- Seri testler ---

$client = New-HttpClient

Write-Host "[1/6] Magaza sayfasi (page=1)..." -ForegroundColor Green
$r1 = Send-TimedRequest -Client $client -Url $storePage1 -Label "magaza-p1"
$allResults += $r1
Write-Host ("  -> " + $r1.Status + " | " + $r1.Ms + "ms | " + [math]::Round($r1.Size/1024, 1) + "KB")

Write-Host "[2/6] Magaza sayfasi (page=2)..." -ForegroundColor Green
$r2 = Send-TimedRequest -Client $client -Url $storePage2 -Label "magaza-p2"
$allResults += $r2
Write-Host ("  -> " + $r2.Status + " | " + $r2.Ms + "ms | " + [math]::Round($r2.Size/1024, 1) + "KB")

if ($storeCategoryUrl) {
    Write-Host ("[3/6] Kategori filtresi (?category=" + $TestCategory + ")...") -ForegroundColor Green
    $r3 = Send-TimedRequest -Client $client -Url $storeCategoryUrl -Label "kategori"
    $allResults += $r3
    Write-Host ("  -> " + $r3.Status + " | " + $r3.Ms + "ms | " + [math]::Round($r3.Size/1024, 1) + "KB")
} else {
    Write-Host "[3/6] Kategori filtresi - atlandi (-TestCategory gerekli)" -ForegroundColor DarkGray
    $r3 = $null
}

Write-Host "[4/6] Urun aramasi (?q=xml)..." -ForegroundColor Green
$r4 = Send-TimedRequest -Client $client -Url $storeSearchUrl -Label "arama"
$allResults += $r4
Write-Host ("  -> " + $r4.Status + " | " + $r4.Ms + "ms | " + [math]::Round($r4.Size/1024, 1) + "KB")

Write-Host ("[5/6] Urun detay sayfasi (" + $ProductSlug + ")...") -ForegroundColor Green
$r5 = Send-TimedRequest -Client $client -Url $productUrl -Label "urun-detay"
$allResults += $r5
Write-Host ("  -> " + $r5.Status + " | " + $r5.Ms + "ms | " + [math]::Round($r5.Size/1024, 1) + "KB")

$client.Dispose()

# --- Eszamanli istekler (Runspace tabanli) ---

Write-Host ("[6/6] " + $ConcurrentCount + " eszamanli istek (magaza sayfasi)...") -ForegroundColor Green

$concurrentResults = Invoke-ConcurrentRequests -Url $storePage1 -Count $ConcurrentCount

foreach ($cr in $concurrentResults) {
    $allResults += $cr
}
Write-Host ("  Tamamlandi: " + $concurrentResults.Count + " istek") -ForegroundColor Gray

# --- Rapor ---

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "             RAPOR" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Show-TestResult -TestName "1. Magaza sayfasi (page=1)" -Items @($r1)
Show-TestResult -TestName "2. Magaza sayfasi (page=2)" -Items @($r2)
if ($r3) { Show-TestResult -TestName "3. Kategori filtresi" -Items @($r3) }
Show-TestResult -TestName "4. Urun aramasi (?q=xml)" -Items @($r4)
Show-TestResult -TestName "5. Urun detay sayfasi" -Items @($r5)
Show-TestResult -TestName ("6. Eszamanli istekler (" + $ConcurrentCount + ")") -Items $concurrentResults

Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor Gray
$allTimes    = $allResults | ForEach-Object { $_.Ms }
$allAvg      = ($allTimes | Measure-Object -Average).Average
$allMin      = ($allTimes | Measure-Object -Minimum).Minimum
$allMax      = ($allTimes | Measure-Object -Maximum).Maximum
$totalErrors = ($allResults | Where-Object { $_.Error }).Count
$totalOk     = ($allResults | Where-Object { -not $_.Error }).Count
$elapsed     = [math]::Round(((Get-Date) - $totalStart).TotalSeconds, 1)

Write-Host "  GENEL OZET" -ForegroundColor Cyan
Write-Host ("    Toplam istek:    " + $allResults.Count) -ForegroundColor White
Write-Host ("    Basarili:        " + $totalOk) -ForegroundColor Green
if ($totalErrors -gt 0) {
    Write-Host ("    Hata:            " + $totalErrors) -ForegroundColor Red
} else {
    Write-Host ("    Hata:            " + $totalErrors) -ForegroundColor Green
}
Write-Host ("    En dusuk sure:   " + [math]::Round($allMin, 1) + "ms") -ForegroundColor White
Write-Host ("    Ortalama sure:   " + [math]::Round($allAvg, 1) + "ms") -ForegroundColor White
Write-Host ("    En yuksek sure:  " + [math]::Round($allMax, 1) + "ms") -ForegroundColor White
Write-Host ("    Toplam sure:     " + $elapsed + "s") -ForegroundColor White
Write-Host ""

Write-Host "GERCEK ROUTE YAPISI:" -ForegroundColor DarkYellow
Write-Host ("  /v/" + $StoreSlug + "              - magaza (ilk 24 urun)") -ForegroundColor Gray
Write-Host ("  /v/" + $StoreSlug + "?page=2       - ikinci sayfa") -ForegroundColor Gray
Write-Host ("  /v/" + $StoreSlug + "?category=X   - kategori filtresi") -ForegroundColor Gray
Write-Host ("  /v/" + $StoreSlug + "?q=X          - urun aramasi") -ForegroundColor Gray
Write-Host ("  /v/" + $StoreSlug + "/urun/{slug}  - urun detay") -ForegroundColor Gray
Write-Host ""
Write-Host "NOTLAR:" -ForegroundColor DarkYellow
Write-Host "  - Sunucu tarafli sayfalama: 24 urun/sayfa, range() ile" -ForegroundColor Gray
Write-Host "  - Kategori + arama: Supabase ilike/equality ile sunucuda" -ForegroundColor Gray
Write-Host "  - ISR cache: magaza 60s, urun detay 300s" -ForegroundColor Gray
Write-Host "  - 4xx/5xx hata olarak sayilir" -ForegroundColor Gray
Write-Host "  - Runspace tabanli eszamanli olcum (PowerShell 5.1 uyumlu)" -ForegroundColor Gray
Write-Host ""
Write-Host "=== Yuk testi tamamlandi ===" -ForegroundColor Cyan
