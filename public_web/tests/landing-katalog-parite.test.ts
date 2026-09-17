import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (relativePath: string) =>
  readFileSync(resolve(__dirname, relativePath), "utf-8");

describe("Landing katalog tek-kaynak sözleşmesi", () => {
  const webKatalog = oku("../src/components/landing/TemplateCatalog.tsx");
  const paylasilan = JSON.parse(
    oku("../../shared/business_categories.json"),
  ) as { categories: Array<{ id: string; aktif?: boolean }> };

  it("web kataloğu paylaşılan JSON'u tek kaynak kullanır", () => {
    expect(webKatalog).toContain("BUSINESS_CATEGORIES");
    expect(webKatalog).toContain("businessCategories");
  });

  it("paylaşılan kategoriler benzersiz ve boş değildir", () => {
    const idler = paylasilan.categories.map((k) => k.id);
    expect(idler.length).toBeGreaterThan(0);
    expect(new Set(idler).size).toBe(idler.length);
    for (const id of idler) {
      expect(id.trim().length).toBeGreaterThan(0);
    }
  });

  it("web başlığı sabit sayı yazmaz, listeden sayar", () => {
    expect(webKatalog).toContain("{kategoriSayisi} farklı kategoride");
  });

  it("kartlar taranabilir sayfalara bağlanır, modal açmaz", () => {
    expect(webKatalog).toContain("/kesfet/");
    expect(webKatalog).not.toContain("showModalBottomSheet");
  });

  it("bilinçli sapma gerekçesi dosyada belgeli kalır", () => {
    expect(webKatalog).toContain("arama motoru göremez");
    expect(webKatalog).toContain("shared/business_categories.json");
  });
});

describe("Landing katalog Flutter tutarlılığı", () => {
  const flutterKatalog = oku(
    "../../lib/widgets/landing/landing_template_catalog.dart",
  );
  const flutterListe = oku(
    "../../lib/widgets/landing/landing_template_category.dart",
  );
  const kategoriler = (
    JSON.parse(oku("../../shared/business_categories.json")) as {
      categories: Array<{ id: string; label: string; aktif?: boolean }>;
    }
  ).categories;

  it("Flutter başlığındaki sabit sayı aktif kategori sayısıyla aynıdır", () => {
    const aktif = kategoriler.filter((k) => k.aktif === true).length;
    expect(flutterKatalog).toContain(`${aktif} farklı kategoride`);
  });

  it("Flutter katalog listesi aktif kanonik kategorileri taşır", () => {
    for (const kategori of kategoriler) {
      const aranan = `'${kategori.id}'`;
      expect(flutterListe.includes(aranan)).toBe(kategori.aktif === true);
    }
  });
});
