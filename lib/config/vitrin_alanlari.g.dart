// ÜRETİLMİŞ DOSYA — ELLE DÜZENLEME.
//
// Kaynak : public_web/src/lib/vitrinFieldSchema.ts
// Üreten : tool/alan_semasi_uret.dart
//
// Vitrinin düzenlenebilir alanlarının tek tanımı. Next.js ve
// Flutter aynı listeyi kullanır; "sırada ne var" sorusuna iki
// taraf da buradan cevap verir.

class VitrinAlani {
  final String anahtar;
  final String tip;
  final String etiket;
  final String kolon;
  final String bolum;
  final bool zorunlu;
  final int? minUzunluk;
  final int? maxUzunluk;
  final List<String>? secenekler;
  final String? ipucu;

  const VitrinAlani({
    required this.anahtar,
    required this.tip,
    required this.etiket,
    required this.kolon,
    required this.bolum,
    this.zorunlu = false,
    this.minUzunluk,
    this.maxUzunluk,
    this.secenekler,
    this.ipucu,
  });
}

const List<VitrinAlani> vitrinAlanlari = [
  VitrinAlani(
    anahtar: 'isletmeAdi',
    tip: 'metin',
    etiket: 'İşletme Adı',
    kolon: 'name',
    bolum: 'hero',
    zorunlu: true,
    minUzunluk: 2,
    maxUzunluk: 60,
  ),
  VitrinAlani(
    anahtar: 'heroRozet',
    tip: 'metin',
    etiket: 'Hero Rozet Metni',
    kolon: 'hero_badge',
    bolum: 'hero',
    maxUzunluk: 60,
    ipucu: 'Örn: Profesyonel Teknik Servis / Kadıköy',
  ),
  VitrinAlani(
    anahtar: 'kisaTanitim',
    tip: 'uzunMetin',
    etiket: 'Kısa Tanıtım',
    kolon: 'description',
    bolum: 'hero',
    maxUzunluk: 300,
  ),
  VitrinAlani(
    anahtar: 'konumMetni',
    tip: 'metin',
    etiket: 'Hero Konum Metni',
    kolon: 'hero_location_text',
    bolum: 'hero',
    maxUzunluk: 60,
    ipucu: 'Örn: Kadıköy, İstanbul',
  ),
  VitrinAlani(
    anahtar: 'kategori',
    tip: 'secim',
    etiket: 'İşletme Kategorisi',
    kolon: 'kategori',
    bolum: 'hero',
    zorunlu: true,
    maxUzunluk: 40,
    secenekler: ['Giyim', 'Butik', 'Gıda', 'Fırın', 'Kozmetik', 'Dekorasyon', 'Elektronik', 'Kırtasiye', 'Pet / Veteriner', 'Kafe / Lokanta', 'Kuaför', 'Teknik Servis', 'Danışmanlık', 'Eğitim', 'Ev Temizlik', 'Spor / Fitness', 'Sağlık / Yaşam', 'Oto / Araç', 'Diğer'],
  ),
  VitrinAlani(
    anahtar: 'isletmeTuru',
    tip: 'metin',
    etiket: 'İşletme Türü',
    kolon: 'business_type',
    bolum: 'hero',
    maxUzunluk: 40,
  ),
  VitrinAlani(
    anahtar: 'logo',
    tip: 'gorsel',
    etiket: 'Logo',
    kolon: 'logo_url',
    bolum: 'hero',
  ),
  VitrinAlani(
    anahtar: 'kapakGorseli',
    tip: 'gorsel',
    etiket: 'Kapak / Hero Görseli',
    kolon: 'shelf_image_url',
    bolum: 'hero',
  ),
  VitrinAlani(
    anahtar: 'tema',
    tip: 'secim',
    etiket: 'Tema Ön Ayarı',
    kolon: 'theme_preset',
    bolum: 'hero',
    maxUzunluk: 40,
  ),
  VitrinAlani(
    anahtar: 'whatsapp',
    tip: 'telefon',
    etiket: 'WhatsApp Numarası',
    kolon: 'whatsapp',
    bolum: 'contact',
    zorunlu: true,
  ),
  VitrinAlani(
    anahtar: 'telefon',
    tip: 'telefon',
    etiket: 'Telefon',
    kolon: 'phone',
    bolum: 'contact',
  ),
  VitrinAlani(
    anahtar: 'eposta',
    tip: 'eposta',
    etiket: 'E-posta',
    kolon: 'email',
    bolum: 'contact',
    maxUzunluk: 120,
  ),
  VitrinAlani(
    anahtar: 'adres',
    tip: 'uzunMetin',
    etiket: 'Açık Adres',
    kolon: 'address',
    bolum: 'contact',
    zorunlu: true,
    maxUzunluk: 200,
  ),
  VitrinAlani(
    anahtar: 'haritaEtiketi',
    tip: 'metin',
    etiket: 'Harita Kartı Etiketi',
    kolon: 'map_label',
    bolum: 'contact',
    maxUzunluk: 120,
  ),
  VitrinAlani(
    anahtar: 'calismaSaatleri',
    tip: 'metin',
    etiket: 'Çalışma Saatleri',
    kolon: 'working_hours',
    bolum: 'contact',
    maxUzunluk: 400,
  ),
  VitrinAlani(
    anahtar: 'instagram',
    tip: 'metin',
    etiket: 'Instagram Kullanıcı Adı',
    kolon: 'instagram',
    bolum: 'contact',
    maxUzunluk: 30,
    ipucu: '@ işareti olmadan yazın',
  ),
  VitrinAlani(
    anahtar: 'website',
    tip: 'url',
    etiket: 'Web Sitesi',
    kolon: 'website',
    bolum: 'contact',
  ),
  VitrinAlani(
    anahtar: 'haritaLinki',
    tip: 'url',
    etiket: 'Google İşletme / Harita Bağlantısı',
    kolon: 'google_business_link',
    bolum: 'contact',
  ),
  VitrinAlani(
    anahtar: 'enlem',
    tip: 'sayi',
    etiket: 'Konum — Enlem',
    kolon: 'latitude',
    bolum: 'contact',
  ),
  VitrinAlani(
    anahtar: 'boylam',
    tip: 'sayi',
    etiket: 'Konum — Boylam',
    kolon: 'longitude',
    bolum: 'contact',
  ),
  VitrinAlani(
    anahtar: 'kategoriBolumBaslik',
    tip: 'metin',
    etiket: 'Kategori Bölümü Başlığı',
    kolon: 'category_section_title',
    bolum: 'categories',
    maxUzunluk: 60,
  ),
  VitrinAlani(
    anahtar: 'urunBolumBaslik',
    tip: 'metin',
    etiket: 'Ürün Bölümü Başlığı',
    kolon: 'product_section_title',
    bolum: 'products',
    maxUzunluk: 60,
  ),
  VitrinAlani(
    anahtar: 'bantEtiket',
    tip: 'metin',
    etiket: 'Kampanya Etiketi',
    kolon: 'featured_banner_label',
    bolum: 'featured',
    maxUzunluk: 40,
  ),
  VitrinAlani(
    anahtar: 'bantBaslik',
    tip: 'metin',
    etiket: 'Kampanya Başlığı',
    kolon: 'featured_banner_title',
    bolum: 'featured',
    maxUzunluk: 90,
  ),
  VitrinAlani(
    anahtar: 'bantAciklama',
    tip: 'uzunMetin',
    etiket: 'Kampanya Açıklaması',
    kolon: 'featured_banner_description',
    bolum: 'featured',
    maxUzunluk: 200,
  ),
  VitrinAlani(
    anahtar: 'bantGorsel',
    tip: 'gorsel',
    etiket: 'Kampanya Görseli',
    kolon: 'featured_banner_image_url',
    bolum: 'featured',
  ),
  VitrinAlani(
    anahtar: 'bantFiyat',
    tip: 'metin',
    etiket: 'Kampanya Fiyat Metni',
    kolon: 'featured_banner_price_text',
    bolum: 'featured',
    maxUzunluk: 30,
  ),
  VitrinAlani(
    anahtar: 'hakkindaUstBaslik',
    tip: 'metin',
    etiket: 'Hakkımızda Üst Başlık',
    kolon: 'about_kicker',
    bolum: 'about',
    maxUzunluk: 40,
  ),
  VitrinAlani(
    anahtar: 'hakkindaBaslik',
    tip: 'metin',
    etiket: 'Hakkımızda Başlığı',
    kolon: 'about_title',
    bolum: 'about',
    maxUzunluk: 90,
  ),
  VitrinAlani(
    anahtar: 'hakkindaMetin',
    tip: 'uzunMetin',
    etiket: 'Hakkımızda Yazısı',
    kolon: 'corporate_bio',
    bolum: 'about',
    maxUzunluk: 1200,
  ),
  VitrinAlani(
    anahtar: 'hakkindaGorsel',
    tip: 'gorsel',
    etiket: 'Hakkımızda Görseli',
    kolon: 'about_image_url',
    bolum: 'about',
  ),
  VitrinAlani(
    anahtar: 'hakkindaGorselAlt',
    tip: 'metin',
    etiket: 'Görsel Alt Yazısı',
    kolon: 'about_image_caption',
    bolum: 'about',
    maxUzunluk: 120,
  ),
  VitrinAlani(
    anahtar: 'galeriUstBaslik',
    tip: 'metin',
    etiket: 'Galeri Üst Başlık',
    kolon: 'gallery_section_kicker',
    bolum: 'gallery',
    maxUzunluk: 40,
  ),
  VitrinAlani(
    anahtar: 'galeriBaslik',
    tip: 'metin',
    etiket: 'Galeri Başlığı',
    kolon: 'gallery_section_title',
    bolum: 'gallery',
    maxUzunluk: 90,
  ),
  VitrinAlani(
    anahtar: 'galeriAksiyonMetni',
    tip: 'metin',
    etiket: 'Galeri Buton Metni',
    kolon: 'gallery_action_label',
    bolum: 'gallery',
    maxUzunluk: 40,
  ),
  VitrinAlani(
    anahtar: 'galeriAksiyonLinki',
    tip: 'url',
    etiket: 'Galeri Buton Bağlantısı',
    kolon: 'gallery_action_href',
    bolum: 'gallery',
  ),
  VitrinAlani(
    anahtar: 'blogUstBaslik',
    tip: 'metin',
    etiket: 'Blog Üst Başlık',
    kolon: 'blog_section_kicker',
    bolum: 'blog',
    maxUzunluk: 40,
  ),
  VitrinAlani(
    anahtar: 'blogBaslik',
    tip: 'metin',
    etiket: 'Blog Bölüm Başlığı',
    kolon: 'blog_section_title',
    bolum: 'blog',
    maxUzunluk: 90,
  ),
  VitrinAlani(
    anahtar: 'sssUstBaslik',
    tip: 'metin',
    etiket: 'SSS Üst Başlık',
    kolon: 'faq_section_kicker',
    bolum: 'faq',
    maxUzunluk: 40,
  ),
  VitrinAlani(
    anahtar: 'sssBaslik',
    tip: 'metin',
    etiket: 'SSS Bölüm Başlığı',
    kolon: 'faq_section_title',
    bolum: 'faq',
    maxUzunluk: 90,
  ),
  VitrinAlani(
    anahtar: 'sssAciklama',
    tip: 'uzunMetin',
    etiket: 'SSS Bölüm Açıklaması',
    kolon: 'faq_section_description',
    bolum: 'faq',
    maxUzunluk: 200,
  ),
  VitrinAlani(
    anahtar: 'puanGoster',
    tip: 'acikKapali',
    etiket: 'Değerlendirme Puanını Göster',
    kolon: 'show_storefront_rating',
    bolum: 'hero',
  ),
  VitrinAlani(
    anahtar: 'yolTarifiGoster',
    tip: 'acikKapali',
    etiket: 'Yol Tarifi Butonunu Göster',
    kolon: 'show_directions_link',
    bolum: 'contact',
  ),
  VitrinAlani(
    anahtar: 'referansLinki',
    tip: 'url',
    etiket: 'Referanslar Bağlantısı',
    kolon: 'references_link',
    bolum: 'about',
  ),
];

/// Yayın için doldurulması ZORUNLU alanlar — şemadan gelir.
/// Elle liste tutulmaz; şemada zorunlu işaretlemek yeter.
final List<VitrinAlani> zorunluAlanlar =
    vitrinAlanlari.where((a) => a.zorunlu).toList();

/// Anahtardan alana hızlı erişim.
final Map<String, VitrinAlani> alanAnahtarla = {
  for (final a in vitrinAlanlari) a.anahtar: a,
};
