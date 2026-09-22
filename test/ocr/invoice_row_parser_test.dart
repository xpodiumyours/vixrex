import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/ocr_text_result.dart';
import 'package:vixrex/models/ocr_token.dart';
import 'package:vixrex/services/ocr/invoice_row_parser.dart';

void main() {
  const parser = InvoiceRowParser();

  test(
    'fatura satırında görülen alanları ayırır ve alış fiyatını satış fiyatı yapmaz',
    () {
      final result = OcrTextResult(
        rawText:
            'ABC100 ORNEK PAMUKLU URUN 2900000000018 750 SIYAH L '
            '2 ad 137,00 TL 274,00 TL',
        lines: const [],
        tokens: [
          token('ABC100', 10, 0),
          token('ORNEK', 90, 1),
          token('PAMUKLU', 150, 2),
          token('URUN', 230, 3),
          token('2900000000018', 430, 4),
          token('750', 560, 5),
          token('SIYAH', 600, 6),
          token('L', 680, 7),
          token('2', 730, 8),
          token('ad', 755, 9),
          token('137,00', 810, 10),
          token('TL', 890, 11),
          token('274,00', 930, 12),
          token('TL', 1000, 13),
        ],
      );

      final products = parser.parse(result);

      expect(products, hasLength(1));
      final product = products.single;
      expect(product.sku, 'ABC100');
      expect(product.barcode, '2900000000018');
      expect(product.name, 'ORNEK PAMUKLU URUN');
      expect(product.variant, 'SIYAH');
      expect(product.size, 'L');
      expect(product.documentQuantity, 2);
      expect(product.purchaseUnitPrice, 137);
      expect(product.lineTotal, 274);
      expect(product.price, isNull);
      expect(product.issues, isEmpty);
    },
  );

  test('OCR model ve adı tek parçada birleştirse de ayırır', () {
    final result = OcrTextResult(
      rawText:
          'XYZ200___TEST_URUN 2900000000025 100 BEYAZ M 1 ad 50,00 TL 50,00 TL',
      lines: const [],
      tokens: [
        token('XYZ200___TEST_URUN', 10, 0, line: 1),
        token('2900000000025', 430, 1, line: 1),
        token('100', 560, 2, line: 1),
        token('BEYAZ', 600, 3, line: 1),
        token('M', 680, 4, line: 1),
        token('1', 730, 5, line: 1),
        token('ad', 755, 6, line: 1),
        token('50,00', 810, 7, line: 1),
        token('TL', 890, 8, line: 1),
        token('50,00', 930, 9, line: 1),
        token('TL', 1000, 10, line: 1),
      ],
    );

    final product = parser.parse(result).single;

    expect(product.sku, 'XYZ200');
    expect(product.name, 'TEST URUN');
  });

  test('okunamayan miktarı yalnız tam matematik eşleşmesinden çıkarır', () {
    final result = OcrTextResult(
      rawText:
          'DEF300 TEST URUN 2900000000032 750 LACIVERT 8-10 YAS xad '
          '81,00 TL 243,00 TL',
      lines: const [],
      tokens: [
        token('DEF300', 10, 0, line: 2),
        token('TEST', 90, 1, line: 2),
        token('URUN', 150, 2, line: 2),
        token('2900000000032', 430, 3, line: 2),
        token('750', 560, 4, line: 2),
        token('LACIVERT', 600, 5, line: 2),
        token('8-10', 680, 6, line: 2),
        token('YAS', 720, 7, line: 2),
        token('xad', 760, 8, line: 2),
        token('81,00', 810, 9, line: 2),
        token('TL', 890, 10, line: 2),
        token('243,00', 930, 11, line: 2),
        token('TL', 1000, 12, line: 2),
      ],
    );

    final product = parser.parse(result).single;

    expect(product.size, '8-10YAS');
    expect(product.documentQuantity, 3);
    expect(product.issues, isNot(contains('QUANTITY_MISSING')));
  });

  test('uyuşmayan satırda miktarı matematikten uydurmaz ve hatayı işaretler', () {
    final result = OcrTextResult(
      rawText:
          'GHI400 TEST URUN 2900000000049 750 SIYAH M 17 ad 63,50 TL 4079,50 TL',
      lines: const [],
      tokens: [
        token('GHI400', 10, 0, line: 3),
        token('TEST', 90, 1, line: 3),
        token('URUN', 150, 2, line: 3),
        token('2900000000049', 430, 3, line: 3),
        token('750', 560, 4, line: 3),
        token('SIYAH', 600, 5, line: 3),
        token('M', 680, 6, line: 3),
        token('17', 730, 7, line: 3),
        token('ad', 760, 8, line: 3),
        token('63,50', 810, 9, line: 3),
        token('TL', 890, 10, line: 3),
        token('4079,50', 930, 11, line: 3),
        token('TL', 1000, 12, line: 3),
      ],
    );

    final product = parser.parse(result).single;

    expect(product.documentQuantity, 17);
    expect(product.issues, contains('ARITHMETIC_MISMATCH'));
  });
}

OcrToken token(String text, double x, int element, {int line = 0}) {
  return OcrToken(
    text: text,
    boundingBox: Rect.fromLTWH(x, line * 30.0, 60, 18),
    blockIndex: 0,
    lineIndex: line,
    elementIndex: element,
  );
}
