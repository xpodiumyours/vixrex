#!/bin/bash
# Claude Code (web) SessionStart hook — bu iki ayrı uygulamayı (Flutter panel
# + Next.js public_web) her yeni oturumda lint/test/build çalıştırılabilir
# hale getirir. Yalnız Claude Code on the web'de koşar (CLAUDE_CODE_REMOTE).
#
# İdempotent: npm install ve flutter pub get zaten güncelse hızlı biter,
# container state koşumlar arasında önbelleklendiği için Flutter'ın ilk
# kurulumu bir kereliğine yavaş, sonraki oturumlarda hızlı olur.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

REPO_ROOT="$CLAUDE_PROJECT_DIR"

# ── 1) Next.js (public_web) ────────────────────────────────────────────────
if [ -f "$REPO_ROOT/public_web/package.json" ]; then
  echo "== public_web: npm install =="
  (cd "$REPO_ROOT/public_web" && npm install)
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
else
  echo "UYARI: flutter PATH'te bulunamadı, 'flutter pub get' atlandı." >&2
fi
