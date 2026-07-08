import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/ocr/ocr_service.dart';
import 'package:vixrex/services/ocr/ocr_text_parser.dart';
import 'package:vixrex/services/ocr/ocr_price_parser.dart';
import 'package:vixrex/services/ocr/ocr_image_preprocessor.dart';
import 'package:vixrex/services/ocr/ocr_product_matcher.dart';
import 'package:vixrex/services/ocr/ocr_excel_verifier.dart';

void main() {
  group('OcrService', () {
    late OcrService service;

    setUp(() {
      service = const OcrService(
        textParser: OcrTextParser(),
        priceParser: OcrPriceParser(),
        preprocessor: OcrImagePreprocessor(),
        matcher: OcrProductMatcher(
          verifier: OcrExcelVerifier(),
        ),
      );
    });

    test('OcrService olusturulabilir', () {
      expect(service, isNotNull);
    });

    test('OcrService parametresiz olusturulabilir', () {
      final defaultService = const OcrService();
      expect(defaultService, isNotNull);
    });
  });

  group('OcrImagePreprocessor', () {
    const preprocessor = OcrImagePreprocessor();

    test('Preprocessor olusturulabilir', () {
      expect(preprocessor, isNotNull);
    });
  });

  group('OcrTextParser', () {
    const parser = OcrTextParser();

    test('Bos metin icin bos aday listesi doner', () {
      final candidates = parser.extractProductCandidates('');
      expect(candidates.isEmpty, true);
    });

    test('Kisa metinleri atlar', () {
      final candidates = parser.extractProductCandidates('ab');
      expect(candidates.isEmpty, true);
    });

    test('Gurultu kelimelerini filtreler', () {
      final candidates = parser.extractProductCandidates('Kargo bedava');
      expect(candidates.isEmpty, true);
    });

    test('Gecerli urun adaylarini bulur', () {
      final candidates = parser.extractProductCandidates('Uker Cikolata 80g');
      expect(candidates.isNotEmpty, true);
    });
  });
}
