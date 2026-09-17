import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import {
  AKTIF_BUSINESS_CATEGORIES,
  BUSINESS_CATEGORIES,
  resolveBusinessCategory,
  validateBusinessCategoryContract,
} from "../src/lib/businessCategories";
import { VITRIN_FIELDS } from "../src/lib/vitrinFieldSchema";
import { PROFILES } from "../src/lib/vitrinProfile";

describe("ortak kategori core", () => {
  it("19 benzersiz ID ve 1-19 sabit sıra taşır", () => {
    expect(BUSINESS_CATEGORIES).toHaveLength(19);
    expect(new Set(BUSINESS_CATEGORIES.map((category) => category.id)).size).toBe(19);
    expect(BUSINESS_CATEGORIES.map((category) => category.order)).toEqual(
      Array.from({ length: 19 }, (_, index) => index + 1),
    );
  });

  it.each([
    ["Hizmet & Danışmanlık", "hizmet_danismanlik"],
    ["Eğitim & Ders", "egitim_ders"],
    ["Ev & Temizlik", "ev_temizlik"],
    ["Spor & Fitness", "spor_fitness"],
    ["Pet Shop & Veteriner", "pet_shop_veteriner"],
    ["Sağlık & Yaşam", "saglik_yasam"],
    ["Oto & Araç Hizmetleri", "oto_arac"],
  ])("eski etiketi çözer: %s", (legacyLabel, expectedId) => {
    expect(resolveBusinessCategory(legacyLabel)?.id).toBe(expectedId);
  });

  it("eski arama aliaslarını ve en özgül kısmi eşleşmeyi korur", () => {
    expect(resolveBusinessCategory("telefon servis")?.id).toBe("teknik_servis");
    expect(resolveBusinessCategory("pet hizmetleri")?.id).toBe("pet_shop_veteriner");
  });

  it("normalize edilmiş alias çakışmasını reddeder", () => {
    expect(() =>
      validateBusinessCategoryContract([
        { id: "bir", order: 1, label: "Bir", templateGroup: "diger", aliases: ["Çakışma"] },
        { id: "iki", order: 2, label: "İki", templateGroup: "diger", aliases: ["cakisma"] },
      ]),
    ).toThrow(/alias.*çakış/i);
  });

  it("Next adapter ve alan şeması bütün canonical kategorileri kapsar", () => {
    expect(PROFILES.map((profile) => profile.id)).toEqual(
      BUSINESS_CATEGORIES.map((category) => category.id),
    );
    expect(PROFILES.map((profile) => profile.label)).toEqual(
      BUSINESS_CATEGORIES.map((category) => category.label),
    );
    const categoryField = VITRIN_FIELDS.find((field) => field.anahtar === "kategori");
    expect(categoryField?.secenekler).toEqual(
      AKTIF_BUSINESS_CATEGORIES.map((category) => category.label),
    );
  });
});

describe("aktif kategori süzgeci", () => {
  const oku = (yol: string) => readFileSync(resolve(__dirname, yol), "utf-8");

  it("19 kaydın hepsi yerinde durur, 6'sı aktiftir", () => {
    expect(BUSINESS_CATEGORIES).toHaveLength(19);
    expect(BUSINESS_CATEGORIES.every((k) => typeof k.aktif === "boolean")).toBe(true);
    expect(AKTIF_BUSINESS_CATEGORIES.map((k) => k.id)).toEqual([
      "giyim",
      "butik",
      "gida",
      "kafe_lokanta",
      "kuafor",
      "teknik_servis",
    ]);
  });

  it("pasif kategori silinmez: adresi, alias'ı ve sırası korunur", () => {
    expect(resolveBusinessCategory("Oto & Araç Hizmetleri")?.id).toBe("oto_arac");
    expect(resolveBusinessCategory("Sağlık & Yaşam")?.id).toBe("saglik_yasam");
    expect(resolveBusinessCategory("kırtasiye")?.id).toBe("kirtasiye");
    expect(BUSINESS_CATEGORIES.map((k) => k.order)).toEqual(
      Array.from({ length: 19 }, (_, i) => i + 1),
    );
  });

  it("görünen yüzeyler yalnız aktif listeyi çizer", () => {
    for (const yol of [
      "../src/components/kesfet/KategoriSeridi.tsx",
      "../src/components/landing/TemplateCatalog.tsx",
    ]) {
      const kaynak = oku(yol);
      expect(kaynak).toContain("AKTIF_BUSINESS_CATEGORIES.map");
      expect(/[^_]BUSINESS_CATEGORIES\.map/.test(kaynak)).toBe(false);
    }
  });

  it("kategori sayfaları ve site haritası 19 kaydın hepsini üretmeye devam eder", () => {
    for (const yol of [
      "../src/app/(site)/kesfet/[kategori]/page.tsx",
      "../src/app/sitemap.xml/route.ts",
    ]) {
      expect(/[^_]BUSINESS_CATEGORIES\.map/.test(oku(yol))).toBe(true);
    }
  });
});
