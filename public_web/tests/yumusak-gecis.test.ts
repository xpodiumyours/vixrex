import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

import { kaydirmaSuresi } from "../src/lib/sayfaKaydirma";
import { SECTION_DOM_ID, SECTION_ORDER } from "../src/lib/vitrinFieldSchema";

// Faz 3b (2026-08-22) — "yumuşak bir şekilde alanları gezdirerek, sayfa
// keskin ve sert inmemeli" (Casper).
//
// Eskiden tek satırdı: `scrollIntoView({behavior:"smooth"})`. Tarayıcı
// mesafeyi umursamıyor, uzak hedefe de aynı kısa sürede gidiyordu —
// canlı testte "birden bire çok hızlı en alttaki bilgilere çakılıyor"
// diye bildirildi.

const oku = (p: string) => readFileSync(resolve(__dirname, p), "utf8");

const secimKaynak = oku("../src/app/v/[slug]/hooks/useFieldSelection.ts");
const kaydirmaKaynak = oku("../src/lib/sayfaKaydirma.ts");
const balonKaynak = oku("../src/app/v/[slug]/components/SpotlightGuide.tsx");
const vitrinKaynak = oku("../src/app/v/[slug]/VitrinProfileView.tsx");
const seritKaynak = oku("../src/app/v/[slug]/components/BolumEksikleri.tsx");

describe("kaydirmaSuresi — mesafeye göre süre", () => {
  it("yakın hedefe kısa, uzak hedefe uzun sürede gider", () => {
    expect(kaydirmaSuresi(50)).toBeLessThan(kaydirmaSuresi(3000));
  });

  it("yön fark etmez — yukarı ve aşağı aynı süre", () => {
    expect(kaydirmaSuresi(-1500)).toBe(kaydirmaSuresi(1500));
  });

  it("çok uzak mesafede bile süre sınırlıdır (tembellik hissi olmasın)", () => {
    expect(kaydirmaSuresi(100000)).toBeLessThanOrEqual(900);
  });
});

describe("kaydırma kullanıcıyla kavga etmez", () => {
  it("kullanıcı dokunur/tekerlek çevirirse kaydırma bırakılır", () => {
    expect(kaydirmaKaynak).toContain('addEventListener("wheel", birak');
    expect(kaydirmaKaynak).toContain('addEventListener("touchstart", birak');
  });

  it("hareket azaltma tercihine uyar", () => {
    expect(kaydirmaKaynak).toContain("prefers-reduced-motion");
    expect(kaydirmaKaynak).toContain("hareketAzaltilsin");
  });

  it("sayfa sınırlarının dışına kaydırmaz", () => {
    expect(kaydirmaKaynak).toContain("enFazlaKaydirma");
  });
});

describe("rehber hedefe yürür", () => {
  it("tarayıcının kendi scrollIntoView'ı artık kullanılmıyor", () => {
    expect(secimKaynak).not.toMatch(/scrollIntoView\(/);
    expect(secimKaynak).toContain("yumusakKaydir");
  });

  it("hedef zaten görünüyorsa sayfa hiç oynatılmaz", () => {
    expect(secimKaynak).toContain("rahatGorunuyorMu");
  });

  it("bölüm değişiyorsa önce bölüm başına inilir, kısa durulur", () => {
    expect(secimKaynak).toContain("oncekiBolum !== bolum");
    expect(secimKaynak).toContain("SECTION_DOM_ID[bolum]");
    expect(secimKaynak).toContain("bekle(300)");
  });

  it("yolda yeni alan seçilirse eski geçiş susar", () => {
    expect(secimKaynak).toContain("gecisRef");
    expect(secimKaynak).toContain("numara === gecisRef.current");
  });

  it("yazma alanı ancak VARINCA odaklanır — klavye yolu bozmasın", () => {
    const bitirGovdesi = secimKaynak.slice(
      secimKaynak.indexOf("const bitir = ()"),
      secimKaynak.indexOf("if (rahatGorunuyorMu"),
    );
    expect(bitirGovdesi).toContain("girisRef.current?.focus()");
  });
});

describe("balon yolda kapalı, sembol yürür", () => {
  it("geçiş sürerken balon görünmez ve tıklanamaz", () => {
    expect(balonKaynak).toContain("gecisSuruyor");
    expect(balonKaynak).toContain("pointer-events-none scale-95 opacity-0");
  });

  it("hedefin yanında ayrı bir Vixrex sembolü var ve kayarak gider", () => {
    const semboller = balonKaynak.match(/<VixrexAvatar/g) ?? [];
    // Biri balonun içinde (başlık), biri hedefin yanında yürüyen.
    expect(semboller.length).toBeGreaterThanOrEqual(2);
    expect(balonKaynak).toContain("transition-all duration-500 ease-out");
  });
});

describe("her bölümün duraklama noktası var", () => {
  it("SECTION_DOM_ID şemadaki her bölümü kapsar", () => {
    for (const bolum of SECTION_ORDER) {
      expect(SECTION_DOM_ID[bolum]).toBeTruthy();
    }
  });

  it("kimlikler vitrinde ya gerçek bölümde ya iskelette bulunur", () => {
    for (const bolum of SECTION_ORDER) {
      const kimlik = SECTION_DOM_ID[bolum];
      const vitrindeVar = vitrinKaynak.includes(`id="${kimlik}"`);
      const iskeletteVar = seritKaynak.includes("SECTION_DOM_ID[bolum]");
      expect(
        vitrindeVar || iskeletteVar,
        `${bolum} bölümünün duraklama noktası yok`,
      ).toBe(true);
    }
  });
});
