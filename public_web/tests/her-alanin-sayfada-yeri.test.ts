import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";

import VitrinProfileView, {
  type VitrinProfileViewProps,
} from "../src/app/v/[slug]/VitrinProfileView";
import { VITRIN_FIELDS } from "../src/lib/vitrinFieldSchema";

// 2026-08-22, Faz 1 — "her alanın sayfada bir yeri olsun".
//
// Rehber balonu hedefini `[data-vixrex-editable="<anahtar>"]` ile arar;
// bulamazsa hiç açılmaz. Bu yüzden 46 alandan 9'u (İl ve İlçe dahil, ikisi
// de yayın için ZORUNLU) sahip için erişilemezdi. Bu dosya o durumun geri
// gelmesini engeller.

const BOS_VITRIN: VitrinProfileViewProps = {
  storeName: "Test Mağazası",
  storeSlug: "test-magazasi",
  kategori: null,
  businessType: null,
  status: null,
  logoUrl: null,
  heroImage: "",
  description: "",
  corporateBio: null,
  address: null,
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
  collections: [],
  productCount: 0,
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
  marketplaceLinks: [],
  articles: [],
  catalog: createElement("div", null, "Ürün kataloğu"),
};

function ciz(ekstra: Partial<VitrinProfileViewProps>) {
  return renderToStaticMarkup(
    createElement(VitrinProfileView, { ...BOS_VITRIN, ...ekstra }),
  );
}

describe("iskelet vitrin — sahip modunda her alan erişilebilir", () => {
  it("46 alanın hepsinin tıklanabilir bir işareti var", () => {
    const html = ciz({ ownerMode: true, ownerDraft: {} });

    const ulasilamayan = VITRIN_FIELDS.filter(
      (alan) => !html.includes(`data-vixrex-editable="${alan.anahtar}"`),
    ).map((alan) => alan.anahtar);

    expect(ulasilamayan, "sayfada yeri olmayan alanlar").toEqual([]);
  });
});

describe("müşteri görünümü — sahip araçları sızmaz", () => {
  it("ownerMode kapalıyken çıktıda hiç sahip işareti yok", () => {
    const html = ciz({});
    expect(html).not.toContain("data-vixrex-");
    expect(html).not.toContain("Bu bölüme eklenebilir");
  });

  it("taslak geçilse bile ownerMode kapalıysa şerit çizilmez", () => {
    const html = ciz({ ownerDraft: {} });
    expect(html).not.toContain("data-vixrex-");
    expect(html).not.toContain("Bu bölüme eklenebilir");
  });

  // Boş bölümler ziyaretçide eskisi gibi tamamen gizli kalır — iskelet
  // yalnız sahip modunda çıkar (dilim2 kampanya bandı sözleşmesi burada
  // davranış olarak da ölçülür).
  it("boş bölümler ziyaretçiye hiç çizilmez", () => {
    const html = ciz({});
    for (const bolumKimligi of ["kategoriler", "urunler", "hakkimizda", "galeri", "blog", "sss"]) {
      expect(html).not.toContain(`id="${bolumKimligi}"`);
    }
    expect(html).not.toContain("müşteriye görünmüyor");
  });
});

