import { readFileSync, readdirSync, statSync } from "node:fs";
import { join, resolve } from "node:path";
import { describe, expect, it } from "vitest";

/**
 * WEB İÇ BAĞLANTI SÖZLEŞMESİ (2026-08-27).
 *
 * Next.js 26 Ağustos'ta platformun ana kapısı oldu; Flutter yüzeyi alt
 * adreste kaldı. Ama sayfalar birer birer web'e taşınırken BAĞLANTILAR
 * taranmadı. Sonuç: "Giriş Yap", "Vitrinini Oluştur", "Bu Şablonla Başla"
 * gibi düğmeler kullanıcıyı Flutter uygulamasına atıyordu — oysa hepsinin
 * web karşılığı çoktan hazırdı.
 *
 * Bu, huninin tam ortasında delik demek: gelen esnaf kendini başka bir
 * uygulamada buluyor ve çoğu geri dönmüyor. Beş ayrı yerde bulundu; tek
 * tek avlamak yerine sınıf kapatıldı.
 *
 * KURAL: web'de karşılığı olan bir adrese `getAppUrl()` ile gidilemez.
 * Gerçekten Flutter'a gitmesi gereken bir bağlantı olursa
 * FLUTTER_ISTISNALARI listesine gerekçesiyle yazılır.
 */

const srcDir = resolve(__dirname, "../src");
const appDir = join(srcDir, "app");

/**
 * Flutter'a gitmesi MEŞRU olan yerler. Boş olması iyi işaret —
 * dolduruyorsan gerekçeni yaz.
 */
const FLUTTER_ISTISNALARI: { dosya: string; gerekce: string }[] = [];

function kaynakDosyalari(dizin: string): string[] {
  return readdirSync(dizin).flatMap((girdi) => {
    const yol = join(dizin, girdi);
    if (statSync(yol).isDirectory()) return kaynakDosyalari(yol);
    return /\.[jt]sx?$/.test(yol) ? [yol] : [];
  });
}

function egikCizgileriDuzelt(yol: string): string {
  return yol.split("\\").join("/");
}

/** `src/app` altındaki gerçek sayfa adresleri — dinamik segmentler atlanır. */
function webAdresleri(): Set<string> {
  const adresler = new Set<string>(["/"]);
  for (const dosya of kaynakDosyalari(appDir)) {
    const duz = egikCizgileriDuzelt(dosya);
    if (!duz.endsWith("/page.tsx")) continue;

    const adres = egikCizgileriDuzelt(dosya.slice(appDir.length))
      .replace(/\/page\.tsx$/, "")
      // (site) gibi route grupları adrese girmez
      .replace(/\/\([^)]+\)/g, "");

    if (adres.includes("[")) continue;
    adresler.add(adres === "" ? "/" : adres);
  }
  return adresler;
}

describe("web iç bağlantı sözleşmesi", () => {
  it("web'de karşılığı olan hiçbir adrese Flutter üzerinden gidilmiyor", () => {
    const adresler = webAdresleri();
    const istisnalar = new Set(FLUTTER_ISTISNALARI.map((i) => i.dosya));
    const ihlaller: string[] = [];

    for (const dosya of kaynakDosyalari(srcDir)) {
      if (dosya.endsWith("siteUrl.ts")) continue;

      const goreli = egikCizgileriDuzelt(dosya.slice(srcDir.length + 1));
      if (istisnalar.has(goreli)) continue;

      const kaynak = readFileSync(dosya, "utf8");
      if (!kaynak.includes("getAppUrl()")) continue;

      // `${getAppUrl()}/app` → "/app" ; düz `getAppUrl()` → "/"
      for (const eslesme of kaynak.matchAll(/getAppUrl\(\)\}?(\/[a-z0-9/-]*)?/gi)) {
        const hedef = eslesme[1] ?? "/";
        if (adresler.has(hedef)) {
          ihlaller.push(`${goreli} → ${hedef} (bu adres web'de var)`);
        }
      }
    }

    expect(ihlaller).toEqual([]);
  });

  it("istisna listesindeki her satırın gerekçesi var", () => {
    for (const istisna of FLUTTER_ISTISNALARI) {
      expect(istisna.gerekce.trim().length).toBeGreaterThan(15);
    }
  });
});
