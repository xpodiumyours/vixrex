#requires -Version 7.0
[CmdletBinding()]
param(
    [switch]$Json
)

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

if ($PSScriptRoot) { $repoRoot = Split-Path -Parent $PSScriptRoot } else { $repoRoot = (Get-Location).Path }
Set-Location -LiteralPath $repoRoot

$now = Get-Date
$notes = New-Object System.Collections.Generic.List[string]
$main = $null
$mainMsg = ''
$mainDate = ''
$live = $null
$liveBuilt = ''
$liveSource = ''
$prTotal = $null
$prDraft = $null
$localHead = ''
$localBranch = ''
$localDirty = 0
$localRef = ''
$defterLines = @()
$envKeys = @()
$envFile = Join-Path $repoRoot 'public_web/.env.local'
$mcpNames = @()
$graphify = 'YOK'
$health = [ordered]@{}
$warns = New-Object System.Collections.Generic.List[string]
$exitCode = 0
$verdict = ''

function Get-Short([string]$sha) {
    if ([string]::IsNullOrWhiteSpace($sha)) { return '' }
    if ($sha.Length -ge 7) { return $sha.Substring(0, 7) }
    return $sha
}

$ghOk = $null -ne (Get-Command gh -ErrorAction SilentlyContinue)
$gitOk = $null -ne (Get-Command git -ErrorAction SilentlyContinue)

if ($ghOk) {
    $raw = & gh api 'repos/xpodiumyours/vixrex/commits/main' --jq '{sha: .sha, msg: (.commit.message | split("\n")[0]), date: .commit.author.date}' 2>$null
    if ($LASTEXITCODE -eq 0 -and $raw) {
        try {
            $j = ($raw | Out-String) | ConvertFrom-Json
            $main = [string]$j.sha
            $mainMsg = [string]$j.msg
            $mainDate = [string]$j.date
        } catch { $notes.Add('ana dal yaniti okunamadi') }
    } else {
        $notes.Add('ana dal okunamadi (gh api)')
    }
} else {
    $notes.Add('gh bulunamadi')
}

try {
    $info = Invoke-RestMethod -Uri 'https://vixrex-public.vercel.app/deploy-info.json' -TimeoutSec 20
    $live = [string]$info.commit
    $liveBuilt = [string]$info.builtAt
    $liveSource = 'deploy-info.json'
} catch {
    $notes.Add('deploy-info.json bu ortamdan okunamadi; GitHub deployment kaydi denendi')
}

if (-not $live -and $ghOk) {
    $prodRaw = & gh api 'repos/xpodiumyours/vixrex/deployments?per_page=100' --jq '[.[] | select(.environment | test("Production"; "i"))][0] | {id: .id, sha: .sha, env: .environment, created: .created_at}' 2>$null
    if ($LASTEXITCODE -eq 0 -and $prodRaw) {
        try {
            $prod = ($prodRaw | Out-String) | ConvertFrom-Json
            if ($prod.sha) {
                $stRaw = & gh api ('repos/xpodiumyours/vixrex/deployments/{0}/statuses' -f $prod.id) --jq 'sort_by(.created_at) | .[-1] | .state' 2>$null
                $st = ''
                if ($stRaw) { $st = ([string]$stRaw).Trim() }
                if ($st -eq 'success') {
                    $live = [string]$prod.sha
                    $liveSource = 'GitHub deployment kaydi'
                    if ($prod.created -is [datetime]) {
                        $liveBuilt = $prod.created.ToUniversalTime().ToString('yyyy-MM-ddTHH:mmZ')
                    } else {
                        $liveBuilt = [string]$prod.created
                    }
                } else {
                    $notes.Add('canli deployment durumu: ' + $st)
                }
            } else {
                $notes.Add('Production deployment kaydi yok')
            }
        } catch { $notes.Add('deployment kaydi okunamadi') }
    } else {
        $notes.Add('deployment kaydi okunamadi (gh api)')
    }
}

if ($gitOk) {
    $h = & git rev-parse --short HEAD 2>$null
    if ($h) { $localHead = ([string]$h).Trim() }
    $b = & git branch --show-current 2>$null
    if ($b) { $localBranch = ([string]$b).Trim() }
    $d = @(& git status --porcelain=v1 2>$null | Where-Object { $_ -ne $null -and "$_".Trim() -ne '' })
    $localDirty = $d.Count
    $r = & git rev-parse --short origin/main 2>$null
    if ($r) { $localRef = ([string]$r).Trim() }
}

