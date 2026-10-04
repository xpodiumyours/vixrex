import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const kok = dirname(fileURLToPath(import.meta.url));
const KATALOG = join(kok, "..", "public_web", "data", "katalog");
const girdi = process.argv[2];
if (!girdi) {
  console.error("kullanim: node tool/fatura_havuz_olc.mjs <fatura-oku-cevabi.json>");
  process.exit(1);
}

const firmalar = JSON.parse(readFileSync(join(KATALOG, "_firmalar.json"), "utf8"));
const normalizeKod = (v) => (v || "").trim().toUpperCase().replace(/[\s._\-/]/g, "");
const normalizeBarkod = (v) => (v || "").replace(/\D/g, "");

const dizinler = firmalar.map((firma) => {
  const katalog = JSON.parse(readFileSync(join(KATALOG, `uretici-katalog-${firma.anahtar}.json`), "utf8"));
  const koda = new Map();
  const barkoda = new Map();
  for (const urun of katalog) {
    const kod = normalizeKod(urun.kod);
    if (kod && !koda.has(kod)) koda.set(kod, urun);
    const barkod = normalizeBarkod(urun.barkod ?? "");
    if (barkod.length >= 8 && !barkoda.has(barkod)) barkoda.set(barkod, urun);
  }
  return { koda, barkoda, firma };
});

function eslesme({ model, barkod, marka }) {
  const b = normalizeBarkod(barkod || "");
  const m = normalizeKod(model || "");
  const mk = (marka || "").trim().toLocaleLowerCase("tr-TR");
  const sec = (alan, anahtar) => {
    const adaylar = dizinler.flatMap((dizin) => {
      const urun = dizin[alan].get(anahtar);
      if (!urun) return [];
      const urunMarka = (urun.marka || "").trim().toLocaleLowerCase("tr-TR");
      const firmaAdi = dizin.firma.ad.trim().toLocaleLowerCase("tr-TR");
      if (mk && urunMarka !== mk && firmaAdi !== mk) return [];
      return [{ dizin, urun }];
    });
    return { adaylar, tek: adaylar.length === 1 ? adaylar[0] : null };
  };
  if (b.length >= 8) {
    const r = sec("barkoda", b);
    if (r.tek) return { tur: "barkod", ...r.tek };
    if (r.adaylar.length > 1) return { tur: "barkod", belirsiz: r.adaylar.map((a) => a.dizin.firma.anahtar) };
  }
  if (m.length >= 4) {
    const r = sec("koda", m);
    if (r.tek) return { tur: "kod", ...r.tek };
    if (r.adaylar.length > 1) return { tur: "kod", belirsiz: r.adaylar.map((a) => a.dizin.firma.anahtar) };
  }
  return { tur: "yok" };
}

const okuma = JSON.parse(readFileSync(girdi, "utf8"));
const ozet = { eslesti: 0, belirsiz: 0, bulunamadi: 0 };
console.log(`tedarikci=${okuma.tedarikci || "-"} | toplam=${okuma.belgeToplami ?? "-"} | adet=${okuma.belgeAdedi ?? "-"}`);
for (const satir of okuma.satirlar ?? []) {
  const r = eslesme({ model: satir.model, barkod: satir.barkod, marka: satir.marka });
  if (r.tek) {
    ozet.eslesti++;
    console.log(`ESLESMIS ${String(satir.ad).slice(0, 40).padEnd(41)} ${r.tur} -> ${r.dizin.firma.anahtar} / ${r.urun.kod}`);
  } else if (r.belirsiz) {
    ozet.belirsiz++;
    console.log(`BELIRSIZ  ${String(satir.ad).slice(0, 40).padEnd(41)} ${r.tur} -> ${r.belirsiz.length} firma: ${r.belirsiz.join(", ")}`);
  } else {
    ozet.bulunamadi++;
    console.log(`YOK       ${String(satir.ad).slice(0, 40).padEnd(41)} kod=${satir.model} barkod=${satir.barkod || "-"}`);
  }
}
console.log(JSON.stringify(ozet));