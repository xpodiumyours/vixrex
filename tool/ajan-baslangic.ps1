#requires -Version 7.0
[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$Kod
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
$graphPath = Join-Path $repoRoot 'graphify-out/graph.json'
$graphSay = 'YOK'
$graphFresh = $false
$graphNode = ''
$graphEdge = ''
$graphMtime = ''
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
    $r = & git rev-parse origin/main 2>$null
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
$health['Ajan baglanti betigi'] = Test-Path -LiteralPath (Join-Path $repoRoot 'tool/baglanti-olcum.mjs')
$health['AGENTS harita kurali'] = $false
if (Test-Path -LiteralPath $agentsPath) {
    $health['AGENTS harita kurali'] = ((Get-Content -LiteralPath $agentsPath -Raw) -match '(?i)graphify')
}
$health['Preset dosyalari'] = ((Test-Path -LiteralPath (Join-Path $repoRoot 'openrouter/preset-okuma.json')) -and (Test-Path -LiteralPath (Join-Path $repoRoot 'openrouter/preset-kart.json')) -and (Test-Path -LiteralPath (Join-Path $repoRoot 'openrouter/preset-gorsel-secim.json')))
$health['Graphify kancasi'] = $false
$hookPath = Join-Path $repoRoot '.git/hooks/post-commit'
if (Test-Path -LiteralPath $hookPath) { $health['Graphify kancasi'] = ((Get-Content -LiteralPath $hookPath -Raw) -match '(?i)graphify') }
$health['README tarihsel etiket'] = $false
if (Test-Path -LiteralPath $readmePath) { $health['README tarihsel etiket'] = ((Get-Content -LiteralPath $readmePath -Raw) -match '(?i)tarihsel') }

$docAge = $null
if ($health['AJAN-BASLANGIC belgesi']) {
    $docText = Get-Content -LiteralPath $docPath -Raw
    if ($docText -match 'Son doğrulama:\s*(\d{4}-\d{2}-\d{2})') {
        $docDate = [datetime]::ParseExact($Matches[1], 'yyyy-MM-dd', $null)
        $docAge = [math]::Floor((New-TimeSpan -Start $docDate -End $now).TotalDays)
    }
}
if ($docAge -ne $null -and $docAge -gt 30) { $warns.Add('belge 30+ gun bayat: ' + $docAge + ' gun') }

$graphCli = ''
$graphVer = ''
$cliCmd = Get-Command graphify -ErrorAction SilentlyContinue
if ($cliCmd) { $graphCli = $cliCmd.Source }
elseif (Test-Path -LiteralPath (Join-Path $env:USERPROFILE '.local\bin\graphify.exe')) { $graphCli = Join-Path $env:USERPROFILE '.local\bin\graphify.exe' }
if ($graphCli) {
    try { $gv = & $graphCli --version 2>$null; if ($gv) { $graphVer = ([string]($gv | Select-Object -First 1)).Trim() } } catch { }
}
if (Test-Path -LiteralPath $graphPath) {
    $gi = Get-Item -LiteralPath $graphPath
    $graphMtime = $gi.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
    $graphSay = 'HAZIR'
    try {
        $cnt = & node -e "const g=require(process.argv[1]);const n=(g.nodes||[]).length;const e=(g.links||g.edges||[]).length;console.log(n+' '+e)" $graphPath 2>$null
        if ($cnt) { $c = ([string]$cnt).Trim().Split(' '); $graphNode = $c[0]; $graphEdge = $c[1] }
    } catch { }
    $lc = & git log -1 --format=%ct -- lib public_web shared 2>$null
    $lcEpoch = 0
    if ($lc) { try { $lcEpoch = [int64]([string]$lc).Trim() } catch { } }
    if ($lcEpoch -gt 0) {
        $gEpoch = [int64]([DateTimeOffset]$gi.LastWriteTimeUtc).ToUnixTimeSeconds()
        $graphFresh = ($gEpoch -ge $lcEpoch)
    } else { $graphFresh = $true }
    if (-not $graphFresh) { $graphSay = 'BAYAT' }
}

$probePath = Join-Path $repoRoot 'tool/baglanti-olcum.mjs'
$probeMap = @{}
if ((Test-Path -LiteralPath $probePath) -and (Get-Command node -ErrorAction SilentlyContinue)) {
    try {
        $probeRaw = & node $probePath 2>$null
        if ($probeRaw) {
            $probeObj = ($probeRaw | Out-String) | ConvertFrom-Json
            foreach ($p in $probeObj.probes) { $probeMap[[string]$p.ad] = $p }
        }
    } catch { $warns.Add('baglanti olcumu calistirilamadi') }
}

function Probe-Durum([string]$ad) {
    if ($probeMap.ContainsKey($ad)) { return [string]$probeMap[$ad].durum }
    return 'OLCULMEDI'
}
function Probe-Http([string]$ad) {
    if ($probeMap.ContainsKey($ad)) { return [int]$probeMap[$ad].http }
    return 0
}
function Durum-Tr([string]$d) {
    switch ($d) {
        'BAGLI' { return 'BAĞLI' }
        'YETKISIZ' { return 'YETKİSİZ' }
        'ERISILEMEDI' { return 'ERİŞİLEMEDİ' }
        'ANAHTAR_YOK' { return 'ANAHTAR YOK' }
        'KISITLI' { return 'KISITLI (depo yetkisi yok)' }
        'OLCULMEDI' { return 'ÖLÇÜLMEDİ' }
        default { return 'HATA' }
    }
}

$ghUser = ''
$ghStatus = 'YOK'
if ($ghOk) {
    $authText = & gh auth status 2>&1
    if ($LASTEXITCODE -eq 0) {
        $ghStatus = 'BAGLI'
        if (($authText | Out-String) -match 'account\s+(\S+)') { $ghUser = $Matches[1] }
    } elseif (($authText | Out-String) -match '(?i)not logged') { $ghStatus = 'YETKISIZ' }
    else { $ghStatus = 'ERISILEMEDI' }
}

$vercelWho = ''
$vercelStatus = 'YOK'
if ($null -ne (Get-Command vercel -ErrorAction SilentlyContinue)) {
    $vw = & vercel whoami 2>$null
    if ($LASTEXITCODE -eq 0 -and $vw) {
        $vercelStatus = 'BAGLI'
        $vercelWho = ([string]($vw | Select-Object -Last 1)).Trim()
    } else { $vercelStatus = 'YETKISIZ' }
}

$graphLineFull = 'YOK'
if ($graphSay -eq 'HAZIR' -or $graphSay -eq 'BAYAT') {
    $parca = @()
    if ($graphNode) { $parca += ($graphNode + ' düğüm') }
    if ($graphEdge) { $parca += ($graphEdge + ' bağlantı') }
    if ($graphMtime) { $parca += ('harita ' + $graphMtime) }
    if ($graphVer) { $parca += $graphVer }
    $graphLineFull = ('YEREL ' + $graphSay + ' (' + ($parca -join ' · ') + ')')
}
$graphLineFull = $graphLineFull + ' · MCP ' + (Durum-Tr (Probe-Durum 'graphify_mcp'))
if ($mcpNames -contains 'graphify') { $graphLineFull = $graphLineFull + ' (.mcp.json)' }

$platforms = [ordered]@{
    github = [ordered]@{ durum = $ghStatus; kullanici = $ghUser }
    vercel = [ordered]@{ durum = $vercelStatus; kullanici = $vercelWho; mcp = (Probe-Durum 'vercel_mcp'); mcp_http = (Probe-Http 'vercel_mcp') }
    supabase = [ordered]@{ durum = (Probe-Durum 'supabase_rest'); http = (Probe-Http 'supabase_rest'); mcp = (Probe-Durum 'supabase_mcp'); mcp_http = (Probe-Http 'supabase_mcp') }
    openrouter = [ordered]@{ durum = (Probe-Durum 'openrouter_models'); http = (Probe-Http 'openrouter_models'); presets = (Probe-Durum 'openrouter_presets'); presets_http = (Probe-Http 'openrouter_presets') }
}

$pLines = @()
$pLines += ('GitHub     : ' + (Durum-Tr $ghStatus) + $(if ($ghUser) { ' (' + $ghUser + ')' } else { '' }))
$pLines += ('Vercel     : ' + (Durum-Tr $vercelStatus) + $(if ($vercelWho) { ' (CLI: ' + $vercelWho + ')' } else { '' }) + ' · MCP ' + (Durum-Tr (Probe-Durum 'vercel_mcp')))
$pLines += ('Supabase   : ' + (Durum-Tr (Probe-Durum 'supabase_rest')) + ' (REST ' + (Probe-Http 'supabase_rest') + ') · MCP ' + (Durum-Tr (Probe-Durum 'supabase_mcp')))
$presetFiles = @(Get-ChildItem -LiteralPath (Join-Path $repoRoot 'openrouter') -Filter 'preset-*.json' -ErrorAction SilentlyContinue)
$presetLine = 'YOK'
if ($presetFiles.Count -gt 0) { $presetLine = 'depoda (' + $presetFiles.Count + ' dosya)' }
$pLines += ('OpenRouter : ' + (Durum-Tr (Probe-Durum 'openrouter_models')) + ' (modeller ' + (Probe-Http 'openrouter_models') + ') · preset ' + $presetLine + ' · API ' + (Durum-Tr (Probe-Durum 'openrouter_presets')))

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
    $kapsam = 'BILINMIYOR'
    if ($ghOk -and $live -and $main) {
        $cmpRaw = & gh api ('repos/xpodiumyours/vixrex/compare/{0}...{1}' -f $live, $main) --jq '{status: .status, files: [.files[].filename]}' 2>$null
        if ($cmpRaw) {
            try {
                $cmp = ($cmpRaw | Out-String) | ConvertFrom-Json
                $yuzey = $false
                foreach ($f in @($cmp.files)) {
                    $p = ([string]$f).Replace('\', '/')
                    $notr = $false
                    if ($p -match '(?i)\.md$') { $notr = $true }
                    elseif ($p -match '^(docs|\.github|\.agents|\.cursor|\.obsidian)/') { $notr = $true }
                    elseif ($p -in @('.gitignore', '.gitattributes', 'LICENSE', 'README.md', 'AGENTS.md', 'CLAUDE.md')) { $notr = $true }
                    if (-not $notr) { $yuzey = $true; break }
                }
                if ($cmp.status -eq 'ahead' -and -not $yuzey) { $kapsam = 'BELGE' }
                elseif ($cmp.status -eq 'ahead') { $kapsam = 'KOD' }
            } catch { }
        }
    }
    if ($kapsam -eq 'BELGE') {
        $verdict = 'CANLI GERİDE — aradaki fark yalnız belge; yayın atlandı (beklenen). Durum cümlesi kurulabilir.'
        $exitCode = 0
    } else {
        $verdict = 'CANLI ANA DALDAN AYRI — "canlıda" denmez; önce yayın kapısı.'
        $exitCode = 3
    }
} else {
    $verdict = 'Ölçüm tam: canlı = ana dal. Durum cümlesi kurulabilir.'
    $exitCode = 0
}

if ($missing.Count -gt 0) {
    if ($exitCode -eq 0) { $exitCode = 4 }
    $verdict = $verdict + ' SİSTEM EKSİK: ' + ($missing -join ', ')
}

if ($Kod -and -not $graphFresh) {
    if ($exitCode -eq 0) { $exitCode = 5 }
    $verdict = $verdict + ' HARİTA BAYAT/YOK — kod değişikliği yok; önce graphify update .'
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
        yerel_ref_bayat = ($localRef -eq '' -or $localRef -ne $main)
        acik_pr = $prTotal
        taslak_pr = $prDraft
        defterler = $defterLines
        anahtar_sayisi = $envKeys.Count
        anahtar_adlari = $envKeys
        mcp = $mcpNames
        graphify = [ordered]@{ durum = $graphSay; dugum = $graphNode; baglanti = $graphEdge; harita_zamani = $graphMtime; taze = $graphFresh; mcp = (Probe-Durum 'graphify_mcp'); tanimli = ($graphify -eq 'TANIMLI') }
        platformlar = $platforms
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
    if ($main -and $localRef -ne $main) { $refLine = ('{0}  BAYAT (ana dal {1})' -f (Get-Short $localRef), $mainShort) }
    elseif ($main -and $localRef -eq $main) { $refLine = (Get-Short $localRef) + '  guncel' }
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
$out += ('Graphify   : ' + $graphLineFull)
$out += $pLines
$out += ('Sınır      : salt okunur ölçüm; yazma/deploy/migration/preset yalnız açık onayla')
$out += ('Belge tarihi: ' + $docLine)
$out += ('Sistem     : ' + $healthLine)
$out += ('Önceki     : ' + $prevLine)
$out += ('HÜKÜM      : ' + $verdict)
if ($notes.Count -gt 0) { $out += ('Not        : ' + ($notes -join ' | ')) }
if ($warns.Count -gt 0) { $out += ('Uyarı      : ' + ($warns -join ' | ')) }
$out | ForEach-Object { Write-Output $_ }

exit $exitCode
