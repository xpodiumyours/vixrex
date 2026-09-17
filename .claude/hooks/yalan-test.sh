#!/bin/bash
# Yalan yesil test freni — VixRex
#
# Neden: 26 parite testinin 23'u ekrana bakmiyor, kaynak kodda kelime ariyordu;
# bir gunde 4 yalan yesil uretti. Anayasa IV: "Kaynak kodda kelime arayan bir
# kontrol hicbir iddianin dayanagi olamaz."
#
# Kural: test klasorlerine, kaynagi okuyup metin arayan bir test yazilamaz.
# Davranis testi yazilir (gercek cikti calistirilir, ekran/veri olculur).

INPUT=$(cat)

if ! command -v node >/dev/null 2>&1; then
  echo "BLOCKED: node bulunamadi, yalan test kancasi calismadi. Kontrol calismiyorsa is ilerlemez (anayasa VII)." >&2
  exit 2
fi

HOOK_INPUT="$INPUT" PROJE="$CLAUDE_PROJECT_DIR" node -e '
let d = {};
try { d = JSON.parse(process.env.HOOK_INPUT || "{}"); } catch (e) {}

const ti = (d && d.tool_input) || {};
const ham = ti.file_path || "";
if (!ham) process.exit(0);

const proje = String(process.env.PROJE || process.cwd()).replace(/\\/g, "/").replace(/\/$/, "");
let p = String(ham).replace(/\\/g, "/");
if (p.toLowerCase().startsWith(proje.toLowerCase())) p = p.slice(proje.length).replace(/^\//, "");

const testDosyasi =
  /(^|\/)tests?\//.test(p) ||
  /\.(test|spec)\.(ts|tsx|js|jsx)$/.test(p) ||
  /(^|\/)test\//.test(p);
if (!testDosyasi) process.exit(0);

const yeni = String(ti.content || "") + "\n" + String(ti.new_string || "");
if (!yeni) process.exit(0);

const kaynagiOkuyor = /readFileSync|readFile\(|File\(|readAsString/.test(yeni);
const metindeAriyor = /toContain|toMatch|includes\(|\.split\(/.test(yeni);
const sayiyor = /\.split\(|match\(|grep|length\s*-\s*1/.test(yeni);

if (kaynagiOkuyor && (metindeAriyor || sayiyor)) {
  console.error("BLOCKED: " + p + " kaynak kodunu okuyup metin arayan bir test. Anayasa IV: boyle bir kontrol hicbir iddianin dayanagi olamaz (yesil olsa bile). Davranis testi yaz: gercek ciktiyi calistir, ekrani veya veriyi olc. Istisna gerekiyorsa Casper acikca soylemeli.");
  process.exit(2);
}

process.exit(0);
'
