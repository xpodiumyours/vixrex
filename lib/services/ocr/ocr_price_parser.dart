import 'dart:ui';
import 'package:vixrex/models/ocr_price.dart';

/// Çok katmanlı fiyat çıkarma servisi.
///
/// 3 strateji kullanır:
/// 1. Regex tabanlı (hızlı, genel)
/// 2. Pattern tabanlı (yapısal fiş formatları)
/// 3. Context-aware (satır bağlamına göre)
class OcrPriceParser {
  const OcrPriceParser();

  // ─── STRATEJİ 1: REGEX ───────────────────────────────────────────

  /// Türk lirası fiyat pattern'i.
  static final RegExp _pricePattern = RegExp(
    r'(?:sepette\s*)?'
    r'(?:₺|TL|TRY|KR|KURUŞ|tl|try|kr|kuruş)?\s*'
    r'(?:\b\d{1,3}(?:[.,]\d{3})*[.,]\d{2,4}\b'
    r'|\b\d+[.,]\d{2,4}\b'
    r'|\b\d{3,4}\b'
    r'|\b\d{1,5}\b)'
    r'\s*(?:₺|TL|TRY|KR|KURUŞ|tl|try|kr|kuruş)?',
    caseSensitive: false,
  );

  /// "2 adet x 15₺ = 30₺" formatı.
  static final RegExp _quantityPricePattern = RegExp(
    r'(\d+)\s*(?:adet|ad|pcs|kutu|paket|kg|lt|g|ADET|AD|PCS)\s*[xX×*]\s*'
    r'([\d.,]+)\s*(?:₺|TL|TRY|KR|KURUŞ|tl|try|kr|kuruş)?\s*=\s*([\d.,]+)\s*(?:₺|TL|TRY|KR|KURUŞ|tl|try|kr|kuruş)?',
    caseSensitive: false,
  );

  // ─── STRATEJİ 2: YAPIsal Fiyat Patternleri ──────────────────────

  /// Fiyat-miktar toplamı pattern'i: "15.00 x 4 = 60.00"
  static final RegExp _priceTimesQuantity = RegExp(
    r'([\d.,]+)\s*[xX×*]\s*(\d+)\s*=\s*([\d.,]+)',
  );

  /// Birim fiyat + toplam pattern'i: "75.0000 TL 300.00 TL"
  static final RegExp _unitAndTotal = RegExp(
    r'([\d.,]+)\s*(?:₺|TL|TRY|tl|try)?\s+([\d.,]+)\s*(?:₺|TL|TRY|tl|try)',
  );

  // ─── ANA METOT ──────────────────────────────────────────────────

  /// Metin içindeki tüm fiyatları çıkar.
  List<OcrPrice> extractPrices(String rawText) {
    final prices = <OcrPrice>[];
    final lines = rawText.split('\n');

    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      final lowerLine = line.toLowerCase();

      // Header/Footer satırlarını atla
      if (_isHeaderOrFooter(lowerLine)) {
        // Ama toplam satırlarını yakala
        if (lowerLine.contains('toplam') && (lowerLine.contains('tl') || lowerLine.contains('₺') || lowerLine.contains('kuruş') || lowerLine.contains('kr'))) {
          final price = _extractSinglePrice(line, lineIndex);
          if (price != null) {
            prices.add(price.copyWith(confidence: _priceConfidence(price.rawText, line)));
          }
        }
        continue;
      }

      // Strateji 2: Yapısal pattern kontrolü
      final structuralPrice = _extractStructuralPrice(line, lineIndex);
      if (structuralPrice != null) {
        prices.add(structuralPrice.copyWith(confidence: _priceConfidence(structuralPrice.rawText, line)));
        continue;
      }

      // Strateji 1: Regex ile fiyat çıkarma
      final matches = _pricePattern.allMatches(line);
      for (final match in matches) {
        final rawPrice = match.group(0)?.trim();
        if (rawPrice == null || rawPrice.isEmpty) continue;

        final amount = parseAmount(rawPrice);
        if (amount == null) continue;

        if (!_looksLikePrice(rawPrice, line)) continue;

        prices.add(OcrPrice(
          rawText: rawPrice,
          amount: amount.toDouble(),
          lineNumber: lineIndex,
          blockIndex: 0,
          confidence: _priceConfidence(rawPrice, line),
          boundingBox: Rect.fromLTWH(0, lineIndex * 30.0, line.length * 8.0, 20),
        ));
        break; // Satırdaki ilk geçerli fiyatı al
      }
    }

