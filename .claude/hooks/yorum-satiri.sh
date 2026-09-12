#!/bin/bash
#
# Yorum satiri sensoru — VixRex
#
# Neden: CLAUDE.md "Varsayim + tahmin + yorum yasagi" (2026-09-09, Casper)
# kod icine yorum satiri eklemeyi yasakliyor. Kural metindi, olcen yoktu.
#
# Bu bir SENSOR, kapi degil: duzenleme zaten yapildi, kanca ajana "yorum
# ekledin" diye geri besler, ajan kendi temizler. Casper beklemez.
# Basarida tamamen sessiz, ihlalde ayrintili (Osmani: success-silent,
# failures-verbose).

INPUT=$(cat)

command -v node >/dev/null 2>&1 || exit 0

SONUC=$(printf '%s' "$INPUT" | node -e '
  let d = "";
  process.stdin.on("data", c => d += c);
  process.stdin.on("end", () => {
    let j;
    try { j = JSON.parse(d); } catch (e) { return; }
    const t = j?.tool_input || {};
    const yol = t.file_path || "";
    if (!/\.(ts|tsx|js|jsx|dart|mjs|cjs)$/.test(yol)) return;
    if (t.new_string === undefined || t.old_string === undefined) return;

    const yorumlar = (metin) => {
      const sayac = new Map();
      for (const ham of String(metin).split("\n")) {
        const s = ham.trim();
        if (/^(\/\/|\/\*|\*\s|\*$)/.test(s)) sayac.set(s, (sayac.get(s) || 0) + 1);
      }
      return sayac;
    };

    const eski = yorumlar(t.old_string);
    const yeni = yorumlar(t.new_string);
    const eklenen = [];
    for (const [satir, adet] of yeni) {
      const fark = adet - (eski.get(satir) || 0);
      for (let i = 0; i < fark; i++) eklenen.push(satir);
    }
    if (eklenen.length) {
      process.stdout.write(eklenen.slice(0, 5).join("\n"));
    }
  });
')

if [ -n "$SONUC" ]; then
  echo "KURAL IHLALI — kod icine yorum satiri eklendi. CLAUDE.md 'yorum yasagi' (2026-09-09, Casper) bunu yasakliyor. Eklenen satirlar:" >&2
  echo "$SONUC" >&2
  echo "Bu satirlari kaldir. Aciklama gerekiyorsa koda degil, Casper'a mesajda yaz." >&2
  exit 2
fi

exit 0
