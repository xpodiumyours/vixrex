# Yerel gelistirme — deploy YOK
# Panel :5000  |  Musteri vitrini :3000  |  PUBLIC_SITE_URL=localhost:3000
#
# Tek komut:
#   .\dev.ps1
#
# Sonra:
#   Panel:  http://localhost:5000/app
#   Vitrin: http://localhost:3000/v/SLUG
#   (Kesfet'ten vitrin acmak da localhost:3000'e gider)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$defines = Join-Path $PSScriptRoot 'dart_defines.local.json'
if (-not (Test-Path $defines)) {
  Write-Host 'Eksik: dart_defines.local.json' -ForegroundColor Red
  exit 1
}

# LOCAL — canli vercel degil
$json = Get-Content $defines -Raw | ConvertFrom-Json
$json.PUBLIC_SITE_URL = 'http://localhost:3000'
$json | ConvertTo-Json | Set-Content $defines -Encoding utf8

if (-not (Test-Path (Join-Path $PSScriptRoot 'public_web\node_modules'))) {
  Write-Host 'public_web npm install...' -ForegroundColor Yellow
  Push-Location (Join-Path $PSScriptRoot 'public_web')
  npm install
  Pop-Location
}

if (-not (Test-Path (Join-Path $PSScriptRoot 'public_web\.env.local'))) {
  Write-Host 'Eksik: public_web\.env.local (Supabase)' -ForegroundColor Red
  exit 1
}

Write-Host ''
Write-Host '  Panel:  http://localhost:5000/app' -ForegroundColor Cyan
Write-Host '  Vitrin: http://localhost:3000/v/SLUG' -ForegroundColor Cyan
Write-Host ''

# Next ayri pencerede (kapanmasin)
Start-Process powershell -WorkingDirectory $PSScriptRoot -ArgumentList @(
  '-NoExit', '-NoProfile', '-ExecutionPolicy', 'Bypass',
  '-Command', "Set-Location '$PSScriptRoot\public_web'; npm run dev -- -p 3000"
)

Start-Sleep -Seconds 2

# Flutter bu pencerede
& (Join-Path $PSScriptRoot 'run.ps1')
