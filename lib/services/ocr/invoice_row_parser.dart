import 'dart:math' as math;

import 'package:vixrex/models/detected_product.dart';
import 'package:vixrex/models/ocr_text_result.dart';
import 'package:vixrex/models/ocr_token.dart';

/// Fatura tablosundaki ürün satırlarını yalnız OCR'ın gerçekten gördüğü
/// değerlerden çıkarır.
///
/// Eksik alanı tahmin etmez. Yalnız adet okunamadığında, görülen alış fiyatı
/// ile satır toplamı tam bir tam sayı miktara eşleşiyorsa adedi deterministik
/// olarak çıkarır. Alış fiyatını satış fiyatına dönüştürmez.
class InvoiceRowParser {
  const InvoiceRowParser();

  static List<String> validateProduct(DetectedProduct product) {
    return const InvoiceRowParser()._validationIssues(
      barcode: product.barcode,
      quantity: product.documentQuantity,
      purchaseUnitPrice: product.purchaseUnitPrice,
      lineTotal: product.lineTotal,
    );
  }

  List<DetectedProduct> parse(OcrTextResult result) {
    if (result.tokens.isEmpty) return <DetectedProduct>[];

    final recognitionProducts = _parseRows(
      _groupByRecognitionLine(result.tokens),
    );
    final visualProducts = _parseRows(_groupByVisualRow(result.tokens));

    final selected =
        visualProducts.length > recognitionProducts.length
            ? visualProducts
            : recognitionProducts;

    return _deduplicate(selected);
  }

  List<List<OcrToken>> _groupByRecognitionLine(List<OcrToken> tokens) {
    final groups = <String, List<OcrToken>>{};

    for (final token in tokens) {
      final key = '${token.blockIndex}:${token.lineIndex}';
      groups.putIfAbsent(key, () => <OcrToken>[]).add(token);
    }

    final rows = groups.values.toList();
    for (final row in rows) {
      row.sort((a, b) => a.centerX.compareTo(b.centerX));
    }
    rows.sort((a, b) => _rowCenterY(a).compareTo(_rowCenterY(b)));
    return rows;
  }

  List<List<OcrToken>> _groupByVisualRow(List<OcrToken> tokens) {
    final sorted = List<OcrToken>.from(tokens)
      ..sort((a, b) => a.centerY.compareTo(b.centerY));

    if (sorted.isEmpty) return <List<OcrToken>>[];

    final heights =
        sorted
            .map((token) => token.height)
            .where((height) => height > 0)
            .toList()
          ..sort();

    final medianHeight = heights.isEmpty ? 12.0 : heights[heights.length ~/ 2];
    final tolerance = math.max(8.0, medianHeight * 0.85);

    final rows = <List<OcrToken>>[];

    for (final token in sorted) {
      List<OcrToken>? bestRow;
      var bestDistance = double.infinity;

      for (final row in rows) {
        final distance = (_rowCenterY(row) - token.centerY).abs();
        if (distance <= tolerance && distance < bestDistance) {
          bestRow = row;
          bestDistance = distance;
        }
      }

      if (bestRow == null) {
        rows.add(<OcrToken>[token]);
      } else {
        bestRow.add(token);
      }
    }

    for (final row in rows) {
      row.sort((a, b) => a.centerX.compareTo(b.centerX));
    }
    rows.sort((a, b) => _rowCenterY(a).compareTo(_rowCenterY(b)));
    return rows;
  }

  List<DetectedProduct> _parseRows(List<List<OcrToken>> rows) {
    final products = <DetectedProduct>[];

    for (final row in rows) {
      final product = _parseRow(row, products.length);
      if (product != null) products.add(product);
    }

    return products;
  }

