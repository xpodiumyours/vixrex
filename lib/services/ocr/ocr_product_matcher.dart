import 'dart:ui';
import 'package:vixrex/models/detected_product.dart';
import 'package:vixrex/models/ocr_line.dart';
import 'package:vixrex/models/ocr_price.dart';
import 'package:vixrex/utils/text_utils.dart';
import 'ocr_fuzzy_matcher.dart';

/// OCR satırlarını ve fiyatlarıyla ürün eşleştirme servisi.
///
/// Mantık:
/// 1. Tüm satırları ve fiyatları sırala (y coordinate'e göre)
/// 2. Her fiyatın en yakınındaki metni ürün adı olarak al
/// 3. Fuzzy matching ile ürün adını iyileştir
/// 4. Eşleşenleri DetectedProduct listesine dönüştür
class OcrProductMatcher {
  final OcrFuzzyMatcher _fuzzyMatcher;

  const OcrProductMatcher() : _fuzzyMatcher = const OcrFuzzyMatcher();

  Future<List<DetectedProduct>> matchProducts(
    List<OcrLine> lines,
    List<OcrPrice> prices, {
    String scanMode = 'receipt',
  }) async {
    if (prices.isEmpty) return [];

    // Satırları ve fiyatları sırala (y coordinate'e göre)
    final sortedLines = List<OcrLine>.from(lines)
      ..sort((a, b) => a.centerY.compareTo(b.centerY));
    final sortedPrices = List<OcrPrice>.from(prices)
      ..sort((a, b) => a.lineNumber.compareTo(b.lineNumber));

    final products = <DetectedProduct>[];
    final usedLineIndices = <int>{};

    // Her fiyat için en yakın ürün satırını bul
    for (final price in sortedPrices) {
      final productLine = _findBestProductLine(
        sortedLines,
        price,
        usedLineIndices,
      );

      if (productLine != null) {
        usedLineIndices.add(productLine.lineIndex);

        // Ürün adını temizle
        final cleanedName = _cleanProductName(productLine.text, price.rawText);
        if (cleanedName.length < 2) continue;

        // Fuzzy matching ile ürün sözlüğünde eşleştir
        final fuzzyResult = _fuzzyMatcher.findBestMatch(
          cleanedName,
          _productDictionary,
          threshold: 0.4,
        );

        // Confidence hesapla
        final baseConfidence = _calculateConfidence(
          cleanedName,
          price,
          productLine,
        );
        final finalConfidence =
            fuzzyResult.isNotEmpty
                ? (baseConfidence + fuzzyResult.score) / 2
                : baseConfidence;

        final finalName =
            fuzzyResult.isNotEmpty ? fuzzyResult.matchedText : cleanedName;

        products.add(
          DetectedProduct(
            id: 'ocr_${DateTime.now().microsecondsSinceEpoch}_${products.length}',
            name: finalName,
            price: price.amount,
            confidence: finalConfidence,
            source: fuzzyResult.isNotEmpty ? 'ocr_fuzzy_matched' : 'ocr_priced',
          ),
        );
      }
    }

    return _deduplicateProducts(products);
  }

  /// Her fiyat için en uygun ürün satırını bul.
  OcrLine? _findBestProductLine(
    List<OcrLine> sortedLines,
    OcrPrice price,
    Set<int> usedLines,
  ) {
    OcrLine? bestLine;
    double bestScore = double.infinity;

    for (final line in sortedLines) {
      if (usedLines.contains(line.lineIndex)) continue;
      if (line.text.length < 2) continue;
      if (_isNoiseLine(line.text)) continue;
      if (_isOnlyPriceOrNumber(line.text)) continue;

      // Fiyatın kendisiyse atla
      if (line.text.trim() == price.rawText.trim()) continue;
      if (line.text.contains(price.rawText)) continue;

      // Bounding box tabanlı mesafe hesaplama
      final yDiff = (line.centerY - price.centerY).abs();
      final xDiff = (line.centerX - price.centerX).abs();

      // Skor: Dikey mesafe öncelikli, yatay benzerlik ikincil
      final score = yDiff * 2 + xDiff;

      if (score < bestScore && yDiff < 150) {
        bestScore = score;
        bestLine = line;
      }
    }

    return bestLine;
  }

