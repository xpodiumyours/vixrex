#!/usr/bin/env bash
#
# merge-hazir.sh — VixRex merge kapısı
#
# NE İŞE YARAR
# "MERGE READY" kaydını elle yazmayı bitirir. Kayıttaki her satır bu script'in
# kendi ölçümüdür: testi kendisi koşturur, çıktısına bakar, öyle yazar. Bir kapı
# düşerse kayıt hiç basılmaz ve komut hata koduyla çıkar.
#
# NEDEN VAR (2026-09-07)
# Aynı gün üç kez "geçti/yenilendi/sırada" denildi, üçü de ölçülmemişti:
#   - gelmeyecek bir yeşil beklendi (secret taraması kota yüzünden hiç koşmuyordu),
#   - "güncel main ile yenilendi" denen dal bir commit gerideydi,
#   - "test sırada" denen iş çoktan iptal olmuştu.
# Bunların hiçbiri kural eksikliği değildi; durumu okumadan durum bildirmekti.
# Metin bunu engellemiyor, ölçüm engelliyor.
#
# KULLANIM
#   bash tool/merge-hazir.sh
#
# Bulunduğun dalı ölçer. Çıkış kodu 0 ise merge edilebilir, değilse edilemez.
#
# KAPSAMADIĞI ŞEY
# Risk sınıfı KIRMIZI olan işler (Supabase göçü, RLS/GRANT, oturum/kimlik,
# ödeme, secret/env, üretim veritabanı) bu script yeşil verse bile kullanıcı
# onayı olmadan merge edilmez. Script bunu bilemez, sadece uyarır.

set -uo pipefail

KOK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$KOK" || exit 2

GITLEAKS_SURUM="8.30.1"

kirmizi=0
SONUC_SATIRLARI=()
UYARILAR=()

basari() { SONUC_SATIRLARI+=("$1: PASS"); }
hata()   { SONUC_SATIRLARI+=("$1: FAIL"); kirmizi=1; }
atlandi(){ SONUC_SATIRLARI+=("$1: -"); }
uyar()   { UYARILAR+=("$1"); }

baslik() { printf '\n=== %s\n' "$1"; }

# --- 0) Ön koşullar ---------------------------------------------------------

baslik "Ön koşullar"

DAL="$(git rev-parse --abbrev-ref HEAD)"
if [ "$DAL" = "main" ]; then
  echo "HATA: main üzerindesin. Merge kapısı bir çalışma dalında koşturulur."
  exit 2
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "HATA: kaydedilmemiş değişiklik var. Ölçüm ancak commit edilmiş hâl üzerinde anlamlı."
  git status --short | grep -v '^??'
  exit 2
fi

echo "Uzak depo tazeleniyor..."
git fetch origin main --quiet || uyar "origin/main tazelenemedi; ölçüm yerel kopyaya göre yapıldı."

# HEAD burada dondurulur. Script'in sonunda tekrar bakılır: bir satır kod
# değişmişse kayıt geçersiz sayılır.
SHA="$(git rev-parse HEAD)"
MAIN_SHA="$(git rev-parse origin/main)"
echo "HEAD      : $SHA"
echo "BASE MAIN : $MAIN_SHA"

# --- 1) Dal güncel main'i içeriyor mu ---------------------------------------

baslik "Güncel main içeriliyor mu"

if git merge-base --is-ancestor origin/main HEAD; then
  echo "Evet."
  basari "Güncel main içeriliyor"
else
  GERIDE="$(git log --oneline HEAD..origin/main | wc -l | tr -d ' ')"
  echo "HAYIR — dal, main'in $GERIDE commit'ini içermiyor:"
  git log --oneline HEAD..origin/main
  echo
  echo "Çözüm: dalı güncel main ile birleştir, sonra bu script'i tekrar koştur."
  hata "Güncel main içeriliyor"
fi

# --- 2) Kaydedilmemiş dosya uyarısı -----------------------------------------
# CI yalnız kaydedilmiş dosyaları görür. Yerelde duran kayıtsız dosyalar
# özellikle lint sonucunu değiştirebilir; ölçümü bozmasın diye listelenir.

