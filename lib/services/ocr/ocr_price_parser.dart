import 'package:vixrex/models/ocr_price.dart';

/// OCR çıktısından fiyat çıkarma servisi.
class OcrPriceParser {
  const OcrPriceParser();

  /// Türk lirası fiyat pattern'i (geliştirilmiş sürüm).
  static final RegExp pricePattern = RegExp(
    r'(?:sepette\s*)?(?:(?:₺|TL|TRY)\s*)?(?:\b\d{1,3}(?:[.,]\d{3})*[.,]\d{2,4}\b|\b\d+[.,]\d{2,4}\b|\b\d{3,4}\b|\b\d{1,5}\b)\s*(?:₺|TL|TRY|tl|try)?',
    caseSensitive: false,
  );

  /// Metin içindeki tüm fiyatları çıkar.
  List<OcrPrice> extractPrices(String rawText) {
    final prices = <OcrPrice>[];
    final lines = rawText.split('\n');

    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      final lowerLine = line.toLowerCase();
      
      // Satır bazlı gürültü kontrolü (Tarih, Saat, Fiş No satırları fiyat içermez)
      if (lowerLine.contains('tarih') || 
          lowerLine.contains('saat :') || 
          lowerLine.contains('fiş no') ||
          lowerLine.contains('sayfa') ||
          lowerLine.contains('model stok')) {
        // Ancak bu satırda açıkça 'TL' veya '₺' geçiyorsa izin ver (örn: Toplam: 1.920,00 TL)
        if (!lowerLine.contains('tl') && !lowerLine.contains('₺')) {
          continue;
        }
      }

      final matches = pricePattern.allMatches(line);

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
        ));
        break; // Fiş/Fatura ve etiketlerde satırdaki İLK geçerli fiyatı (Birim Fiyatı) baz al
      }
    }

    return prices;
  }

  /// Satırdaki ilk fiyatı çıkar.
  OcrPrice? extractFirstPrice(String text, {int lineNumber = 0}) {
    final match = pricePattern.firstMatch(text);
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
    );
  }

  /// Fiyat string'inden sayısal değeri çıkar.
  num? parseAmount(String rawPrice) {
    var normalized = rawPrice
        .replaceAll(RegExp(r'sepette|tl|try|₺|\$', caseSensitive: false), '')
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

    // 1. Saat formatı kontrolü
    if (RegExp(r'\b\d{1,2}:\d{2}(:\d{2})?\b').hasMatch(normalizedLine)) return false;

    // 2. Özel simge ve gürültü kelimeleri
    if (normalizedLine.contains('★') || normalizedLine.contains('⭐')) return false;
    if (normalizedLine.contains('puan') || normalizedLine.contains('yorum')) return false;
    if (normalizedLine.contains('%')) return false;
    if (normalizedLine.contains('kupon')) return false;

    // 3. Barkod kontrolü (10 haneden büyük sayılar fiyat olamaz)
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length >= 10) return false;

    // 4. Tarih formatları kontrolü (örn: 07.07.2026, 07/07/2026)
    if (RegExp(r'\b\d{2}[./-]\d{2}[./-]\d{2,4}\b').hasMatch(value)) return false;

    // 5. Adet / Miktar kontrolü (örn: 18 ad, 2 AD)
    if (RegExp(value.replaceAll('.', r'\.') + r'\s*(ad|adet|dz|pcs|kg|g|lt|l)\b', caseSensitive: false).hasMatch(normalizedLine)) {
      return false;
    }

    final numeric = parseAmount(value);
    if (numeric == null) return false;

    // 6. Aşırı büyük veya sıfıra yakın tutarları engelle
    if (numeric <= 0.5 || numeric > 150000) return false;

    final hasCurrency = normalizedLine.contains('tl') ||
        normalizedLine.contains('try') ||
        normalizedLine.contains('₺') ||
        normalizedLine.contains(r'$');

    // 7. Satırda para birimi varsa ve bu değer para birimi simgesi taşımıyorsa, ama satırdaki başka bir değer taşıyorsa bunu skip et
    if (!value.contains('TL') && !value.contains('₺') && !value.contains('tl')) {
      final lineHasExplicitCurrency = lineHasCurrency(fullLine);
      if (lineHasExplicitCurrency) {
        // Eğer bu değer düz bir tamsayı ise (kuruşsuz, örn: 115) skip et. Fiyatlar genellikle kuruşludur.
        if (numeric % 1 == 0 && numeric < 1000) return false;
      }
    }

    // 8. Başı 0 ile başlayan ve ondalık barındırmayan kodları skip et (örn: 021)
    if (value.trim().startsWith('0') && !value.contains('.') && !value.contains(',')) {
      return false;
    }

    // 9. Satırda ondalıklı (kuruşlu) bir sayı varsa ve bu değer düz tamsayı ise skip et (örn: 129 ve 80.00 aynı satırdaysa 129'u skip et)
    if (!value.contains('.') && !value.contains(',')) {
      final lineHasDecimals = RegExp(r'\b\d+[\.,]\d{2}\b').hasMatch(fullLine);
      if (lineHasDecimals) return false;
    }

    if (hasCurrency) return true;
    
    // Para birimi yoksa, en azından bir ondalık ayracı (virgül veya nokta) içermesini isteyelim ki (örn: 70,50) adetlerle karışmasın
    final hasDecimalSeparator = value.contains(',') || value.contains('.');
    if (hasDecimalSeparator) return true;

    // Hiçbir ayırt edici özellik yoksa tamsayı fiyatlar için makul aralıkta olmasını isteyelim (örn: 700)
    return numeric >= 10 && numeric <= 5000;
  }

  /// Satırda açıkça para birimi geçiyor mu?
  bool lineHasCurrency(String line) {
    final lower = line.toLowerCase();
    return RegExp(r'\b(tl|try|₺|\$)\b').hasMatch(lower);
  }
}
