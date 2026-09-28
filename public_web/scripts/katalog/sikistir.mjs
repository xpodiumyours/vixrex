/**
 * Mevcut katalogları yeniden yazar — ağa hiç çıkmadan.
 *
 * Normalleştirme kuralları değiştiğinde (ör. fotoğraf veya açıklama sınırı)
 * tüm siteleri yeniden taramak gerekmez; bu komut eldeki katalogları aynı
 * kurallardan geçirip yerinde yeniden yazar.
 *
 * Kullanım:
 *   node scripts/katalog/sikistir.mjs
 */

import { readdir, readFile, stat, writeFile } from "node:fs/promises";
import path from "node:path";

import { VERI_KLASORU, urunuNormalle } from "./_ortak.mjs";

const DOSYA_DUZENI = /^uretici-katalog-(.+)\.json$/;

async function ana() {
  const dosyalar = (await readdir(VERI_KLASORU)).filter((ad) => DOSYA_DUZENI.test(ad)).sort();

  console.log(`${dosyalar.length} katalog yeniden yazılıyor: ${VERI_KLASORU}\n`);
  console.log(`${"katalog".padEnd(34)} ${"önce".padStart(10)} ${"sonra".padStart(10)} ${"ürün".padStart(7)}`);

  let oncekiToplam = 0;
  let sonrakiToplam = 0;

  for (const dosya of dosyalar) {
    const tam = path.join(VERI_KLASORU, dosya);
    const onceki = (await stat(tam)).size;
    const ham = JSON.parse(await readFile(tam, "utf8"));

    const harita = new Map();
    for (const urun of ham) {
      const normal = urunuNormalle(urun, urun?.kaynak ?? "");
      if (normal && !harita.has(normal.kod)) harita.set(normal.kod, normal);
    }
    const urunler = [...harita.values()].sort((a, b) => a.kod.localeCompare(b.kod, "tr"));

    const govde = `${JSON.stringify(urunler)}\n`;
    await writeFile(tam, govde, "utf8");

    oncekiToplam += onceki;
    sonrakiToplam += Buffer.byteLength(govde);

    console.log(
      `${dosya.replace(DOSYA_DUZENI, "$1").padEnd(34)} ${`${Math.round(onceki / 1024)} KB`.padStart(10)} ${`${Math.round(Buffer.byteLength(govde) / 1024)} KB`.padStart(10)} ${String(urunler.length).padStart(7)}`,
    );
  }

  console.log(
    `\ntoplam: ${Math.round(oncekiToplam / 1024)} KB → ${Math.round(sonrakiToplam / 1024)} KB`,
  );
}

ana().catch((hata) => {
  console.error("Sıkıştırma başarısız:", hata.message);
  process.exitCode = 1;
});
