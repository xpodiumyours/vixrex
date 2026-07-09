import 'package:vixrex/models/detected_product.dart';
import 'package:vixrex/models/ocr_line.dart';
import 'package:vixrex/models/ocr_price.dart';
import 'package:vixrex/utils/text_utils.dart';
import 'ocr_excel_verifier.dart';

/// OCR satırlarını ve fiyatlarıyla ürün eşleştirme servisi.
class OcrProductMatcher {
  final OcrExcelVerifier _verifier;
  final int maxVerticalDiff;
  final double maxHorizontalCenterDiff;

  const OcrProductMatcher({
    required OcrExcelVerifier verifier,
    this.maxVerticalDiff = 5,
    this.maxHorizontalCenterDiff = 300,
  }) : _verifier = verifier;

  /// OCR satırlarını ve fiyatlarıyla ürünleri eşleştir.
  Future<List<DetectedProduct>> matchProducts(
    List<OcrLine> lines,
    List<OcrPrice> prices, {
    String scanMode = 'receipt',
  }) async {
    final products = <DetectedProduct>[];
    final usedLines = <int>{};

    if (scanMode == 'shelf_label') {
      // 1. Raf/Etiket Modu: Aynı blockIndex altındaki veya hemen üstündeki metinleri fiyatla eşleştir
      for (final price in prices) {
        OcrLine? matchingProductLine;

        // Aynı block içindeki en yakın üst satırı bulmaya çalış
        final sameBlockLines = lines.where((l) =>
            l.blockIndex == price.blockIndex &&
            l.lineIndex < price.lineNumber &&
            !usedLines.contains(l.lineIndex) &&
            l.text.length >= 3 &&
            !_isNoiseLine(l.text) &&
            !_isOnlyPrice(l.text));

        if (sameBlockLines.isNotEmpty) {
          // En yakın üst satırı seç
          matchingProductLine = sameBlockLines.reduce((a, b) =>
              (price.lineNumber - a.lineIndex) < (price.lineNumber - b.lineIndex) ? a : b);
        } else {
          // Farklı block'taysa en yakın dikey mesafedeki üst satırı ara
          final candidates = lines.where((l) =>
              !usedLines.contains(l.lineIndex) &&
              l.text.length >= 3 &&
              !_isNoiseLine(l.text) &&
              !_isOnlyPrice(l.text) &&
              l.centerY < lines.firstWhere((pl) => pl.lineIndex == price.lineNumber && pl.blockIndex == price.blockIndex, orElse: () => lines.first).centerY);

          if (candidates.isNotEmpty) {
            final priceLine = lines.firstWhere((pl) => pl.lineIndex == price.lineNumber && pl.blockIndex == price.blockIndex, orElse: () => lines.first);
            OcrLine? closest;
            double minDist = double.infinity;
            for (final c in candidates) {
              final dist = priceLine.verticalDistanceTo(c);
              if (dist < minDist && dist < 300) { // Maksimum dikey mesafe sınırı
                minDist = dist;
                closest = c;
              }
            }
            matchingProductLine = closest;
          }
        }

        if (matchingProductLine != null) {
          usedLines.add(matchingProductLine.lineIndex);

          final normalized = TextUtils.normalizeTurkish(matchingProductLine.text);
          final match = await _verifier.findBestMatch(normalized);

          products.add(DetectedProduct(
            id: 'ocr_${DateTime.now().microsecondsSinceEpoch}_${products.length}',
            name: match?.urunAdi ?? matchingProductLine.text,
            brand: match?.marka ?? '',
            category: match?.kategori ?? 'Genel',
            price: price.amount,
            confidence: (match?.confidence ?? 0.3) + 0.1, // Blok içi eşleşmeler daha güvenilirdir
            source: 'ocr_shelf_label',
          ));
        }
      }
    } else {
      // 2. Fiş/Fatura Modu: Önce fiyat içeren satırları işle
      for (final price in prices) {
        // Fiyata en yakın metin satırını bul (yukarıda veya aynı satırda)
        final nearbyLine = _findNearestTextAbove(lines, price, usedLines);
        if (nearbyLine != null) {
          usedLines.add(nearbyLine.lineIndex);

          final cleaned = _cleanProductText(nearbyLine.text, prices);
          if (cleaned.length < 3) continue;

          final normalized = TextUtils.normalizeTurkish(cleaned);
          final match = await _verifier.findBestMatch(normalized);

          products.add(DetectedProduct(
            id: 'ocr_${DateTime.now().microsecondsSinceEpoch}_${products.length}',
            name: match?.urunAdi ?? cleaned,
            brand: match?.marka ?? '',
            category: match?.kategori ?? 'Genel',
            price: price.amount,
            confidence: match?.confidence ?? 0.3,
            source: 'ocr_priced',
          ));
        }
      }
    }

    // 2. Fiyat içermeyen ama ürün olabilecek satırları işle
    for (final line in lines) {
      if (usedLines.contains(line.lineIndex)) continue;
      if (line.text.length < 3) continue;
      if (_isNoiseLine(line.text)) continue;

      final normalized = TextUtils.normalizeTurkish(line.text);
      final match = await _verifier.findBestMatch(normalized);

      if (match != null && match.confidence >= 0.5) {
        products.add(DetectedProduct(
          id: 'ocr_${DateTime.now().microsecondsSinceEpoch}_${products.length}',
          name: match.urunAdi,
          brand: match.marka,
          category: match.kategori,
          confidence: match.confidence,
          source: 'ocr_text',
        ));
      }
    }

    return _deduplicateProducts(products);
  }

