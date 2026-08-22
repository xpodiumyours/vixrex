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
  /**
   * Şart değil ama vitrini web sitesi kalitesine çıkarır — hazırlık
   * raporunun "kalite" önem sınıfı buradan gelir (bkz. vitrinReadiness.ts).
   * Bir alan aynı anda hem zorunlu hem kalite olamaz.
   */
  kalite?: boolean;
  minUzunluk?: number;
  maxUzunluk?: number;
  /** sayi tipi için sınırlar. */
  min?: number;
  max?: number;
  /** secim tipi için geçerli değerler. Boşsa serbest seçim. */
  secenekler?: readonly string[];
  /** Kısa yardım metni; asistan ve form birlikte kullanır. */
  ipucu?: string;
  /**
   * Bu alan esnafa NE KAZANDIRIR — tek cümle, zorlamayan, öğreten.
   * Rehber balonu bunu konuşur (bkz. SpotlightGuide). `ipucu` "nasıl
   * yazılır"ı söyler, bu "neden yazılır"ı; ikisi ayrı iştir.
   *
   * tool/sema_disa_aktar.ts bu alanı DIŞA AKTARMAZ — Flutter tarafının
   * ihtiyacı yok, shared/vitrin_alanlari.json değişmesin diye bilerek
   * listeye alınmadı (schema-drift CI'ı).
   */
  neden?: string;
  /**
   * Doğrulama kuralının adı (ör. "tr_mobil"). Flutter ve Next.js bu kuralı
   * kendi doğrulama adapter'larında uygular; şema kuralın ortak adını taşır.
   */
  dogrulama?: string;
  /**
   * Bu değerlere sahip bir alan "boş" sayılır — örn. kategori için
   * "Diğer" seçilmesi teknik olarak dolu ama işlevsel olarak eksik
   * (kategoriye bağlı hiçbir şey çalışmaz). `doluMu()` bunu okur.
   */
  bosDegerler?: readonly string[];
}

