/**
 * SAHİPSİZ VİTRİN GÖRSELLERİNİ RAPORLAR VE (İSTENİRSE) SİLER.
 *
 * NEDEN VAR (2026-08-28 ölçümü): `shelf-images` kovasındaki 328 dosyanın
 * 328'i sahipsizdi — 120 MB, deponun %77'si. Hepsi silinmiş test
 * vitrinlerinden kalmıştı. Silme yolundaki kalıcı düzeltme ayrı yapıldı
 * (`public_web/src/lib/depoTemizle.ts`); bu betik yalnız geçmişte birikeni
 * temizler, tek seferliktir.
 *
 * GÜVENLİK KURALLARI
 *   - Varsayılan kip RAPOR. Silmek için açıkça `--sil` gerekir.
 *   - YALNIZ `shelf-images` kovasına dokunur. `category-templates`
 *     kullanımda (349 şablon kaydının 326'sı oradan) ve asla açılmaz.
 *   - Bir klasör, adı `stores.slug` ile eşleşmiyorsa sahipsiz sayılır.
 *     Eşleşen tek bir vitrin varsa o klasöre dokunulmaz.
 *   - Anahtar ekrana yazılmaz.
 *
 * Kullanım:
 *   node tool/sahipsiz_gorselleri_temizle.mjs          # rapor
 *   node tool/sahipsiz_gorselleri_temizle.mjs --sil    # sil
 */

import { readFileSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { createClient } = require("../public_web/node_modules/@supabase/supabase-js");

const KOK = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const KOVA = "shelf-images";
const SAYFA = 100;
const SIL = process.argv.includes("--sil");

function ortamOku() {
  // Anahtar dosyası dışarıdan verilebilir: `--ortam <yol>`.
  // NEDEN GEREKLİ: `public_web/.env.local` canlı URL'i gösteriyor ama
  // içindeki service_role anahtarı YEREL projeye ait — canlıya karşı
  // "Invalid API key" veriyor (28 Ağustos'ta ölçüldü). Canlı anahtar
  // Vercel'de duruyor, `vercel env pull` ile geçici bir dosyaya çekilip
  // buraya verilir. Anahtar hiçbir yerde ekrana yazılmaz.
  const bayrak = process.argv.indexOf("--ortam");
  const yol =
    bayrak > -1 && process.argv[bayrak + 1]
      ? process.argv[bayrak + 1]
      : resolve(KOK, "public_web/.env.local");
  const metin = readFileSync(yol, "utf8");
  const kv = {};
  for (const satir of metin.split(/\r?\n/)) {
    const e = satir.match(/^([A-Z0-9_]+)=(.*)$/);
    if (e) kv[e[1]] = e[2].replace(/^["']|["']$/g, "");
  }
  const url = kv.NEXT_PUBLIC_SUPABASE_URL || kv.SUPABASE_URL;
  const anahtar = kv.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !anahtar) throw new Error("URL veya service_role anahtarı yok.");
  return { url, anahtar };
}

async function klasorleriListele(depo) {
  const klasorler = [];
  let offset = 0;
  for (;;) {
    const { data, error } = await depo.list("", { limit: SAYFA, offset });
    if (error) throw error;
    if (!data || data.length === 0) break;
    for (const oge of data) if (oge.id === null) klasorler.push(oge.name);
    if (data.length < SAYFA) break;
    offset += SAYFA;
  }
  return klasorler;
}

async function dosyalariTopla(depo, onEk, derinlik = 0) {
  if (derinlik > 4) return [];
  const yollar = [];
  let offset = 0;
  for (;;) {
    const { data, error } = await depo.list(onEk, { limit: SAYFA, offset });
    if (error) throw error;
    if (!data || data.length === 0) break;
    for (const oge of data) {
      const tam = `${onEk}/${oge.name}`;
      if (oge.id === null) {
        yollar.push(...(await dosyalariTopla(depo, tam, derinlik + 1)));
      } else {
        yollar.push({ yol: tam, bayt: Number(oge.metadata?.size || 0) });
      }
    }
    if (data.length < SAYFA) break;
    offset += SAYFA;
  }
  return yollar;
}

const mb = (b) => (b / 1024 / 1024).toFixed(1) + " MB";

async function main() {
  const { url, anahtar } = ortamOku();
  const istemci = createClient(url, anahtar, {
    auth: { persistSession: false },
  });
  const depo = istemci.storage.from(KOVA);

  const { data: vitrinler, error: vitrinHata } = await istemci
    .from("stores")
    .select("slug");
  if (vitrinHata) throw vitrinHata;
  const mevcutSluglar = new Set((vitrinler || []).map((v) => v.slug));
  console.log(`Veritabanındaki vitrin sayısı: ${mevcutSluglar.size}`);

  const klasorler = await klasorleriListele(depo);
  console.log(`Kovadaki klasör sayısı: ${klasorler.length}\n`);

  const sahipsiz = klasorler.filter((k) => !mevcutSluglar.has(k));
  const sahipli = klasorler.filter((k) => mevcutSluglar.has(k));

  if (sahipli.length > 0) {
    console.log(`DOKUNULMAYACAK (vitrini duran ${sahipli.length} klasör):`);
    for (const k of sahipli) console.log(`  - ${k}`);
    console.log();
  }

  let toplamBayt = 0;
  let toplamDosya = 0;
  const silinecek = [];

  for (const klasor of sahipsiz) {
    const dosyalar = await dosyalariTopla(depo, klasor);
    const bayt = dosyalar.reduce((t, d) => t + d.bayt, 0);
    toplamBayt += bayt;
    toplamDosya += dosyalar.length;
    silinecek.push(...dosyalar.map((d) => d.yol));
    console.log(`  ${klasor.padEnd(32)} ${String(dosyalar.length).padStart(4)} dosya  ${mb(bayt)}`);
  }

  console.log(
    `\nSAHİPSİZ TOPLAM: ${sahipsiz.length} klasör, ${toplamDosya} dosya, ${mb(toplamBayt)}`
  );

  if (!SIL) {
    console.log("\nRAPOR KİPİ — hiçbir şey silinmedi.");
    console.log("Silmek için: node tool/sahipsiz_gorselleri_temizle.mjs --sil");
    return;
  }

  console.log("\nSİLİNİYOR...");
  let silinen = 0;
  for (let i = 0; i < silinecek.length; i += SAYFA) {
    const parca = silinecek.slice(i, i + SAYFA);
    const { error } = await depo.remove(parca);
    if (error) {
      console.error("HATA:", error.message);
      break;
    }
    silinen += parca.length;
    console.log(`  ${silinen}/${silinecek.length}`);
  }
  console.log(`\nSilinen dosya: ${silinen}`);
}

main().catch((hata) => {
  console.error("Betik hatası:", hata.message || hata);
  process.exit(1);
});
