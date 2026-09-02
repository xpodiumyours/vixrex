import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

// Faz 4 (2026-08-22) — Casper, gerçek cihazda test etti:
// "mobilde herhangi bir yeri değiştirmek istediğimizde yine Vixrex
// asistanın sohbet paneli bütün sayfayı kapatıyor."
//
// Kararı: ayrı bir alt şerit İCAT EDİLMESİN. "Sadece Vixrex'in maskot
// simgesi olsun, kutucuklarda zaten ne yapılması gerektiği yazıyor —
// kutuları ve Vixrex maskotunu mobile uyumlu yapamıyor muyuz?"
//
// Yani tek kutu, tek mantık: panel çekilir, balon ve sembol kalır; balon
// klavyeyi bilerek konumlanır.

const oku = (p: string) => readFileSync(resolve(__dirname, p), "utf8");
const panel = oku("../src/app/v/[slug]/OwnerAssistantPanel.tsx");
const balon = oku("../src/app/v/[slug]/components/SpotlightGuide.tsx");

describe("mobilde panel sayfayı kapatmaz", () => {
  it("alan seçilince mobilde harita kapanır", () => {
    expect(panel).toContain("setHaritaAcik(false)");
    expect(panel).toContain('window.matchMedia("(min-width: 640px)")');
  });

  it("panel yalnız harita açıkken çizilir", () => {
    expect(panel).toContain("{acik && haritaAcik && (");
  });

  it("mobilde harita açıkken balon gizlenir — üst üste binmez", () => {
    expect(panel).toContain("{acik && !(!masaustu && haritaAcik) && (");
  });

  it("haritaya dönüş yolu balondaki düğmede", () => {
    expect(panel).toContain("onHaritaAc={() => setHaritaAcik(true)}");
    expect(balon).toContain('aria-label="Tüm alanlar"');
  });

  it("masaüstünde harita kapanmaz — yer bol", () => {
    // Kapatma düğmesi masaüstünde asistanı, mobilde yalnız haritayı kapatır.
    expect(panel).toContain("masaustu ? setAcik(false) : setHaritaAcik(false)");
  });
});

describe("balon klavyeyi biliyor", () => {
  it("pencere değil GÖRÜNEN alan ölçülür", () => {
    expect(balon).toContain("window.visualViewport");
    expect(balon).toContain("gv?.offsetTop");
  });

  it("klavye açılıp kapanınca yeniden konumlanır", () => {
    expect(balon).toContain(
      'window.visualViewport?.addEventListener("resize", konumuGuncelle)',
    );
    expect(balon).toContain(
      'window.visualViewport?.removeEventListener("resize", konumuGuncelle)',
    );
  });

  it("altına/üstüne sığmıyorsa görünen bandın dibine sabitlenir", () => {
    expect(balon).toContain("const altaSigar");
    expect(balon).toContain("const usteSigar");
    expect(balon).toContain("balonUst = bandAlt - 8 - yukseklik");
  });

  it("balon görünen bandın üstünden taşmaz", () => {
    expect(balon).toContain("balonUst = Math.max(bandUst + 8, balonUst)");
  });

  it("yüksekliği tahmin etmez, gerçek boyunu ölçer", () => {
    expect(balon).toContain("balonRef");
    expect(balon).toContain("setBalonYukseklik");
  });

  it("dibe sabitlenmiş balonda ok çizilmez — yanlış yeri gösterirdi", () => {
    expect(balon).toContain("const okGorunur = altaSigar || usteSigar");
    expect(balon).toContain("{okGorunur && (");
  });
});

describe("maskot rehberi başlatır, haritayı değil", () => {
  it("Vixrex düğmesi haritayı AÇMAZ (masaüstünde de) — Faz A, Tek Asistan planı", () => {
    // Casper, 2026-08-22: "mobilde asistan maskota tıklayınca yine sayfa
    // kapanıyor". Düğme haritayı da açıyordu, harita mobilde tam ekran.
    // Faz A (2026-09-02): masaüstünde de artık otomatik açmıyor —
    // SpotlightGuide varsayılan yol, harita yalnız ☰ ile elle açılır.
    expect(panel).toContain("setHaritaAcik(yeni && !yapilacakVar)");
    expect(panel).not.toContain("setHaritaAcik(yeni);");
  });

  it("doldurulacak alan kalmadıysa harita açılır", () => {
    // Yoksa asistan açılıyor ama ekranda hiçbir şey görünmüyor gibi olur.
    expect(panel).toContain("setHaritaAcik(yeni && !yapilacakVar)");
  });

  it("aktif akışta masaüstünde artık otomatik harita açılmıyor", () => {
    expect(panel).not.toContain("setHaritaAcik(isDesktop)");
  });
});
