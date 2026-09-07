import { readFileSync, readdirSync, statSync } from "node:fs";
import { join, resolve } from "node:path";
import { describe, expect, it } from "vitest";

/**
 * WEB İÇ BAĞLANTI + TEK UI SAHİPLİĞİ SÖZLEŞMESİ.
 *
 * - Next.js müşteri/public yüzeyinin sahibidir (ana sayfa, SEO Keşfet, vitrin).
 * - Flutter Android + Web uygulama kabuğunun sahibidir (Vitrinim, uygulama
 *   Keşfet'i, Vixrex, Profil).
 * - Public sayfalar Flutter URL'sini kendi başına kurmaz; tek giriş bileşeni
 *   `AppEntryLink` üzerinden geçer.
 * - Next -> Flutter kalıcı hesap geçişi access/refresh token'ı URL'ye taşımaz;
 *   doğrulanmış kullanıcı için tek kullanımlık Supabase magic-link üretir.
 */

const srcDir = resolve(__dirname, "../src");
const appDir = join(srcDir, "app");

const FLUTTER_ISTISNALARI: { dosya: string; gerekce: string }[] = [
  {
    dosya: "components/app/AppEntryLink.tsx",
    gerekce: "Tek uygulama giriş bileşeni Flutter Web uygulama kabuğunun merkezi adres sahibidir.",
  },
];

const TEK_UI_GIRIS_DOSYALARI = [
  "app/not-found.tsx",
  "app/(site)/kesfet/[kategori]/page.tsx",
  "components/vixrex/SharedVixrexAssistant.tsx",
] as const;

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

      for (const eslesme of kaynak.matchAll(/getAppUrl\(\)\}?(\/[a-z0-9/-]*)?/gi)) {
        const hedef = eslesme[1] ?? "/";
        if (adresler.has(hedef)) {
          ihlaller.push(`${goreli} → ${hedef} (bu adres web'de var)`);
        }
      }
    }

    expect(ihlaller).toEqual([]);
  });

  it("public uygulama girişleri yalnız ortak AppEntryLink'i kullanıyor", () => {
    for (const goreli of TEK_UI_GIRIS_DOSYALARI) {
      const kaynak = readFileSync(join(srcDir, goreli), "utf8");
      expect(kaynak, `${goreli} AppEntryLink kullanmalı`).toContain("AppEntryLink");
      expect(kaynak, `${goreli} kendi getAppUrl çağrısını taşımamalı`).not.toContain(
        "getAppUrl()"
      );
      expect(kaynak, `${goreli} yerel /app href'i içermemeli`).not.toMatch(
        /href=["']\/app(?:[?/#"'])/
      );
    }
  });

  it("AppEntryLink kalıcı hesabı tek kullanımlık sunucu köprüsüyle taşır", () => {
    const kaynak = readFileSync(
      join(srcDir, "components/app/AppEntryLink.tsx"),
      "utf8"
    );
    expect(kaynak).toContain("getAppUrl()");
    expect(kaynak).toContain('fetch("/api/app-handoff"');
    expect(kaynak).toContain("session.access_token");
    expect(kaynak).not.toContain("refresh_token");
    expect(kaynak).toContain("window.location.assign(APP_TARGET)");
  });

  it("app-handoff kullanıcıyı doğrular ve mevcut tokenları URL'ye koymaz", () => {
    const kaynak = readFileSync(join(appDir, "api/app-handoff/route.ts"), "utf8");
    expect(kaynak).toContain("auth.getUser(bearerToken)");
    expect(kaynak).toContain("auth.admin.generateLink");
    expect(kaynak).toContain('type: "magiclink"');
    expect(kaynak).toContain("linkData.user.id !== user.id");
    expect(kaynak).toContain("getAppUrl()");
    expect(kaynak).toContain('"Cache-Control", "private, no-store, max-age=0"');
    expect(kaynak).not.toContain("refresh_token");
  });

  it("istisna listesindeki her satırın gerekçesi var", () => {
    for (const istisna of FLUTTER_ISTISNALARI) {
      expect(istisna.gerekce.trim().length).toBeGreaterThan(15);
    }
  });
});