  DetectedProduct? _parseRow(List<OcrToken> input, int index) {
    if (input.length < 3) return null;

    final row = List<OcrToken>.from(input)
      ..sort((a, b) => a.centerX.compareTo(b.centerX));

    final barcodeIndex = _findBarcodeIndex(row);
    if (barcodeIndex <= 0) return _parseRowWithoutBarcode(row, index);

    final barcode = _barcodeDigits(row[barcodeIndex].text);
    if (barcode == null) return _parseRowWithoutBarcode(row, index);

    final left = row.sublist(0, barcodeIndex);
    final right =
        barcodeIndex + 1 < row.length
            ? row.sublist(barcodeIndex + 1)
            : <OcrToken>[];

    final modelIndex = _findModelIndex(left);
    var model = modelIndex >= 0 ? _cleanText(left[modelIndex].text, 80) : null;

    final nameParts = <String>[];

    if (modelIndex >= 0) {
      final merged = _splitMergedModelAndName(left[modelIndex].text);
      if (merged != null) {
        model = merged.model;
        nameParts.add(merged.name);
      }

      nameParts.addAll(
        left
            .sublist(modelIndex + 1)
            .map((token) => token.text.trim())
            .where((value) => value.isNotEmpty),
      );
    } else {
      nameParts.addAll(
        left
            .map((token) => token.text.trim())
            .where((value) => value.isNotEmpty),
      );
    }

    final name = _joinStrings(nameParts);
    if (name == null || name.length < 2) return null;

    var quantity = _findQuantity(right);
    final money = _findMoney(right);

    final purchaseUnitPrice = money.isNotEmpty ? money.first.value : null;
    final lineTotal = money.length > 1 ? money[1].value : null;

    quantity ??= _deriveExactQuantity(
      purchaseUnitPrice: purchaseUnitPrice,
      lineTotal: lineTotal,
      startIndex: money.isNotEmpty ? money.first.startIndex : right.length,
    );

    final preDetailEnd =
        quantity?.startIndex ??
        (money.isNotEmpty ? money.first.startIndex : right.length);

    final safePreDetailEnd =
        preDetailEnd < 0
            ? 0
            : preDetailEnd > right.length
            ? right.length
            : preDetailEnd;

    final beforeDetail = right.sublist(0, safePreDetailEnd);
    final size = _findSize(beforeDetail);

    final variantEnd = size?.startIndex ?? beforeDetail.length;
    final safeVariantEnd =
        variantEnd < 0
            ? 0
            : variantEnd > beforeDetail.length
            ? beforeDetail.length
            : variantEnd;

    final variant = _joinVariantTokens(beforeDetail.sublist(0, safeVariantEnd));

    final issues = _validationIssues(
      barcode: barcode,
      quantity: quantity?.value,
      purchaseUnitPrice: purchaseUnitPrice,
      lineTotal: lineTotal,
    );

    return DetectedProduct(
      id: 'ocr_invoice_${DateTime.now().microsecondsSinceEpoch}_$index',
      name: name,
      quantity: quantity?.value ?? 1,
      documentQuantity: quantity?.value,
      confidence: _confidence(
        hasModel: model != null,
        barcodeValid: _isValidGtin(barcode),
        hasVariant: variant != null,
        hasSize: size != null,
        hasQuantity: quantity != null,
        hasPurchasePrice: purchaseUnitPrice != null,
        hasLineTotal: lineTotal != null,
        issues: issues,
      ),
      source: 'ocr_invoice',
      barcode: barcode,
      sku: model,
      variant: variant,
      size: size?.value,
      purchaseUnitPrice: purchaseUnitPrice,
      lineTotal: lineTotal,
      issues: issues,
    );
  }

