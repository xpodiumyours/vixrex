# Tek komut: müşteri vitrini (Next.js) yerel
# Kullanım: .\run_public.ps1
# Açılınca: http://localhost:3000/v/SLUG

$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot 'public_web')

if (-not (Test-Path '.\node_modules')) {
  Write-Host 'node_modules yok — npm install calisiyor...' -ForegroundColor Yellow
  npm install
}

if (-not (Test-Path '.\.env.local')) {
  Write-Host 'Eksik: public_web\.env.local' -ForegroundColor Red
  exit 1
}

Write-Host 'http://localhost:3000/v/SENIN-SLUG' -ForegroundColor Cyan
npm run dev -- -p 3000
