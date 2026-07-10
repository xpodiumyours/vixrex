/// OCR gürültü filtresi v2.
///
/// 60+ piyasa terimi ile context-aware filtering.
class OcrNoiseFilter {
  const OcrNoiseFilter();

  // ─── GENEL GÜRÜLTÜ TERİMLERİ ────────────────────────────────────
  static const _generalNoise = [
    'kargo', 'teslimat', 'kupon', 'puan', 'yorum',
    'bedava', 'indirim', 'sepet', 'taksit', 'kampanya',
    'hakkımızda', 'iletişim', 'fiş no', 'fiş tarihi', 'mağaza',
    'sayfa', 'tarih', 'saat', 'adet', 'toplam',
    'ara toplam', 'genel toplam', 'mal bedeli', 'net tutar',
    'kdv', 'ötv', 'iskonto', 'iskontolu', 'iskontosuz',
  ];

  // ─── POS/MARKET TERİMLERİ ──────────────────────────────────────
  static const _posNoise = [
    'pos', 'terminal', 'kasiyer', 'işlem no', 'kart no',
    'ödeme yöntemi', 'nakit', 'kredi kartı', 'banka kartı',
    'taksit sayısı', 'kart son dört', 'onay kodu',
    'terminal no', 'işyeri no', 'batch no', 'referans no',
  ];

  // ─── MARKET ZARFI TERİMLERİ ─────────────────────────────────────
  static const _storeNoise = [
    'müşteri no', 'kart no', 'üyelik no', 'puan bakiyesi',
    'indirim kuponu', 'hediye çeki', 'değişim-iade',
    'garanti süresi', 'kullanım kılavuzu', 'barkod',
    'üretim yeri', 'son kullanma', 'raf ömrü',
  ];

  // ─── FATURA TERİMLERİ ────────────────────────────────────────────
  static const _invoiceNoise = [
    'vergi numarası', 'vergi dairesi', 'mükellef',
    'fatura numarası', 'irsaliye numarası', 'sevk irsaliyesi',
    'ödeme vadesi', 'banka hesap', 'iban', 'swift',
    'teslim tarihi', 'sevk tarihi', 'düzenleme tarihi',
  ];

  // ─── SAAT/TARİH FORMATLARI ───────────────────────────────────────
  static final _timePattern = RegExp(r'\b\d{1,2}:\d{2}(:\d{2})?\b');
  static final _datePattern = RegExp(r'\b\d{2}[./-]\d{2}[./-]\d{2,4}\b');

  // ─── TEKRAR EDEN KARAKTERLER ─────────────────────────────────────
  static final _repeatedCharPattern = RegExp(r'(.)\1{2,}');

  /// Ana filtre metodu.
  /// Satır gürültü mü değil mi karar verir.
  bool isNoiseLine(String text, {String? section}) {
    final lower = text.toLowerCase().trim();

    // Boş veya çok kısa
    if (lower.length < 2) return true;

    // Tekrar eden karakterler ("AAAA", "1111", "====")
    if (_repeatedCharPattern.hasMatch(lower)) return true;

    // Saat formatı
    if (_timePattern.hasMatch(lower) && !lower.contains('tl') && !lower.contains('₺')) {
      return true;
    }

    // Tarih formatı (ama fiş tarihi hariç — o zaten noise)
    if (_datePattern.hasMatch(lower) && !lower.contains('fiş')) {
      return true;
    }

    // Genel gürültü
    if (_generalNoise.any((kw) => lower.contains(kw))) return true;

    // POS/Market terimleri
    if (_posNoise.any((kw) => lower.contains(kw))) return true;

    // Market zarfı terimleri
    if (_storeNoise.any((kw) => lower.contains(kw))) return true;

    // Fatura terimleri
    if (_invoiceNoise.any((kw) => lower.contains(kw))) return true;

    // Section bazlı filtreleme
    if (section == 'header') {
      return _isHeaderNoise(lower);
    } else if (section == 'footer') {
      return _isFooterNoise(lower);
    }

    return false;
  }

  /// Header bölümündeki gürültü.
  bool _isHeaderNoise(String lower) {
    const headerNoise = [
      'tarih', 'saat', 'fiş no', 'sayfa', 'firma',
      'adres', 'telefon', 'vergi', 'kasiyer', 'işlem',
      'pos', 'terminal', 'batch', 'referans',
    ];
    return headerNoise.any((kw) => lower.contains(kw));
  }

  /// Footer bölümündeki gürültü.
  bool _isFooterNoise(String lower) {
    const footerNoise = [
      'teşekkür', 'iyi günler', 'gorüşmek üzere',
      'bizi tercih ettiğiniz', 'müşteri memnuniyeti',
      'öneri ve şikayet', 'çağrı merkezi',
    ];
    return footerNoise.any((kw) => lower.contains(kw));
  }

  /// Metin ürün adı olabilir mi?
  /// Noise değilse ve anlamlı bir metinse true dön.
  bool looksLikeProductName(String text) {
    final lower = text.toLowerCase().trim();

    // Çok kısa
    if (lower.length < 3) return false;

    // Tamamen sayısal
    if (RegExp(r'^\d+$').hasMatch(lower)) return false;

    // Tamamen fiyat formatında
    if (RegExp(r'^[\d.,\s]+[TL₺]$').hasMatch(lower)) return false;

    // Noise ise
    if (isNoiseLine(text)) return false;

    // En az 2 kelime içermeli (ürün adı genellikle çok kelimeli)
    final words = lower.split(RegExp(r'\s+'));
    if (words.length < 2) return false;

    return true;
  }

  /// Metin fiyat olabilir mi?
  bool looksLikePrice(String text) {
    final trimmed = text.trim();

    // Para birimi içermeli
    if (!RegExp(r'(?:₺|TL|TRY|tl|try|KR|KURUŞ)', caseSensitive: false).hasMatch(trimmed)) {
      return false;
    }

    // Sayısal değer içermeli
    if (!RegExp(r'\d').hasMatch(trimmed)) return false;

    return true;
  }
}
