import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/ocr_text_result.dart';
import 'package:vixrex/models/ocr_token.dart';
import 'package:vixrex/services/ocr/invoice_row_parser.dart';

void main() {
  const parser = InvoiceRowParser();

  test('barkodsuz toptanci satirini urun uydurmadan ayirir', () {
    final result = OcrTextResult(
      rawText: '129 ERKEK ALT 5 AD 300,00 TL 1.500,00 TL',
      lines: const [],
      tokens: [
        _token('129', 10, 0),
        _token('ERKEK', 90, 1),
        _token('ALT', 160, 2),
        _token('5', 260, 3),
        _token('AD', 300, 4),
        _token('300,00', 380, 5),
        _token('TL', 450, 6),
        _token('1.500,00', 520, 7),
        _token('TL', 610, 8),
      ],
    );

    final product = parser.parse(result).single;

    expect(product.barcode, isNull);
    expect(product.sku, '129');
    expect(product.name, 'ERKEK ALT');
    expect(product.documentQuantity, 5);
    expect(product.purchaseUnitPrice, 300);
    expect(product.lineTotal, 1500);
    expect(product.issues, isNot(contains('INVALID_BARCODE_CHECK_DIGIT')));
  });
}

OcrToken _token(String text, double x, int element) => OcrToken(
  text: text,
  boundingBox: Rect.fromLTWH(x, 20, 60, 18),
  blockIndex: 0,
  lineIndex: 0,
  elementIndex: element,
);
