// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/ocr/ocr_price_parser.dart';
import 'package:vixrex/services/ocr/ocr_text_parser.dart';

/// OCR Önyükleme Eğitim Betiği
///
/// Bu betik, seed verileri üzerinden parser'ı koşturarak
/// doğruluk yüzdesini hesaplar ve raporlar.
void main() {
  final priceParser = OcrPriceParser();
  final textParser = OcrTextParser();

  late List<dynamic> seedData;

  setUpAll(() async {
    final file = File('test/ocr/bootstrap_seed_data.json');
    final contents = await file.readAsString();
    seedData = jsonDecode(contents) as List<dynamic>;
  });

  group('OCR Bootstrap Training', () {
    test('Seed verileri başarıyla yükleniyor', () {
      expect(seedData, isNotEmpty);
      expect(seedData.length, 5);
    });

    test('Her seed vakası için fiyat çıkarma çalışıyor', () {
      int totalProducts = 0;
      int correctlyParsedPrices = 0;

      for (final seed in seedData) {
        final rawText = seed['rawText'] as String;
        final expected = seed['expected'] as List<dynamic>;

        // Fiyatları çıkar
        final prices = priceParser.extractPrices(rawText);

        totalProducts += expected.length;

        // Her beklenen ürün için fiyat bulunup bulunmadığını kontrol et
        for (final exp in expected) {
          final expectedPrice = exp['unitPrice'] as double?;
          if (expectedPrice == null) continue;

          // Çıkarılan fiyatlar arasında eşleşme ara
          final found = prices.any((p) =>
              (p.amount - expectedPrice).abs() < 0.01 ||
              (p.amount - (expectedPrice * (exp['quantity'] as int? ?? 1))).abs() < 0.01);

          if (found) correctlyParsedPrices++;
        }

        // Seed ID'sini raporla
        print('  [${seed['id']}] Fiyatlar: ${prices.length} bulundu, '
            'Beklenen: ${expected.length} ürün');
      }

      final accuracy = totalProducts > 0 ? (correctlyParsedPrices / totalProducts * 100) : 0.0;
      print('');
      print('=== FIYAT ÇIKARMA DOĞRULUĞU ===');
      print('Toplam ürün: $totalProducts');
      print('Doğru fiyat: $correctlyParsedPrices');
      print('Doğruluk: %${accuracy.toStringAsFixed(1)}');
      print('');

      // En az %50 fiyat bulunmalı (başlangıç eşiği)
      expect(accuracy, greaterThanOrEqualTo(50.0),
          reason: 'Fiyat çıkarma doğruluğu %50\'nin altında');
    });

    test('Her seed vakası için ürün adı çıkarma çalışıyor', () {
      int totalExpected = 0;
      int correctlyParsedNames = 0;

      for (final seed in seedData) {
        final rawText = seed['rawText'] as String;
        final expected = seed['expected'] as List<dynamic>;

        // Metin adaylarını çıkar
        final candidates = textParser.extractProductCandidates(rawText);

        totalExpected += expected.length;

        // Her beklenen ürün için adaylar arasında eşleşme ara
        for (final exp in expected) {
          final expectedName = (exp['name'] as String?)?.toUpperCase() ?? '';
          if (expectedName.isEmpty) continue;

          final found = candidates.any((c) {
            final normalized = c.toUpperCase();
            // Kısmi eşleşme: beklenen isim adayların içinde geçiyor mu?
            return normalized.contains(expectedName) ||
                expectedName.contains(normalized) ||
                _fuzzyMatch(normalized, expectedName, 0.6) > 0.0;
          });

          if (found) correctlyParsedNames++;
        }

        print('  [${seed['id']}] Adaylar: ${candidates.length}, '
            'Beklenen: ${expected.length} ürün');
      }

      final accuracy = totalExpected > 0 ? (correctlyParsedNames / totalExpected * 100) : 0.0;
      print('');
      print('=== ÜRÜN ADI ÇIKARMA DOĞRULUĞU ===');
      print('Toplam ürün: $totalExpected');
      print('Doğru isim: $correctlyParsedNames');
      print('Doğruluk: %${accuracy.toStringAsFixed(1)}');
      print('');

      // En az %30 ürün ismi bulunmalı (başlangıç eşiği)
      expect(accuracy, greaterThanOrEqualTo(30.0),
          reason: 'Ürün adı çıkarma doğruluğu %30\'un altında');
    });

    test('Genel doğruluk raporu', () {
      int totalChecks = 0;
      int passedChecks = 0;

      for (final seed in seedData) {
        final rawText = seed['rawText'] as String;
        final expected = seed['expected'] as List<dynamic>;
        final expectedTotal = seed['expectedTotal'] as Map<String, dynamic>?;

        // Fiyat kontrolü
        final prices = priceParser.extractPrices(rawText);
        for (final exp in expected) {
          totalChecks++;
          final expectedPrice = exp['unitPrice'] as double?;
          if (expectedPrice != null) {
            final found = prices.any((p) =>
                (p.amount - expectedPrice).abs() < 0.01 ||
                (p.amount - (expectedPrice * (exp['quantity'] as int? ?? 1))).abs() < 0.01);
            if (found) passedChecks++;
          }
        }

        // Toplam kontrolü (eğer beklenen toplam varsa)
        if (expectedTotal != null && expectedTotal.containsKey('grandTotal')) {
          totalChecks++;
          final grandTotal = expectedTotal['grandTotal'] as double;
          final found = prices.any((p) => (p.amount - grandTotal).abs() < 1.0);
          if (found) passedChecks++;
        }
      }

      final accuracy = totalChecks > 0 ? (passedChecks / totalChecks * 100) : 0.0;

      print('');
      print('╔══════════════════════════════════════╗');
      print('║     OCR BOOTLET RAPORU              ║');
      print('╠══════════════════════════════════════╣');
      print('║ Seed vakası: ${seedData.length}                       ║');
      print('║ Toplam kontrol: $totalChecks                     ║');
      print('║ Geçen: $passedChecks                           ║');
      print('║ Doğruluk: %${accuracy.toStringAsFixed(1)}                  ║');
      print('║ Hedef: %95                          ║');
      print('║ Durum: ${accuracy >= 95 ? "✅ HAZIR" : "⚠️ İYİLEŞTİRME GEREKLİ"}          ║');
      print('╚══════════════════════════════════════╝');
      print('');

      // Bu test her zaman geçmeli (sadece rapor üretir)
      expect(totalChecks, greaterThan(0));
    });
  });
}

/// Basit fuzzy eşleşme: iki string arasındaki benzerlik oranını hesaplar.
double _fuzzyMatch(String a, String b, double threshold) {
  if (a.isEmpty || b.isEmpty) return 0.0;

  final shorter = a.length < b.length ? a : b;
  final longer = a.length < b.length ? b : a;

  int matches = 0;
  for (int i = 0; i < shorter.length; i++) {
    if (longer.contains(shorter[i])) matches++;
  }

  final ratio = matches / longer.length;
  return ratio >= threshold ? ratio : 0.0;
}