if ($ghOk) {
    $prRaw = & gh pr list --state open --limit 200 --json number,isDraft 2>$null
    if ($LASTEXITCODE -eq 0 -and $prRaw) {
        try {
            $prs = ($prRaw | Out-String) | ConvertFrom-Json
            $prTotal = @($prs).Count
            $prDraft = @($prs | Where-Object { $_.isDraft }).Count
        } catch { $notes.Add('PR listesi okunamadi') }
    } else {
        $notes.Add('PR listesi okunamadi')
    }
}

$defterPaths = @('C:\Projects\vixrex\CALISMA-DEFTERI.md', 'C:\Projects\Casper\DEFTER.md')
foreach ($p in $defterPaths) {
    $name = Split-Path -Leaf $p
    if (Test-Path -LiteralPath $p) {
        $it = Get-Item -LiteralPath $p
        $age = [math]::Floor((New-TimeSpan -Start $it.LastWriteTime -End $now).TotalDays)
        $defterLines += ("{0}: var · son yazim {1} · {2} gun once" -f $name, $it.LastWriteTime.ToString('yyyy-MM-dd HH:mm'), $age)
    } else {
        $defterLines += ("{0}: YOK (bu ortamda depo disi)" -f $name)
    }
}

if (Test-Path -LiteralPath $envFile) {
    $keys = @(Get-Content -LiteralPath $envFile | Where-Object { $_ -match '^\s*[A-Za-z_][A-Za-z0-9_]*\s*=' } | ForEach-Object { ($_ -split '=', 2)[0].Trim() } | Select-Object -Unique)
    $envKeys = $keys
}

$mcpPath = Join-Path $repoRoot '.mcp.json'
if (Test-Path -LiteralPath $mcpPath) {
    try {
        $mcp = Get-Content -LiteralPath $mcpPath -Raw | ConvertFrom-Json
        $mcpNames = @($mcp.mcpServers.PSObject.Properties.Name)
    } catch { $warns.Add('.mcp.json okunamadi') }
}
if ($mcpNames -contains 'graphify') { $graphify = 'TANIMLI' }

$docPath = Join-Path $repoRoot 'docs/AJAN-BASLANGIC.md'
$agentsPath = Join-Path $repoRoot 'AGENTS.md'
$readmePath = Join-Path $repoRoot 'README.md'
$health['AJAN-BASLANGIC belgesi'] = Test-Path -LiteralPath $docPath
$health['AGENTS kapi satiri'] = $false
$health['README harita baglantisi'] = $false
if (Test-Path -LiteralPath $agentsPath) {
    $health['AGENTS kapi satiri'] = (Get-Content -LiteralPath $agentsPath -Raw).Contains('tool/ajan-baslangic.ps1')
}
if (Test-Path -LiteralPath $readmePath) {
    $health['README harita baglantisi'] = (Get-Content -LiteralPath $readmePath -Raw).Contains('docs/AJAN-BASLANGIC.md')
}

$docAge = $null
if ($health['AJAN-BASLANGIC belgesi']) {
    $docText = Get-Content -LiteralPath $docPath -Raw
    if ($docText -match 'Son doğrulama:\s*(\d{4}-\d{2}-\d{2})') {
        $docDate = [datetime]::ParseExact($Matches[1], 'yyyy-MM-dd', $null)
        $docAge = [math]::Floor((New-TimeSpan -Start $docDate -End $now).TotalDays)
    }
}

$missing = @($health.Keys | Where-Object { -not $health[$_] })

$mainShort = Get-Short $main
$liveShort = Get-Short $live

if (-not $main) {
    $verdict = 'ÖLÇÜM EKSİK — ana dal okunamadı; durum cümlesi kurma.'
    $exitCode = 2
} elseif (-not $live) {
    $verdict = 'ÖLÇÜM EKSİK — canlı okunamadı; "canlıda" denmez.'
    $exitCode = 1
} elseif ($liveShort -ne $mainShort) {
    $verdict = 'CANLI ANA DALDAN AYRI — "canlıda" denmez; önce yayın kapısı.'
    $exitCode = 3
} else {
    $verdict = 'Ölçüm tam: canlı = ana dal. Durum cümlesi kurulabilir.'
    $exitCode = 0
}

if ($missing.Count -gt 0) {
    if ($exitCode -eq 0) { $exitCode = 4 }
    $verdict = $verdict + ' SİSTEM EKSİK: ' + ($missing -join ', ')
}

$logDir = Join-Path $repoRoot '.olcum/ajan'
$logFile = Join-Path $logDir 'acilis.log'
$previous = ''
try {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    if (Test-Path -LiteralPath $logFile) {
        $prevLine = Get-Content -LiteralPath $logFile -Tail 1
        if ($prevLine) { $previous = ([string]$prevLine).Split('|')[0].Trim() }
    }
    $logLine = ('{0} | ana={1} | canli={2} | hüküm={3}' -f $now.ToString('o'), $mainShort, $liveShort, $verdict)
    Add-Content -LiteralPath $logFile -Value $logLine -Encoding utf8
} catch {
    $warns.Add('acilis kaydi yazilamadi')
}

