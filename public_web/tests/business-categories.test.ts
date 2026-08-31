import { describe, expect, it } from "vitest";
import {
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
      BUSINESS_CATEGORIES.map((category) => category.label),
    );
  });
});