KAYITSIZ="$(git ls-files --others --exclude-standard -- public_web lib test shared supabase | head -20)"
if [ -n "$KAYITSIZ" ]; then
  uyar "Kayıtsız dosyalar var; lint/test sonucu CI'dan farklı çıkabilir:"
  while IFS= read -r satir; do uyar "    $satir"; done <<< "$KAYITSIZ"
fi

# --- 3) Değişen yüzeyler ----------------------------------------------------

baslik "Değişen yüzeyler"

YUZEYLER="$(python .github/scripts/changed_surfaces.py --base origin/main --head HEAD 2>/dev/null)"
if [ -z "$YUZEYLER" ]; then
  echo "Yüzey sınıflandırıcı çalışmadı; ihtiyatlı davranılıp hepsi koşturuluyor."
  YUZEYLER=$'flutter=true\nschema=true\npublic_web=true'
fi
echo "$YUZEYLER"

deger() { echo "$YUZEYLER" | grep -E "^$1=" | cut -d= -f2; }
PW="$(deger public_web)"
FL="$(deger flutter)"
SC="$(deger schema)"

# --- 4) Next.js kapıları ----------------------------------------------------

if [ "$PW" = "true" ]; then
  baslik "Next.js — lint"
  if (cd public_web && npm run lint >/tmp/mh-lint.log 2>&1); then
    basari "Next lint"
  else
    tail -20 /tmp/mh-lint.log
    hata "Next lint"
  fi

  baslik "Next.js — tip kontrolü"
  if (cd public_web && npx tsc --noEmit >/tmp/mh-tsc.log 2>&1); then
    basari "TypeScript"
  else
    tail -20 /tmp/mh-tsc.log
    hata "TypeScript"
  fi

  baslik "Next.js — testler"
  if (cd public_web && npm run test >/tmp/mh-test.log 2>&1); then
    grep -E "Test Files|  Tests" /tmp/mh-test.log | tail -2
    basari "Tests"
  else
    grep -E "^\s+×|Test Files|  Tests" /tmp/mh-test.log | tail -15
    hata "Tests"
  fi

  baslik "Next.js — üretim derlemesi"
  if (cd public_web && npm run build >/tmp/mh-build.log 2>&1); then
    basari "Production build"
  else
    tail -25 /tmp/mh-build.log
    hata "Production build"
  fi
else
  atlandi "Next lint"; atlandi "TypeScript"; atlandi "Tests"; atlandi "Production build"
fi

# --- 5) Flutter kapıları ----------------------------------------------------

if [ "$FL" = "true" ]; then
  baslik "Flutter — biçim"
  if dart format --output=none --set-exit-if-changed lib test >/tmp/mh-fmt.log 2>&1; then
    basari "Dart format"
  else
    tail -15 /tmp/mh-fmt.log
    hata "Dart format"
  fi

  baslik "Flutter — analiz"
  if dart analyze --fatal-infos >/tmp/mh-analyze.log 2>&1; then
    basari "Dart analyze"
  else
    tail -20 /tmp/mh-analyze.log
    hata "Dart analyze"
  fi

  baslik "Flutter — testler"
  if flutter test >/tmp/mh-fltest.log 2>&1; then
    basari "Flutter tests"
  else
    tail -25 /tmp/mh-fltest.log
    hata "Flutter tests"
  fi
else
  atlandi "Dart format"; atlandi "Dart analyze"; atlandi "Flutter tests"
fi

# --- 6) Şema sapması --------------------------------------------------------
# shared/*.json değiştiyse üretilen dosyalar tazelenip fark aranır. Fark varsa
# üretim çalıştırılmamış demektir; CI da aynı yerde düşer.

if [ "$SC" = "true" ]; then
  baslik "Şema üretim hattı — sapma"
  {
    (cd public_web && npx tsx ../tool/sema_disa_aktar.ts) &&
    dart run tool/alan_semasi_uret.dart &&
    dart run tool/business_categories_uret.dart &&
    dart run tool/mesaj_semasi_uret.dart &&
    dart format lib/config/vitrin_alanlari.g.dart \
                lib/config/business_categories.g.dart \
                lib/config/vixrex_mesajlar.g.dart
  } >/tmp/mh-sema.log 2>&1

  if git diff --quiet; then
    basari "Schema drift"
  else
    echo "Üretilen dosyalar kaynakla uyuşmuyor — üretim komutları çalıştırılmamış:"
    git diff --stat
    hata "Schema drift"
  fi
