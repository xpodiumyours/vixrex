import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";
import { VITRIN_FIELDS, SECTION_LABELS, SECTION_ORDER } from "@/lib/vitrinFieldSchema";

// Tüm alanlara erişim nöbetçisi (bulgu 5).
//
// Panel yalnız "eksik" saydığı 12 alanı listeliyordu; şemadaki 44 alanın
// 32'si "isteğe bağlı" olduğu için ne yüzdeye ne de listeye giriyordu.
// Bir alana ulaşmanın iki yolu vardı — vitrinde o yazıya tıklamak (alan
// BOŞSA vitrinde çizilmiyor, tıklanacak bir şey yok) ya da eksikler
// listesinden seçmek (orada değil). Sonuç: 32 alan hiçbir yoldan
// erişilemiyordu.
//
// Casper 2026-08-06: "41 alana çıkarmıştık ama asistan hiçbir şeyi
// düzenleyemiyor gibi görünüyor."

const panel = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/OwnerAssistantPanel.tsx"),
  "utf-8"
);

describe("Sahip paneli şemadaki her alana ulaştırıyor", () => {
  it("tüm alanlar görünümü var", () => {
    expect(panel).toContain("Tüm alanlar");
    expect(panel).toContain("VITRIN_FIELDS.length");
  });

  it("liste şemadan üretiliyor, elle yazılmıyor", () => {
    // Elle yazılan liste kaçınılmaz olarak eskir; yeni alan eklenince
    // yine erişilemez olur.
    expect(panel).toContain("VITRIN_FIELDS.filter");
    expect(panel).toContain("SECTION_ORDER.map");
  });

  it("her alan tıklanabilir — alanSec çağrısı bağlı", () => {
    const blok = panel.slice(panel.indexOf("Tüm alanlar"));
    expect(blok).toContain("alanSec(alan.anahtar)");
  });

  it("her bölümün Türkçe adı var", () => {
    for (const bolum of SECTION_ORDER) {
      expect(SECTION_LABELS[bolum]).toBeTruthy();
    }
    // Şemadaki her bölüm sırada olmalı; biri unutulursa alanları görünmez.
    const bolumler = new Set(VITRIN_FIELDS.map((a) => a.bolum));
    for (const bolum of bolumler) {
      expect(SECTION_ORDER).toContain(bolum);
    }
  });
});