  DetectedProduct? _parseRowWithoutBarcode(List<OcrToken> input, int index) {
    final row = List<OcrToken>.from(input)
      ..sort((a, b) => a.centerX.compareTo(b.centerX));
    final money = _findMoney(row);
    if (money.isEmpty || money.first.startIndex <= 0) return null;

    final purchaseUnitPrice = money.first.value;
    final lineTotal = money.length > 1 ? money[1].value : null;
    final beforeMoney = List<OcrToken>.from(
      row.sublist(0, money.first.startIndex),
    );
    if (beforeMoney.isEmpty) return null;

    final explicitQuantity = _findQuantity(beforeMoney);
    var quantity = explicitQuantity;
    quantity ??= _deriveExactQuantity(
      purchaseUnitPrice: purchaseUnitPrice,
      lineTotal: lineTotal,
      startIndex: beforeMoney.length,
    );

    final identity = List<OcrToken>.from(beforeMoney);
    if (explicitQuantity != null &&
        explicitQuantity.startIndex >= 0 &&
        explicitQuantity.startIndex < identity.length) {
      final start = explicitQuantity.startIndex;
      var end = start + 1;
      if (end < identity.length) {
        final next = _normalizeCompact(identity[end].text);
        if (next == 'AD' || next == 'ADET' || next == 'PCS') end++;
      }
      identity.removeRange(start, end);
    }

    if (explicitQuantity == null && quantity != null && identity.isNotEmpty) {
      final q = quantity.value.toString();
      if (_normalizeCompact(identity.first.text) == q && identity.length > 1) {
        identity.removeAt(0);
      }
      if (identity.isNotEmpty &&
          _normalizeCompact(identity.last.text) == q &&
          identity.length > 1) {
        identity.removeLast();
      }
    }

    identity.removeWhere((token) {
      final value = _normalizeCompact(token.text);
      return value == 'AD' ||
          value == 'ADET' ||
          value == 'PCS' ||
          RegExp(r'^\d{1,6}(?:AD|ADET|PCS)$').hasMatch(value);
    });
    if (identity.isEmpty) return null;

    var modelIndex = -1;
    for (var i = 0; i < identity.length; i++) {
      final compact = _normalizeCompact(identity[i].text);
      final hasLetter = RegExp(r'[A-Z]').hasMatch(compact);
      final hasDigit = RegExp(r'\d').hasMatch(compact);
      if (hasLetter && hasDigit) {
        modelIndex = i;
        break;
      }
      if (i == 0 &&
          identity.length > 1 &&
          RegExp(r'^\d{2,20}$').hasMatch(compact)) {
        modelIndex = i;
        break;
      }
    }

    final model =
        modelIndex >= 0 ? _cleanText(identity[modelIndex].text, 80) : null;
    final nameParts = <String>[];
    for (var i = 0; i < identity.length; i++) {
      if (i == modelIndex) continue;
      final value = identity[i].text.trim();
      if (value.isNotEmpty) nameParts.add(value);
    }
    final name = _joinStrings(nameParts);
    if (name == null || name.length < 2) return null;

    final issues = _validationIssues(
      barcode: null,
      quantity: quantity?.value,
      purchaseUnitPrice: purchaseUnitPrice,
      lineTotal: lineTotal,
    );

    return DetectedProduct(
      id: 'ocr_invoice_${DateTime.now().microsecondsSinceEpoch}_$index',
      name: name,
      quantity: quantity?.value ?? 1,
      documentQuantity: quantity?.value,
      confidence: _confidence(
        hasModel: model != null,
        barcodeValid: false,
        hasVariant: false,
        hasSize: false,
        hasQuantity: quantity != null,
        // Bu noktada purchaseUnitPrice her zaman dolu: money boşsa satır
        // zaten null dönüyor. Kontrol analiz uyarısı üretiyordu.
        hasPurchasePrice: true,
        hasLineTotal: lineTotal != null,
        issues: issues,
      ),
      source: 'ocr_invoice',
      sku: model,
      purchaseUnitPrice: purchaseUnitPrice,
      lineTotal: lineTotal,
      issues: issues,
    );
  }

  List<String> _validationIssues({
    required String? barcode,
    required int? quantity,
    required double? purchaseUnitPrice,
    required double? lineTotal,
  }) {
    final issues = <String>[];

    if (barcode != null && !_isValidGtin(barcode)) {
      issues.add('INVALID_BARCODE_CHECK_DIGIT');
    }
    if (quantity == null) issues.add('QUANTITY_MISSING');
    if (purchaseUnitPrice == null) issues.add('PURCHASE_PRICE_MISSING');
    if (lineTotal == null) issues.add('LINE_TOTAL_MISSING');

    if (quantity != null &&
        purchaseUnitPrice != null &&
        lineTotal != null &&
        !_moneyClose(quantity * purchaseUnitPrice, lineTotal)) {
      issues.add('ARITHMETIC_MISMATCH');
    }

    return issues;
  }

  int _findBarcodeIndex(List<OcrToken> row) {
    var firstCandidate = -1;

    for (var i = 0; i < row.length; i++) {
      final digits = _barcodeDigits(row[i].text);
      if (digits == null) continue;

      if (firstCandidate < 0) firstCandidate = i;
      if (_isValidGtin(digits)) return i;
    }

    return firstCandidate;
  }

