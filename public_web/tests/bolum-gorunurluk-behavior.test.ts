import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";

import VitrinProfileView, {
  type VitrinProfileViewProps,
} from "../src/app/v/[slug]/VitrinProfileView";

const bolumKimlikleri = [
  "kategoriler",
  "urunler",
  "hakkimizda",
  "galeri",
  "blog",
  "sss",
  "iletisim",
];

const doluVitrin: VitrinProfileViewProps = {
  storeName: "Test Mağazası",
  storeSlug: "test-magazasi",
  kategori: "Giyim",
  businessType: null,
  status: "Açık",
  logoUrl: null,
  heroImage: "",
  description: "Test açıklaması",
  corporateBio: "Hakkımızda metni",
  address: "Test adresi",
  workingHoursToday: null,
  workingHoursWeek: [],
  googleBusinessLink: null,
  publicUrl: "https://example.com/v/test-magazasi",
  whatsappUrl: null,
  instagramUrl: null,
  websiteUrl: null,
  mapsUrl: null,
  mapsEmbedUrl: null,
  referencesUrl: null,
  isBookingEnabled: false,
  profile: {
    id: "giyim",
    label: "Giyim",
    family: "product",
    sectionTitle: "Ürünler",
    ctaLabel: "Ürün Sor",
    primaryActions: [],
  },
  collections: [{ name: "Elbise", count: 1 }],
  productCount: 1,
  sectionVisibility: null,
  heroLocationText: null,
  mapLabel: null,
  provinceName: null,
  districtName: null,
  neighborhoodName: null,
  categorySectionTitle: null,
  productSectionTitle: null,
  galleryActionLabel: null,
  galleryActionHref: null,
  blogSectionKicker: null,
  blogSectionTitle: null,
  faqSectionKicker: null,
  faqSectionTitle: null,
  faqSectionDescription: null,
  galleryItems: [],
  gallerySection: {
    kicker: "Galeri",
    title: "Mağazamız",
    items: [{ id: "galeri-1", imageUrl: "/galeri.jpg", title: "Vitrin" }],
  },
  marketplaceLinks: [],
  articles: [
    {
      id: "yazi-1",
      slug: "ilk-yazi",
      title: "İlk yazı",
      content: "Yazı içeriği",
    },
  ],
  aboutSection: {
    kicker: "Biz kimiz?",
    title: "Hakkımızda",
    body: "Hakkımızda metni",
    imageUrl: "",
    imageCaption: "",
    values: [],
  },
  faqItems: [{ id: "sss-1", question: "Soru?", answer: "Cevap." }],
  catalog: createElement("div", null, "Ürün kataloğu"),
};

function renderVitrin(sectionVisibility: Record<string, boolean> | null) {
  return renderToStaticMarkup(
    createElement(VitrinProfileView, {
      ...doluVitrin,
      sectionVisibility,
    }),
  );
}

describe("vitrin bölüm görünürlüğü", () => {
  it("kesin false olan dolu bölümleri ziyaretçiden gizler", () => {
    const html = renderVitrin({
      categories: false,
      products: false,
      about: false,
      gallery: false,
      blog: false,
      faq: false,
      contact: false,
    });

    for (const bolumKimligi of bolumKimlikleri) {
      expect(html).not.toContain(`id="${bolumKimligi}"`);
    }
  });

  it.each([null, {}])("%j eski veri doluluğu davranışını korur", (sectionVisibility) => {
    const html = renderVitrin(sectionVisibility);

    for (const bolumKimligi of bolumKimlikleri) {
      expect(html).toContain(`id="${bolumKimligi}"`);
    }
  });

  it("sahibin dolu bölüm metinlerini ve galeri aksiyonunu gösterir", () => {
    const html = renderToStaticMarkup(
      createElement(VitrinProfileView, {
        ...doluVitrin,
        heroLocationText: "Kadıköy, İstanbul",
        mapLabel: "Mağaza girişimiz",
        categorySectionTitle: "Koleksiyonlar",
        productSectionTitle: "Yeni Ürünler",
        galleryActionLabel: "Randevu al",
        galleryActionHref: "#iletisim",
        blogSectionKicker: "Güncel",
        blogSectionTitle: "Mağazadan Haberler",
        faqSectionKicker: "Merak Edilenler",
        faqSectionTitle: "Sorular ve Yanıtlar",
        faqSectionDescription: "Siparişten önce bilmeniz gerekenler.",
      }),
    );

    for (const metin of [
      "Kadıköy, İstanbul",
      "Mağaza girişimiz",
      "Koleksiyonlar",
      "Yeni Ürünler",
      "Randevu al",
      "Güncel",
      "Mağazadan Haberler",
      "Merak Edilenler",
      "Sorular ve Yanıtlar",
      "Siparişten önce bilmeniz gerekenler.",
    ]) {
      expect(html).toContain(metin);
    }
    expect(html).toContain('href="#iletisim"');
  });

  it("boş bölüm metinlerinde mevcut sabit metinleri korur", () => {
    const html = renderVitrin(null);

    for (const metin of [
      "Kategoriler",
      "Ürünler",
      "Tüm Ürünler",
      "Mağazaya gel →",
      "Yazılar",
      "SSS",
      "Sıkça sorulan sorular",
      "Sipariş, stok ve mağaza ziyareti hakkında merak edilenler.",
    ]) {
      expect(html).toContain(metin);
    }
  });
});
