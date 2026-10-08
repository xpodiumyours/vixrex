/**
 * Excel'deki firma havuzunu toplayıcının okuyacağı listeye çevirir.
 *
 * Kaynak: Tekstil-Gida-Firma-Havuzu.xlsx — "Ana Liste" sekmesi
 * Çıktı : public_web/scripts/katalog/firmalar.json
 *
 * ÖNEMLİ: Bu Excel bir FİRMA KEŞİF listesidir. Firma başına yalnızca BİR örnek
 * ürün adı ve BİR örnek görsel bağlantısı vardır. Ürünler burada değil,
 * toplayıcının sitelerden çektiği katalog dosyalarında durur.
 *
 * Kullanım:
 *   node scripts/katalog/firmalar-uret.mjs [excel-yolu]
 */

import { writeFile } from "node:fs/promises";
import { existsSync, readFileSync } from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";

// xlsx'in ESM girişi dosya okuyamayan tarayıcı sürümüne düşer; Node sürümü
// kullanılır.
const require = createRequire(import.meta.url);
const XLSX = require("xlsx");

const BURASI = path.dirname(fileURLToPath(import.meta.url));
const CIKTI = path.join(BURASI, "firmalar.json");

/**
 * Daha önce verilmiş izinleri okur. İzin firma başına elle alınan bir haktır;
 * Excel'den yeniden üretim onu silmemeli. Hem anahtar hem site adresiyle
 * eşleşebilsin diye ikisi de anahtar olarak konur.
 */
function izinleriOku() {
  const harita = new Map();
  if (!existsSync(CIKTI)) return harita;
  try {
    for (const firma of JSON.parse(readFileSync(CIKTI, "utf8"))) {
      if (!firma?.izin) continue;
      if (firma.anahtar) harita.set(firma.anahtar, firma.izin);
      if (firma.site) harita.set(firma.site, firma.izin);
    }
  } catch (hata) {
    // Bozuk dosya yüzünden izinleri sessizce sıfırlamak en kötüsü olur.
    console.error(`UYARI: mevcut firmalar.json okunamadı, izinler korunamıyor: ${hata.message}`);
  }
  return harita;
}

const VARSAYILAN_EXCEL =
  "C:/Users/Casper/Desktop/Tekstil-Gida-Firma-Havuzu.xlsx";

const SUTUNLAR = {
  ad: 0,
  sektor: 1,
  altKategori: 2,
  adres: 3,
  site: 4,
};

const TURKCE_HARITA = {
  ç: "c", Ç: "c", ğ: "g", Ğ: "g", ı: "i", İ: "i",
  ö: "o", Ö: "o", ş: "s", Ş: "s", ü: "u", Ü: "u",
};

/** Firma adını dosya adında kullanılabilecek anahtara çevirir. */
export function anahtarUret(ad) {
  return String(ad ?? "")
    .replace(/[çÇğĞıİöÖşŞüÜ]/g, (harf) => TURKCE_HARITA[harf] ?? harf)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

/** Site adresini yalnız alan adına indirger. */
export function siteTemizle(site) {
  return String(site ?? "")
    .trim()
    .replace(/^https?:\/\//i, "")
    .replace(/\/+$/, "")
    .replace(/^www\./i, "");
}

export function firmalariUret(excelYolu) {
  const kitap = XLSX.readFile(excelYolu);
  const sayfa = kitap.Sheets["Ana Liste"];
  if (!sayfa) throw new Error('Excel içinde "Ana Liste" sekmesi bulunamadı.');

  const satirlar = XLSX.utils.sheet_to_json(sayfa, { header: 1, defval: "" });
  const hamlar = satirlar.slice(1).filter((satir) => String(satir[SUTUNLAR.ad]).trim() !== "");

  const kullanilan = new Set();
  const firmalar = [];
  const oncekiIzinler = izinleriOku();

  for (const satir of hamlar) {
    const ad = String(satir[SUTUNLAR.ad]).trim();
    const site = siteTemizle(satir[SUTUNLAR.site]);

    let anahtar = anahtarUret(ad);
    if (!anahtar) anahtar = "firma";
    while (kullanilan.has(anahtar)) anahtar = `${anahtar}-2`;
    kullanilan.add(anahtar);

    firmalar.push({
      anahtar,
      ad,
      sektor: String(satir[SUTUNLAR.sektor]).trim(),
      altKategori: String(satir[SUTUNLAR.altKategori]).trim(),
      site,
      // Platform taranınca otomatik tespit edilir; boş bırakılır.
      platform: "",
      // Görsel kullanım izni. "yok" | "bekliyor" | "var"
      // Daha önce alınmış izin ASLA silinmez: mevcut firmalar.json'daki değer
      // korunur. Yoksa Excel'den yeniden üretim, alınan izinleri sıfırlar.
      izin: oncekiIzinler.get(anahtar) ?? oncekiIzinler.get(site) ?? "yok",
    });
  }

  return firmalar;
}

async function ana() {
  const excelYolu = process.argv[2] ?? VARSAYILAN_EXCEL;
  const firmalar = firmalariUret(excelYolu);

  await writeFile(CIKTI, `${JSON.stringify(firmalar, null, 2)}\n`, "utf8");

  const sitesiz = firmalar.filter((f) => !f.site);
  console.log(`${firmalar.length} firma yazıldı → ${CIKTI}`);
  if (sitesiz.length) {
    console.log(`UYARI: ${sitesiz.length} firmada site adresi boş: ${sitesiz.map((f) => f.ad).join(", ")}`);
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  ana().catch((hata) => {
    console.error("Hata:", hata.message);
    process.exitCode = 1;
  });
}
