#requires -Version 7.0
[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

$ana = 'C:\Projects\vixrex'
$kok = 'C:\Projects'
$fbKok = Join-Path $env:USERPROFILE '.freebuff\worktrees'
$bulutKok = Join-Path $env:USERPROFILE '.config\freebuff-desktop\cloud-projects'

function Get-GitDurum([string]$yol) {
    $dal = (& git -C $yol branch --show-current 2>$null) -join ''
    $head = (& git -C $yol rev-parse --short HEAD 2>$null) -join ''
    $kirli = @(& git -C $yol status --porcelain 2>$null | Where-Object { "$_".Trim() -ne '' }).Count
    $remote = (& git -C $yol remote 2>$null | Select-Object -First 1)
    [pscustomobject]@{
        Dal = if ($dal) { $dal } else { '(detached)' }
        Head = if ($head) { $head } else { '-' }
        Kirli = [int]$kirli
        Remote = if ($remote) { 'var' } else { 'YOK' }
    }
}

$satirlar = @()

function Ekle([string]$yer, [string]$tur, [string]$yol) {
    if (-not (Test-Path -LiteralPath $yol)) { return }
    $g = Get-GitDurum $yol
    $hukum = 'temiz'
    if ($g.Remote -eq 'YOK') { $hukum = 'KOPYA - çalışma yeri değil' }
    elseif ($g.Kirli -gt 0) { $hukum = 'SAHİPSİZ İŞ (' + $g.Kirli + ' dosya)' }
    if ($yol -eq $ana) {
        if ($g.Kirli -gt 0) { $hukum = 'ANA KLASÖR - kirli ' + $g.Kirli } else { $hukum = 'ANA KLASÖR' }
    }
    $script:satirlar += [pscustomobject]@{ Yer = $yer; Tur = $tur; Dal = $g.Dal; Head = $g.Head; Kirli = $g.Kirli; Remote = $g.Remote; Hukum = $hukum }
}

Ekle 'C:\Projects\vixrex' 'ana' $ana

Get-ChildItem -LiteralPath $kok -Directory -Filter 'vixrex*' -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -ne $ana } |
    ForEach-Object { Ekle $_.FullName 'klasör' $_.FullName }

if (Test-Path -LiteralPath $fbKok) {
    Get-ChildItem -LiteralPath $fbKok -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $hash = $_.Name
        Get-ChildItem -LiteralPath $_.FullName -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            Ekle ('freebuff:' + $hash) 'kopya' $_.FullName
        }
    }
}

$bulutSayi = 0
if (Test-Path -LiteralPath $bulutKok) {
    $bulutSayi = @(Get-ChildItem -LiteralPath $bulutKok -Directory -ErrorAction SilentlyContinue).Count
}

$icWorktree = @()
$wt = & git -C $ana worktree list 2>$null
foreach ($satir in @($wt)) {
    if (-not $satir) { continue }
    $yol = ($satir -split '\s+')[0]
    if ($yol -and $yol -ne 'C:/Projects/vixrex' -and (Test-Path -LiteralPath $yol)) {
        $g = Get-GitDurum $yol
        $h = 'boş worktree'
        if ($g.Kirli -gt 0) { $h = 'SAHİPSİZ İŞ (' + $g.Kirli + ' dosya)' }
        $icWorktree += [pscustomobject]@{ Yer = $yol; Tur = 'iç worktree'; Dal = $g.Dal; Head = $g.Head; Kirli = $g.Kirli; Remote = $g.Remote; Hukum = $h }
    }
}

Write-Host 'VIXREX KOPYA DURUMU · ölçüm salt okunur'
Write-Host ('Ana klasör : ' + $ana)
Write-Host ('Bulut kopya: ' + $bulutSayi + ' klasör')
Write-Host ''
$hepsi = @($satirlar) + @($icWorktree)
if ($hepsi.Count -eq 0) {
    Write-Host 'HATA: hiçbir yer okunamadı.'
} else {
    $hepsi | Format-Table -AutoSize Yer, Tur, Dal, Head, Kirli, Remote, Hukum | Out-String -Width 220 | Write-Host
}

$sahipli = @($hepsi | Where-Object { $_.Hukum -like 'SAHİPSİZ*' })
$kopya = @($hepsi | Where-Object { $_.Hukum -like 'KOPYA*' })
Write-Host ('Özet: ' + $hepsi.Count + ' yer · sahipsiz iş ' + $sahipli.Count + ' · çalışma yeri olmayan kopya ' + $kopya.Count)
if ($sahipli.Count -gt 0) { Write-Host 'Uyarı: sahipsiz işi olan kopya silinmez; önce dal/commit/PR kararı verilir.' }
if ($kopya.Count -gt 0) { Write-Host 'Not: kopya (remote yok) yalnız okuma içindir; ölçüm ana klasörde koşulur.' }
