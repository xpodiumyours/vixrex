// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/ocr_line.dart';
import 'package:vixrex/services/ocr/ocr_price_parser.dart';
import 'package:vixrex/services/ocr/ocr_product_matcher.dart';
import 'package:vixrex/services/ocr/ocr_excel_verifier.dart';

class MockOcrExcelVerifier extends OcrExcelVerifier {
  const MockOcrExcelVerifier() : super(client: null);

  @override
  Future<ProductMatch?> findBestMatch(String normalized, {double threshold = 0.7}) async {
    return null; // Çevrimdışı testlerde DB'yi mock'la
  }
}

void main() {
  group('OCR Bootstrap Trainer', () {
    late OcrPriceParser priceParser;
    late OcrProductMatcher productMatcher;
    late Map<String, dynamic> seedData;

    setUpAll(() {
      priceParser = const OcrPriceParser();
      productMatcher = const OcrProductMatcher(
        verifier: MockOcrExcelVerifier(),
      );

      // JSON veri setini oku
      final file = File('test/ocr/bootstrap_seed_data.json');
      seedData = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    test('Önyükleme Doğruluk Skoru Hesaplama (Hedef: >= %95)', () async {
      final cases = seedData['test_cases'] as List<dynamic>;
      int totalExpected = 0;
      int totalMatched = 0;

      print('\n================== OCR BOOTSTRAP TRAINING REPORT ==================');

      for (final testCase in cases) {
        final id = testCase['id'] as String;
        final scanMode = testCase['scan_mode'] as String;
        final rawText = testCase['raw_text'] as String;
        final expectedList = testCase['expected_products'] as List<dynamic>;

        // 1. Ham metni satırlara ayır ve OcrLine listesi oluştur
        final rawLines = rawText.split('\n');
        final lines = <OcrLine>[];
        for (var i = 0; i < rawLines.length; i++) {
          final text = rawLines[i].trim();
          if (text.isEmpty) continue;
          
          // Basit blok atama: Fişte hepsi tek blok, rafta her etiket satırı ayrı blockIndex veya hepsi tek block
          lines.add(OcrLine(
            text: text,
            boundingBox: Rect.fromLTWH(10, i * 30.0, 300, 20),
            blockIndex: scanMode == 'shelf_label' ? i ~/ 3 : 0, // Raf modunda 3 satırda bir blok değişimi simülasyonu
            lineIndex: i,
          ));
        }

        // 2. Fiyatları çıkar
        final prices = priceParser.extractPrices(rawText);
        print('Extracted prices for $id:');
        for (final p in prices) {
          print('  - Raw: "${p.rawText}", Amount: ${p.amount}, LineNumber: ${p.lineNumber}');
        }

        // 3. Eşleştiriciyi çalıştır
        final detected = await productMatcher.matchProducts(lines, prices, scanMode: scanMode);

        // 4. Doğruluğu hesapla
        int caseMatched = 0;
        print('\n--- Case: $id ---');
        print('Detected products:');
        for (final p in detected) {
          print('  - Name: "${p.name}", Price: ${p.price}, Source: ${p.source}');
        }
        print('Expected products:');
        for (final expected in expectedList) {
          final expName = expected['name'] as String;
          final expPrice = (expected['price'] as num).toDouble();
          print('  - Name: "$expName", Price: $expPrice');

          totalExpected++;

          final hasMatch = detected.any((p) {
            final nameMatches = p.name.toLowerCase().contains(expName.toLowerCase()) || 
                                expName.toLowerCase().contains(p.name.toLowerCase());
            final priceMatches = p.price != null && (p.price! - expPrice).abs() < 0.01;
            return nameMatches && priceMatches;
          });

          if (hasMatch) {
            caseMatched++;
            totalMatched++;
            print('    => MATCHED!');
          } else {
            print('    => FAILED TO MATCH');
          }
        }

        final caseAccuracy = expectedList.isNotEmpty 
            ? (caseMatched / expectedList.length * 100).toStringAsFixed(1)
            : '100';
        print('Accuracy: %$caseAccuracy');
      }

      final overallAccuracy = (totalMatched / totalExpected) * 100;
      print('------------------------------------------------------------------');
      print('GENEL DOĞRULUK SKORU: %${overallAccuracy.toStringAsFixed(2)} ($totalMatched/$totalExpected)');
      print('==================================================================\n');

      // Doğruluk eşiği kontrolü
      expect(overallAccuracy, greaterThanOrEqualTo(95.0), 
        reason: 'OCR doğruluk oranı %95\'in altında kaldı! Lütfen parser kurallarını iyileştirin.');
    });
  });
}