  /// Ürün adını temizle - Fatura/Receipt formatları için iyileştirildi.
  String _cleanProductName(String text, String priceText) {
    var cleaned = text;

    // Fiyat metnini çıkar
    cleaned = cleaned.replaceAll(priceText, '');

    // Para birimlerini çıkar (TL, ₺, TRY, tl, try, KR, KURUŞ)
    cleaned = cleaned.replaceAll(
      RegExp(r'(?:₺|TL|TRY|KR|KURUŞ|tl|try|kr|kuruş)', caseSensitive: false),
      '',
    );

    // KDV oranlarını çıkar (%8, %10, %18 vb.)
    cleaned = cleaned.replaceAll(RegExp(r'%\\d+'), '');
    cleaned = cleaned.replaceAll(
      RegExp(r'kdv %?\\d*', caseSensitive: false),
      '',
    );

    // Barkod/GTIN çıkar (10-13 haneli)
    cleaned = cleaned.replaceAll(RegExp(r'\b\d{10,13}\b'), '');

    // Adet/miktar ifadelerini çıkar (ad, adet, pc, kg, g, lt, lt, dz, pcs)
    cleaned = cleaned.replaceAll(
      RegExp(
        r'\b\d+\s*(ad|adet|pcs|kg|g|lt|dz|AD|ADET|PCS|KG|G|LT|DZ)\b',
        caseSensitive: false,
      ),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'\b(ad|adet|pcs|kg|g|lt|dz)\s*\d+', caseSensitive: false),
      '',
    );

    // Fatura numarası / referans numarası çıkar (rakamlı referanslar)
    cleaned = cleaned.replaceAll(
      RegExp(r'[\d]{4,}-[\d]{3,}-[\d]{3,}|[\d]{8,}|[\d]{4,}.[\d]{2}.[\d]{2}'),
      '',
    );

    // Özellik ifadeleri (renk, boyut vb. - sadece büyük/küçük harf ifadeleri)
    cleaned = cleaned.replaceAll(RegExp(r'\b[A-Z]{2,8}\b'), '');

