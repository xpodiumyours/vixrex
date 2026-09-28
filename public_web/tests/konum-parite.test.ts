import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

/**
 * Konum bilgileri parite testi (Flutter referansiyla).
 */

const flutterStoreData = readFileSync(
  resolve(__dirname, "../../lib/models/store_data.dart"),
  "utf8",
);
const nextSchema = readFileSync(
  resolve(__dirname, "../src/lib/vitrinFieldSchema.ts"),
  "utf8",
);

describe("konum bilgileri parite (Flutter referansiyla)", () => {
  it("Flutter gibi acik adres alanini icerir", () => {
    expect(flutterStoreData).toContain("String address");
    expect(nextSchema).toContain('anahtar: "adres"');
    expect(nextSchema).toContain('kolon: "address"');
  });

  it("Flutter gibi il (province) alanlarini icerir", () => {
    expect(flutterStoreData).toContain("provinceCode");
    expect(flutterStoreData).toContain("provinceName");
    expect(nextSchema).toContain('anahtar: "il"');
    expect(nextSchema).toContain('kolon: "province_name"');
  });

  it("Flutter gibi ilce (district) alanlarini icerir", () => {
    expect(flutterStoreData).toContain("districtCode");
    expect(flutterStoreData).toContain("districtName");
    expect(nextSchema).toContain('anahtar: "ilce"');
    expect(nextSchema).toContain('kolon: "district_name"');
  });

  it("Flutter gibi mahalle alanini icerir", () => {
    expect(flutterStoreData).toContain("neighborhoodName");
    expect(nextSchema).toContain('anahtar: "mahalle"');
    expect(nextSchema).toContain('kolon: "neighborhood_name"');
  });

  it("Flutter gibi GPS koordinatlarini (enlem/boylam) icerir", () => {
    expect(flutterStoreData).toContain("double? latitude");
    expect(flutterStoreData).toContain("double? longitude");
    expect(nextSchema).toContain('anahtar: "enlem"');
    expect(nextSchema).toContain('kolon: "latitude"');
    expect(nextSchema).toContain('anahtar: "boylam"');
    expect(nextSchema).toContain('kolon: "longitude"');
  });

  it("Flutter gibi konum izni (consent) ve kaynak alanlarini icerir", () => {
    expect(flutterStoreData).toContain("locationConsentAt");
    expect(flutterStoreData).toContain("locationSource");
  });

  it("Flutter gibi Google isletme/harita baglantisini icerir", () => {
    expect(flutterStoreData).toContain("googleBusinessLink");
    expect(nextSchema).toContain('anahtar: "haritaLinki"');
    expect(nextSchema).toContain('kolon: "google_business_link"');
  });
});