$mcpLine = 'YOK'
if ($mcpNames.Count -gt 0) { $mcpLine = ($mcpNames -join ', ') }

if ($Json) {
    $obj = [ordered]@{
        zaman = $now.ToString('o')
        ana_dal = $mainShort
        ana_dal_mesaj = $mainMsg
        ana_dal_tarih = $mainDate
        canli = $liveShort
        canli_derleme = $liveBuilt
        canli_kaynak = $liveSource
        canli_ana_dal = ($mainShort -ne '' -and $mainShort -eq $liveShort)
        yerel_head = $localHead
        yerel_dal = $localBranch
        yerel_kirli = $localDirty
        yerel_origin_main = $localRef
        yerel_ref_bayat = ($localRef -eq '' -or $localRef -ne $mainShort)
        acik_pr = $prTotal
        taslak_pr = $prDraft
        defterler = $defterLines
        anahtar_sayisi = $envKeys.Count
        anahtar_adlari = $envKeys
        mcp = $mcpNames
        graphify = $graphify
        sistem = $health
        belge_yasi_gun = $docAge
        hukum = $verdict
        cikis_kodu = $exitCode
        notlar = $notes
        uyarilar = $warns
    }
    $obj | ConvertTo-Json -Depth 4
    exit $exitCode
}

$mainLine = 'YOK'
if ($mainShort) {
    $msg = $mainMsg
    if ($msg.Length -gt 64) { $msg = $msg.Substring(0, 64) + '…' }
    $mainLine = ('{0}  ({1})' -f $mainShort, $msg)
}
$liveLine = 'YOK'
if ($liveShort) {
    $liveLine = ('{0}  ({1}: {2})' -f $liveShort, $liveSource, $liveBuilt)
}
$refLine = 'YOK'
if ($localRef) {
    if ($mainShort -and $localRef -ne $mainShort) { $refLine = ('{0}  BAYAT (ana dal {1})' -f $localRef, $mainShort) }
    elseif ($localRef -eq $mainShort) { $refLine = $localRef + '  guncel' }
}
$prLine = 'ÖLÇÜLEMEDİ'
if ($null -ne $prTotal) { $prLine = ('{0} acik · {1} taslak' -f $prTotal, $prDraft) }
$keyLine = 'env.local YOK'
if ($envKeys.Count -gt 0) {
    $req = @('OPENROUTER_API_KEY', 'SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY')
    $reqLine = ($req | ForEach-Object { if ($envKeys -contains $_) { $_ + ':var' } else { $_ + ':yok' } }) -join ' · '
    $keyLine = ('{0} ad · {1}' -f $envKeys.Count, $reqLine)
}
$graphifyLine = 'BAĞLI DEĞİL'
if ($graphify -eq 'TANIMLI') { $graphifyLine = 'TANIMLI (.mcp.json)' }
$healthLine = ($health.Keys | ForEach-Object { $mark = '✔'; if (-not $health[$_]) { $mark = '✖' }; $_ + ' ' + $mark }) -join ' · '
$docLine = 'YOK'
if ($docAge -ne $null) { $docLine = ('{0} gun once' -f $docAge) }
$prevLine = 'ilk acilis'
if ($previous) { $prevLine = $previous }

$out = @()
$out += ('VIXREX AÇILIŞ KAPISI · ' + $now.ToString('yyyy-MM-dd HH:mm zzz'))
$out += ('Ana dal    : ' + $mainLine)
$out += ('Canlı      : ' + $liveLine)
$out += ('Yerel      : ' + $localHead + ' · dal ' + $localBranch + ' · kirli ' + $localDirty + ' dosya')
$out += ('Yerel ref  : ' + $refLine)
$out += ('Açık PR    : ' + $prLine)
$out += ('Defter     : ' + ($defterLines -join ' | '))
$out += ('Anahtarlar : ' + $keyLine)
$out += ('MCP        : ' + $mcpLine)
$out += ('Harita     : ' + $graphifyLine)
$out += ('Belge tarihi: ' + $docLine)
$out += ('Sistem     : ' + $healthLine)
$out += ('Önceki     : ' + $prevLine)
$out += ('HÜKÜM      : ' + $verdict)
if ($notes.Count -gt 0) { $out += ('Not        : ' + ($notes -join ' | ')) }
if ($warns.Count -gt 0) { $out += ('Uyarı      : ' + ($warns -join ' | ')) }
$out | ForEach-Object { Write-Output $_ }

exit $exitCode
