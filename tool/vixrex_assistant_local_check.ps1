[CmdletBinding()]
param(
  [switch]$Full,
  [switch]$Install,
  [switch]$Build
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Invoke-Checked {
  param(
    [Parameter(Mandatory = $true)][string]$Label,
    [Parameter(Mandatory = $true)][scriptblock]$Command
  )
  Write-Host "`n=== $Label ===" -ForegroundColor Cyan
  & $Command
  if ($LASTEXITCODE -ne 0) {
    throw "$Label başarısız (exit=$LASTEXITCODE)."
  }
}

$nextTests = @(
  "tests/vixrex-46-alan-davranis-denetimi.test.ts",
  "tests/vixrex-validation-parity.test.ts",
  "tests/vixrex-dogal-netlestirme-kabul.test.ts",
  "tests/vixrex-dogal-netlestirme-pipeline.test.ts",
  "tests/vixrex-general-fallback-parity.test.ts",
  "tests/assistant-cross-client-memory-contract.test.ts",
  "tests/owner-assistant-real-undo-contract.test.ts",
  "tests/assistant-db-value-validation-contract.test.ts",
  "tests/vixrex-46-alan-yayin-yasal-kapi.test.ts"
)

$flutterTests = @(
  "test/vixrex_nlu_46_alan_guvenlik_test.dart",
  "test/vixrex_validation_parity_test.dart",
  "test/vixrex_dogal_netlestirme_kabul_test.dart",
  "test/vixrex_dogal_netlestirme_pipeline_test.dart",
  "test/vixrex_general_intent_parity_test.dart",
  "test/vixrex_pending_slot_context_test.dart",
  "test/vixrex_executor_temizleme_test.dart",
  "test/vixrex_46_alan_executor_kapsam_test.dart",
  "test/vixrex_yayin_yasal_kapi_test.dart"
)

Push-Location $root
try {
  if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw "Node.js bulunamadı." }
  if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { throw "npm bulunamadı." }
  if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw "Flutter bulunamadı." }
  if (-not (Get-Command dart -ErrorAction SilentlyContinue)) { throw "Dart bulunamadı." }

  Push-Location (Join-Path $root "public_web")
  try {
    if ($Install -or -not (Test-Path "node_modules")) {
      Invoke-Checked "Next bağımlılıkları" { npm ci }
    }

    if ($Full) {
      Invoke-Checked "Next lint" { npm run lint }
      Invoke-Checked "Next TypeScript" { npx tsc --noEmit }
      Invoke-Checked "Next tüm testler" { npm run test }
    } else {
      Invoke-Checked "Next Assistant hedefli testler" { npm run test -- @nextTests }
    }

    if ($Build) {
      if (-not $env:NEXT_PUBLIC_SUPABASE_URL -or -not $env:NEXT_PUBLIC_SUPABASE_ANON_KEY) {
        throw "Build için NEXT_PUBLIC_SUPABASE_URL ve NEXT_PUBLIC_SUPABASE_ANON_KEY gerekli."
      }
      Invoke-Checked "Next production build" { npm run build }
    }
  }
  finally {
    Pop-Location
  }

  if ($Install -or -not (Test-Path ".dart_tool/package_config.json")) {
    Invoke-Checked "Flutter bağımlılıkları" { flutter pub get }
  }

  if ($Full) {
    Invoke-Checked "Dart biçim kontrolü" { dart format --output=none --set-exit-if-changed lib test }
    Invoke-Checked "Dart statik analiz" { dart analyze --fatal-infos }
    Invoke-Checked "Flutter tüm testler" { flutter test --reporter expanded }
  } else {
    Invoke-Checked "Assistant Dart biçim kontrolü" {
      dart format --output=none --set-exit-if-changed `
        lib/services/vixrex_nlu `
        lib/config/vitrin_alanlari.g.dart `
        test/vixrex_nlu_46_alan_guvenlik_test.dart `
        test/vixrex_validation_parity_test.dart `
        test/vixrex_dogal_netlestirme_kabul_test.dart `
        test/vixrex_dogal_netlestirme_pipeline_test.dart `
        test/vixrex_general_intent_parity_test.dart `
        test/vixrex_pending_slot_context_test.dart `
        test/vixrex_executor_temizleme_test.dart `
        test/vixrex_46_alan_executor_kapsam_test.dart `
        test/vixrex_yayin_yasal_kapi_test.dart
    }

    foreach ($test in $flutterTests) {
      Invoke-Checked "Flutter $test" { flutter test $test --reporter expanded }
    }
  }

  Write-Host "`nVixrex Assistant yerel kontrol kapısı YEŞİL." -ForegroundColor Green
}
finally {
  Pop-Location
}
