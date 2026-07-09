import 'package:vixrex/models/detected_product.dart';
import 'package:vixrex/models/ocr_line.dart';
import 'package:vixrex/models/ocr_price.dart';
import 'package:vixrex/utils/text_utils.dart';
import 'ocr_excel_verifier.dart';

/// OCR satırlarını ve fiyatlarıyla ürün eşleştirme servisi.
///
/// Mantık:
/// 1. Tüm satırları ve fiyatları sırala (y coordinate'e göre)
/// 2. Her fiyatın hemen üstündeki veya aynı satırındaki metni ürün adı olarak al
/// 3. Eşleşenleri DetectedProduct listesine dönüştür
class OcrProductMatcher {
  final OcrExcelVerifier _verifier;

  const OcrProductMatcher({required OcrExcelVerifier verifier})
      : _verifier = verifier;

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
      final productLine = _findBestProductLine(sortedLines, price, usedLineIndices);

      if (productLine != null) {
        usedLineIndices.add(productLine.lineIndex);

        // Ürün adını temizle
        final cleanedName = _cleanProductName(productLine.text, price.rawText);
        if (cleanedName.length < 2) continue;

        products.add(DetectedProduct(
          id: 'ocr_${DateTime.now().microsecondsSinceEpoch}_${products.length}',
          name: cleanedName,
          price: price.amount,
          confidence: 0.5,
          source: 'ocr_priced',
        ));
      }
    }

    return _deduplicateProducts(products);
  }

  /// Her fiyat için en uygun ürün satırını bul.
  /// Mantık: Fiyatın hemen üstündeki veya aynı yatay hizada olan satırı seç.
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

      // Dikey mesafe: Fiyatın üstündeki veya en fazla 3 satır altındaki
      final yDiff = (line.centerY - price.lineNumber * 30).abs();

      // Yatay benzerlik: Aynı yatay hizada mı?
      // centerX farklılıklarını hesapla (ML Kit farklı boyutlarda okuyabilir)
      final xDiff = (line.centerX - price.lineNumber * 5).abs();

      // Skor: Dikey mesafe öncelikli, yatay benzerlik ikincil
      final score = yDiff * 10 + xDiff;

      if (score < bestScore && yDiff < 200) { // Maksimum 200px dikey mesafe
        bestScore = score;
        bestLine = line;
      }
    }

    return bestLine;
  }

  /// Ürün adını temizle: Fiyat, barkod, miktar bilgilerini kaldır.
  String _cleanProductName(String text, String priceText) {
    var cleaned = text;

    // Fiyatı temizle
    cleaned = cleaned.replaceAll(priceText, '');

    // TL/₺ sembollerini temizle
    cleaned = cleaned.replaceAll(RegExp(r'(?:₺|TL|TRY|tl|try)', caseSensitive: false), '');

    // 13 haneli barkodları temizle
    cleaned = cleaned.replaceAll(RegExp(r'\b\d{13}\b'), '');

    // Adet bilgilerini temizle (2 AD, 3 ADET, 5 dz)
    cleaned = cleaned.replaceAll(RegExp(r'\b\d+\s*(ad|adet|dz|pcs|ADET)\b', caseSensitive: false), '');

    // 4+ haneli model kodlarını temizle (ama kısa kodları KORU: 129, 158 vb.)
    cleaned = cleaned.replaceAll(RegExp(r'\b[A-Z]{2,4}\d{4,6}\b'), '');

    // Baştaki/sondaki fazlalık boşlukları temizle
    cleaned = cleaned.trim();

    return cleaned;
  }

  /// Satır sadece fiyat veya sayılıysa true dön.
  bool _isOnlyPriceOrNumber(String text) {
    final trimmed = text.trim();
    // Tamamen sayısal veya fiyat içeren satır
    if (RegExp(r'^[\d\s.,TL₺TRY%:\-+*xX]+$').hasMatch(trimmed)) return true;
    // Kısa sayısal değerler (sıra no, vb.)
    if (trimmed.length <= 5 && RegExp(r'^\d+$').hasMatch(trimmed)) return true;
    return false;
  }

  bool _isNoiseLine(String text) {
    final lower = text.toLowerCase();
    const noiseKeywords = [
      'kargo', 'teslimat', 'kupon', 'puan', 'yorum',
      'bedava', 'indirim', 'sepet',
      'taksit', 'kampanya', 'hakkımızda', 'iletişim',
      'fiş no', 'fiş tarihi', 'mağaza',
      'toplam', 'ara toplam', 'genel toplam', 'mal bedeli',
      'net tutar', 'kdv',
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
}
