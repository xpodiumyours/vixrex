/// Ürün veritabanı girişi.
class ProductDatabaseEntry {
  final String id;
  final String urunAdi;
  final String normalizeUrunAdi;
  final String marka;
  final String markaAlias;
  final String kategori;
  final String altKategori;
  final String aciklama;
  final String anahtarKelimeler;
  final String ocrEslesmeKelimeleri;
  final String ambalajTipi;
  final String hacimMiktar;
  final String birim;

  const ProductDatabaseEntry({
    required this.id,
    required this.urunAdi,
    required this.normalizeUrunAdi,
    required this.marka,
    this.markaAlias = '',
    required this.kategori,
    this.altKategori = '',
    this.aciklama = '',
    this.anahtarKelimeler = '',
    this.ocrEslesmeKelimeleri = '',
    this.ambalajTipi = '',
    this.hacimMiktar = '',
    this.birim = '',
  });

  factory ProductDatabaseEntry.fromJson(Map<String, dynamic> json) {
    return ProductDatabaseEntry(
      id: json['id'] as String? ?? '',
      urunAdi: json['urun_adi'] as String? ?? '',
      normalizeUrunAdi: json['normalize_urun_adi'] as String? ?? '',
      marka: json['marka'] as String? ?? '',
      markaAlias: json['marka_alias'] as String? ?? '',
      kategori: json['kategori'] as String? ?? '',
      altKategori: json['alt_kategori'] as String? ?? '',
      aciklama: json['aciklama'] as String? ?? '',
      anahtarKelimeler: json['anahtar_kelimeler'] as String? ?? '',
      ocrEslesmeKelimeleri: json['ocr_eslesme_kelimeleri'] as String? ?? '',
      ambalajTipi: json['ambalaj_tipi'] as String? ?? '',
      hacimMiktar: json['hacim_miktar'] as String? ?? '',
      birim: json['birim'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'urun_adi': urunAdi,
    'normalize_urun_adi': normalizeUrunAdi,
    'marka': marka,
    'marka_alias': markaAlias,
    'kategori': kategori,
    'alt_kategori': altKategori,
    'aciklama': aciklama,
    'anahtar_kelimeler': anahtarKelimeler,
    'ocr_eslesme_kelimeleri': ocrEslesmeKelimeleri,
    'ambalaj_tipi': ambalajTipi,
    'hacim_miktar': hacimMiktar,
    'birim': birim,
  };

  /// Eşleme skorunu hesapla.
  double matchScore(String query) {
    final normalizedQuery = query.toLowerCase();
    final normalizedTarget = normalizeUrunAdi.toLowerCase();

    // Tam eşleşme
    if (normalizedTarget.contains(normalizedQuery)) return 1.0;
    if (normalizedQuery.contains(normalizedTarget)) return 0.9;

    // OCR eşleme kelimelerini kontrol et
    final keywords = ocrEslesmeKelimeleri.split(',').map((k) => k.trim().toLowerCase());
    for (final keyword in keywords) {
      if (keyword.isNotEmpty && normalizedQuery.contains(keyword)) {
        return 0.8;
      }
    }

    // Marka eşleşmesi
    final brandLower = marka.toLowerCase();
    if (normalizedQuery.contains(brandLower)) return 0.7;

    return 0.0;
  }
}
