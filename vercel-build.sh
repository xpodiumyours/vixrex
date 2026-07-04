#!/usr/bin/env bash
set -euo pipefail

if [ -z "${SUPABASE_URL:-}" ] || [ -z "${SUPABASE_PUBLISHABLE_KEY:-}" ]; then
  echo "Missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY." >&2
  echo "Add both variables in Vercel Project Settings > Environment Variables." >&2
  exit 1
fi

FLUTTER_HOME="${FLUTTER_HOME:-$PWD/.vercel/flutter}"
BUILD_COMMIT="${VERCEL_GIT_COMMIT_SHA:-$(git rev-parse HEAD 2>/dev/null || echo unknown)}"
BUILD_TIME="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  rm -rf "$FLUTTER_HOME"
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH"

flutter config --enable-web
flutter clean
flutter pub get
rm -rf build/web

flutter build web --release \
  --base-href="/" \
  --pwa-strategy=none \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY" \
  --dart-define=PUBLIC_SITE_URL="${PUBLIC_SITE_URL:-}" \
  --dart-define=INSTAGRAM_SYNC_ENABLED="${INSTAGRAM_SYNC_ENABLED:-false}" \
  --dart-define=LEGAL_DATA_CONTROLLER_TITLE="${LEGAL_DATA_CONTROLLER_TITLE:-}" \
  --dart-define=LEGAL_DATA_CONTROLLER_ADDRESS="${LEGAL_DATA_CONTROLLER_ADDRESS:-}" \
  --dart-define=LEGAL_MERSIS_NUMBER="${LEGAL_MERSIS_NUMBER:-}" \
  --dart-define=LEGAL_TAX_NUMBER="${LEGAL_TAX_NUMBER:-}" \
  --dart-define=LEGAL_PRIVACY_EMAIL="${LEGAL_PRIVACY_EMAIL:-}"

if grep -q "showScoreCard" build/web/main.dart.js; then
  echo "Stale web build detected: showScoreCard is still present in main.dart.js." >&2
  exit 1
fi

cat > build/web/deploy-info.json <<EOF
{
  "commit": "$BUILD_COMMIT",
  "builtAt": "$BUILD_TIME",
  "pwaStrategy": "none"
}
EOF
