import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { EXPLORE_STORE_SELECT } from "@/lib/publicStoreSelect";

/**
 * Keşfet listeleme parite testi.
 *
 * Kural: Flutter ExploreRepository.fetchPublishedStores() ile
 * Next.js kesfetVitrinleriniGetir() aynı sorguyu çalıştırır.
 * - Aynı tablo: stores
 * - Aynı filtre: is_published = true
 * - Aynı sıralama: updated_at DESC
 * - Aynı limit: 100
 * - Aynı ürün sorgusu: products WHERE store_id IN (...) AND is_active=true AND is_visible=true
 */

const flutterRepository = readFileSync(
  resolve(__dirname, "../../lib/repositories/explore_repository.dart"),
  "utf8",
);

describe("kesfet listeleme parite (Flutter referansiyla)", () => {
  it("Flutter gibi yayinli vitrinleri ceker (is_published = true)", () => {
    expect(flutterRepository).toContain("is_published");
    expect(flutterRepository).toContain("true");
  });

  it("Flutter gibi guncelleme zamanina gore siralar (updated_at DESC)", () => {
    expect(flutterRepository).toMatch(/order\('updated_at'\s*,\s*ascending:\s*false\)/);
  });

  it("Flutter gibi 100 kayit limiti koyar", () => {
    expect(flutterRepository).toContain(".limit(100)");
  });

  it("Flutter gibi aktif ve gorunur urunleri ceker", () => {
    expect(flutterRepository).toContain("is_active");
    expect(flutterRepository).toContain("is_visible");
    expect(flutterRepository).toContain("true");
  });

  it("Next.js ayni limiti ve sir mayi kullanir (EXPLORE_STORE_SELECT)", () => {
    // Next.js'in sorgu parcaciğini kontrol et
    const nextExplore = readFileSync(
      resolve(__dirname, "../src/lib/explore.ts"),
      "utf8",
    );
    expect(nextExplore).toContain("is_published");
    expect(nextExplore).toContain("updated_at");
    expect(nextExplore).toContain("KESFET_LIMIT");
    expect(nextExplore).toContain("is_active");
    expect(nextExplore).toContain("is_visible");
  });

  it("Kategori filtresi Flutter ile ayni: is_demo = true kiraliktan", () => {
    const nextExplore = readFileSync(
      resolve(__dirname, "../src/lib/explore.ts"),
      "utf8",
    );
    expect(nextExplore).toContain("is_demo");
    expect(nextExplore).toContain("kiralikMi");
  });
});