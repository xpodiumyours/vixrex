import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/ocr_line.dart';
import 'package:vixrex/models/ocr_price.dart';
import 'package:vixrex/services/ocr/ocr_product_matcher.dart';
import 'package:vixrex/services/ocr/ocr_excel_verifier.dart';

class MockOcrExcelVerifier extends OcrExcelVerifier {
  const MockOcrExcelVerifier() : super(client: null);

  @override
  Future<ProductMatch?> findBestMatch(
    String normalized, {
    double threshold = 0.7,
  }) async {
    return null; // Test veritabanı bağımlılığını kes
  }
}

void main() {
  group('OcrProductMatcher', () {
    late OcrProductMatcher matcher;

    setUp(() {
      matcher = const OcrProductMatcher();
    });

    group('matchProducts', () {
      test('Bos satir listesi icin bos sonuc doner', () async {
        final result = await matcher.matchProducts([], []);
        expect(result.isEmpty, true);
      });

      test('Fis Modu: Fiyatı en yakın ust satırla eslestirir', () async {
        final lines = [
          OcrLine(
            text: 'Dankek Lokmalik Hindistan Cevizi',
            boundingBox: const Rect.fromLTRB(10, 10, 200, 30),
            blockIndex: 0,
            lineIndex: 0,
          ),
          OcrLine(
            text: '55.00 TL',
            boundingBox: const Rect.fromLTRB(10, 40, 100, 60),
            blockIndex: 0,
            lineIndex: 1,
          ),
        ];

        final prices = [
          OcrPrice(
            rawText: '55.00 TL',
            amount: 55.0,
            lineNumber: 1,
            blockIndex: 0,
          ),
        ];

        final result = await matcher.matchProducts(
          lines,
          prices,
          scanMode: 'receipt',
        );
        expect(result.length, 1);
        expect(result.first.name.toUpperCase(), contains('DANKEK'));
        expect(result.first.price, 55.0);
        expect(result.first.source, 'ocr_fuzzy_matched');
      });

      test('Raf Modu: Ayni bloktaki satirlari eslestirir', () async {
        final lines = [
          OcrLine(
            text: 'Biscolata Mood 110g',
            boundingBox: const Rect.fromLTRB(10, 10, 200, 30),
            blockIndex: 1,
            lineIndex: 0,
          ),
          OcrLine(
            text: '54.99 TL',
            boundingBox: const Rect.fromLTRB(10, 40, 100, 60),
            blockIndex: 1,
            lineIndex: 1,
          ),
        ];

        final prices = [
          OcrPrice(
            rawText: '54.99 TL',
            amount: 54.99,
            lineNumber: 1,
            blockIndex: 1,
          ),
        ];

        final result = await matcher.matchProducts(
          lines,
          prices,
          scanMode: 'shelf_label',
        );
        expect(result.length, 1);
        expect(result.first.name.toUpperCase(), contains('BİSCOLATA'));
        expect(result.first.price, 54.99);
        expect(result.first.source, 'ocr_fuzzy_matched');
      });

      test('Gurultu satirlarini atlar', () async {
        final lines = [
          OcrLine(
            text: 'Kargo bedava',
            boundingBox: const Rect.fromLTRB(0, 0, 100, 20),
            blockIndex: 0,
            lineIndex: 0,
          ),
          OcrLine(
            text: 'Indirim %50',
            boundingBox: const Rect.fromLTRB(0, 30, 100, 50),
            blockIndex: 0,
            lineIndex: 1,
          ),
        ];
        final result = await matcher.matchProducts(
          lines,
          [],
          scanMode: 'receipt',
        );
        expect(result.isEmpty, true);
      });

      // **Yeni: Fatura modu testleri**
      test('Fatura modu: KDV oranlari ile urun eslestirme', () async {
        final lines = [
          OcrLine(
            text: 'MERCİ ÇIKOLATALI BISCUIT',
            boundingBox: const Rect.fromLTRB(10, 10, 200, 30),
            blockIndex: 0,
            lineIndex: 0,
          ),
          OcrLine(
            text: 'KDV %8',
            boundingBox: const Rect.fromLTRB(10, 50, 150, 70),
            blockIndex: 0,
            lineIndex: 1,
          ),
          OcrLine(
            text: '8.50 TL',
            boundingBox: const Rect.fromLTRB(10, 80, 100, 100),
            blockIndex: 0,
            lineIndex: 2,
          ),
        ];

        final prices = [
          OcrPrice(
            rawText: '8.50 TL',
            amount: 8.5,
            lineNumber: 2,
            blockIndex: 0,
          ),
        ];

        final result = await matcher.matchProducts(
          lines,
          prices,
          scanMode: 'invoice',
        );
        expect(result.length, 1);
        expect(result.first.name.toUpperCase(), contains('MERCİ'));
        expect(result.first.price, 8.5);
      });

      test('Fatura modu: KDV %10 ile urun eslestirme', () async {
        final lines = [
          OcrLine(
            text: 'SÜTAŞ TAM YAĞLI SÜT 1L',
            boundingBox: const Rect.fromLTRB(10, 10, 200, 30),
            blockIndex: 0,
            lineIndex: 0,
          ),
          OcrLine(
            text: 'KDV %10',
            boundingBox: const Rect.fromLTRB(10, 50, 150, 70),
            blockIndex: 0,
            lineIndex: 1,
          ),
          OcrLine(
            text: '15.00 TL',
            boundingBox: const Rect.fromLTRB(10, 80, 100, 100),
            blockIndex: 0,
            lineIndex: 2,
          ),
        ];

        final prices = [
          OcrPrice(
            rawText: '15.00 TL',
            amount: 15.0,
            lineNumber: 2,
            blockIndex: 0,
          ),
        ];

        final result = await matcher.matchProducts(
          lines,
          prices,
          scanMode: 'invoice',
        );
        expect(result.length, 1);
        expect(result.first.name.toUpperCase(), contains('SÜTAŞ'));
        expect(result.first.price, 15.0);
      });

      test('Fatura modu: Net tutar ve toplami atla', () async {
        final lines = [
          OcrLine(
            text: 'NET TUTAR',
            boundingBox: const Rect.fromLTRB(0, 0, 200, 30),
            blockIndex: 0,
            lineIndex: 0,
          ),
          OcrLine(
            text: 'GENEL TOPLAM: 120.00 TL',
            boundingBox: const Rect.fromLTRB(0, 40, 200, 70),
            blockIndex: 0,
            lineIndex: 1,
          ),
          OcrLine(
            text: '120.00 TL',
            boundingBox: const Rect.fromLTRB(0, 80, 200, 100),
            blockIndex: 0,
            lineIndex: 2,
          ),
        ];
        final result = await matcher.matchProducts(
          lines,
          [],
          scanMode: 'invoice',
        );
        expect(result.isEmpty, true);
      });
    });
  });
}
