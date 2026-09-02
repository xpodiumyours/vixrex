#!/bin/bash
# Claude Code (web) SessionStart hook — bu iki ayrı uygulamayı (Flutter panel
# + Next.js public_web) her yeni oturumda lint/test/build çalıştırılabilir
# hale getirir. Yalnız Claude Code on the web'de koşar (CLAUDE_CODE_REMOTE).
#
# İdempotent: npm ci ve flutter pub get zaten güncelse hızlı biter,
# container state koşumlar arasında önbelleklendiği için Flutter'ın ilk
# kurulumu bir kereliğine yavaş, sonraki oturumlarda hızlı olur.
#
# NEDEN `npm install` DEĞİL `npm ci` (2026-09-02): `npm install`, yerel npm
# sürümü package-lock.json'ı üreten sürümden farklıysa lockfile'ı sessizce
# yeniden yazıyordu (optional dependency girdilerinden "libc" alanlarını
# siliyordu) — hook'un işi olmayan, commit'e karışma riski taşıyan bir yan
# etki. `npm ci` lockfile'ı ASLA değiştirmez, yalnız onunla birebir kurar
# (package.json ile uyuşmazsa hata verir) — CI'nın (ci.yml) kendisinin de
# kullandığı komut, yani yerelde gördüğün kurulum CI'yla birebir aynı.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

REPO_ROOT="$CLAUDE_PROJECT_DIR"

# Kurulum araçlarının (npm ci, flutter pub get, ...) takip edilen dosyaları
# YAN ETKİ olarak değiştirmesine karşı güvenlik ağı — hook'un tek işi
# ortamı hazırlamak, git working tree'yi değiştirmek değil.
restore_if_dirty() {
  local f="$1"
  if [ -f "$f" ] && ! git -C "$REPO_ROOT" diff --quiet -- "$f" 2>/dev/null; then
    echo "UYARI: $f kurulum sırasında değişti, commit'lenmiş hâline geri alınıyor." >&2
    git -C "$REPO_ROOT" checkout -- "$f"
  fi
}

# ── 1) Next.js (public_web) ────────────────────────────────────────────────
if [ -f "$REPO_ROOT/public_web/package.json" ]; then
  echo "== public_web: npm ci =="
  (cd "$REPO_ROOT/public_web" && npm ci)
  restore_if_dirty "public_web/package-lock.json"
fi

# ── 2) Flutter panel (lib/) ─────────────────────────────────────────────────
# ci.yml'deki FLUTTER_VERSION ile aynı sürüm — CI'da göreceğin hatalarla
# burada gördüklerin arasında sürüm farkı olmasın diye pinlenmiş.
FLUTTER_VERSION="3.44.4"
FLUTTER_HOME="$HOME/.flutter-sdk"

if ! command -v flutter >/dev/null 2>&1 && [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  echo "== Flutter $FLUTTER_VERSION kuruluyor ($FLUTTER_HOME) =="
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi

if [ -x "$FLUTTER_HOME/bin/flutter" ]; then
  export PATH="$FLUTTER_HOME/bin:$PATH"
  echo "export PATH=\"$FLUTTER_HOME/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

if command -v flutter >/dev/null 2>&1; then
  echo "== flutter pub get =="
  (cd "$REPO_ROOT" && flutter pub get)
  restore_if_dirty "pubspec.lock"
else
  echo "UYARI: flutter PATH'te bulunamadı, 'flutter pub get' atlandı." >&2
fi
