import { readFileSync, readdirSync, statSync } from "node:fs";
import { join, resolve } from "node:path";
import { describe, expect, it } from "vitest";

/**
 * WEB İÇ BAĞLANTI SÖZLEŞMESİ.
 *
 * 2026-09-07 UI sahipliği düzeltmesi:
 * - Next.js müşteri/public yüzeyinin sahibidir (ana sayfa, SEO Keşfet, vitrin).
 * - Flutter Android + Web uygulama kabuğunun sahibidir (Vitrinim, uygulama
 *   Keşfet'i, Vixrex, Profil).
 * - `public_web/src/app/app/*` geçici uyumluluk yüzeyidir; yeni public girişler
 *   bu kopyaya yönlendirilmez.
 *
 * KURAL: normal web içeriği web'de kalır. Ancak kullanıcı uygulama kabuğuna
 * girecekse `getAppUrl()` kullanılır. Mevcut Next `/app` rotasının varlığı bu
 * bağlantıyı tekrar yerel `/app` yapma gerekçesi değildir.
 */

const srcDir = resolve(__dirname, "../src");
const appDir = join(srcDir, "app");

/**
 * Uygulama kabuğuna girmesi gereken public giriş noktaları.
 * Bunlar Next `/app` kopyasına değil Flutter Web'e gider.
 */
const FLUTTER_ISTISNALARI: { dosya: string; gerekce: string }[] = [
  {
    dosya: "app/not-found.tsx",
    gerekce: "Vitrin oluştur CTA'sı public web'den tek Flutter uygulama kabuğuna geçiştir.",
  },
  {
    dosya: "app/(site)/kesfet/[kategori]/page.tsx",
    gerekce: "Şablonla başlama işlemi SEO sayfasından uygulama kurulum kabuğuna geçiştir.",
  },
  {
    dosya: "components/vixrex/SharedVixrexAssistant.tsx",
    gerekce: "Sıfırdan vitrin oluştur seçeneği uygulama yönetim kabuğunda devam etmelidir.",
  },
];

const TEK_UI_GIRIS_DOSYALARI = FLUTTER_ISTISNALARI.map((i) => i.dosya);

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
  it("web'de kalması gereken adresler gereksiz yere Flutter'a gönderilmiyor", () => {
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

  it("tek uygulama girişleri yerel Next /app kopyasına bağlanmıyor", () => {
    for (const goreli of TEK_UI_GIRIS_DOSYALARI) {
      const kaynak = readFileSync(join(srcDir, goreli), "utf8");
      expect(kaynak, `${goreli} getAppUrl() kullanmalı`).toContain("getAppUrl()");
      expect(kaynak, `${goreli} yerel /app href'i içermemeli`).not.toMatch(
        /href=["']\/app(?:[?/#"'])/
      );
    }
  });

  it("istisna listesindeki her satırın gerekçesi var", () => {
    for (const istisna of FLUTTER_ISTISNALARI) {
      expect(istisna.gerekce.trim().length).toBeGreaterThan(15);
    }
  });
});
