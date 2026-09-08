import { kategoriSablonHaritasi } from "@/lib/categoryTemplates";

export type MaterialRoundIconName =
  | "build_circle"
  | "calendar_month"
  | "camera_alt"
  | "chat_bubble"
  | "checkroom"
  | "construction"
  | "content_cut"
  | "delivery_dining"
  | "directions"
  | "event_available"
  | "local_dining"
  | "location_on"
  | "menu_book"
  | "phone_android"
  | "photo_library"
  | "qr_code_2"
  | "restaurant_menu"
  | "shopping_bag"
  | "spa"
  | "verified";

/** Hero telefon mockup'ındaki dört örnek profil — Flutter landing_screen.dart referansı. */
export type MockupProfili = {
  ad: string;
  kategoriSeridi: string;
  kategoriKimligi: string;
  kapakUrl: string | null;
  galeriUrlleri: string[];
  hedefUrl: string;
  aciklama: string;
  durum: string;
  vurguRengi: string;
  anaSimge: MaterialRoundIconName;
  uStRozet: { simge: MaterialRoundIconName; renk: string; metin: string };
  altRozet: { simge: MaterialRoundIconName; renk: string; metin: string };
  eylemler: readonly { simge: MaterialRoundIconName; renk: string }[];
  eylemSatirlari: readonly {
    simge: MaterialRoundIconName;
    baslik: string;
    altBaslik: string;
    renk: string;
  }[];
};

const TANIMLAR = [
  {
    ad: "Aymira Giyim",
    serit: "KADIN GİYİM / BUTİK",
    kimlik: "giyim",
    demoSlug: "demo-aymira-giyim",
    aciklama: "Yeni sezon reyonları ve mağaza fotoğrafları tek vitrinde.",
    durum: "AÇIK",
    vurguRengi: "#FF5A1F",
    anaSimge: "checkroom",
    uStRozet: { simge: "photo_library", renk: "#FF5A1F", metin: "Galeri" },
    altRozet: { simge: "qr_code_2", renk: "#FF5A1F", metin: "QR kod" },
    eylemler: [
      { simge: "chat_bubble", renk: "#25D366" },
      { simge: "camera_alt", renk: "#E1306C" },
    ],
    eylemSatirlari: [
      { simge: "photo_library", baslik: "Vitrin galerisi", altBaslik: "Raf ve reyon fotoğrafları", renk: "#FF5A1F" },
      { simge: "shopping_bag", baslik: "Trendyol", altBaslik: "Mağazayı ziyaret edin", renk: "#F27A1A" },
    ],
  },
  {
    ad: "Lezzet Durağı",
    serit: "KAFE / RESTORAN",
    kimlik: "kafe_lokanta",
    demoSlug: "demo-lezzet-duragi",
    aciklama: "Menü, konum ve WhatsApp sipariş bilgileri tek ekranda.",
    durum: "AÇIK",
    vurguRengi: "#EA580C",
    anaSimge: "restaurant_menu",
    uStRozet: { simge: "menu_book", renk: "#EA580C", metin: "Menü" },
    altRozet: { simge: "directions", renk: "#EA580C", metin: "Yol tarifi" },
    eylemler: [
      { simge: "chat_bubble", renk: "#25D366" },
      { simge: "location_on", renk: "#EF4444" },
    ],
    eylemSatirlari: [
      { simge: "local_dining", baslik: "Günün menüsü", altBaslik: "Sıcak yemek ve tatlılar", renk: "#EA580C" },
      { simge: "delivery_dining", baslik: "Paket servis", altBaslik: "WhatsApp ile sipariş", renk: "#10B981" },
    ],
  },
  {
    ad: "Nova Kuaför",
    serit: "KUAFÖR / GÜZELLİK",
    kimlik: "kuafor",
    demoSlug: "demo-nova-kuafor",
    aciklama: "Randevu, hizmetler ve sosyal medya bağlantıları hazır.",
    durum: "AÇIK",
    vurguRengi: "#DB2777",
    anaSimge: "content_cut",
    uStRozet: { simge: "calendar_month", renk: "#DB2777", metin: "Randevu" },
    altRozet: { simge: "camera_alt", renk: "#DB2777", metin: "Instagram" },
    eylemler: [
      { simge: "chat_bubble", renk: "#25D366" },
      { simge: "camera_alt", renk: "#E1306C" },
    ],
    eylemSatirlari: [
      { simge: "spa", baslik: "Hizmetler", altBaslik: "Kesim, boya ve bakım", renk: "#DB2777" },
      { simge: "event_available", baslik: "Randevu al", altBaslik: "WhatsApp ile hızlı iletişim", renk: "#10B981" },
    ],
  },
  {
    ad: "TeknoFix",
    serit: "TELEFON TEKNİK SERVİS",
    kimlik: "teknik_servis",
    demoSlug: "demo-teknofix",
    aciklama: "Servis talebi, adres ve güvenilir iletişim tek vitrinde.",
    durum: "AÇIK",
    vurguRengi: "#2563EB",
    anaSimge: "build_circle",
    uStRozet: { simge: "chat_bubble", renk: "#2563EB", metin: "WhatsApp" },
    altRozet: { simge: "location_on", renk: "#2563EB", metin: "Konum" },
    eylemler: [
      { simge: "chat_bubble", renk: "#25D366" },
      { simge: "phone_android", renk: "#2563EB" },
    ],
    eylemSatirlari: [
      { simge: "construction", baslik: "Servis kaydı", altBaslik: "Ekran, batarya ve bakım", renk: "#2563EB" },
      { simge: "verified", baslik: "Google yorumları", altBaslik: "Müşteri güveni", renk: "#6366F1" },
    ],
  },
] as const;

export async function mockupProfilleriniGetir(): Promise<MockupProfili[]> {
  const sablonlar = await kategoriSablonHaritasi();

  return TANIMLAR.map((tanim) => {
    const sablon = sablonlar.get(tanim.kimlik);
    return {
      ad: tanim.ad,
      kategoriSeridi: tanim.serit,
      kategoriKimligi: tanim.kimlik,
      kapakUrl: sablon?.kapaklar[0]?.url ?? null,
      galeriUrlleri: (sablon?.galeri ?? []).slice(0, 3).map((g) => g.url),
      hedefUrl: `/v/${tanim.demoSlug}`,
      aciklama: tanim.aciklama,
      durum: tanim.durum,
      vurguRengi: tanim.vurguRengi,
      anaSimge: tanim.anaSimge,
      uStRozet: tanim.uStRozet,
      altRozet: tanim.altRozet,
      eylemler: tanim.eylemler,
      eylemSatirlari: tanim.eylemSatirlari,
    };
  });
}