  int _findModelIndex(List<OcrToken> left) {
    for (var i = 0; i < left.length; i++) {
      final text = left[i].text.trim();

      if (text.length < 3 || text.length > 80) continue;
      if (!RegExp(r'[A-Za-zÇĞİÖŞÜçğıöşü]').hasMatch(text)) continue;
      if (!RegExp(r'\d').hasMatch(text)) continue;

      return i;
    }

    return left.isEmpty ? -1 : 0;
  }

  _IndexedInt? _findQuantity(List<OcrToken> tokens) {
    for (var i = 0; i < tokens.length; i++) {
      final current = _normalizeCompact(tokens[i].text);

      final attached = RegExp(
        r'^(\d{1,6})(?:AD|ADET|PCS)$',
      ).firstMatch(current);

      if (attached != null) {
        final value = int.tryParse(attached.group(1)!);
        if (value != null) return _IndexedInt(i, value);
      }

      if (RegExp(r'^\d{1,6}$').hasMatch(current) && i + 1 < tokens.length) {
        final next = _normalizeCompact(tokens[i + 1].text);
        if (RegExp(r'^(?:AD|ADET|PCS)$').hasMatch(next)) {
          final value = int.tryParse(current);
          if (value != null) return _IndexedInt(i, value);
        }
      }
    }

    return null;
  }

  List<_IndexedMoney> _findMoney(List<OcrToken> tokens) {
    final matches = <_IndexedMoney>[];

    for (var i = 0; i < tokens.length; i++) {
      final text = tokens[i].text.trim();
      if (!_looksLikeMoney(text)) continue;

      final value = _parseMoney(text);
      if (value == null) continue;

      matches.add(_IndexedMoney(i, value));
      if (matches.length == 2) break;
    }

    return matches;
  }

  _IndexedText? _findSize(List<OcrToken> tokens) {
    for (var i = tokens.length - 1; i >= 0; i--) {
      final current = _normalizeCompact(tokens[i].text);

      if (i + 1 < tokens.length) {
        final next = _normalizeCompact(tokens[i + 1].text);
        final combined = '$current$next';
        if (_isSize(combined)) return _IndexedText(i, combined);
      }

      if (_isSize(current)) return _IndexedText(i, current);
    }

    return null;
  }

  _IndexedInt? _deriveExactQuantity({
    required double? purchaseUnitPrice,
    required double? lineTotal,
    required int startIndex,
  }) {
    if (purchaseUnitPrice == null ||
        lineTotal == null ||
        purchaseUnitPrice <= 0 ||
        lineTotal <= 0) {
      return null;
    }

    final raw = lineTotal / purchaseUnitPrice;
    final rounded = raw.round();

    if (rounded <= 0 || rounded > 100000) return null;
    if ((raw - rounded).abs() > 0.000001) return null;
    if (!_moneyClose(rounded * purchaseUnitPrice, lineTotal)) return null;

    return _IndexedInt(startIndex, rounded);
  }

