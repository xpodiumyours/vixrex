#!/bin/bash
#
# Canli anahtar sizintisi kancasi — VixRex
#
# Neden: 2026-08-19'da anon + service_role jetonlari yanlislikla bir oturum
# dokumune yazildi (memory/vixrex-api-anahtar-sizinti-bekliyor.md). Kural
# metin olarak vardi, engel yoktu. Bu kanca o engeli koyar.
#
# Alan ADINA bakmaz, DEGER SEKLINE bakar (memory/anahtar-gosterme-dersi.md):
# bir alanin adi "SAFE_KEY" olabilir ama icindeki sey yine de canli jetondur.

INPUT=$(cat)

if command -v node >/dev/null 2>&1; then
  ICERIK=$(printf '%s' "$INPUT" | node -e '
    let d = "";
    process.stdin.on("data", c => d += c);
    process.stdin.on("end", () => {
      try {
        const j = JSON.parse(d);
        const t = j?.tool_input || {};
        process.stdout.write([t.new_string, t.content].filter(Boolean).join("\n"));
      } catch (e) {}
    });
  ')
else
  echo "BLOCKED: kanca yukunu cozecek node yok; riske girmemek icin reddedildi." >&2
  exit 2
fi

[ -z "$ICERIK" ] && exit 0

SIZINTI=(
  "eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\."
  "sk-[A-Za-z0-9_-]{32,}"
  "sk_live_[A-Za-z0-9]{16,}"
  "ghp_[A-Za-z0-9]{30,}"
  "github_pat_[A-Za-z0-9_]{30,}"
  "AIza[A-Za-z0-9_-]{30,}"
)

for kalip in "${SIZINTI[@]}"; do
  if printf '%s' "$ICERIK" | grep -qE "$kalip"; then
    echo "BLOCKED: yazmak uzere oldugun icerik canli bir anahtar/jeton sekline uyuyor. Bu yazma iptal edildi. Degeri dosyaya gomme; ortam degiskeni kullan. Gercekten gerekiyorsa Casper'a soyle, kararini o versin." >&2
    exit 2
  fi
done

exit 0
