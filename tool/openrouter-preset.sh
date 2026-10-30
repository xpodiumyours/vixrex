#!/usr/bin/env bash
set -euo pipefail
KOK=$(cd "$(dirname "$0")/.." && pwd)
ORTAM="$KOK/public_web/.env"
ANAHTAR=$(grep -m1 '^OPENROUTER_MANAGEMENT_API_KEY=' "$ORTAM" | cut -d= -f2-)
TEMEL=${OPENROUTER_BASE_URL:-https://openrouter.ai/api/v1}
komut=${1:-}
case "$komut" in
  liste)
    curl -s -H "Authorization: Bearer $ANAHTAR" "$TEMEL/presets"
    ;;
  oku)
    curl -s -H "Authorization: Bearer $ANAHTAR" "$TEMEL/presets/$2/versions/$3"
    ;;
  yukle)
    curl -s -X POST -H "Authorization: Bearer $ANAHTAR" -H 'Content-Type: application/json' -d @"$2" "$TEMEL/presets/$3/chat/completions"
    ;;
  *)
    echo "kullanım: tool/openrouter-preset.sh liste | oku <slug> <surum> | yukle <govde.json> <slug>"
    exit 1
    ;;
esac
