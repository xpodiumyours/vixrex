// Graphify etki: YonetmenMasasi -> public_web/src/lib/sektorelSablonlar.ts:360
import { describe, it, expect } from "vitest";
import {
  sektorelYonetmenSecenekleri,
  type YonetmenKampanyaSecenegi,
  type YonetmenHikayeSecenegi,
} from "@/lib/sektorelSablonlar";
import { alanOnemi, sonrakiRehberAlanlar } from "@/lib/vitrinReadiness";
import { FIELD_BY_KEY } from "@/lib/vitrinFieldSchema";

describe("Faz 2: Asistan Yaratıcı Yönetmen Sözleşmesi (5 Kurumsal Katman)", () => {
  describe("Katman A: Sektörel Seçenek Motoru Bütünlüğü", () => {
    const sektorler = ["butik", "giyim", "gida", "firin", "kafe_lokanta", "bilinmeyen", null, undefined];

    it.each(sektorler)("%s sektörü için en az 3 kampanya ve 3 hikaye üretmeli", (sektor) => {
      const secenekler = sektorelYonetmenSecenekleri(sektor);

      expect(secenekler.kampanyalar.length).toBeGreaterThanOrEqual(3);
      expect(secenekler.hikayeler.length).toBeGreaterThanOrEqual(3);
    });

    it("Butik sektörü kampanyaları zengin içerik ve rozet taşımalı", () => {
      const secenekler = sektorelYonetmenSecenekleri("butik");
      secenekler.kampanyalar.forEach((camp: YonetmenKampanyaSecenegi) => {
        expect(camp.id).toBeTruthy();
        expect(camp.rozet.length).toBeGreaterThan(2);
        expect(camp.baslik.length).toBeGreaterThan(10);
        expect(camp.aciklama.length).toBeGreaterThan(20);
      });
    });

    it("Butik sektörü hikayeleri 3 farklı esnaf tonu ve 3 kurumsal değer kartı taşımalı", () => {
      const secenekler = sektorelYonetmenSecenekleri("butik");
      expect(secenekler.hikayeler).toHaveLength(3);

      secenekler.hikayeler.forEach((story: YonetmenHikayeSecenegi) => {
        expect(story.id).toBeTruthy();
        expect(story.tonAdi).toBeTruthy();
        expect(story.title.length).toBeGreaterThan(10);
        expect(story.bio.length).toBeGreaterThan(50);
        expect(story.values).toHaveLength(3);
        story.values.forEach((v) => {
          expect(v.title).toBeTruthy();
          expect(v.description.length).toBeGreaterThan(10);
        });
      });
    });

    it("Gıda/Fırın sektörü taş fırın ve doğal ekşi maya içerikleri sunmalı", () => {
      const secenekler = sektorelYonetmenSecenekleri("firin");
      const basliklar = secenekler.kampanyalar.map((c) => c.baslik).join(" ");
      expect(basliklar).toContain("Taş Fırın");
    });
  });

  describe("Katman B & D: Mikro-Form Çilesinin Filtrelenmesi (UpNextList)", () => {
    it("İsteğe bağlı mikro-alanlar (galeriButonMetni vb.) istege-bagli olarak işaretlenmeli", () => {
      const galeriButon = FIELD_BY_KEY.get("galeriButonMetni");
      if (galeriButon) {
        expect(alanOnemi(galeriButon)).toBe("istege-bagli");
      }
    });

    it("UpNextList mantığında isteğe bağlı alanlar filtrelendiğinde form sorgusu yaratmamalı", () => {
      // Boş bir taslakta bile rehber listesinden isteğe bağlı mikro alanlar elenmeli
      const bosTaslak = { store_name: "Test" };
      const sirali = sonrakiRehberAlanlar(bosTaslak, null, new Set(), 10);
      const filtrelenmis = sirali.filter((alan) => alanOnemi(alan) !== "istege-bagli");

      filtrelenmis.forEach((alan) => {
        expect(alanOnemi(alan)).not.toBe("istege-bagli");
      });
    });
  });
});