    return prices;
  }

  // ─── STRATEJİ 2: YAPIsal Fiyat Çıkarma ─────────────────────────

  /// Yapısal pattern'lerden fiyat çıkar.
  OcrPrice? _extractStructuralPrice(String line, int lineIndex) {
    // "75.0000 TL 300.00 TL" → birim fiyat = 75.0000
    final unitMatch = _unitAndTotal.firstMatch(line);
    if (unitMatch != null) {
      final unitPrice = parseAmount(unitMatch.group(1)!);
      if (unitPrice != null && unitPrice > 0 && unitPrice <= 100000) {
        return OcrPrice(
          rawText: unitMatch.group(1)!,
          amount: unitPrice.toDouble(),
          lineNumber: lineIndex,
          blockIndex: 0,
          boundingBox: Rect.fromLTWH(0, lineIndex * 30.0, line.length * 8.0, 20),
        );
      }
    }

    // "2 adet x 15₺ = 30₺" → birim fiyat = 15
    final qpMatch = _quantityPricePattern.firstMatch(line);
    if (qpMatch != null) {
      final unitPrice = parseAmount(qpMatch.group(2)!);
      if (unitPrice != null && unitPrice > 0) {
        return OcrPrice(
          rawText: qpMatch.group(2)!,
          amount: unitPrice.toDouble(),
          lineNumber: lineIndex,
          blockIndex: 0,
          boundingBox: Rect.fromLTWH(0, lineIndex * 30.0, line.length * 8.0, 20),
        );
      }
    }

    return null;
  }

  // ─── STRATEJİ 3: CONTEXT-AWARE ──────────────────────────────────

  /// Satır bağlamına göre fiyat olasılığını hesapla.
  /// 0.0 (fiyat değil) ile 1.0 (kesin fiyat) arasında.
  double _priceConfidence(String rawPrice, String fullLine) {
    double confidence = 0.5; // Başlangıç

    final lower = fullLine.toLowerCase();

    // Para birimi varsa +0.3
    if (lower.contains('tl') || lower.contains('₺') || lower.contains('try') || lower.contains('kr') || lower.contains('kuruş')) {
      confidence += 0.3;
    }

    // Ondalık ayracı varsa +0.1
    if (rawPrice.contains('.') || rawPrice.contains(',')) {
      confidence += 0.1;
    }

    // "TOPMAL", "GENEL TOPLAM" gibi ifadeler varsa bu bir fiyat
    if (lower.contains('toplam') || lower.contains('genel') || lower.contains('tutar')) {
      confidence += 0.2;
    }

    // Sadece sayısal değer ve para birimi yoksa -0.2
    if (!lower.contains('tl') && !lower.contains('₺') && !lower.contains('try') && !lower.contains('kr') && !lower.contains('kuruş')) {
      confidence -= 0.2;
    }

    return confidence.clamp(0.0, 1.0);
  }

  // ─── YARDIMCI METOTLAR ──────────────────────────────────────────

  /// Tek satırdan fiyat çıkar.
  OcrPrice? _extractSinglePrice(String line, int lineNumber) {
    final matches = _pricePattern.allMatches(line);
    for (final match in matches) {
      final rawPrice = match.group(0)?.trim();
      if (rawPrice == null) continue;
      final amount = parseAmount(rawPrice);
      if (amount != null && amount > 0 && amount <= 100000) {
        return OcrPrice(
          rawText: rawPrice,
          amount: amount.toDouble(),
          lineNumber: lineNumber,
          blockIndex: 0,
          boundingBox: Rect.fromLTWH(0, lineNumber * 30.0, rawPrice.length * 8.0, 20),
        );
      }
    }
    return null;
  }

  /// Header/footer satırı mı kontrol et.
  bool _isHeaderOrFooter(String lowerLine) {
    const headerFooterKeywords = [
      'tarih', 'saat :', 'fiş no', 'sayfa', 'model stok',
      'mağaza', 'firma', 'adres', 'telefon', 'vergi no',
      'kasiyer', 'işlem no', 'pos', 'terminal',
    ];
    return headerFooterKeywords.any((kw) => lowerLine.contains(kw));
  }

  /// Fiyat string'inden sayısal değeri çıkar.
  num? parseAmount(String rawPrice) {
    var normalized = rawPrice
        .replaceAll(RegExp(r'sepette|tl|try|₺|\$|kr|kuruş', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (normalized.isEmpty) return null;
    normalized = normalized.replaceAll(' ', '');

    if (!RegExp(r'\d').hasMatch(normalized)) return null;

    final lastComma = normalized.lastIndexOf(',');
    final lastDot = normalized.lastIndexOf('.');

    if (lastComma != -1 && lastDot != -1) {
      final decimalSeparator = lastComma > lastDot ? ',' : '.';
      final thousandsSeparator = decimalSeparator == ',' ? '.' : ',';
      normalized = normalized.replaceAll(thousandsSeparator, '');
      if (decimalSeparator == ',') {
        normalized = normalized.replaceAll(',', '.');
      }
    } else if (lastComma != -1 || lastDot != -1) {
      final separator = lastComma != -1 ? ',' : '.';
      final parts = normalized.split(separator);
      if (parts.length > 2) {
        normalized = normalized.replaceAll(separator, '');
      } else if (parts.length == 2) {
        final fractionalLength = parts.last.length;
        if (fractionalLength == 3) {
          normalized = normalized.replaceAll(separator, '');
        } else if (fractionalLength == 1 || fractionalLength == 2 || fractionalLength == 4) {
          if (separator == ',') {
            normalized = normalized.replaceAll(',', '.');
          }
        } else {
          normalized = normalized.replaceAll(separator, '');
        }
      }
    }

    final parsed = num.tryParse(normalized);
    if (parsed == null) return null;
    if (parsed % 1 == 0) return parsed.toInt();
    return parsed;
  }

  /// Verilen değerin fiyat olup olmadığını kontrol et.
  bool _looksLikePrice(String value, String fullLine) {
    final normalizedLine = fullLine.toLowerCase();

    // 1. Saat formatı
    if (RegExp(r'\b\d{1,2}:\d{2}(:\d{2})?\b').hasMatch(normalizedLine)) return false;

    // 2. Yıldız ve emoji
    if (normalizedLine.contains('★') || normalizedLine.contains('⭐')) return false;

    // 3. Puan/yorum
    if (normalizedLine.contains('puan') || normalizedLine.contains('yorum')) return false;

    // 4. Yüzde
    if (normalizedLine.contains('%')) return false;

    // 5. Kupon
    if (normalizedLine.contains('kupon')) return false;

    // 6. Barkod (10+ haneli)
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length >= 10) return false;

    // 7. Tarih formatı
    if (RegExp(r'\b\d{2}[./-]\d{2}[./-]\d{2,4}\b').hasMatch(value)) return false;

    // 8. Adet/miktar
    if (RegExp(value.replaceAll('.', r'\.') + r'\s*(ad|adet|dz|pcs|kg|g|lt|l|kutu|paket)\b', caseSensitive: false).hasMatch(normalizedLine)) {
      return false;
    }

    final numeric = parseAmount(value);
    if (numeric == null) return false;

    // 9. Aşırı büyük/sıfıra yakın
    if (numeric <= 0.5 || numeric > 150000) return false;

    final hasCurrency = normalizedLine.contains('tl') ||
        normalizedLine.contains('try') ||
        normalizedLine.contains('₺') ||
        normalizedLine.contains(r'$') ||
        normalizedLine.contains('kr') ||
        normalizedLine.contains('kuruş');

    // 10. Para birimi varsa ve düz tamsayıysa skip et
    if (!value.contains('TL') && !value.contains('₺') && !value.contains('tl')) {
      if (lineHasCurrency(fullLine)) {
        if (numeric % 1 == 0 && numeric < 1000) return false;
      }
    }

    // 11. Başı 0 ile başlayan kodlar
    if (value.trim().startsWith('0') && !value.contains('.') && !value.contains(',')) {
      return false;
    }

    // 12. Ondalıklı satırda düz tamsayı
    if (!value.contains('.') && !value.contains(',')) {
      final lineHasDecimals = RegExp(r'\b\d+[\.,]\d{2}\b').hasMatch(fullLine);
      if (lineHasDecimals) return false;
    }

    if (hasCurrency) return true;

    // Para birimi yoksa ondalık ayracı şart
    final hasDecimalSeparator = value.contains(',') || value.contains('.');
    if (hasDecimalSeparator) return true;

    // Tamsayı fiyatlar için makul aralık
    return numeric >= 10 && numeric <= 5000;
  }

  /// Satırda para birimi geçiyor mu?
  bool lineHasCurrency(String line) {
    final lower = line.toLowerCase();
    return RegExp(r'\b(tl|try|₺|\$|kr|kuruş)\b').hasMatch(lower);
  }

  /// Satırdaki ilk fiyatı çıkar.
  OcrPrice? extractFirstPrice(String text, {int lineNumber = 0}) {
    final match = _pricePattern.firstMatch(text);
    if (match == null) return null;

    final rawPrice = match.group(0)?.trim();
    if (rawPrice == null) return null;

    final amount = parseAmount(rawPrice);
    if (amount == null) return null;

    if (!_looksLikePrice(rawPrice, text)) return null;

    return OcrPrice(
      rawText: rawPrice,
      amount: amount.toDouble(),
      lineNumber: lineNumber,
      blockIndex: 0,
      boundingBox: Rect.fromLTWH(0, lineNumber * 30.0, text.length * 8.0, 20),
    );
  }
}
