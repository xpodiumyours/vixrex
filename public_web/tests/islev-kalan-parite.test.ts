import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

/**
 * Konum/harita, galeri, hakkimizda, KVKK, dil/ceviri parite testi.
 */

const flutterStoreData = readFileSync(
  resolve(__dirname, "../../lib/models/store_data.dart"),
  "utf8",
);
const nextSchema = readFileSync(
  resolve(__dirname, "../src/lib/vitrinFieldSchema.ts"),
  "utf8",
);

describe("konum/harita parite", () => {
  it("Flutter gibi mapLabel icerir", () => {
    expect(flutterStoreData).toContain("mapLabel");
    expect(nextSchema).toContain("map_label");
  });

  it("Flutter gibi heroLocationText icerir", () => {
    expect(flutterStoreData).toContain("heroLocationText");
    expect(nextSchema).toContain("hero_location_text");
  });
});

describe("galeri parite", () => {
  it("Flutter gibi galleryItems icerir", () => {
    expect(flutterStoreData).toContain("galleryItems");
    expect(nextSchema).toContain("gallery");
  });

  it("Flutter gibi gallerySectionKicker icerir", () => {
    expect(flutterStoreData).toContain("gallerySectionKicker");
    expect(nextSchema).toContain("gallery_section_kicker");
  });
});

describe("hakkimizda parite", () => {
  it("Flutter gibi aboutKicker icerir", () => {
    expect(flutterStoreData).toContain("aboutKicker");
    expect(nextSchema).toContain("about_kicker");
  });

  it("Flutter gibi aboutTitle icerir", () => {
    expect(flutterStoreData).toContain("aboutTitle");
    expect(nextSchema).toContain("about_title");
  });

  it("Flutter gibi aboutImageUrl icerir", () => {
    expect(flutterStoreData).toContain("aboutImageUrl");
    expect(nextSchema).toContain("about_image_url");
  });
});

describe("KVKK/yasal parite", () => {
  it("Flutter gibi legalConfig icerir", () => {
    const flutterLegal = readFileSync(
      resolve(__dirname, "../../lib/config/legal_config.dart"),
      "utf8",
    );
    expect(flutterLegal).toContain("LegalConfig");
  });

  it("Next.js KVKK sayfasi vardir", () => {
    const nextPrivacy = readFileSync(
      resolve(__dirname, "../src/app/privacy/page.tsx"),
      "utf8",
    );
    expect(nextPrivacy).toContain("KVKK");
  });
});

describe("dil/ceviri parite", () => {
  it("Flutter gibi ceviri altyapisi vardir", () => {
    // Flutter'da l10n.yaml ve çeviri dosyali
    const l10n = readFileSync(
      resolve(__dirname, "../../l10n.yaml"),
      "utf8",
    );
    expect(l10n).toContain("arb");
  });

  it("Next.js ceviri altyapisi vardir", () => {
    // Next.js'de locale destegi
    const nextLayout = readFileSync(
      resolve(__dirname, "../src/app/layout.tsx"),
      "utf8",
    );
    expect(nextLayout).toContain("lang");
  });
});