// Dolu bir vitrin: her bölüm gerçekten çizilir, alanların çoğu kendi
// görünen öğesini alır. Buradaki asıl soru "boş alan doldurulabiliyor mu"
// değil, "DOLDURDUKTAN SONRA düzeltilebiliyor mu" — 2026-08-22'de ölçüldü,
// 9 alan (il/ilçe dahil) dolduktan sonra erişilemez hâle geliyordu.
const DOLU_EKSTRA: Partial<VitrinProfileViewProps> = {
  kategori: "Giyim",
  businessType: "Butik",
  status: "Açık",
  isClosed: false,
  logoUrl: "/logo.png",
  heroImage: "/kapak.jpg",
  heroBadge: "Kadıköy'ün butiği",
  description: "Kısa tanıtım metni",
  corporateBio: "Hakkımızda yazısı",
  address: "Test Mah. Test Sok. No:1",
  phone: "02161234567",
  phoneUrl: "tel:+902161234567",
  email: "test@example.com",
  showStorefrontRating: true,
  ratingScore: 4.8,
  reviewCount: 12,
  workingHoursToday: "09:00 - 19:00",
  workingHoursWeek: [{ day: "Pazartesi", hours: "09:00 - 19:00", isToday: true }],
  googleBusinessLink: "https://maps.google.com/isletme",
  whatsappUrl: "https://wa.me/905551112233",
  instagramUrl: "https://instagram.com/testmagaza",
  websiteUrl: "https://example.com",
  mapsUrl: "https://maps.google.com/yol",
  mapsEmbedUrl: "https://maps.google.com/embed",
  referencesUrl: "https://example.com/referanslar",
  collections: [{ name: "Elbise", count: 3 }],
  productCount: 3,
  heroLocationText: "Kadıköy, İstanbul",
  mapLabel: "Mağaza girişimiz",
  provinceName: "İstanbul",
  districtName: "Kadıköy",
  neighborhoodName: "Caddebostan",
  categorySectionTitle: "Koleksiyonlar",
  productSectionTitle: "Yeni Ürünler",
  galleryActionLabel: "Hepsini gör",
  galleryActionHref: "https://instagram.com/testmagaza",
  blogSectionKicker: "Güncel",
  blogSectionTitle: "Mağazadan Haberler",
  faqSectionKicker: "Merak Edilenler",
  faqSectionTitle: "Sorular ve Yanıtlar",
  faqSectionDescription: "Sipariş ve stok hakkında.",
  featuredBanner: {
    label: "Bu haftaya özel",
    title: "Kampanya başlığı",
    description: "Kampanya açıklaması",
    priceText: "499 TL",
    imageUrl: "/kampanya.jpg",
  },
  aboutSection: {
    kicker: "Biz kimiz",
    title: "Hakkımızda başlığı",
    body: "Hakkımızda yazısı",
    imageUrl: "/hakkinda.jpg",
    imageCaption: "Atölyemiz, 2019",
    values: [{ id: "d1", title: "Değer", description: "Açıklama" }],
  },
  gallerySection: {
    kicker: "İşlerimizden",
    title: "Galeri başlığı",
    items: [{ id: "g1", imageUrl: "/galeri.jpg", title: "Vitrin" }],
  },
  galleryItems: [{ id: "g1", imageUrl: "/galeri.jpg", title: "Vitrin" }],
  articles: [{ id: "y1", slug: "ilk-yazi", title: "İlk yazı", content: "İçerik" }],
  faqItems: [{ id: "s1", question: "Soru?", answer: "Cevap." }],
};

/** Şemadaki her alanın dolu sayıldığı taslak — DOLU_EKSTRA ile aynı gerçek. */
const DOLU_TASLAK: Record<string, unknown> = Object.fromEntries(
  VITRIN_FIELDS.map((alan) => [
    alan.kolon,
    alan.tip === "acikKapali" ? true : alan.anahtar === "kategori" ? "Giyim" : "dolu",
  ]),
);

describe("dolu vitrin — alanlar dolduktan sonra da düzeltilebilir", () => {
  it("46 alanın hepsi hâlâ tıklanabilir", () => {
    const html = ciz({
      ...DOLU_EKSTRA,
      ownerMode: true,
      ownerDraft: DOLU_TASLAK,
    });

    const ulasilamayan = VITRIN_FIELDS.filter(
      (alan) => !html.includes(`data-vixrex-editable="${alan.anahtar}"`),
    ).map((alan) => alan.anahtar);

    expect(
      ulasilamayan,
      "dolduktan sonra erişilemez hâle gelen alanlar — BolumEksikleri " +
        "içindeki SAYFADA_KENDI_YERI_OLMAYANLAR listesine bakın",
    ).toEqual([]);
  });

  it("dolu vitrinde de müşteri görünümüne sahip işareti sızmaz", () => {
    const html = ciz({ ...DOLU_EKSTRA });
    expect(html).not.toContain("data-vixrex-");
    expect(html).not.toContain("Bu bölüme eklenebilir");
  });
});