  /// Fiyata en yakın metin satırını bul (yukarıda, dikey koridorda).
  OcrLine? _findNearestTextAbove(
    List<OcrLine> lines,
    OcrPrice price,
    Set<int> usedLines,
  ) {
    OcrLine? bestLine;
    double bestDistance = double.infinity;

    for (final line in lines) {
      if (usedLines.contains(line.lineIndex)) continue;
      if (line.text.length < 3) continue;
      if (_isNoiseLine(line.text)) continue;

      // Fiyatın kendisiyle birebir aynıysa skip
      if (line.text.trim() == price.rawText.trim()) continue;
      // Sadece fiyat/sayı içeren satırları skip
      final isOnlyPrice = RegExp(r'^[\d\s.,TL₺TRY%:\-+*xXadADETadetsılmSIRAoOgG\(\)]+$').hasMatch(line.text.trim());
      if (isOnlyPrice) {
        // Eğer satırda birden fazla boşlukla ayrılmış sayı grubu varsa (örn: 2 021 250 500), bu bir fiş satırıdır, skip etme!
        final tokens = line.text.trim().split(RegExp(r'\s+'));
        if (tokens.length < 3) continue;
      }

      // Satır fiyatın yukarısında olmalı (dikey koridor)
      final verticalDiff = price.lineNumber - line.lineIndex;
      if (verticalDiff < 0 || verticalDiff > maxVerticalDiff) continue;

      // Yatay eksende yakın olmalı
      final horizontalCenterDiff = (line.centerX - price.rawText.length * 5).abs();
      if (horizontalCenterDiff > maxHorizontalCenterDiff) continue;

      final distance = verticalDiff * 100 + horizontalCenterDiff;
      if (distance < bestDistance) {
        bestDistance = distance;
        bestLine = line;
      }
    }

    return bestLine;
  }

  bool _isNoiseLine(String text) {
    final lower = text.toLowerCase();
    const noiseKeywords = [
      'kargo', 'teslimat', 'kupon', 'puan', 'yorum',
      'bedava', 'indirim', 'sepet',
      'taksit', 'kampanya', 'hakkımızda', 'iletişim',
      'fiş no', 'fiş tarihi', 'mağaza',
    ];
    return noiseKeywords.any((kw) => lower.contains(kw));
  }

  /// Aynı ürünleri birleştir (miktarı artır).
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

  /// Satırdaki fiyat, miktar, barkod ve model kodlarını temizler.
  String _cleanProductText(String text, List<OcrPrice> prices) {
    var cleaned = text;

    // 1. Tüm tespit edilen fiyatları temizle
    for (final price in prices) {
      cleaned = cleaned.replaceAll(price.rawText, '');
    }

    // 2. Barkodları (13 haneli) temizle
    cleaned = cleaned.replaceAll(RegExp(r'\b\d{13}\b'), '');

    // 3. Adet ve Miktarları temizle (örn: 18 ad, 2 AD, 3 adet)
    cleaned = cleaned.replaceAll(RegExp(r'\b\d+\s*(ad|adet|dz|AD|ADET|adetsılmSIRA)\b', caseSensitive: false), '');

    // 4. Model kodlarını temizle (hem harf hem rakam içeren alfa-nümerik yapılar veya 4+ haneli düz sayılar)
    cleaned = cleaned.replaceAll(RegExp(r'\b(?=[A-Za-z0-9-]*\d)(?=[A-Za-z0-9-]*[A-Za-z])[A-Za-z0-9-]{4,15}\b|\b\d{4,9}\b'), '');

    // 5. Baştaki ve sondaki sayıları temizle (sıra no, adet no vb.)
    cleaned = cleaned.replaceAll(RegExp(r'^\d+\s+'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+\d+$'), '');

    // 6. Fazlalık boşlukları düzelt
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned;
  }

  /// Satırın sadece fiyat veya sayısal değerlerden oluşup oluşmadığını denetler.
  bool _isOnlyPrice(String text) {
    final trimmed = text.trim();
    final isOnlyPrice = RegExp(r'^[\d\s.,TL₺TRY%:\-+*xXadADETadetsılmSIRAoOgG\(\)]+$').hasMatch(trimmed);
    if (!isOnlyPrice) return false;
    final tokens = trimmed.split(RegExp(r'\s+'));
    return tokens.length < 3;
  }
}
