import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

/**
 * SAHİP YÖNETİM ARAYÜZÜ SÖZLEŞMESİ (2026-08-27).
 *
 * NOT — bu dosya neden `.ts`: ilk hâli `owner-ui-contract.test.mjs` idi ve
 * `node:test` koşucusunu kullanıyordu. Vitest yalnız `tests` altındaki
 * `.test.ts` dosyalarını
 * topluyor (`vitest.config.ts`), `node --test`'i de hiçbir betik
 * çağırmıyordu. Sonuç: dosya bekçi gibi duruyordu ama HİÇ KOŞMUYORDU —
 * test sayısı eklendikten önce ve sonra aynıydı (675). Koşmayan bekçi,
 * bekçi olmadığını da gizlediği için hiç yoktan kötüdür.
 */

const KOK = resolve(__dirname, "..");
const oku = (yol: string) => readFileSync(resolve(KOK, yol), "utf8");

const globals = oku("src/app/globals.css");
const giris = oku("src/app/giris/page.tsx");
const kayit = oku("src/app/kayit/page.tsx");
const pano = oku("src/app/app/page.tsx");
const vitrinimEditor = oku("src/components/owner/VitrinimEditor.tsx");
const urunler = oku("src/components/owner/OwnerProductManager.tsx");

// Sahip yönetim yüzeyleri — yeni sayfa eklenince buraya da eklenmeli.
const YONETIM_SAYFALARI = [
  "src/app/app/page.tsx",
  "src/app/app/hesap/page.tsx",
  "src/app/v/[slug]/blog-yonetim/page.tsx",
  "src/app/v/[slug]/blog-yonetim/[articleSlug]/page.tsx",
  "src/app/v/[slug]/randevu-yonetim/page.tsx",
] as const;

describe("sahip yönetim arayüzü sözleşmesi", () => {
  it("üç palet ayrı kalıyor — yönetim, landing ve canlı vitrin", () => {
    // Bu ayrım kazara değil: yayındaki vitrinlerin rengi (#38A0E4) yönetim
    // ve landing renginden (#147DFF) bağımsız olmak zorunda. "Tasarımı
    // tekleştirelim" diye bunları birleştiren bir değişiklik, canlıdaki
    // bütün vitrinlerin görünümünü sessizce değiştirir.
    expect(globals).toMatch(/\.owner-shell\s*\{/);
    expect(globals).toMatch(/--owner-primary:\s*#147DFF/);
    expect(globals).toMatch(/--color-lp-primary:\s*#147DFF/);
    expect(globals).toMatch(/--primary:\s*#38A0E4/);
    expect(globals).toMatch(/\.vitrin-shell\s*\{/);
  });

  it("yönetim formları etiket, meşgul durumu ve hata gösteriyor", () => {
    for (const kaynak of [giris, kayit, pano]) {
      expect(kaynak).toMatch(/<label htmlFor=/);
      expect(kaynak).toMatch(/aria-busy=/);
      expect(kaynak).toMatch(/role="alert"/);
    }
  });

  it("sahip dili tek-vitrin modelini izliyor", () => {
    expect(vitrinimEditor).toMatch(/>Vitrinim</);
    // Hesap başına tek vitrin kuralı veritabanında zorlanıyor; arayüz
    // çoğul dil kullanırsa kullanıcıya olmayan bir yetenek vaat eder.
    expect(pano).not.toMatch(/Vitrinlerim/);
    expect(pano).not.toMatch(/Yeni Vitrin Oluştur/);
  });

  it("ürün alanları ve kalıcı silme dili Flutter ile aynı kalıyor", () => {
    for (const etiket of [
      "Ürün adı *",
      "Fiyat",
      "Stok durumu",
      "Kısa açıklama",
      "Kategori *",
    ]) {
      expect(urunler).toContain(etiket);
    }
    expect(urunler).toMatch(/Ürünü Sil/);
    expect(urunler).toMatch(/Bu işlem geri alınamaz\./);
    expect(urunler).toMatch(/Vazgeç/);
    expect(urunler).toMatch(/Kalıcı Sil/);
  });

  it("arama motorunun okuduğu sayfalar sunucu bileşeni kalıyor", () => {
    // `"use client"` eklemek SSR'ı ve SEO'yu sessizce öldürür: sayfa
    // çalışmaya devam eder, testler yeşil kalır, yalnız arama motoru
    // farklı görür. Bu yüzden ayrı bir iddia olarak kilitleniyor.
    const publicSayfalar = [
      "src/app/(site)/page.tsx",
      "src/app/(site)/kesfet/page.tsx",
      "src/app/v/[slug]/page.tsx",
    ];

    for (const yol of publicSayfalar) {
      expect(oku(yol), `${yol} istemci bileşenine çevrilmiş`).not.toMatch(
        /^\s*["']use client["'];/m
      );
    }
  });

  it("yönetim sayfaları kendi rengini uydurmuyor — tanımları kullanıyor", () => {
    // 27 Ağustos: blog ve randevu yönetim sayfaları eklendiğinde dördüncü bir
    // palet doğdu — siyah zemin (#0c0d10) ve turuncu vurgu (#E8A87C) elle
    // yazılmıştı. Sahip panelinin gerçek rengi lacivert-mavi; kullanıcı aynı
    // panelin içinde gezerken renk değiştiğini gördü.
    //
    // Mevcut palet iddiası bunu YAKALAMIYORDU: o, üç paletin birbirine
    // karışmasını yasaklıyor, yeni bir sayfanın hiçbirini kullanmamasını
    // değil. Bu iddia o boşluğu kapatıyor.
    const ihlaller = YONETIM_SAYFALARI.flatMap((yol) => {
      const kaynak = oku(yol);
      const sabitRenkler = kaynak.match(/#[0-9A-Fa-f]{6}/g) ?? [];
      const hatalar: string[] = [];

      if (sabitRenkler.length > 0) {
        hatalar.push(`${yol}: elle yazılmış renk ${[...new Set(sabitRenkler)].join(", ")}`);
      }
      if (!kaynak.includes("owner-shell")) {
        hatalar.push(`${yol}: kök kabuk 'owner-shell' yok — --owner-* tanımları o kapsamda`);
      }
      return hatalar;
    });

    expect(ihlaller).toEqual([]);
  });
});
