import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (yol: string) =>
  readFileSync(resolve(__dirname, `../src/${yol}`), "utf8");

/**
 * Serbest metinle alan doldurma (2026-09-02) — kullanıcı NET olarak yeni
 * bir ekran elemanı istemedi, "sadece çalışmasında ve niyetinde değişiklik"
 * istedi. Bu yüzden ayrı bir kart YOK — mevcut soru kutusuna (gonder(),
 * useOwnerActions.ts) doğrudan cevaplanmayan alanları da bulan bir
 * "bonus çıkarım" eklendi. Panelin görünümü/DOM'u bu özellik için hiç
 * değişmedi.
 */
describe("OwnerAssistantPanel — yeni bir ekran elemanı yok", () => {
  const panel = oku("app/v/[slug]/OwnerAssistantPanel.tsx");

  it("panelde serbest anlatım kartına/state'ine dair hiçbir iz yok", () => {
    expect(panel).not.toContain("anlatimAcik");
    expect(panel).not.toContain("IsletmeniAnlatKarti");
    expect(panel).not.toContain("serbestMetindenAlanlariCikar");
  });

  it("panel açılınca otomatik ilk-alan seçimi eski (2026-08-22'den beri değişmemiş) hâliyle çalışıyor", () => {
    expect(panel).toContain("if (!acik || seciliAlan) return;");
  });
});

describe("useOwnerActions.gonder() — mevcut kutuya bonus çıkarım katıldı", () => {
  const kaynak = oku("app/v/[slug]/hooks/useOwnerActions.ts");

  it("yalnız gonder()'ın (metin girişi) başarılı akışının İÇİNDE tetiklenir — ayrı bir buton/kart yok", () => {
    const gonderBaslangici = kaynak.indexOf("const gonder = useCallback(async () => {");
    const cagriIndex = kaynak.indexOf("bonusAlanlariCikarVeKaydet(", gonderBaslangici);
    expect(cagriIndex).toBeGreaterThan(gonderBaslangici);
  });

  it("kısa/tek kelimelik cevaplarda gereksiz yere çalışmaz (uzunluk eşiği var)", () => {
    expect(kaynak).toContain("metin.length >= 15");
  });

  it("az önce doğrudan cevaplanan alanın kolonu bonus setinden hariç tutulur — çift yazma yok", () => {
    expect(kaynak).toContain("alan.kolon === cevaplananKolon");
  });

  it("bonus başarısız olursa asıl kayıt/akış hiç etkilenmez — sessizce yutulur", () => {
    const idx = kaynak.indexOf("async function bonusAlanlariCikarVeKaydet");
    const fonksiyon = kaynak.slice(idx, idx + 1600);
    expect(fonksiyon).toContain("} catch {");
    expect(fonksiyon).toContain("Bonus bir zenginleştirme");
  });

  it("bonus bulunca aynı ✓ liste stilini kullanır (D3'teki desenle aynı)", () => {
    expect(kaynak).toContain("Yazdığından ayrıca şunları da anladım");
    expect(kaynak).toContain("basarili.map(({ etiket }) => `✓ ${etiket}`)");
  });
});
