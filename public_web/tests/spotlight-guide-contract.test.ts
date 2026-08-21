import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

// 2026-08-22: "sayfada dolaşan rehber" — esnaf tıkladığında yan panelde
// form açılmak yerine, oyunlardaki gibi ok/spot ışığıyla ilgili alana
// yönlendirilsin isteği. Sıralama mantığı (önce zorunlu, sonra kalite
// alanları) zaten vitrinReadiness.ts'te vardı; bu test yalnız yeni görsel
// katmanın ONU TEKRAR YAZMADAN, mevcut mantığa bağlandığını kilitler.

const spotlightPath = resolve(
  __dirname,
  "../src/app/v/[slug]/components/SpotlightGuide.tsx",
);
const panelPath = resolve(__dirname, "../src/app/v/[slug]/OwnerAssistantPanel.tsx");
const spotlightSource = readFileSync(spotlightPath, "utf8");
const panelSource = readFileSync(panelPath, "utf8");

describe("SpotlightGuide — sayfada dolaşan rehber", () => {
  it("kendi sıralama/seçim mantığını icat etmiyor, mevcut data-vixrex-editable işaretini okuyor", () => {
    expect(spotlightSource).toContain("data-vixrex-editable");
    // Bu dosya yalnız seçili TEK alanın önemini sınıflandırır (alanOnemi);
    // "hangi alan sırada" hesaplamasını (tumAlanlarSirali/sonrakiRehberAlan)
    // import ETMEMELİ — sıralama tek kaynak vitrinReadiness.ts'te kalmalı.
    const importSatiri = spotlightSource
      .split("\n")
      .find((satir) => satir.includes('from "@/lib/vitrinReadiness"'));
    expect(importSatiri).toContain("alanOnemi");
    expect(importSatiri).not.toMatch(/tumAlanlarSirali|sonrakiRehberAlan/);
  });

  it("önem seviyesine göre (temel/kalite/isteğe bağlı) farklı metin gösterir", () => {
    expect(spotlightSource).toContain("temel");
    expect(spotlightSource).toContain("kalite");
    expect(spotlightSource).toContain("istege-bagli");
  });

  it("panel açıldığında ilk eksik alanı otomatik seçer — mevcut sonrakiRehberAlan sırasını (önce zorunlu, sonra kalite) kullanır", () => {
    expect(panelSource).toContain(
      'import { alanOnemi, asamaDolulugu, sonrakiRehberAlan } from "@/lib/vitrinReadiness";',
    );
    expect(panelSource).toMatch(
      /sonrakiRehberAlan\(yerelTaslak,\s*null,\s*atlanmisAlanlar\)/,
    );
  });

  it("panel açık ve bir alan seçiliyken SpotlightGuide render edilir", () => {
    expect(panelSource).toContain("<SpotlightGuide");
    expect(panelSource).toMatch(/\{acik\s*&&\s*\(\s*<SpotlightGuide/);
  });

  it("rehberi kapatmak yalnız seçimi temizler, panelin kendisini veya sıradaki-alana-geç akışını kapatmaz", () => {
    expect(panelSource).toContain("const rehberiKapat");
    expect(panelSource).toMatch(/rehberiKapat = \(\) => \{\s*vurguyuTemizle\(\);\s*setSeciliAlan\(null\);/);
  });
});
