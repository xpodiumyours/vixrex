import { readdirSync, readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";
import { BUSINESS_CATEGORIES } from "@/lib/businessCategories";

const landingDizini = resolve(__dirname, "../src/components/landing");
const siteDizini = resolve(__dirname, "../src/components/site");

function dizinKaynagi(dizin: string): string {
  return readdirSync(dizin)
    .filter((ad) => ad.endsWith(".tsx") || ad.endsWith(".ts"))
    .map((ad) => readFileSync(resolve(dizin, ad), "utf-8"))
    .join("\n");
}

const kaynak = dizinKaynagi(landingDizini) + "\n" + dizinKaynagi(siteDizini);

/**
 * Landing metin KURALLARI.
 *
 * Metinlerin Flutter ile aynı olup olmadığı burada DEĞİL,
 * `landing-esitlik-contract.test.ts` içinde doğrulanıyor — o test listeyi
 * elle tutmak yerine doğrudan Flutter kaynağından çıkarıyor. Burada yalnız
 * listeden çıkarılamayacak kurallar kalıyor: yazım biçimi ve tek kaynak
 * disiplini.
 *
 * (Bu dosya önce 35 satırlık elle yazılmış bir metin listesi taşıyordu.
 * Liste kaldırıldı: iki yerde iki kopya tutmak, tam da önlemeye çalıştığımız
 * ayrışmanın kendisiydi.)
 */
describe("landing metin kuralları", () => {
  it("kesme işaretleri U+2019 — düz tırnak kullanılmamış", () => {
    expect(kaynak).toContain("Vixrex’e");
    expect(kaynak).toContain("Vixrex’ini");
    expect(kaynak).not.toContain("Vixrex'e ekle");
  });

  it("2026-08-22'de kaldırılan emoji önekleri geri gelmemiş", () => {
    for (const emoji of ["🔒", "💳", "🎯", "🔗", "✅"]) {
      expect(kaynak).not.toContain(emoji);
    }
  });

  it("kategori sayısı tek kaynaktan gelir, metne gömülmez", () => {
    // Flutter'da başlık "12 farklı kategoride" diyor ama katalog 20 kart
    // çiziyor; veritabanında ise 19 kanonik kategori var. Sayı artık
    // BUSINESS_CATEGORIES.length'ten okunuyor, yani üçü de ayrışamaz.
    expect(kaynak).toContain("{kategoriSayisi} farklı kategoride");
    expect(kaynak).not.toContain("12 farklı kategoride");
    expect(BUSINESS_CATEGORIES.length).toBe(19);
  });

  it("kategori kartları paylaşılan sözleşmeden üretilir, elle yazılmaz", () => {
    expect(kaynak).toContain("BUSINESS_CATEGORIES.map");
  });
});