    // Boşlukları temizle ve kes
    cleaned = cleaned.trim();
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    return cleaned;
  }

  /// Satır sadece fiyat veya sayılıysa true dön.
  bool _isOnlyPriceOrNumber(String text) {
    final trimmed = text.trim();
    if (RegExp(r'^[\d\s.,TL₺TRY%:\-+*xX]+$').hasMatch(trimmed)) return true;
    if (trimmed.length <= 5 && RegExp(r'^\d+$').hasMatch(trimmed)) return true;
    return false;
  }

  bool _isNoiseLine(String text) {
    final lower = text.toLowerCase();
    const noiseKeywords = [
      'kargo',
      'teslimat',
      'kupon',
      'puan',
      'yorum',
      'bedava',
      'indirim',
      'sepet',
      'taksit',
      'kampanya',
      'hakkımızda',
      'iletişim',
      'fiş no',
      'fiş tarihi',
      'mağaza',
      'toplam',
      'ara toplam',
      'genel toplam',
      'mal bedeli',
      'net tutar',
      'kdv',
    ];
    return noiseKeywords.any((kw) => lower.contains(kw));
  }

  /// Aynı ürünleri birleştir.
  List<DetectedProduct> _deduplicateProducts(List<DetectedProduct> products) {
    final map = <String, DetectedProduct>{};
    for (final product in products) {
      final key = TextUtils.normalizeTurkish(product.name).toLowerCase();
      if (map.containsKey(key)) {
        map[key]!.quantity += product.quantity;
        if (product.price != null && map[key]!.price == null) {
          map[key]!.price = product.price;
        }
      } else {
        map[key] = product;
      }
    }
    return map.values.toList();
  }

  /// Confidence skoru hesapla (0.0 - 1.0).
  double _calculateConfidence(String name, OcrPrice price, OcrLine line) {
    double score = 0.5; // Başlangıç

    // 1. Ürün adı uzunluğu: Kısa ise güvenilirlik düşer
    if (name.length >= 8) score += 0.1;
    if (name.length >= 15) score += 0.1;
    if (name.length < 4) score -= 0.2;

    // 2. Ürün adında harf oranı: Sayısal değerler güvenilir değil
    final letterRatio =
        name.replaceAll(RegExp(r'[^a-zA-Zà-üÀ-Ü]'), '').length / name.length;
    if (letterRatio > 0.7) score += 0.1;
    if (letterRatio < 0.3) score -= 0.2;

    // 3. BoundingBox mesafesi: Yakın ise yüksek güvenilirlik
    if (price.boundingBox != null && line.boundingBox != Rect.zero) {
      final yDiff = (line.centerY - price.centerY).abs();
      if (yDiff < 30) {
        score += 0.1; // Aynı satır
      } else if (yDiff < 80) {
        score += 0.05; // Yakın
      } else if (yDiff > 150) {
        score -= 0.1; // Uzak
      }
    }

    // 4. Fiyat formatı: Kuruşlu fiyatlar daha güvenilir
    if (price.amount % 1 != 0 && price.amount > 0) score += 0.05;

    // 5. Fiyat makul aralıktaysa
    if (price.amount >= 1 && price.amount <= 50000) score += 0.05;

    // 6. Noise kelimesi içeriyor mu
    if (_isNoiseLine(name)) score -= 0.3;

    // 7. Sadece sayısal değer mi
    if (RegExp(r'^\d+$').hasMatch(name.trim())) score -= 0.3;

    // 8. Tek kelime mi (ürün adları genellikle çok kelimeli)
    if (name.split(RegExp(r'\s+')).length == 1) score -= 0.1;

    // 9. Para birimi içeriğe yazılı mı (TL, ₺)
    if (price.rawText.contains('TL') || price.rawText.contains('₺')) {
      score += 0.05;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Bilinen ürün sözlüğü (fuzzy matching için).
  /// **Güncellendi: Fatura/Receipt çeşitliliği için genişletildi.**
  static const List<String> _productDictionary = [
    // Tekstil
    'V YAKA KISA KOL BADI', 'YAKASI KISA KOL REÇME ARA BIYELI',
    'YAKA KISA KOLU REÇME ARA BIYELI', 'ARA BEDEN KALIN BIYELİ IP ASKILI ATLET',
    'L XL XXL YARIM BALIKÇI UZUN KOL BADI', 'ELİT ERK PENYE ATLET',
    'ELİT ERK ARJANTİN', 'ELİT ERK ELASTAN SIFIRYAKA',
    'ELİT BYN MOD ELAS UZUN TAYT', 'ELİT BYN ELASTAN SIFIRKOL',
    'ELİT BYN ELASTAN YARIMKOL', 'SHR ERK BOXER DESENLİ',
    'SHR BYN PEN KAŞKORSE', 'TUT ERK PEN ATLET',
    'TUT BYN KAŞKORSE BİKİNİ',
    // Gıda
    'ÜLKER ÇİKOLATALI GOFRET', 'ÇAYKUR FİLİZ ÇAYI 500G',
    'SÜTAŞ TAM YAĞLI SÜT 1L', 'RULOKAT FINDIKLI RULO GOFRET',
    'DANKEK LOKMALIK HİNDİSTAN CEVİZLİ', 'BİSCOLATA MOOD ÇİKOLATALI',
    'KEKSTRA ÇİLEKLİ JOLEBOL', 'ÜLKER ÇOKOPRENS',
    'LUPPO SANDVİCE KEK', 'BİSKÜVİ',
    // Elektronik
    'SAMSUNG GALAXY A54', 'JBL TUNE 520BT KULAKLIK',
    'ANKER POWERBANK 10000',
    // Ofis
    'A4 KAGIT 500 SK', 'PEN SET 12 ADET', 'MUSTERİ FAKTÜRU',
    // Genel/Market
    'PAKET', 'KUTU', 'ŞİŞE', 'TENEKE', 'TORBA',
    // **Yeni: Fatura ortak ürünleri**
    'FİŞ', 'TOPLAM', 'KDV %8', 'KDV %10', 'KDV %18',
    'NET TUTAR', 'GENEL TOPLAM', 'İADE', 'İADE NÖTASI',
    'ÖDENMESİ GEREKEN', 'KALDIRIM', 'İNDİRİM',
    // **Yeni: Market/Market products**
    'MERCİ ÇIKOLATALI BISCUIT', 'ŞÖFER TEREYAĞI 1L',
    'EV AİNSİ TEREYAĞI 900G', 'MERCİ KAŞAR PEYNİRİ 400G',
    'Taze MY WORK', 'SEKERLER karışımı', 'Kurutulmuş BİLEM',
    // **Yeni: Ofis products**
    'XEROX KAGIT A4', 'TAMELİK KARDI', 'POST-IT 75X75',
  ];
}