  _MergedModelName? _splitMergedModelAndName(String value) {
    final text = value.trim();
    final match = RegExp(
      r'^([A-Za-zÇĞİÖŞÜçğıöşü]{2,}\d{2,})[_|:;\-]{2,}(.+)$',
    ).firstMatch(text);

    if (match == null) return null;

    final model = _cleanText(match.group(1) ?? '', 80);
    final name =
        (match.group(2) ?? '')
            .replaceAll(RegExp(r'[_|:;]+'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

    if (model == null || name.length < 2) return null;
    return _MergedModelName(model, name);
  }

  String? _joinVariantTokens(List<OcrToken> tokens) {
    final values = <String>[];

    for (final token in tokens) {
      final text = token.text.trim();

      if (text.isEmpty) continue;
      if (RegExp(r'^_+$').hasMatch(text)) continue;
      if (RegExp(r'^\d{3}$').hasMatch(text)) continue;
      if (_looksLikeMoney(text)) continue;

      values.add(text);
    }

    return _joinStrings(values);
  }

  String? _joinStrings(List<String> values) {
    final clean = values.where((value) => value.trim().isNotEmpty).toList();
    if (clean.isEmpty) return null;

    return clean.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String? _cleanText(String value, int maxLength) {
    final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty) return null;

    return clean.length <= maxLength ? clean : clean.substring(0, maxLength);
  }

  String? _barcodeDigits(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8 || digits.length > 14) return null;
    return digits;
  }

  bool _isValidGtin(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (![8, 12, 13, 14].contains(digits.length)) return false;

    final body = digits.substring(0, digits.length - 1);
    final expected = int.tryParse(digits.substring(digits.length - 1));
    if (expected == null) return false;

    var sum = 0;
    var position = 1;

    for (var i = body.length - 1; i >= 0; i--, position++) {
      final digit = int.tryParse(body[i]);
      if (digit == null) return false;
      sum += digit * (position.isOdd ? 3 : 1);
    }

    return ((10 - (sum % 10)) % 10) == expected;
  }

  bool _looksLikeMoney(String value) {
    final upper = value.toUpperCase();

    if (!RegExp(r'\d').hasMatch(upper)) return false;

    return upper.contains(',') || upper.contains('TL') || upper.contains('₺');
  }

  double? _parseMoney(String value) {
    var text = value
        .toUpperCase()
        .replaceAll('TRY', '')
        .replaceAll('TL', '')
        .replaceAll('₺', '')
        .replaceAll(RegExp(r'[^0-9,.]'), '');

    if (text.isEmpty) return null;

    if (text.contains(',')) {
      final comma = text.lastIndexOf(',');
      final integerPart = text.substring(0, comma).replaceAll('.', '');
      final decimalPart = text.substring(comma + 1);
      text = '$integerPart.$decimalPart';
    } else if ('.'.allMatches(text).length > 1) {
      text = text.replaceAll('.', '');
    }

    return double.tryParse(text);
  }

  bool _isSize(String value) {
    final normalized = _normalizeCompact(value);

    if (RegExp(r'^(XS|S|M|L|XL|XXL|XXXL|XXXXL)$').hasMatch(normalized)) {
      return true;
    }

    if (RegExp(r'^\d{1,2}$').hasMatch(normalized)) return true;

    return RegExp(
      r'^\d{1,2}[-/]\d{1,2}(?:YAS|YIL|YA|YI|Y)?$',
    ).hasMatch(normalized);
  }

  String _normalizeCompact(String value) {
    return value
        .trim()
        .toUpperCase()
        .replaceAll('İ', 'I')
        .replaceAll('Ş', 'S')
        .replaceAll('Ğ', 'G')
        .replaceAll('Ü', 'U')
        .replaceAll('Ö', 'O')
        .replaceAll('Ç', 'C')
        .replaceAll(RegExp(r'\s+'), '');
  }

  bool _moneyClose(double a, double b) => (a - b).abs() <= 0.02;

  double _confidence({
    required bool hasModel,
    required bool barcodeValid,
    required bool hasVariant,
    required bool hasSize,
    required bool hasQuantity,
    required bool hasPurchasePrice,
    required bool hasLineTotal,
    required List<String> issues,
  }) {
    var score = 0.35;

    if (hasModel) score += 0.08;
    if (barcodeValid) score += 0.18;
    if (hasVariant) score += 0.06;
    if (hasSize) score += 0.06;
    if (hasQuantity) score += 0.10;
    if (hasPurchasePrice) score += 0.09;
    if (hasLineTotal) score += 0.05;
    if (issues.isEmpty) score += 0.03;

    return score.clamp(0.0, 1.0).toDouble();
  }

  List<DetectedProduct> _deduplicate(List<DetectedProduct> products) {
    final seen = <String>{};
    final output = <DetectedProduct>[];

    for (final product in products) {
      final barcode = product.barcode?.trim();
      final key =
          barcode != null && barcode.isNotEmpty
              ? 'barcode:$barcode'
              : 'row:${product.sku}|${product.name}|${product.documentQuantity}|${product.purchaseUnitPrice}|${product.lineTotal}';

      if (seen.add(key)) output.add(product);
    }

    return output;
  }

  double _rowCenterY(List<OcrToken> row) {
    if (row.isEmpty) return 0;

    return row.fold<double>(0, (sum, token) => sum + token.centerY) /
        row.length;
  }
}

class _MergedModelName {
  final String model;
  final String name;

  const _MergedModelName(this.model, this.name);
}

class _IndexedInt {
  final int startIndex;
  final int value;

  const _IndexedInt(this.startIndex, this.value);
}

class _IndexedMoney {
  final int startIndex;
  final double value;

  const _IndexedMoney(this.startIndex, this.value);
}

class _IndexedText {
  final int startIndex;
  final String value;

  const _IndexedText(this.startIndex, this.value);
}