export const VITRIN_FIELDS: readonly VitrinField[] = [
  // ── Hero / işletme kimliği ────────────────────────────────────────────
  {
    anahtar: "isletmeAdi",
    tip: "metin",
    etiket: "İşletme Adı",
    neden: "Müşterinin ilk gördüğü isim. Google aramalarında ve paylaşımlarda da bu çıkar.",
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
    neden: "Adının yanında duran küçük vurgu — seni benzer işletmelerden ayıran cümle.",
    kolon: "hero_badge",
    bolum: "hero",
    kalite: true,
    maxUzunluk: 60,
    ipucu: "Örn: Profesyonel Teknik Servis / Kadıköy",
  },
  {
    anahtar: "kisaTanitim",
    tip: "uzunMetin",
    etiket: "Kısa Tanıtım",
    neden: "Sayfaya giren kişi iki saniyede ne yaptığını anlar. Boş kalırsa vitrin sessiz görünür.",
    kolon: "description",
    bolum: "hero",
    maxUzunluk: 300,
  },
  {
    anahtar: "konumMetni",
    tip: "metin",
    etiket: "Hero Konum Metni",
    neden: "Üstte duran \"neredeyim\" bilgisi. Yakındaki müşteri seni görünce güvenir.",
    kolon: "hero_location_text",
    bolum: "hero",
    maxUzunluk: 60,
    ipucu: "Örn: Kadıköy, İstanbul",
  },
  {
    anahtar: "kategori",
    tip: "secim",
    etiket: "İşletme Kategorisi",
    neden: "Vitrinin renkleri, butonları ve hazır görselleri buna göre gelir. Boşken hiçbiri çalışmaz.",
    kolon: "kategori",
    bolum: "hero",
    maxUzunluk: 40,
    zorunlu: true,
    // Tek kaynak vitrinProfile.ts — ayrı liste tutulmaz.
    secenekler: PROFILES.map((p) => p.label),
    // Flutter'ın categoryCompleted getter'ıyla aynı kural (Faz F): "Diğer"
    // teknik olarak dolu ama kategoriye bağlı hiçbir şey (butonlar, hazır
    // görseller) çalışmadığı için işlevsel olarak eksik sayılır.
    bosDegerler: ["diger", "diğer"],
  },
  {
    anahtar: "isletmeTuru",
    tip: "metin",
    etiket: "İşletme Türü",
    neden: "Kategorinin altındaki ince tanım — \"Kuaför\" yerine \"Erkek kuaförü\" gibi.",
    kolon: "business_type",
    bolum: "hero",
    maxUzunluk: 40,
  },
  {
    anahtar: "logo",
    tip: "gorsel",
    etiket: "Logo",
    neden: "Küçük de olsa bir logo, vitrini şablon değil gerçek bir işletme gibi gösterir.",
    kolon: "logo_url",
    bolum: "hero",
    kalite: true,
  },
  {
    anahtar: "kapakGorseli",
    tip: "gorsel",
    etiket: "Kapak / Hero Görseli",
    neden: "Sayfanın en üstündeki büyük görsel. İlk izlenimin yarısı budur.",
    kolon: "shelf_image_url",
    bolum: "hero",
    kalite: true,
  },

  // ── İletişim ──────────────────────────────────────────────────────────
  {
    anahtar: "whatsapp",
    tip: "telefon",
    etiket: "WhatsApp Numarası",
    neden: "Müşterinin sana ulaşmasının en kısa yolu. Tek dokunuşla sohbet açılır.",
    kolon: "whatsapp",
    bolum: "contact",
    zorunlu: true,
    dogrulama: "tr_mobil",
  },
  {
    anahtar: "telefon",
    tip: "telefon",
    etiket: "Telefon",
    neden: "Arayarak ulaşmak isteyenler için. WhatsApp kullanmayan müşteri de var.",
    kolon: "phone",
    bolum: "contact",
  },
  {
    anahtar: "eposta",
    tip: "eposta",
    etiket: "E-posta",
    neden: "Kurumsal iş ve teklif isteyenler buradan yazar.",
    kolon: "email",
    bolum: "contact",
    maxUzunluk: 120,
  },
  {
    anahtar: "adres",
    tip: "uzunMetin",
    etiket: "Açık Adres",
    neden: "Müşteri kapına gelebilsin diye. Haritada işaretlenen yer de burasıdır.",
    kolon: "address",
    bolum: "contact",
    zorunlu: true,
    maxUzunluk: 200,
  },
  // Faz F (Tek Asistan planı) eklendi: Flutter'ın addressCompleted'ı ve
  // asıl yayın kapısı store_publish_validator.dart adresle BİRLİKTE il/ilçe
  // de zorunlu tutuyordu, ama şemada hiç alan olarak yoktu — Next.js
  // tarafı bunu hiç bilmiyordu (bkz. docs/alan-eslemesi.md). Kolonlar
  // (province_name/district_name) DB'de zaten var, migration gerekmedi.
  {
    anahtar: "il",
    tip: "metin",
    etiket: "İl",
    neden: "Yayın için gerekli. Bulunduğun ilin aramalarında çıkmanı sağlar.",
    kolon: "province_name",
    bolum: "contact",
    zorunlu: true,
    maxUzunluk: 60,
  },
  {
    anahtar: "ilce",
    tip: "metin",
    etiket: "İlçe",
    neden: "Yayın için gerekli. \"Kadıköy kuaför\" gibi aramalarda seni öne çıkarır.",
    kolon: "district_name",
    bolum: "contact",
    zorunlu: true,
    maxUzunluk: 60,
  },
  // #264: il/ilçeden daha yerel bir SEO sinyali yoktu. Zorunlu değil —
  // il/ilçe zaten yayın kapısını karşılıyor, bu yalnız kaliteyi artırır.
  {
    anahtar: "mahalle",
    tip: "metin",
    etiket: "Mahalle",
    neden: "En yerel arama sinyali — yakınındaki müşteri seni daha kolay bulur.",
    kolon: "neighborhood_name",
    bolum: "contact",
    kalite: true,
    maxUzunluk: 60,
    ipucu: "Örn: Caddebostan",
  },
  {
    anahtar: "haritaEtiketi",
    tip: "metin",
    etiket: "Harita Kartı Etiketi",
    neden: "Harita kartının üstünde duran kısa not. Örn: Çarşı içi, otopark var.",
    kolon: "map_label",
    bolum: "contact",
    maxUzunluk: 120,
  },
  {
    anahtar: "calismaSaatleri",
    tip: "metin",
    etiket: "Çalışma Saatleri",
    neden: "Müşteri boşuna gelmesin. Açık/kapalı rozeti de buradan hesaplanır.",
    kolon: "working_hours",
    bolum: "contact",
    maxUzunluk: 400,
    kalite: true,
  },
  {
    anahtar: "instagram",
    tip: "metin",
    etiket: "Instagram Kullanıcı Adı",
    neden: "Instagram hesabın vitrine bağlanır, müşteri işlerini oradan da görür.",
    kolon: "instagram",
    bolum: "contact",
    maxUzunluk: 30,
    ipucu: "@ işareti olmadan yazın",
  },
  {
    anahtar: "website",
    tip: "url",
    etiket: "Web Sitesi",
    neden: "Ayrı bir siten varsa buraya koy, ziyaretçi kaybolmaz.",
    kolon: "website",
    bolum: "contact",
  },
  {
    anahtar: "haritaLinki",
    tip: "url",
    etiket: "Google İşletme / Harita Bağlantısı",
    neden: "Google İşletme kaydın — yol tarifi ve yorumlar oraya bağlanır.",
    kolon: "google_business_link",
    bolum: "contact",
    kalite: true,
  },
  {
    anahtar: "enlem",
    tip: "sayi",
    etiket: "Konum — Enlem",
    neden: "Haritadaki iğnenin tam yeri. Adres tam bulunamıyorsa bunu düzeltir.",
    kolon: "latitude",
    bolum: "contact",
    min: -90,
    max: 90,
  },
  {
    anahtar: "boylam",
    tip: "sayi",
    etiket: "Konum — Boylam",
    neden: "Enlemle birlikte çalışır; ikisi olmadan harita tam oturmaz.",
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
    neden: "Ürün gruplarının üstündeki başlık. \"Kategoriler\" yerine kendi cümleni yazabilirsin.",
    kolon: "category_section_title",
    bolum: "categories",
    maxUzunluk: 60,
  },
  {
    anahtar: "urunBolumBaslik",
    tip: "metin",
    etiket: "Ürün Bölümü Başlığı",
    neden: "Ürün listesinin üstündeki başlık. \"Ürünler\" yerine \"Menümüz\" gibi yazabilirsin.",
    kolon: "product_section_title",
    bolum: "products",
    maxUzunluk: 60,
  },

  // ── Öne çıkan kampanya bandı ──────────────────────────────────────────
  {
    anahtar: "bantEtiket",
    tip: "metin",
    etiket: "Kampanya Etiketi",
    neden: "Kampanya kutusunun köşesindeki küçük etiket. Örn: Bu haftaya özel.",
    kolon: "featured_banner_label",
    bolum: "featured",
    maxUzunluk: 40,
  },
  {
    anahtar: "bantBaslik",
    tip: "metin",
    etiket: "Kampanya Başlığı",
    neden: "Öne çıkarmak istediğin teklifin başlığı. Sayfanın en dikkat çeken yeri.",
    kolon: "featured_banner_title",
    bolum: "featured",
    maxUzunluk: 90,
  },
  {
    anahtar: "bantAciklama",
    tip: "uzunMetin",
    etiket: "Kampanya Açıklaması",
    neden: "Kampanyanın ne olduğunu bir iki cümleyle anlatır.",
    kolon: "featured_banner_description",
    bolum: "featured",
    maxUzunluk: 200,
  },
  {
    anahtar: "bantGorsel",
    tip: "gorsel",
    etiket: "Kampanya Görseli",
    neden: "Kampanyanın yanındaki fotoğraf. Görselli kampanya daha çok tıklanır.",
    kolon: "featured_banner_image_url",
    bolum: "featured",
  },
  {
    anahtar: "bantFiyat",
    tip: "metin",
    etiket: "Kampanya Fiyat Metni",
    neden: "Fiyatı yazarsan müşteri sormadan karar verir. Örn: 499 TL'den başlayan.",
    kolon: "featured_banner_price_text",
    bolum: "featured",
    maxUzunluk: 30,
  },

  // ── Hakkımızda ────────────────────────────────────────────────────────
  {
    anahtar: "hakkindaUstBaslik",
    tip: "metin",
    etiket: "Hakkımızda Üst Başlık",
    neden: "Hakkında bölümünün üstündeki küçük yazı. Örn: Biz kimiz.",
    kolon: "about_kicker",
    bolum: "about",
    maxUzunluk: 40,
  },
  {
    anahtar: "hakkindaBaslik",
    tip: "metin",
    etiket: "Hakkımızda Başlığı",
    neden: "\"Hakkımızda\" yerine kendi cümlen — örn. Kadıköy'ün 12 yıllık teknik servisi.",
    kolon: "about_title",
    bolum: "about",
    maxUzunluk: 90,
    kalite: true,
  },
  {
    anahtar: "hakkindaMetin",
    tip: "uzunMetin",
    etiket: "Hakkımızda Yazısı",
    neden: "Hikâyeni anlattığın yer. Güven buradan doğar; şablon vitrinden ayıran şey budur.",
    kolon: "corporate_bio",
    bolum: "about",
    maxUzunluk: 1200,
    kalite: true,
  },
  {
    anahtar: "hakkindaGorsel",
    tip: "gorsel",
    etiket: "Hakkımızda Görseli",
    neden: "Dükkânın veya ekibin fotoğrafı. Gerçek bir yer olduğunu gösterir.",
    kolon: "about_image_url",
    bolum: "about",
  },
  {
    anahtar: "hakkindaGorselAlt",
    tip: "metin",
    etiket: "Görsel Alt Yazısı",
    neden: "Fotoğrafın altındaki kısa yazı. Örn: Atölyemiz, 2019.",
    kolon: "about_image_caption",
    bolum: "about",
    maxUzunluk: 120,
  },

  // ── Galeri ────────────────────────────────────────────────────────────
  {
    anahtar: "galeriUstBaslik",
    tip: "metin",
    etiket: "Galeri Üst Başlık",
    neden: "Galerinin üstündeki küçük yazı. Örn: İşlerimizden.",
    kolon: "gallery_section_kicker",
    bolum: "gallery",
    maxUzunluk: 40,
  },
  {
    anahtar: "galeriBaslik",
    tip: "metin",
    etiket: "Galeri Başlığı",
    neden: "\"Galeri\" yerine kendi başlığın — örn. Önce ve sonra.",
    kolon: "gallery_section_title",
    bolum: "gallery",
    maxUzunluk: 90,
  },
  {
    anahtar: "galeriAksiyonMetni",
    tip: "metin",
    etiket: "Galeri Buton Metni",
    neden: "Galerinin yanındaki bağlantı yazısı. Örn: Hepsini gör.",
    kolon: "gallery_action_label",
    bolum: "gallery",
    maxUzunluk: 40,
  },
  {
    anahtar: "galeriAksiyonLinki",
    tip: "url",
    etiket: "Galeri Buton Bağlantısı",
    neden: "O yazının nereye gideceği — Instagram hesabın veya başka bir sayfan olabilir.",
    kolon: "gallery_action_href",
    bolum: "gallery",
  },

  // ── Blog ──────────────────────────────────────────────────────────────
  {
    anahtar: "blogUstBaslik",
    tip: "metin",
    etiket: "Blog Üst Başlık",
    neden: "Yazıların üstündeki küçük yazı. Örn: Bilgi köşesi.",
    kolon: "blog_section_kicker",
    bolum: "blog",
    maxUzunluk: 40,
  },
  {
    anahtar: "blogBaslik",
    tip: "metin",
    etiket: "Blog Bölüm Başlığı",
    neden: "\"Yazılar\" yerine kendi başlığın. Yazı yazmak Google'da görünmeni artırır.",
    kolon: "blog_section_title",
    bolum: "blog",
    maxUzunluk: 90,
  },

  // ── SSS ───────────────────────────────────────────────────────────────
  {
    anahtar: "sssUstBaslik",
    tip: "metin",
    etiket: "SSS Üst Başlık",
    neden: "Soru bölümünün üstündeki küçük yazı. Örn: Merak edilenler.",
    kolon: "faq_section_kicker",
    bolum: "faq",
    maxUzunluk: 40,
  },
  {
    anahtar: "sssBaslik",
    tip: "metin",
    etiket: "SSS Bölüm Başlığı",
    neden: "\"Sıkça sorulan sorular\" yerine kendi cümlen.",
    kolon: "faq_section_title",
    bolum: "faq",
    maxUzunluk: 90,
  },
  {
    anahtar: "sssAciklama",
    tip: "uzunMetin",
    etiket: "SSS Bölüm Açıklaması",
    neden: "Bölümün altındaki açıklama. Müşterinin en çok sorduklarını burada topla.",
    kolon: "faq_section_description",
    bolum: "faq",
    maxUzunluk: 200,
  },

  // ── Görünürlük ────────────────────────────────────────────────────────
  {
    anahtar: "puanGoster",
    tip: "acikKapali",
    etiket: "Değerlendirme Puanını Göster",
    neden: "Değerlendirme puanın varsa üstte görünür. İstemezsen kapalı kalır.",
    kolon: "show_storefront_rating",
    bolum: "hero",
  },
  {
    anahtar: "yolTarifiGoster",
    tip: "acikKapali",
    etiket: "Yol Tarifi Butonunu Göster",
    neden: "Açarsan müşteri tek dokunuşla yol tarifi alır.",
    kolon: "show_directions_link",
    bolum: "contact",
  },
  {
    anahtar: "referansLinki",
    tip: "url",
    etiket: "Referanslar Bağlantısı",
    neden: "Çalıştığın firmalar veya işlerin varsa bağlantısını buraya koy.",
    kolon: "references_link",
    bolum: "about",
  },
] as const;

