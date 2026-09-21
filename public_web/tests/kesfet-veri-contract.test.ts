import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";
import { EXPLORE_STORE_SELECT } from "@/lib/publicStoreSelect";
import {
  kategoriUrlParcasi,
  kategoriUrlParcasindanCoz,
  BUSINESS_CATEGORIES,
} from "@/lib/businessCategories";
import { kategoriVitrinleriniGetir } from "@/lib/explore";

/**
 * Yorumları söker. Bu dosyadaki iddialar KODU sınıyor; açıklama satırında
 * geçen bir isim (örn. "storefront_kind kullanılmıyor" notu) iddiayı
 * yanlışlıkla tetiklememeli.
 */
function yorumsuz(kaynak: string): string {
  return kaynak
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/^\s*\/\/.*$/gm, "");
}

const exploreKaynak = yorumsuz(
  readFileSync(resolve(__dirname, "../src/lib/explore.ts"), "utf-8")
);
const dartKaynak = readFileSync(
  resolve(__dirname, "../../lib/repositories/explore_repository.dart"),
  "utf-8"
);

/**
 * Keşfet veri sözleşmesi (#344, 2026-08-26).
 *
 * İki ayrı riski kilitler:
 *
 * 1. KOLON SIZINTISI / 42501. `stores.user_id`'nin SELECT yetkisi V-09 ile
 *    authenticated'ten çekildi. PostgreSQL sorguda geçen HER kolon için
 *    yetki arar, o yüzden `user_id`'nin seçim listesinde bulunması tüm
 *    sorguyu düşürür. Bu tam olarak iki kez oldu: 20260820210000 Keşfet
 *    ekranını, 20260826000000 ise sahiplik sorgusunu bu yüzden düşürmüştü.
 *
 * 2. İKİ İSTEMCİ AYRIŞMASI. Uygulama ve web aynı listeyi göstermezse
 *    "uygulamada gördüğüm vitrin sitede yok" kaçınılmaz.
 *    (bkz. docs/agents/iki-istemci-ortak-omurga-denetimi.md)
 */
describe("Keşfet veri katmanı", () => {
  it("seçim listesi açık liste — joker yok", () => {
    expect(EXPLORE_STORE_SELECT).not.toContain("*");
    expect(EXPLORE_STORE_SELECT.split(",").length).toBeGreaterThan(5);
  });

  it("user_id ve edit_token seçim listesinde YOK", () => {
    const kolonlar = EXPLORE_STORE_SELECT.split(",");
    expect(kolonlar).not.toContain("user_id");
    expect(kolonlar).not.toContain("edit_token");
  });

  it("kart için gereken kolonlar var", () => {
    const kolonlar = EXPLORE_STORE_SELECT.split(",");
    for (const gerekli of [
      "slug",
      "name",
      "kategori",
      "shelf_image_url",
      "province_name",
      "district_name",
      "is_demo",
    ]) {
      expect(kolonlar).toContain(gerekli);
    }
  });

  it("sorgu Flutter'daki Keşfet sorgusuyla aynı kuralları taşır", () => {
    expect(exploreKaynak).toContain('.eq("is_published", true)');
    expect(exploreKaynak).toContain('.order("updated_at", { ascending: false })');
    expect(exploreKaynak).toContain("KESFET_LIMIT = 100");
    // Dart tarafı da aynı üç kuralı uyguluyor olmalı.
    expect(dartKaynak).toContain("'is_published', true");
    expect(dartKaynak).toContain("limit(100)");
  });

  it("kiralık ayrımı yalnız is_demo — var olmayan storefront_kind kullanılmaz", () => {
    expect(exploreKaynak).toContain("is_demo");
    expect(exploreKaynak).not.toContain("storefront_kind");
    expect(EXPLORE_STORE_SELECT.split(",")).not.toContain("storefront_kind");
  });
});

describe("kategori adres parçaları", () => {
  it("alt çizgi yerine tire üretir", () => {
    expect(kategoriUrlParcasi("kafe_lokanta")).toBe("kafe-lokanta");
    expect(kategoriUrlParcasi("butik")).toBe("butik");
  });

  it("gidiş-dönüş kayıpsız — 19 kanonik kimliğin hepsi", () => {
    for (const kategori of BUSINESS_CATEGORIES) {
      const parca = kategoriUrlParcasi(kategori.id);
      expect(kategoriUrlParcasindanCoz(parca)?.id).toBe(kategori.id);
    }
  });

  it("bilinmeyen parça null döner", () => {
    expect(kategoriUrlParcasindanCoz("boyle-bir-kategori-yok")).toBeNull();
  });
});

describe("kategori sayfası yayın dayanıklılığı", () => {
  it("build sırasında veri kaynağına ulaşılamazsa boş liste döner", async () => {
    const sonuc = await kategoriVitrinleriniGetir("giyim", async () => {
      throw new Error("geçici bağlantı hatası");
    });

    expect(sonuc).toEqual([]);
  });
});