else
  atlandi "Schema drift"
fi

# --- 7) Secret taraması -----------------------------------------------------
# Her zaman koşar. "Altyapı hatası, geç" muafiyeti burada YOKTUR: taramanın
# çalışmaması geçti sayılmaz.

baslik "Secret taraması"

KUR="/tmp/gitleaks-${GITLEAKS_SURUM}"
mkdir -p "$KUR"
if [ ! -x "$KUR/gitleaks.exe" ] && [ ! -x "$KUR/gitleaks" ]; then
  PAKET="gitleaks_${GITLEAKS_SURUM}_windows_x64.zip"
  if curl -fsSL -o "$KUR/$PAKET" \
      "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_SURUM}/${PAKET}" 2>/dev/null; then
    ZIPW="$(cygpath -w "$KUR/$PAKET" 2>/dev/null || echo "$KUR/$PAKET")"
    DIZINW="$(cygpath -w "$KUR" 2>/dev/null || echo "$KUR")"
    powershell -NoProfile -Command \
      "Expand-Archive -Path '$ZIPW' -DestinationPath '$DIZINW' -Force" >/dev/null 2>&1
  fi
fi

GL=""
[ -x "$KUR/gitleaks.exe" ] && GL="$KUR/gitleaks.exe"
[ -z "$GL" ] && [ -x "$KUR/gitleaks" ] && GL="$KUR/gitleaks"

if [ -z "$GL" ]; then
  echo "gitleaks kurulamadı. Tarama koşmadı — bu GEÇTİ sayılmaz."
  hata "Secret scan"
elif "$GL" git . -c .gitleaks.toml --redact --no-banner >/tmp/mh-gitleaks.log 2>&1; then
  grep -E "commits scanned|no leaks" /tmp/mh-gitleaks.log | tail -2
  basari "Secret scan"
else
  tail -20 /tmp/mh-gitleaks.log
  hata "Secret scan"
fi

# --- 8) Riskli yüzey uyarısı ------------------------------------------------
# Bu script bir değişikliğin gerçekten tehlikeli olup olmadığını anlayamaz;
# yalnız hangi dosyaların dokunulduğuna bakıp kullanıcıya haber verir.

RISKLI="$(git diff --name-only origin/main...HEAD | grep -E '^(supabase/|.*auth|.*session|.*payment|.*odeme)' | head -10)"
if [ -n "$RISKLI" ]; then
  uyar "KIRMIZI sınıf olabilecek dosyalar değişti — kullanıcı onayı olmadan merge etme:"
  while IFS= read -r satir; do uyar "    $satir"; done <<< "$RISKLI"
fi

# --- 9) SHA hâlâ aynı mı ----------------------------------------------------

SON_SHA="$(git rev-parse HEAD)"
if [ "$SON_SHA" != "$SHA" ]; then
  echo
  echo "HATA: ölçüm sırasında HEAD değişti ($SHA -> $SON_SHA). Kayıt geçersiz."
  exit 2
fi

# --- 10) Kayıt --------------------------------------------------------------

echo
echo "----------------------------------------"
if [ "$kirmizi" -eq 0 ]; then
  echo "MERGE READY"
else
  echo "MERGE READY DEĞİL"
fi
echo "Dal       : $DAL"
echo "HEAD      : $SHA"
echo "BASE MAIN : $MAIN_SHA"
echo
for satir in "${SONUC_SATIRLARI[@]}"; do echo "$satir"; done

if [ "${#UYARILAR[@]}" -gt 0 ]; then
  echo
  echo "Uyarılar:"
  for satir in "${UYARILAR[@]}"; do echo "  $satir"; done
fi

echo "----------------------------------------"

if [ "$kirmizi" -eq 0 ]; then
  echo "Bu kayıt yalnız $SHA için geçerlidir. Bir satır kod değişirse geçersizdir."
  exit 0
fi
exit 1
