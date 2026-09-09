import { kategoriSablonHaritasi } from "@/lib/categoryTemplates";
import { kategoriUrlParcasi } from "@/lib/businessCategories";

/**
 * Hero telefon mockup'ındaki dört örnek profil — envanter §2.3.
 *
 * Adlar Flutter landing'deki tanıtım mockup'ıyla aynı tutuldu (ürün kararı,
 * 2026-08-26): bunlar bir vitrin vaadini gösteren reklam görselleridir.
 *
 * İKİ FARK var, ikisi de bilinçli:
 *   1. Görseller uydurma Unsplash bağlantılarından değil, GERÇEK şablon
 *      kütüphanesinden gelir (category_image_templates). Flutter'da bu
 *      eşleme bozuktu: 20 arayüz anahtarının 11'i veritabanındaki 19
 *      kanonik kimlikle eşleşmiyordu, o kartlar sessizce yedek görsele
 *      düşüyordu. Burada doğrudan kanonik kimlik kullanılıyor.
 *   2. Tıklama `/v/demo-*` demo vitrinine değil, o kategorinin Keşfet
 *      sayfasına gider. Demo vitrinler #345 ile aramadan çıkarılıyor;
 *      ana sayfadan oraya iç bağlantı vermek o bağlantıyı boşa harcardı.
 */

export type MockupProfili = {
  ad: string;
  kategoriSeridi: string;
  kategoriKimligi: string;
  kapakUrl: string | null;
  galeriUrlleri: string[];
  hedefUrl: string;
  /** Uygulamadaki HeroDemoProfile ile aynı metinler */
  aciklama: string;
  durum: string;
  /**
   * Rozet metni Flutter'dan ayrı alan olarak alınır (landing_screen.dart
   * 62/64, 101/103, 140/142, 179/181): rengine göre ternary ile tahmin
   * etmek kırılgandı — 2026-09-08 canlı karşılaştırmada yanlış etiket
   * ürettiği görüldü.
   */
  /** Üst rozet (ör. "Galeri", "Menü") */
  uStRozet: { simge: string; renk: string; metin: string };
  /** Alt rozet (ör. "QR kod", "Yol tarifi") */
  altRozet: { simge: string; renk: string; metin: string };
  /** Eylem simgeleri (ör. WhatsApp, Instagram) */
  eylemler: readonly { simge: string; renk: string }[];
  /** Eylem satırları (ör. "Günün menüsü / Sıcak yemek ve tatlılar") */
  eylemSatirlari: readonly { baslik: string; altBaslik: string; renk: string }[];
};

const TANIMLAR = [
  {
    ad: "Aymira Giyim",
    serit: "KADIN GİYİM / BUTİK",
    kimlik: "giyim",
    aciklama: "Yeni sezon reyonları ve mağaza fotoğrafları tek vitrinde.",
    durum: "AÇIK",
    uStRozet: { simge: "🖼️", renk: "#FF5A1F", metin: "Galeri" },
    altRozet: { simge: "📱", renk: "#FF5A1F", metin: "QR kod" },
    eylemler: [
      { simge: "💬", renk: "#25D366" },
      { simge: "📷", renk: "#E1306C" },
    ],
    eylemSatirlari: [
      { baslik: "Vitrin galerisi", altBaslik: "Raf ve reyon fotoğrafları", renk: "#FF5A1F" },
      { baslik: "Trendyol", altBaslik: "Mağazayı ziyaret edin", renk: "#F27A1A" },
    ],
  },
  {
    ad: "Lezzet Durağı",
    serit: "KAFE / RESTORAN",
    kimlik: "kafe_lokanta",
    aciklama: "Menü, konum ve WhatsApp sipariş bilgileri tek ekranda.",
    durum: "AÇIK",
    uStRozet: { simge: "📖", renk: "#EA580C", metin: "Menü" },
    altRozet: { simge: "📍", renk: "#EA580C", metin: "Yol tarifi" },
    eylemler: [
      { simge: "💬", renk: "#25D366" },
      { simge: "📍", renk: "#EF4444" },
    ],
    eylemSatirlari: [
      { baslik: "Günün menüsü", altBaslik: "Sıcak yemek ve tatlılar", renk: "#EA580C" },
      { baslik: "Paket servis", altBaslik: "WhatsApp ile sipariş", renk: "#10B981" },
    ],
  },
  {
    ad: "Nova Kuaför",
    serit: "KUAFÖR / GÜZELLİK",
    kimlik: "kuafor",
    aciklama: "Randevu, hizmetler ve sosyal medya bağlantıları hazır.",
    durum: "AÇIK",
    uStRozet: { simge: "📅", renk: "#DB2777", metin: "Randevu" },
    altRozet: { simge: "📷", renk: "#DB2777", metin: "Instagram" },
    eylemler: [
      { simge: "💬", renk: "#25D366" },
      { simge: "📷", renk: "#E1306C" },
    ],
    eylemSatirlari: [
      { baslik: "Hizmetler", altBaslik: "Kesim, boya ve bakım", renk: "#DB2777" },
      { baslik: "Randevu al", altBaslik: "WhatsApp ile hızlı iletişim", renk: "#10B981" },
    ],
  },
  {
    ad: "TeknoFix",
    serit: "TELEFON TEKNİK SERVİS",
    kimlik: "teknik_servis",
    aciklama: "Servis talebi, adres ve güvenilir iletişim tek vitrinde.",
    durum: "AÇIK",
    uStRozet: { simge: "💬", renk: "#2563EB", metin: "WhatsApp" },
    altRozet: { simge: "📍", renk: "#2563EB", metin: "Konum" },
    eylemler: [
      { simge: "💬", renk: "#25D366" },
      { simge: "📱", renk: "#2563EB" },
    ],
    eylemSatirlari: [
      { baslik: "Servis kaydı", altBaslik: "Ekran, batarya ve bakım", renk: "#2563EB" },
      { baslik: "Google yorumları", altBaslik: "Müşteri güveni", renk: "#6366F1" },
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
      hedefUrl: `/kesfet/${kategoriUrlParcasi(tanim.kimlik)}`,
      aciklama: tanim.aciklama,
      durum: tanim.durum,
      uStRozet: tanim.uStRozet,
      altRozet: tanim.altRozet,
      eylemler: tanim.eylemler,
      eylemSatirlari: tanim.eylemSatirlari,
    };
  });
}
