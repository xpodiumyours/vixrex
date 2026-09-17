#!/bin/bash
# Is siniri freni — VixRex
#
# Neden: 2026-09-17 urun karti isinde onayli ekran listesi yazilmadigi icin
# kategoriye ozel alanlar yanlis yuzeye cizildi. Kapsam calisirken buyudu.
# Anayasa I (zincir atlanmaz), III (etkilenen yuzeyler ayni iste), VI (kapsam kilitli).
#
# Kural: aktif is kaydi (.claude/aktif-is.json) yoksa veya dosya o isin
# onayli listesinde degilse, Edit/Write DURDURULUR. Bypass jetonu yoktur.
# Kaldirmak icin Casper'in acik talimati gerekir (bu kancayi duzenlemek ayri,
# gorunur bir islemdir).

INPUT=$(cat)

if ! command -v node >/dev/null 2>&1; then
  echo "BLOCKED: node bulunamadi, is siniri kancasi calismadi. Kontrol calismiyorsa is ilerlemez (anayasa VII)." >&2
  exit 2
fi

HOOK_INPUT="$INPUT" PROJE="$CLAUDE_PROJECT_DIR" node -e '
const fs = require("fs");
const path = require("path");

let d = {};
try { d = JSON.parse(process.env.HOOK_INPUT || "{}"); } catch (e) {}

const ham = (d && d.tool_input && d.tool_input.file_path) || "";
if (!ham) process.exit(0);

const proje = process.env.PROJE || process.cwd();
const norm = function (s) {
  return String(s).replace(/\\/g, "/").replace(/\/+$/, "").toLowerCase();
};
const adaylar = [norm(proje)];
const pn = adaylar[0];
if (/^\/[a-z]\//.test(pn)) adaylar.push(pn[1] + ":" + pn.slice(2));
if (/^[a-z]:\//.test(pn)) adaylar.push("/" + pn[0] + pn.slice(2));

let p = norm(ham);
for (const a of adaylar) {
  if (a && p.startsWith(a)) {
    p = p.slice(a.length).replace(/^\/+/, "");
    break;
  }
}

const serbest = [".specify/", ".claude/", "docs/is-kayitlari/"];
for (const s of serbest) {
  if (p.startsWith(s)) process.exit(0);
}

const kartYolu = path.join(proje, ".claude", "aktif-is.json");
if (!fs.existsSync(kartYolu)) {
  console.error("BLOCKED: aktif is kaydi yok, bu yuzden " + p + " dosyasina dokunulamaz. Once .claude/aktif-is.json yazilir: is cumlesi + onayli dosya listesi + onay. Kart yoksa is baslamamistir (AGENTS.md 3e).");
  process.exit(2);
}

let is = null;
try { is = JSON.parse(fs.readFileSync(kartYolu, "utf8")); } catch (e) {
  console.error("BLOCKED: .claude/aktif-is.json okunamadi (bozuk JSON). Is durur.");
  process.exit(2);
}

if (is.onay !== "verildi") {
  console.error("BLOCKED: aktif isin onayi yok (onay = " + JSON.stringify(is.onay) + "). Onaylanmamis degisiklik yasak (anayasa VII). Casper acikca onaylamali.");
  process.exit(2);
}

const liste = Array.isArray(is.onayli_dosyalar) ? is.onayli_dosyalar : [];
if (liste.length === 0) {
  console.error("BLOCKED: onayli_dosyalar listesi bos. Sinir yoksa is yok.");
  process.exit(2);
}

const uygun = liste.some(function (x) {
  const t = String(x).replace(/\\/g, "/").replace(/\/$/, "").toLowerCase();
  return p === t || p.startsWith(t + "/");
});

if (!uygun) {
  console.error("BLOCKED: " + p + " onayli sinir listesinde DEGIL. Sinir disina cikmak kapsam buyutmedir (anayasa VI). Dur ve Casper a sor. Onayli liste: " + liste.join(", "));
  process.exit(2);
}

process.exit(0);
'
