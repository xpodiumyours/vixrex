# Vixrex local runner — defines come from dart_defines.local.json (no broken --dart flags).
# Usage:
#   .\run.ps1
#   .\run.ps1 chrome
#   .\run.ps1 edge
#   .\run.ps1 windows
#   .\run.ps1 -Device chrome -Port 5000

param(
  [Parameter(Position = 0)]
  [string]$Device = 'chrome',
  [int]$Port = 5000
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$definesFile = Join-Path $PSScriptRoot 'dart_defines.local.json'
if (-not (Test-Path $definesFile)) {
  Write-Host 'Missing dart_defines.local.json' -ForegroundColor Red
  Write-Host 'Copy dart_defines.example.json -> dart_defines.local.json and fill values.'
  exit 1
}

$flutterArgs = @(
  'run',
  '-d', $Device,
  "--dart-define-from-file=$definesFile"
)

if ($Device -eq 'chrome' -or $Device -eq 'edge' -or $Device -eq 'web-server') {
  $flutterArgs += @('--web-port', "$Port")
}

Write-Host "flutter $($flutterArgs -join ' ')" -ForegroundColor Cyan
flutter @flutterArgs
