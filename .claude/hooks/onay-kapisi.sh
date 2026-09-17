#!/bin/bash

INPUT=$(cat)

if ! command -v node >/dev/null 2>&1; then
  echo "BLOCKED: kanca yukunu cozecek node yok; riske girmemek icin reddedildi." >&2
  exit 2
fi

OKUNAN=$(printf '%s' "$INPUT" | node -e '
  let d = "";
  process.stdin.on("data", c => d += c);
  process.stdin.on("end", () => {
    let yol = "", komut = "";
    try {
      const j = JSON.parse(d);
      const t = j?.tool_input || {};
      yol = String(t.file_path || "");
      komut = String(t.command || "").replace(/\s+/g, " ");
    } catch (e) {}
    process.stdout.write(yol + "\n" + komut);
  });
')

YOL=$(printf '%s\n' "$OKUNAN" | sed -n 1p)
KOMUT=$(printf '%s\n' "$OKUNAN" | sed -n 2p)

KORUNAN='(lib|public_web/src|supabase/migrations|shared)/'

HEDEF=""
if [ -n "$YOL" ]; then
  GORECELI=${YOL#"$CLAUDE_PROJECT_DIR"/}
  if printf '%s' "$GORECELI" | grep -qE "^$KORUNAN"; then
    HEDEF="$GORECELI"
  fi
elif [ -n "$KOMUT" ]; then
  if printf '%s' "$KOMUT" | grep -qE "(>>?[[:space:]]*[\"']?$KORUNAN|sed[[:space:]]+-i[^|;]*[[:space:]]$KORUNAN|tee[[:space:]]+[^|;]*$KORUNAN|(cp|mv)[[:space:]]+[^|;]*[[:space:]]$KORUNAN)"; then
    HEDEF="kabuk komutu"
  fi
fi

[ -z "$HEDEF" ] && exit 0

cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || exit 0

IS=""
if [ -f .specify/feature.json ]; then
  IS=$(node -e '
    const fs = require("fs");
    try {
      const j = JSON.parse(fs.readFileSync(".specify/feature.json", "utf8"));
      process.stdout.write(String(j.feature_dir || j.featureDir || j.path || ""));
    } catch (e) {}
  ' 2>/dev/null)
  IS=${IS#"$PWD"/}
fi

if [ -z "$IS" ] || [ ! -d "$IS" ]; then
  IS=$(ls -dt specs/*/ 2>/dev/null | head -1)
fi
IS=${IS%/}

if [ -z "$IS" ]; then
  echo "BLOCKED: $HEDEF urun kodudur, acik is kaydi yok. Once specs/<is>/kesif.md yazilir ve onayi alinir." >&2
  exit 2
fi

[ -f "$IS/root-cause.md" ] && exit 0

if [ -f "$IS/kesif.md" ] && grep -qE '^[[:space:]]*ONAY:[[:space:]]*alındı[[:space:]]*$' "$IS/kesif.md"; then
  exit 0
fi

echo "BLOCKED: $HEDEF urun kodudur. Acik is: $IS — kesif.md icinde 'ONAY: alındı' satiri yok." >&2
echo "Once kesfi yaz, Furkan'a sun, onayi kayda gecir; sonra uygula. Hata duzeltmesinde $IS/root-cause.md yeterlidir." >&2
exit 2
