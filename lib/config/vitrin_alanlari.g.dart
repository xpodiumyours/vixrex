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
  final bool kalite;
  final int? minUzunluk;
  final int? maxUzunluk;
  final num? min;
  final num? max;
  final List<String>? secenekler;
  final String? ipucu;
  final String? dogrulama;
  final List<String>? bosDegerler;

  const VitrinAlani({
    required this.anahtar,
    required this.tip,
    required this.etiket,
    required this.kolon,
    required this.bolum,
    this.zorunlu = false,
    this.kalite = false,
    this.minUzunluk,
    this.maxUzunluk,
    this.min,
    this.max,
    this.secenekler,
    this.ipucu,
    this.dogrulama,
    this.bosDegerler,
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
    etiket: 'Üstteki Küçük Yazı',
    kolon: 'hero_badge',
    bolum: 'hero',
    kalite: true,
    maxUzunluk: 60,
    ipucu: 'Örn: Profesyonel Teknik Servis / Kadıköy',
  ),
  VitrinAlani(
    anahtar: 'kisaTanitim',
    tip: 'uzunMetin',
    etiket: 'İşletme Tanıtımı',
    kolon: 'description',
    bolum: 'hero',
    maxUzunluk: 300,
  ),
  VitrinAlani(
    anahtar: 'konumMetni',
    tip: 'metin',
    etiket: 'Üstteki Yer Yazısı',
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
    secenekler: ['Giyim', 'Butik', 'Gıda', 'Fırın', 'Kozmetik', 'Dekorasyon', 'Elektronik', 'Kırtasiye', 'Kafe / Lokanta', 'Kuaför', 'Teknik Servis', 'Danışmanlık', 'Eğitim', 'Ev Temizlik', 'Spor / Fitness', 'Pet / Veteriner', 'Sağlık / Yaşam', 'Oto / Araç', 'Diğer'],
    dogrulama: 'kategori',
    bosDegerler: ['diger', 'diğer'],
  ),
  VitrinAlani(
    anahtar: 'isletmeTuru',
    tip: 'metin',
    etiket: 'Alt Hizmet Tanımı',
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
    kalite: true,
  ),
  VitrinAlani(
    anahtar: 'kapakGorseli',
    tip: 'gorsel',
    etiket: 'Üstteki Büyük Fotoğraf',
    kolon: 'shelf_image_url',
    bolum: 'hero',
    kalite: true,
  ),
  VitrinAlani(
    anahtar: 'whatsapp',
    tip: 'telefon',
    etiket: 'WhatsApp Hattı',
    kolon: 'whatsapp',
    bolum: 'contact',
    zorunlu: true,
    dogrulama: 'tr_mobil',
  ),
  VitrinAlani(
    anahtar: 'telefon',
    tip: 'telefon',
    etiket: 'Arama Numarası',
    kolon: 'phone',
    bolum: 'contact',
  ),
  VitrinAlani(
    anahtar: 'eposta',
    tip: 'eposta',
    etiket: 'E-posta Adresi',
    kolon: 'email',
    bolum: 'contact',
    maxUzunluk: 120,
  ),
  VitrinAlani(
    anahtar: 'adres',
    tip: 'uzunMetin',
    etiket: 'İşletme Adresi',
    kolon: 'address',
    bolum: 'contact',
    zorunlu: true,
    maxUzunluk: 200,
    dogrulama: 'adres',
  ),
  VitrinAlani(
    anahtar: 'il',
    tip: 'metin',
    etiket: 'Şehir',
    kolon: 'province_name',
    bolum: 'contact',
    zorunlu: true,
    maxUzunluk: 60,
  ),
  VitrinAlani(
    anahtar: 'ilce',
    tip: 'metin',
    etiket: 'İlçe',
    kolon: 'district_name',
    bolum: 'contact',
    zorunlu: true,
    maxUzunluk: 60,
  ),
  VitrinAlani(
    anahtar: 'mahalle',
    tip: 'metin',
    etiket: 'Mahalle',
    kolon: 'neighborhood_name',
    bolum: 'contact',
    kalite: true,
    maxUzunluk: 60,
    ipucu: 'Örn: Caddebostan',
  ),
  VitrinAlani(
    anahtar: 'haritaEtiketi',
    tip: 'metin',
    etiket: 'Haritadaki Kısa Not',
    kolon: 'map_label',
    bolum: 'contact',
    maxUzunluk: 120,
  ),
  VitrinAlani(
    anahtar: 'calismaSaatleri',
    tip: 'metin',
    etiket: 'Açılış Saatleri',
    kolon: 'working_hours',
    bolum: 'contact',
    kalite: true,
    maxUzunluk: 400,
  ),
  VitrinAlani(
    anahtar: 'instagram',
    tip: 'metin',
    etiket: 'Instagram Adı',
    kolon: 'instagram',
    bolum: 'contact',
    maxUzunluk: 30,
    ipucu: '@ işareti olmadan yazın',
  ),
  VitrinAlani(
    anahtar: 'website',
    tip: 'url',
    etiket: 'İnternet Sitesi',
    kolon: 'website',
    bolum: 'contact',
  ),
  VitrinAlani(
    anahtar: 'haritaLinki',
    tip: 'url',
    etiket: 'Harita Bağlantısı',
    kolon: 'google_business_link',
    bolum: 'contact',
    kalite: true,
  ),
  VitrinAlani(
    anahtar: 'enlem',
    tip: 'sayi',
    etiket: 'Konum — Enlem',
    kolon: 'latitude',
    bolum: 'contact',
    min: -90,
    max: 90,
  ),
  VitrinAlani(
    anahtar: 'boylam',
    tip: 'sayi',
    etiket: 'Konum — Boylam',
    kolon: 'longitude',
    bolum: 'contact',
    min: -180,
    max: 180,
  ),
  VitrinAlani(
    anahtar: 'kategoriBolumBaslik',
    tip: 'metin',
    etiket: 'Vitrin Gruplarının Başlığı',
    kolon: 'category_section_title',
    bolum: 'categories',
    maxUzunluk: 60,
  ),
  VitrinAlani(
    anahtar: 'urunBolumBaslik',
    tip: 'metin',
    etiket: 'Ürünlerin Başlığı',
    kolon: 'product_section_title',
    bolum: 'products',
    maxUzunluk: 60,
  ),
  VitrinAlani(
    anahtar: 'bantEtiket',
    tip: 'metin',
    etiket: 'Fırsat Etiketi',
    kolon: 'featured_banner_label',
    bolum: 'featured',
    maxUzunluk: 40,
  ),
  VitrinAlani(
    anahtar: 'bantBaslik',
    tip: 'metin',
    etiket: 'Fırsat Başlığı',
    kolon: 'featured_banner_title',
    bolum: 'featured',
    maxUzunluk: 90,
  ),
  VitrinAlani(
    anahtar: 'bantAciklama',
    tip: 'uzunMetin',
    etiket: 'Fırsat Açıklaması',
    kolon: 'featured_banner_description',
    bolum: 'featured',
    maxUzunluk: 200,
  ),
  VitrinAlani(
    anahtar: 'bantGorsel',
    tip: 'gorsel',
    etiket: 'Fırsat Fotoğrafı',
    kolon: 'featured_banner_image_url',
    bolum: 'featured',
  ),
  VitrinAlani(
    anahtar: 'bantFiyat',
    tip: 'metin',
    etiket: 'Fırsat Fiyatı',
    kolon: 'featured_banner_price_text',
    bolum: 'featured',
    maxUzunluk: 30,
  ),
  VitrinAlani(
    anahtar: 'hakkindaUstBaslik',
    tip: 'metin',
    etiket: 'Hakkımızda Küçük Başlık',
    kolon: 'about_kicker',
    bolum: 'about',
    maxUzunluk: 40,
  ),
  VitrinAlani(
    anahtar: 'hakkindaBaslik',
    tip: 'metin',
    etiket: 'Hakkımızda Büyük Başlık',
    kolon: 'about_title',
    bolum: 'about',
    kalite: true,
    maxUzunluk: 90,
  ),
  VitrinAlani(
    anahtar: 'hakkindaMetin',
    tip: 'uzunMetin',
    etiket: 'İşletme Hikayesi',
    kolon: 'corporate_bio',
    bolum: 'about',
    kalite: true,
    maxUzunluk: 1200,
  ),
  VitrinAlani(
    anahtar: 'hakkindaGorsel',
    tip: 'gorsel',
    etiket: 'İşletme Fotoğrafı',
    kolon: 'about_image_url',
    bolum: 'about',
  ),
  VitrinAlani(
    anahtar: 'hakkindaGorselAlt',
    tip: 'metin',
    etiket: 'Fotoğraf Alt Yazısı',
    kolon: 'about_image_caption',
    bolum: 'about',
    maxUzunluk: 120,
  ),
  VitrinAlani(
    anahtar: 'galeriUstBaslik',
    tip: 'metin',
    etiket: 'Galeri Küçük Başlık',
    kolon: 'gallery_section_kicker',
    bolum: 'gallery',
    maxUzunluk: 40,
  ),
  VitrinAlani(
    anahtar: 'galeriBaslik',
    tip: 'metin',
    etiket: 'Galeri Büyük Başlık',
    kolon: 'gallery_section_title',
    bolum: 'gallery',
    maxUzunluk: 90,
  ),
  VitrinAlani(
    anahtar: 'galeriAksiyonMetni',
    tip: 'metin',
    etiket: 'Galeri Düğmesinin Yazısı',
    kolon: 'gallery_action_label',
    bolum: 'gallery',
    maxUzunluk: 40,
  ),
  VitrinAlani(
    anahtar: 'galeriAksiyonLinki',
    tip: 'url',
    etiket: 'Galeri Düğmesinin Bağlantısı',
    kolon: 'gallery_action_href',
    bolum: 'gallery',
    dogrulama: 'ankor_serbest',
  ),
  VitrinAlani(
    anahtar: 'blogUstBaslik',
    tip: 'metin',
    etiket: 'Yazılar Küçük Başlık',
    kolon: 'blog_section_kicker',
    bolum: 'blog',
    maxUzunluk: 40,
  ),
  VitrinAlani(
    anahtar: 'blogBaslik',
    tip: 'metin',
    etiket: 'Yazıların Başlığı',
    kolon: 'blog_section_title',
    bolum: 'blog',
    maxUzunluk: 90,
  ),
  VitrinAlani(
    anahtar: 'sssUstBaslik',
    tip: 'metin',
    etiket: 'Sorular Küçük Başlık',
    kolon: 'faq_section_kicker',
    bolum: 'faq',
    maxUzunluk: 40,
  ),
  VitrinAlani(
    anahtar: 'sssBaslik',
    tip: 'metin',
    etiket: 'Soruların Başlığı',
    kolon: 'faq_section_title',
    bolum: 'faq',
    maxUzunluk: 90,
  ),
  VitrinAlani(
    anahtar: 'sssAciklama',
    tip: 'uzunMetin',
    etiket: 'Soruların Açıklaması',
    kolon: 'faq_section_description',
    bolum: 'faq',
    maxUzunluk: 200,
  ),
  VitrinAlani(
    anahtar: 'puanGoster',
    tip: 'acikKapali',
    etiket: 'Puan Görünsün',
    kolon: 'show_storefront_rating',
    bolum: 'hero',
  ),
  VitrinAlani(
    anahtar: 'yolTarifiGoster',
    tip: 'acikKapali',
    etiket: 'Yol Tarifi Düğmesi',
    kolon: 'show_directions_link',
    bolum: 'contact',
  ),
  VitrinAlani(
    anahtar: 'referansLinki',
    tip: 'url',
    etiket: 'Referans Bağlantısı',
    kolon: 'references_link',
    bolum: 'about',
  ),
];

/// Yayın için doldurulması ZORUNLU alanlar — şemadan gelir.
/// Elle liste tutulmaz; şemada zorunlu işaretlemek yeter.
final List<VitrinAlani> zorunluAlanlar =
    vitrinAlanlari.where((a) => a.zorunlu).toList();

/// Zorunlu değil ama vitrini kaliteye çıkaran alanlar — şemadan
/// gelir. Elle liste tutulmaz; şemada kalite işaretlemek yeter.
final List<VitrinAlani> kaliteAlanlari =
    vitrinAlanlari.where((a) => a.kalite).toList();

/// Anahtardan alana hızlı erişim.
final Map<String, VitrinAlani> alanAnahtarla = {
  for (final a in vitrinAlanlari) a.anahtar: a,
};
