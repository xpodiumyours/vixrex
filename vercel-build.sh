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
SENTRY_RELEASE="vixrex-app@$BUILD_COMMIT"
SENTRY_ENVIRONMENT="production"
if [ -n "${SENTRY_DSN:-}" ]; then
  SENTRY_CONFIGURED=true
else
  SENTRY_CONFIGURED=false
fi

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
  --dart-define=PUBLIC_SITE_URL="${PUBLIC_SITE_URL:-https://vixrex-public.vercel.app}" \
  --dart-define=SENTRY_DSN="${SENTRY_DSN:-}" \
  --dart-define=SENTRY_RELEASE="$SENTRY_RELEASE" \
  --dart-define=SENTRY_ENVIRONMENT="$SENTRY_ENVIRONMENT" \
  --dart-define=INSTAGRAM_SYNC_ENABLED="${INSTAGRAM_SYNC_ENABLED:-false}"

if grep -q "showScoreCard" build/web/main.dart.js; then
  echo "Stale web build detected: showScoreCard is still present in main.dart.js." >&2
  exit 1
fi

cat > build/web/deploy-info.json <<EOF
{
  "commit": "$BUILD_COMMIT",
  "builtAt": "$BUILD_TIME",
  "sentryConfigured": $SENTRY_CONFIGURED,
  "sentryRelease": "$SENTRY_RELEASE",
  "sentryEnvironment": "$SENTRY_ENVIRONMENT",
  "pwaStrategy": "none"
}
EOF
