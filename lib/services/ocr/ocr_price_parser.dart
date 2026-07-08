import 'package:vixrex/models/ocr_price.dart';

/// OCR çıktısından fiyat çıkarma servisi.
class OcrPriceParser {
  const OcrPriceParser();

  /// Türk lirası fiyat pattern'i.
  static final RegExp pricePattern = RegExp(
    r'(?:sepette\s*)?(?:(?:₺|TL|TRY)\s*)?(?:\d{1,3}(?:[.,\s]\d{3})*|\d{1,9})(?:[.,]\d{1,2})?\s*(?:₺|TL|TRY|tl|try)?',
    caseSensitive: false,
  );

  /// Metin içindeki tüm fiyatları çıkar.
  List<OcrPrice> extractPrices(String rawText) {
    final prices = <OcrPrice>[];
    final lines = rawText.split('\n');

    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
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
        } else if (fractionalLength == 1 || fractionalLength == 2) {
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

    if (RegExp(r'\d{1,2}:\d{2}').hasMatch(normalizedLine)) return false;
    if (normalizedLine.contains('★') || normalizedLine.contains('⭐')) return false;
    if (normalizedLine.contains('puan') || normalizedLine.contains('yorum')) return false;
    if (normalizedLine.contains('%')) return false;
    if (normalizedLine.contains('kupon')) return false;

    final numeric = parseAmount(value);
    if (numeric == null) return false;

    final hasCurrency = normalizedLine.contains('tl') ||
        normalizedLine.contains('try') ||
        normalizedLine.contains('₺') ||
        normalizedLine.contains(r'$');

    if (hasCurrency) return true;
    return numeric >= 4;
  }
}
