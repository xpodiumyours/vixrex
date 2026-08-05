// Vitrin alan şeması — sahibin düzenleyebileceği her alanın tek kaynağı.
//
// İnsan tarafı: docs/vitrin-alan-semasi.md
// Plan: implementation_plan.md Commit 8
//
// NEDEN BU DOSYA VAR
// Alan başına ayrı dallanma yazılırsa kırk alanda tıkanılır. Referans
// sablonlar/hedef-vitrin.html'de tam olarak bu oldu: sekiz elle yazılmış
// dal var, o yüzden orada yalnız dokuz alan tıklanabiliyor; Hakkımızda ve
// SSS bölümleri tıklanamıyor bile.
//
// Buradaki her satır tek başına şunları üretir:
//   - izin listesi (hangi alan yazılabilir)
//   - sunucu doğrulaması (tip ve sınırlar)
//   - kullanıcıya gösterilen Türkçe etiket
//   - tıkla-düzenle işareti (data-vixrex-editable / data-vixrex-label)
//   - hangi bölüme odaklanılacağı
//
// YENİ ALAN EKLEMEK = BU LİSTEYE BİR SATIR. Kod değişikliği gerekiyorsa
// mekanizma yanlış kurulmuştur.
//
// `anahtar` yayına çıktıktan sonra DEĞİŞTİRİLMEZ: asistan komutları ve
// kayıtlı taslaklar ona bağlıdır. Yeni alan eklenir, eski anahtar silinmez.

import { PROFILES } from "./vitrinProfile";

export type VitrinFieldType =
  | "metin"
  | "uzunMetin"
  | "sayi"
  | "telefon"
  | "eposta"
  | "url"
  | "gorsel"
  | "secim"
  | "acikKapali";

export type VitrinSection =
  | "hero"
  | "contact"
  | "categories"
  | "products"
  | "featured"
  | "about"
  | "gallery"
  | "blog"
  | "faq";

export interface VitrinField {
  /** Komutlarda kullanılan sabit ad. Yayına çıktıktan sonra değişmez. */
  anahtar: string;
  tip: VitrinFieldType;
  /** Kullanıcıya gösterilen Türkçe ad. Asistan bunu konuşur. */
  etiket: string;
  /** stores tablosundaki / draft_data içindeki hedef anahtar. */
  kolon: string;
  /** Vitrindeki hangi bölüm — tıkla-düzenle odaklaması için. */
  bolum: VitrinSection;
  zorunlu?: boolean;
  minUzunluk?: number;
  maxUzunluk?: number;
  /** sayi tipi için sınırlar. */
  min?: number;
  max?: number;
  /** secim tipi için geçerli değerler. Boşsa serbest seçim. */
  secenekler?: readonly string[];
  /** Kısa yardım metni; asistan ve form birlikte kullanır. */
  ipucu?: string;
}

