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
    return null;
  }
}

void main() {
  group('OCR Parameter Auto-Tuner (Grid Search)', () {
    late OcrPriceParser priceParser;
    late List<dynamic> seedData;

    setUpAll(() {
      priceParser = const OcrPriceParser();
      final file = File('test/ocr/bootstrap_seed_data.json');
      seedData = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    });

    test('Grid Search ve En İyi Parametrelerin Bulunması', () async {
      int bestVertical = 5;
      double bestHorizontal = 300;
      double bestAccuracy = 0.0;

      print('\n================== STARTING GRID SEARCH ==================');
      print('VerticalDiff | HorizontalCenterDiff | Accuracy %');
      print('---------------------------------------------------------');

      for (int vDiff = 2; vDiff <= 8; vDiff++) {
        for (double hDiff = 100; hDiff <= 450; hDiff += 50) {
          final matcher = OcrProductMatcher(
            verifier: const MockOcrExcelVerifier(),
            maxVerticalDiff: vDiff,
            maxHorizontalCenterDiff: hDiff,
          );

          int totalExpected = 0;
          int totalMatched = 0;

          for (final testCase in seedData) {
            final testCaseMap = testCase as Map<String, dynamic>;
            final id = testCaseMap['id'] as String;
            final scanMode = id.contains('reyon') || id.contains('etiket') ? 'shelf_label' : 'receipt';
            final rawText = testCaseMap['rawText'] as String;
            final expectedList = testCaseMap['expected'] as List<dynamic>;

            final rawLines = rawText.split('\n');
            final lines = <OcrLine>[];
            for (var i = 0; i < rawLines.length; i++) {
              final text = rawLines[i].trim();
              if (text.isEmpty) continue;
              
              lines.add(OcrLine(
                text: text,
                boundingBox: Rect.fromLTWH(10, i * 30.0, 300, 20),
                blockIndex: scanMode == 'shelf_label' ? i ~/ 4 : 0,
                lineIndex: i,
              ));
            }

            final prices = priceParser.extractPrices(rawText);
            final detected = await matcher.matchProducts(lines, prices, scanMode: scanMode);

            for (final expected in expectedList) {
              final exp = expected as Map<String, dynamic>;
              final expName = exp['name'] as String;
              final expPrice = (exp['unitPrice'] as num?)?.toDouble();
              if (expPrice == null) continue;
              totalExpected++;

              final hasMatch = detected.any((p) {
                final nameMatches = p.name.toLowerCase().contains(expName.toLowerCase()) || 
                                    expName.toLowerCase().contains(p.name.toLowerCase()) ||
                                    _fuzzyMatch(p.name, expName, 0.55) > 0.0;
                final priceMatches = p.price != null && (p.price! - expPrice).abs() < 0.01;
                return nameMatches && priceMatches;
              });

              if (hasMatch) {
                totalMatched++;
              } else {
                if (vDiff == 5 && hDiff == 300) {
                  print('      [UNMATCHED] Expected: "$expName" with price $expPrice. Detected products:');
                  for (final p in detected) {
                    print('        - Name: "${p.name}", Price: ${p.price}');
                  }
                }
              }
            }
          }

          final accuracy = totalExpected > 0 ? (totalMatched / totalExpected) * 100 : 0.0;
          print('${vDiff.toString().padRight(12)} | ${hDiff.toString().padRight(20)} | %${accuracy.toStringAsFixed(2)}');

          if (accuracy > bestAccuracy) {
            bestAccuracy = accuracy;
            bestVertical = vDiff;
            bestHorizontal = hDiff;
          }
        }
      }

      print('---------------------------------------------------------');
      print('EN İYİ PARAMETRELER:');
      print('  - maxVerticalDiff: $bestVertical');
      print('  - maxHorizontalCenterDiff: $bestHorizontal');
      print('  - En Yüksek Doğruluk Oranı: %${bestAccuracy.toStringAsFixed(2)}');
      print('=========================================================\n');

      expect(bestAccuracy, greaterThanOrEqualTo(95.0), 
        reason: 'En iyi parametre kombinasyonu bile %95 doğruluğun altında kaldı!');
    });
  });
}

double _fuzzyMatch(String a, String b, double threshold) {
  if (a.isEmpty || b.isEmpty) return 0.0;

  final shorter = a.toLowerCase();
  final longer = b.toLowerCase();

  int matches = 0;
  for (int i = 0; i < shorter.length; i++) {
    if (longer.contains(shorter[i])) matches++;
  }

  final ratio = matches / longer.length;
  return ratio >= threshold ? ratio : 0.0;
}
