#!/bin/bash
# Bitti kapisi — VixRex
#
# Neden: "gonderdim" demek canlida duzeldi demek degil. 18 is main deydi,
# 11 i canlida degildi; bir PR indi ama veritabani degisikligi canliya
# uygulanmadi. Anayasa IV: dalda duruyor / ana dala indi / yayina dagitildi /
# canlida dogrulandi dort ayri seydir.
#
# Kural: aktif is varken kayit yapmadan once, is kaydinin Durum bolumunde
# bu dort durumdan hangisi oldugu isaretlenmis olmali.

INPUT=$(cat)

if ! command -v node >/dev/null 2>&1; then
  echo "BLOCKED: node bulunamadi, bitti kapisi calismadi. Kontrol calismiyorsa is ilerlemez (anayasa VII)." >&2
  exit 2
fi

HOOK_INPUT="$INPUT" PROJE="$CLAUDE_PROJECT_DIR" node -e '
let d = {};
try { d = JSON.parse(process.env.HOOK_INPUT || "{}"); } catch (e) {}
const komut = String(((d && d.tool_input) || {}).command || "");
if (!/git\s+commit/.test(komut)) process.exit(0);

const fs = require("fs");
const path = require("path");
const proje = process.env.PROJE || process.cwd();

if (!fs.existsSync(path.join(proje, ".claude", "aktif-is.json"))) process.exit(0);

const klasor = path.join(proje, "docs", "is-kayitlari");
if (!fs.existsSync(klasor)) {
  console.error("BLOCKED: aktif is var ama docs/is-kayitlari yok. Is kaydi yazilmadan kayit yapilmaz.");
  process.exit(2);
}

const dosyalar = fs.readdirSync(klasor).filter(function (f) { return f.endsWith(".md"); });
if (dosyalar.length === 0) {
  console.error("BLOCKED: aktif is var ama is kaydi yok. Once docs/is-kayitlari/<tarih>-<konu>.md yazilir.");
  process.exit(2);
}

const yollar = dosyalar.map(function (f) { return path.join(klasor, f); });
yollar.sort(function (a, b) { return fs.statSync(b).mtimeMs - fs.statSync(a).mtimeMs; });
const icerik = fs.readFileSync(yollar[0], "utf8");

const i = icerik.indexOf("Durum");
if (i < 0) {
  console.error("BLOCKED: is kaydinda Durum bolumu yok (" + path.basename(yollar[0]) + "). Dort durumdan hangisi oldugu yazilmali.");
  process.exit(2);
}
const durumBolumu = icerik.slice(i);
if (durumBolumu.indexOf("\u2611") < 0) {
  console.error(
    "BLOCKED: is kaydinin Durum bolumunde hicbir durum isaretlenmemis. " +
    "Dordunu ayir: dalda duruyor / ana dala indi / yayina dagitildi / canlida dogrulandi. " +
    "Bunlar birbirinin yerine kullanilmaz (anayasa IV). Kayit: " + path.basename(yollar[0])
  );
  process.exit(2);
}
process.exit(0);
'