export const VITRIN_FIELDS: readonly VitrinField[] = [
  // ── Hero / işletme kimliği ────────────────────────────────────────────
  {
    anahtar: "isletmeAdi",
    tip: "metin",
    etiket: "İşletme Adı",
    kolon: "name",
    bolum: "hero",
    zorunlu: true,
    minUzunluk: 2,
    maxUzunluk: 60,
  },
  {
    anahtar: "heroRozet",
    tip: "metin",
    etiket: "Hero Rozet Metni",
    kolon: "hero_badge",
    bolum: "hero",
    maxUzunluk: 60,
    ipucu: "Örn: Profesyonel Teknik Servis / Kadıköy",
  },
  {
    anahtar: "kisaTanitim",
    tip: "uzunMetin",
    etiket: "Kısa Tanıtım",
    kolon: "description",
    bolum: "hero",
    maxUzunluk: 300,
  },
  {
    anahtar: "konumMetni",
    tip: "metin",
    etiket: "Hero Konum Metni",
    kolon: "hero_location_text",
    bolum: "hero",
    maxUzunluk: 60,
    ipucu: "Örn: Kadıköy, İstanbul",
  },
  {
    anahtar: "kategori",
    tip: "secim",
    etiket: "İşletme Kategorisi",
    kolon: "kategori",
    bolum: "hero",
    maxUzunluk: 40,
    // Tek kaynak vitrinProfile.ts — ayrı liste tutulmaz.
    secenekler: PROFILES.map((p) => p.label),
  },
  {
    anahtar: "isletmeTuru",
    tip: "metin",
    etiket: "İşletme Türü",
    kolon: "business_type",
    bolum: "hero",
    maxUzunluk: 40,
  },
  {
    anahtar: "logo",
    tip: "gorsel",
    etiket: "Logo",
    kolon: "logo_url",
    bolum: "hero",
  },
  {
    anahtar: "kapakGorseli",
    tip: "gorsel",
    etiket: "Kapak / Hero Görseli",
    kolon: "shelf_image_url",
    bolum: "hero",
  },
  {
    anahtar: "tema",
    tip: "secim",
    etiket: "Tema Ön Ayarı",
    kolon: "theme_preset",
    bolum: "hero",
    maxUzunluk: 40,
  },

  // ── İletişim ──────────────────────────────────────────────────────────
  {
    anahtar: "whatsapp",
    tip: "telefon",
    etiket: "WhatsApp Numarası",
    kolon: "whatsapp",
    bolum: "contact",
  },
  {
    anahtar: "telefon",
    tip: "telefon",
    etiket: "Telefon",
    kolon: "phone",
    bolum: "contact",
  },
  {
    anahtar: "eposta",
    tip: "eposta",
    etiket: "E-posta",
    kolon: "email",
    bolum: "contact",
    maxUzunluk: 120,
  },
  {
    anahtar: "adres",
    tip: "uzunMetin",
    etiket: "Açık Adres",
    kolon: "address",
    bolum: "contact",
    maxUzunluk: 200,
  },
  {
    anahtar: "haritaEtiketi",
    tip: "metin",
    etiket: "Harita Kartı Etiketi",
    kolon: "map_label",
    bolum: "contact",
    maxUzunluk: 120,
  },
  {
    anahtar: "calismaSaatleri",
    tip: "metin",
    etiket: "Çalışma Saatleri",
    kolon: "working_hours",
    bolum: "contact",
    maxUzunluk: 400,
  },
  {
    anahtar: "instagram",
    tip: "metin",
    etiket: "Instagram Kullanıcı Adı",
    kolon: "instagram",
    bolum: "contact",
    maxUzunluk: 30,
    ipucu: "@ işareti olmadan yazın",
  },
  {
    anahtar: "website",
    tip: "url",
    etiket: "Web Sitesi",
    kolon: "website",
    bolum: "contact",
  },
  {
    anahtar: "haritaLinki",
    tip: "url",
    etiket: "Google İşletme / Harita Bağlantısı",
    kolon: "google_business_link",
    bolum: "contact",
  },
  {
    anahtar: "enlem",
    tip: "sayi",
    etiket: "Konum — Enlem",
    kolon: "latitude",
    bolum: "contact",
    min: -90,
    max: 90,
  },
  {
    anahtar: "boylam",
    tip: "sayi",
    etiket: "Konum — Boylam",
    kolon: "longitude",
    bolum: "contact",
    min: -180,
    max: 180,
  },

  // ── Katalog bölüm başlıkları ──────────────────────────────────────────
  {
    anahtar: "kategoriBolumBaslik",
    tip: "metin",
    etiket: "Kategori Bölümü Başlığı",
    kolon: "category_section_title",
    bolum: "categories",
    maxUzunluk: 60,
  },
  {
    anahtar: "urunBolumBaslik",
    tip: "metin",
    etiket: "Ürün Bölümü Başlığı",
    kolon: "product_section_title",
    bolum: "products",
    maxUzunluk: 60,
  },

  // ── Öne çıkan kampanya bandı ──────────────────────────────────────────
  {
    anahtar: "bantEtiket",
    tip: "metin",
    etiket: "Kampanya Etiketi",
    kolon: "featured_banner_label",
    bolum: "featured",
    maxUzunluk: 40,
  },
  {
    anahtar: "bantBaslik",
    tip: "metin",
    etiket: "Kampanya Başlığı",
    kolon: "featured_banner_title",
    bolum: "featured",
    maxUzunluk: 90,
  },
  {
    anahtar: "bantAciklama",
    tip: "uzunMetin",
    etiket: "Kampanya Açıklaması",
    kolon: "featured_banner_description",
    bolum: "featured",
    maxUzunluk: 200,
  },
  {
    anahtar: "bantGorsel",
    tip: "gorsel",
    etiket: "Kampanya Görseli",
    kolon: "featured_banner_image_url",
    bolum: "featured",
  },
  {
    anahtar: "bantFiyat",
    tip: "metin",
    etiket: "Kampanya Fiyat Metni",
    kolon: "featured_banner_price_text",
    bolum: "featured",
    maxUzunluk: 30,
  },

  // ── Hakkımızda ────────────────────────────────────────────────────────
  {
    anahtar: "hakkindaUstBaslik",
    tip: "metin",
    etiket: "Hakkımızda Üst Başlık",
    kolon: "about_kicker",
    bolum: "about",
    maxUzunluk: 40,
  },
  {
    anahtar: "hakkindaBaslik",
    tip: "metin",
    etiket: "Hakkımızda Başlığı",
    kolon: "about_title",
    bolum: "about",
    maxUzunluk: 90,
  },
  {
    anahtar: "hakkindaMetin",
    tip: "uzunMetin",
    etiket: "Hakkımızda Yazısı",
    kolon: "corporate_bio",
    bolum: "about",
    maxUzunluk: 1200,
  },
  {
    anahtar: "hakkindaGorsel",
    tip: "gorsel",
    etiket: "Hakkımızda Görseli",
    kolon: "about_image_url",
    bolum: "about",
  },
  {
    anahtar: "hakkindaGorselAlt",
    tip: "metin",
    etiket: "Görsel Alt Yazısı",
    kolon: "about_image_caption",
    bolum: "about",
    maxUzunluk: 120,
  },

  // ── Galeri ────────────────────────────────────────────────────────────
  {
    anahtar: "galeriUstBaslik",
    tip: "metin",
    etiket: "Galeri Üst Başlık",
    kolon: "gallery_section_kicker",
    bolum: "gallery",
    maxUzunluk: 40,
  },
  {
    anahtar: "galeriBaslik",
    tip: "metin",
    etiket: "Galeri Başlığı",
    kolon: "gallery_section_title",
    bolum: "gallery",
    maxUzunluk: 90,
  },
  {
    anahtar: "galeriAksiyonMetni",
    tip: "metin",
    etiket: "Galeri Buton Metni",
    kolon: "gallery_action_label",
    bolum: "gallery",
    maxUzunluk: 40,
  },
  {
    anahtar: "galeriAksiyonLinki",
    tip: "url",
    etiket: "Galeri Buton Bağlantısı",
    kolon: "gallery_action_href",
    bolum: "gallery",
  },

  // ── Blog ──────────────────────────────────────────────────────────────
  {
    anahtar: "blogUstBaslik",
    tip: "metin",
    etiket: "Blog Üst Başlık",
    kolon: "blog_section_kicker",
    bolum: "blog",
    maxUzunluk: 40,
  },
  {
    anahtar: "blogBaslik",
    tip: "metin",
    etiket: "Blog Bölüm Başlığı",
    kolon: "blog_section_title",
    bolum: "blog",
    maxUzunluk: 90,
  },

  // ── SSS ───────────────────────────────────────────────────────────────
  {
    anahtar: "sssUstBaslik",
    tip: "metin",
    etiket: "SSS Üst Başlık",
    kolon: "faq_section_kicker",
    bolum: "faq",
    maxUzunluk: 40,
  },
  {
    anahtar: "sssBaslik",
    tip: "metin",
    etiket: "SSS Bölüm Başlığı",
    kolon: "faq_section_title",
    bolum: "faq",
    maxUzunluk: 90,
  },
  {
    anahtar: "sssAciklama",
    tip: "uzunMetin",
    etiket: "SSS Bölüm Açıklaması",
    kolon: "faq_section_description",
    bolum: "faq",
    maxUzunluk: 200,
  },

  // ── Görünürlük ────────────────────────────────────────────────────────
  {
    anahtar: "puanGoster",
    tip: "acikKapali",
    etiket: "Değerlendirme Puanını Göster",
    kolon: "show_storefront_rating",
    bolum: "hero",
  },
  {
    anahtar: "yolTarifiGoster",
    tip: "acikKapali",
    etiket: "Yol Tarifi Butonunu Göster",
    kolon: "show_directions_link",
    bolum: "contact",
  },
  {
    anahtar: "referansLinki",
    tip: "url",
    etiket: "Referanslar Bağlantısı",
    kolon: "references_link",
    bolum: "about",
  },
] as const;

/** anahtar → alan. Komut işleyicisi bunu kullanır. */
export const FIELD_BY_KEY: ReadonlyMap<string, VitrinField> = new Map(
  VITRIN_FIELDS.map((f) => [f.anahtar, f])
);

/** Yazılabilir kolon adları. Sunucu tarafı izin listesi. */
export const EDITABLE_COLUMNS: readonly string[] = VITRIN_FIELDS.map(
  (f) => f.kolon
);

/** Belirli bir bölümün alanları — tıkla-düzenle ve panel gruplaması için. */
export function fieldsOfSection(bolum: VitrinSection): VitrinField[] {
  return VITRIN_FIELDS.filter((f) => f.bolum === bolum);
}
