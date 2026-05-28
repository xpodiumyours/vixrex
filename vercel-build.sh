#!/usr/bin/env bash
set -euo pipefail

if [ -z "${SUPABASE_URL:-}" ] || [ -z "${SUPABASE_PUBLISHABLE_KEY:-}" ]; then
  echo "Missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY." >&2
  echo "Add both variables in Vercel Project Settings > Environment Variables." >&2
  exit 1
fi

FLUTTER_HOME="${FLUTTER_HOME:-$PWD/.vercel/flutter}"

if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  rm -rf "$FLUTTER_HOME"
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH"

flutter config --enable-web
flutter pub get
flutter build web --release \
  --base-href="/" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY" \
  --dart-define=PUBLIC_SITE_URL="${PUBLIC_SITE_URL:-}"
