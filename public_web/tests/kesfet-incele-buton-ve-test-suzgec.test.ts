import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it, vi } from "vitest";
import { isTestOrDenemeStore } from "@/lib/testStoreFilter";
import type { KesfetVitrini } from "@/lib/explore";

vi.mock("next/link", () => ({
  default: (props: { href: string; children?: unknown; className?: string }) =>
    createElement("a", { href: props.href, className: props.className }, props.children as never),
}));

vi.mock("@/lib/useKesfetKirala", () => ({
  useKesfetKirala: () => ({
    durum: "kapali",
    hataMesaji: "",
    mevcutSlug: "",
    token: null,
    formRef: { current: null },
    baslat: () => {},
    sifirla: () => {},
  }),
}));

vi.mock("@/lib/fiyatlandirma", () => ({
  AYLIK_PREMIUM_BEDEL: "aylik-bedel",
  PREMIUM_DEGIL_ROZET: "premium-degil",
}));

vi.mock("@/app/v/[slug]/components/VixrexAvatar", () => ({
  VixrexAvatar: () => createElement("span", { "data-testid": "mock-avatar" }),
}));

import { VitrinKarti } from "@/components/kesfet/VitrinKarti";

function ornekVitrin(kiralikMi: boolean): KesfetVitrini {
  return {
    slug: kiralikMi ? "kiralik-vitrin-42" : "normal-vitrin-17",
    ad: "Örnek Dükkan",
    aciklama: "",
    kategoriEtiketi: "Yeme İçme",
    kategoriKimligi: null,
    kapakUrl: null,
    konum: "İstanbul",
    kiralikMi,
    acikMi: true,
    urunSayisi: 3,
    urunAdlari: [],
    whatsapp: null,
    guncellemeZamani: null,
    puan: null,
    mesafeMetre: null,
  };
}

function renderEdilenBaglantilar(html: string): Array<{ href: string; ad: string }> {
  const baglantilar: Array<{ href: string; ad: string }> = [];
  for (const eslesme of html.matchAll(/<a\b[^>]*\bhref="([^"]*)"[^>]*>([\s\S]*?)<\/a>/g)) {
    baglantilar.push({
      href: eslesme[1],
      ad: eslesme[2].replace(/<[^>]*>/g, "").trim(),
    });
  }
  return baglantilar;
}

describe("VitrinKarti İncele bağlantısı — gerçek render", () => {
  for (const kiralikMi of [true, false]) {
    it(`kiralikMi=${kiralikMi} vitrinde İncele bağlantısı doğru /v/<slug> adresini taşır`, () => {
      const vitrin = ornekVitrin(kiralikMi);
      const html = renderToStaticMarkup(createElement(VitrinKarti, { vitrin }));

      const inceleBaglantilari = renderEdilenBaglantilar(html).filter(
        (baglanti) => baglanti.ad === "İncele",
      );

      expect(inceleBaglantilari).toHaveLength(1);
      expect(inceleBaglantilari[0].href).toBe(`/v/${vitrin.slug}`);
    });
  }
});

describe("isTestOrDenemeStore", () => {
  it("is_demo === true olan resmi kiralık şablonları her zaman korur", () => {
    expect(
      isTestOrDenemeStore({
        name: "Test Kiralık Vitrin",
        slug: "deneme-sablon-mw123456",
        is_demo: true,
      })
    ).toBe(false);
  });

  it("is_demo !== true olup adı veya slug'ı test/deneme/aasd/sssss/dename/-mw... içeren kayıtları eler", () => {
    const elenecekler = [
      { name: "Test Market", slug: "market-1", is_demo: false },
      { name: "Normal Market", slug: "test-market", is_demo: false },
      { name: "Deneme Dükkan", slug: "dukkan-1", is_demo: null },
      { name: "Dükkan", slug: "deneme-dukkan", is_demo: false },
      { name: "aasd", slug: "aasd-1", is_demo: false },
      { name: "Mağaza", slug: "sssss-magaza", is_demo: false },
      { name: "Dename Vitrin", slug: "vitrin-1", is_demo: false },
      { name: "Gerçek İsim", slug: "dukkan-mw1a2b3c", is_demo: false },
    ];

    for (const kayit of elenecekler) {
      expect(isTestOrDenemeStore(kayit)).toBe(true);
    }
  });

  it("gerçek vitrinleri ve boş alanlı kayıtları elemez", () => {
    expect(
      isTestOrDenemeStore({
        name: "Karadeniz Pide & Kebap",
        slug: "karadeniz-pide-kebap",
        is_demo: false,
      })
    ).toBe(false);
    expect(
      isTestOrDenemeStore({
        name: null,
        slug: null,
        is_demo: null,
      })
    ).toBe(false);
  });
});