/** anahtar → alan. Komut işleyicisi bunu kullanır. */
export const FIELD_BY_KEY: ReadonlyMap<string, VitrinField> = new Map(
  VITRIN_FIELDS.map((f) => [f.anahtar, f]),
);

/** Yazılabilir kolon adları. Sunucu tarafı izin listesi. */
export const EDITABLE_COLUMNS: readonly string[] = VITRIN_FIELDS.map(
  (f) => f.kolon,
);

/** Belirli bir bölümün alanları — tıkla-düzenle ve panel gruplaması için. */
/** Bölümlerin Türkçe adı — panelde başlık olarak kullanılır. */
export const SECTION_LABELS: Record<VitrinSection, string> = {
  hero: "Üst bölüm",
  contact: "İletişim ve konum",
  categories: "Kategoriler",
  products: "Ürünler",
  featured: "Öne çıkan",
  about: "Hakkında",
  gallery: "Galeri",
  blog: "Yazılar",
  faq: "Sık sorulanlar",
};

/** Bölümlerin panelde görünme sırası — vitrindeki sırayla aynı. */
export const SECTION_ORDER: readonly VitrinSection[] = [
  "hero",
  "contact",
  "featured",
  "about",
  "gallery",
  "products",
  "categories",
  "blog",
  "faq",
];

export function fieldsOfSection(bolum: VitrinSection): VitrinField[] {
  return VITRIN_FIELDS.filter((f) => f.bolum === bolum);
}
