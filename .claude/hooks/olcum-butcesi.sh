#!/usr/bin/env bash
# Ölçüm bütçesi — Casper, 2026-09-20.
#
# Kural: iki iş çıktısı (commit) arasında en fazla OLCUM_LIMIT tarama/ölçüm
# komutu. Sayaç HEAD değişince sıfırlanır; yani ölçüm ancak iş üretildikçe
# yeniden hak edilir. Amaç: "araştırıyorum" diye saatlerce token yakmayı
# mekanizmayla durdurmak, sözle değil.

set -u

OLCUM_LIMIT="${VIXREX_OLCUM_LIMIT:-12}"

girdi="$(cat)"

okuma="$(printf '%s' "$girdi" | python -c 'import json,sys
try:
    d = json.load(sys.stdin)
except Exception:
    print("|"); raise SystemExit
g = d.get("tool_input") or {}
print((d.get("tool_name") or "") + "|" + (g.get("command") or ""))' 2>/dev/null)"

arac="${okuma%%|*}"
komut="${okuma#*|}"

# Arama araçları her çağrıda ölçüm sayılır. Bash tarafında yalnız
# tarama/araştırma kalıpları sayılır; dosya okuma, test koşma, derleme ve
# düzenleme işleri sayılmaz — onlar iş üretir.
case "$arac" in
  Grep|Glob) ;;
  *)
    [ -z "$komut" ] && exit 0
    case "$komut" in
      *"grep -r"*|*"grep -R"*|*"rg "*|*"find "*|*"ls -R"*|\
      *"gh run view"*|*"gh run list"*|*"gh api"*|*"gh search"*|\
      *"curl "*|*"git log"*|*"git grep"*) ;;
      *) exit 0 ;;
    esac
    ;;
esac

proje_dizini="${CLAUDE_PROJECT_DIR:-.}"
durum_dizini="$proje_dizini/.claude/.olcum"
mkdir -p "$durum_dizini" 2>/dev/null || exit 0

head_simdi="$(
  {
    git -C "$proje_dizini" rev-parse HEAD 2>/dev/null
    git -C "$proje_dizini" worktree list --porcelain 2>/dev/null \
      | awk '/^worktree /{print $2}' \
      | while IFS= read -r wt; do git -C "$wt" rev-parse HEAD 2>/dev/null; done
  } | sort -u | tr '\n' ' '
)"
[ -z "$head_simdi" ] && head_simdi="bilinmiyor"
head_dosya="$durum_dizini/head"
sayac_dosya="$durum_dizini/sayac"

head_onceki="$(cat "$head_dosya" 2>/dev/null || echo "")"
if [ "$head_simdi" != "$head_onceki" ]; then
  printf '%s' "$head_simdi" > "$head_dosya"
  printf '0' > "$sayac_dosya"
fi

sayac="$(cat "$sayac_dosya" 2>/dev/null || echo 0)"
case "$sayac" in (*[!0-9]*|'') sayac=0 ;; esac
sayac=$((sayac + 1))
printf '%s' "$sayac" > "$sayac_dosya"

if [ "$sayac" -gt "$OLCUM_LIMIT" ]; then
  cat >&2 <<EOF
OLCUM BUTCESI DOLDU — bu commit'ten beri $sayac tarama komutu calistirildi (sinir: $OLCUM_LIMIT).

Casper'in kurali (2026-09-20): "Olculere daha cok token ve zaman ayiriyorsun."
Butce ancak IS URETILINCE yenilenir: bir commit at, ya da elindeki sonucu
Casper'a tek satirda soyle ve devam et.

Gercekten baska care yoksa: VIXREX_OLCUM_LIMIT degerini yukselt.
EOF
  exit 2
fi

exit 0
