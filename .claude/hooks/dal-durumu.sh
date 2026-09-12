#!/bin/bash
#
# Dal durumu sensoru — VixRex
#
# Neden: memory/dal-push-canliyi-degistirmez.md ve
# memory/vixrex-ci-tuzaklari.md — "gonderdim" demek canlida duzeldi demek
# degil. Dal / ana dal / canli ayrimi defalarca karisti.
#
# Bu kanca kayit veya gonderme komutundan SONRA gercek durumu olcup ajanin
# baglamina enjekte eder. Boylece rapor tahmine degil olcume dayanir.

INPUT=$(cat)
command -v node >/dev/null 2>&1 || exit 0

KOMUT=$(printf '%s' "$INPUT" | node -e '
  let d = "";
  process.stdin.on("data", c => d += c);
  process.stdin.on("end", () => {
    try { process.stdout.write(JSON.parse(d)?.tool_input?.command || ""); } catch (e) {}
  });
')

printf '%s' "$KOMUT" | grep -qE 'git\s+(commit|push)|gh\s+pr\s+(create|merge)|git\s+merge' || exit 0

cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || exit 0

DAL=$(git branch --show-current 2>/dev/null)
[ -z "$DAL" ] && exit 0

KIRLI=$(git status --porcelain 2>/dev/null | grep -vc '^??' )
UST=$(git rev-parse --abbrev-ref "@{upstream}" 2>/dev/null)

if [ -n "$UST" ]; then
  SAYIM=$(git rev-list --left-right --count "$UST"...HEAD 2>/dev/null)
  GERI=$(echo "$SAYIM" | cut -f1)
  ILERI=$(echo "$SAYIM" | cut -f2)
  UZAK="uzakta: $UST, gonderilmemis $ILERI kayit, gerideki $GERI kayit"
else
  UZAK="bu dalin uzak karsiligi YOK — hicbir sey gonderilmedi"
fi

if [ "$DAL" = "main" ]; then
  YER="ANA DAL uzerindesin"
else
  YER="ozellik dali: $DAL (ana dal degil)"
fi

MESAJ="OLCULEN DURUM: $YER. $UZAK. Kayda girmemis $KIRLI degisiklik var. Casper'a rapor verirken dal / ana dal / canli ayrimini bu olcume gore yaz; 'canlida duzeldi' demeden once canli yayini ayrica dogrula."

node -e '
  const m = process.argv[1];
  process.stdout.write(JSON.stringify({
    hookSpecificOutput: { hookEventName: "PostToolUse", additionalContext: m }
  }));
' "$MESAJ"

exit 0
