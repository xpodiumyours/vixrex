import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

import { VITRIN_FIELDS, SECTION_ORDER } from "../src/lib/vitrinFieldSchema";
import { PUBLIC_STORE_SELECT } from "../src/lib/publicStoreSelect";

const viewSource = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/VitrinProfileView.tsx"),
  "utf-8",
);
const vitrinEditorSource = readFileSync(
  resolve(__dirname, "../src/components/owner/VitrinimEditor.tsx"),
  "utf-8",
);
const flutterFormSource = readFileSync(
  resolve(__dirname, "../../lib/screens/my_vitrin/sections/vitrin_form_section.dart"),
  "utf-8",
);

function camelCase(kolon: string) {
  return kolon.replace(/_([a-z])/g, (_, harf: string) => harf.toUpperCase());
}

const mevcutRenderEslemeleri: Readonly<Record<string, string>> = {
  shelf_image_url: "heroImage",
  latitude: "mapsUrl",
  longitude: "mapsEmbedUrl",
  featured_banner_label: "featuredLabel",
  featured_banner_title: "featuredTitle",
  featured_banner_description: "featuredDescription",
  featured_banner_image_url: "featuredImageUrl",
  featured_banner_price_text: "featuredPriceText",
  gallery_section_kicker: "galleryKicker",
  gallery_section_title: "galleryTitle",
  show_directions_link: "mapsUrl",
  references_link: "referencesUrl",
};

describe("vitrin alan şeması render bütünlüğü", () => {
  it("şemadaki her kolonu public mağaza sorgusunda taşır", () => {
    const eksikKolonlar = VITRIN_FIELDS.map((alan) => alan.kolon).filter(
      (kolon) => !PUBLIC_STORE_SELECT.split(",").includes(kolon),
    );

    expect(eksikKolonlar, `PUBLIC_STORE_SELECT eksikleri: ${eksikKolonlar.join(", ")}`).toEqual([]);
  });

  it("şemadaki her kolonun camelCase karşılığını vitrin görünümünde kullanır", () => {
    const eksikAlanlar = VITRIN_FIELDS.map((alan) => ({
      kolon: alan.kolon,
      prop: mevcutRenderEslemeleri[alan.kolon] ?? camelCase(alan.kolon),
    })).filter(({ prop }) => !viewSource.includes(prop));

    expect(
      eksikAlanlar,
      `VitrinProfileView eksikleri: ${eksikAlanlar
        .map(({ kolon, prop }) => `${kolon} → ${prop}`)
        .join(", ")}`,
    ).toEqual([]);
  });
});

describe("F0 — bölüm ve form iskeleti kilidi (Flutter = Next.js)", () => {
  it("SECTION_ORDER sayfa sırası vitrindeki gerçek sıra ile aynı", () => {
    expect(SECTION_ORDER).toEqual([
      "hero",
      "categories",
      "featured",
      "products",
      "about",
      "gallery",
      "blog",
      "faq",
      "contact",
    ]);
  });

  it("VitrinimEditor 5 bölüm başlığı Flutter ile birebir", () => {
    const flutterBasliklar = ["Kimlik", "İletişim", "Konum ve saatler", "Görseller", "İçerik ve SEO"];
    for (const baslik of flutterBasliklar) {
      expect(flutterFormSource).toContain(`'${baslik}'`);
      expect(vitrinEditorSource).toContain(`"${baslik}"`);
    }
  });

  it("VitrinimEditor her bölümün zorunlu işareti Flutter ile eşit (ilk 3 bölüm zorunlu)", () => {
    const bolumZorunluSayisi = (vitrinEditorSource.match(/title:\s*"(?:Kimlik|İletişim|Konum ve saatler)",\s*\n\s*required:\s*true/g) || []).length;
    expect(bolumZorunluSayisi).toBe(3);
    expect(flutterFormSource).toContain("isRequired: index <= MyVitrinState.locationSectionIndex");
  });

  it("F2 — zorunlu konum alanları ve GPS akışı Next.js Vitrinim'e bağlıdır", () => {
    // Güncel Flutter Vitrinim il/ilçe/adres/GPS'i doğrudan gösterir.
    // Logo, mahalle ve ham koordinatları ekranda görünür tutmak artık parite
    // sözleşmesi değildir; bu alanların veri şemasında bulunması ayrı konudur.
    for (const key of ["il", "ilce", "adres"]) {
      expect(vitrinEditorSource, `VitrinimEditor ${key} içermeli`).toContain(`key: "${key}"`);
    }
    expect(vitrinEditorSource).toContain("konumuAl");
    expect(vitrinEditorSource).toContain("gpsAdresiniCoz");
    expect(vitrinEditorSource).toContain("gpsOnerisiniKabulEt");
    expect(vitrinEditorSource).toContain('const adresTamam = ["adres", "il", "ilce"].every');
  });

  it("F2b — VitrinimEditor akordeonda inline (modal kaldırıldı)", () => {
    for (const comp of ["AboutEditor inline", "CampaignEditor inline", "FaqEditor inline", "MarketplaceEditor inline", "GalleryEditor inline"]) {
      expect(vitrinEditorSource, comp).toContain(comp);
    }
    expect(vitrinEditorSource).not.toContain('setActiveEditor("about")');
    expect(vitrinEditorSource).not.toContain('setActiveEditor("gallery")');
  });
});