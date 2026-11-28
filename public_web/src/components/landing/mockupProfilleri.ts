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

export type MockupAksiyonHapi = {
  etiket: string;
  vurgu: "birincil" | "whatsapp" | "notr";
};

export type MockupVitrinKarti = {
  baslik: string;
  altBilgi: string;
  gorselUrl: string | null;
};

export type MockupProfili = {
  ad: string;
  basHarfler: string;
  kategoriSeridi: string;
  kategoriKimligi: string;
  konumSatiri: string;
  calismaSaati: string;
  bolumBasligi: string;
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
  aksiyonHaplari: readonly MockupAksiyonHapi[];
  vitrinKartlari: readonly MockupVitrinKarti[];
};

const TANIMLAR = [
  {
    ad: "Aymira Giyim",
    basHarfler: "AG",
    serit: "KADIN GİYİM / BUTİK",
    kimlik: "giyim",
    konumSatiri: "Kadıköy, İstanbul",
    calismaSaati: "Bugün 09:30–21:00",
    bolumBasligi: "Ürün Kategorileri",
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
    aksiyonHaplari: [
      { etiket: "Hemen Ara", vurgu: "birincil" as const },
      { etiket: "Rafta Ayırt", vurgu: "notr" as const },
      { etiket: "WhatsApp Sor", vurgu: "whatsapp" as const },
      { etiket: "Yol Tarifi", vurgu: "notr" as const },
    ],
    vitrinBolumleri: [
      { baslik: "Yeni Sezon", altBilgi: "Koleksiyon" },
      { baslik: "Butik Seçki", altBilgi: "Öne çıkanlar" },
      { baslik: "Kombinler", altBilgi: "Vitrin seçimi" },
      { baslik: "Aksesuar", altBilgi: "Mağaza reyonu" },
    ],
  },
  {
    ad: "Lezzet Durağı",
    basHarfler: "LD",
    serit: "KAFE / RESTORAN",
    kimlik: "kafe_lokanta",
    konumSatiri: "Şişli, İstanbul",
    calismaSaati: "Bugün 08:30–22:30",
    bolumBasligi: "Menü Kategorileri",
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
    aksiyonHaplari: [
      { etiket: "Hemen Ara", vurgu: "birincil" as const },
      { etiket: "Menüye Bak", vurgu: "notr" as const },
      { etiket: "WhatsApp Sipariş", vurgu: "whatsapp" as const },
      { etiket: "Yol Tarifi", vurgu: "notr" as const },
    ],
    vitrinBolumleri: [
      { baslik: "Günün Menüsü", altBilgi: "Sıcak tabaklar" },
      { baslik: "Kahve & Tatlı", altBilgi: "Taze sunum" },
      { baslik: "Kahvaltı", altBilgi: "Serpme seçki" },
      { baslik: "Paket Servis", altBilgi: "Hızlı gönderim" },
    ],
  },
  {
    ad: "Nova Kuaför",
    basHarfler: "NK",
    serit: "KUAFÖR / GÜZELLİK",
    kimlik: "kuafor",
    konumSatiri: "Beşiktaş, İstanbul",
    calismaSaati: "Bugün 09:00–20:00",
    bolumBasligi: "Hizmet Kategorileri",
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
    aksiyonHaplari: [
      { etiket: "Hemen Ara", vurgu: "birincil" as const },
      { etiket: "Randevu Al", vurgu: "notr" as const },
      { etiket: "WhatsApp Sor", vurgu: "whatsapp" as const },
      { etiket: "Yol Tarifi", vurgu: "notr" as const },
    ],
    vitrinBolumleri: [
      { baslik: "Saç Kesimi", altBilgi: "Stil tasarım" },
      { baslik: "Renklendirme", altBilgi: "Boya & bakım" },
      { baslik: "Fön & Şekil", altBilgi: "Günlük stil" },
      { baslik: "Kişisel Bakım", altBilgi: "Randevulu" },
    ],
  },
  {
    ad: "TeknoFix",
    basHarfler: "TF",
    serit: "TELEFON TEKNİK SERVİS",
    kimlik: "teknik_servis",
    konumSatiri: "Konak, İzmir",
    calismaSaati: "Bugün 09:00–19:30",
    bolumBasligi: "Servis Kategorileri",
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
    aksiyonHaplari: [
      { etiket: "Hemen Ara", vurgu: "birincil" as const },
      { etiket: "Servis Kaydı", vurgu: "notr" as const },
      { etiket: "WhatsApp Sor", vurgu: "whatsapp" as const },
      { etiket: "Yol Tarifi", vurgu: "notr" as const },
    ],
    vitrinBolumleri: [
      { baslik: "Ekran Değişimi", altBilgi: "Aynı gün" },
      { baslik: "Batarya", altBilgi: "Hızlı servis" },
      { baslik: "Donanım", altBilgi: "Kontrol" },
      { baslik: "Aksesuar", altBilgi: "Orijinal" },
    ],
  },
] as const;

export async function mockupProfilleriniGetir(): Promise<MockupProfili[]> {
  const sablonlar = await kategoriSablonHaritasi();

  return TANIMLAR.map((tanim) => {
    const sablon = sablonlar.get(tanim.kimlik);
    const kapakUrl = sablon?.kapaklar[0]?.url ?? null;
    const galeriUrlleri = (sablon?.galeri ?? []).slice(0, 3).map((g) => g.url);
    const kartHavuzu = Array.from(
      new Set([
        ...(sablon?.urunler ?? []).map((u) => u.url),
        ...(sablon?.galeri ?? []).map((g) => g.url),
        ...(sablon?.kapaklar ?? []).slice(1).map((k) => k.url),
        ...(kapakUrl ? [kapakUrl] : []),
      ]),
    );

    return {
      ad: tanim.ad,
      basHarfler: tanim.basHarfler,
      kategoriSeridi: tanim.serit,
      kategoriKimligi: tanim.kimlik,
      konumSatiri: tanim.konumSatiri,
      calismaSaati: tanim.calismaSaati,
      bolumBasligi: tanim.bolumBasligi,
      kapakUrl,
      galeriUrlleri,
      hedefUrl: `/kesfet/${kategoriUrlParcasi(tanim.kimlik)}`,
      aciklama: tanim.aciklama,
      durum: tanim.durum,
      uStRozet: tanim.uStRozet,
      altRozet: tanim.altRozet,
      eylemler: tanim.eylemler,
      eylemSatirlari: tanim.eylemSatirlari,
      aksiyonHaplari: tanim.aksiyonHaplari,
      vitrinKartlari: tanim.vitrinBolumleri.map((bolum, index) => ({
        baslik: bolum.baslik,
        altBilgi: bolum.altBilgi,
        gorselUrl: kartHavuzu[index] ?? null,
      })),
    };
  });
}
