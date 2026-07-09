import 'package:flutter/foundation.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/core/supabase_error_mapper.dart';
import 'package:vixrex/models/detected_product.dart';
import 'package:vixrex/models/ocr_catalog_result.dart';
import 'ocr_image_preprocessor.dart';
import 'ocr_text_parser.dart';
import 'ocr_price_parser.dart';
import 'ocr_product_matcher.dart';
import 'ocr_excel_verifier.dart';

/// Ana OCR servisi. Tüm OCR işlemlerini koordine eder.
class OcrService {
  final OcrTextParser _textParser;
  final OcrPriceParser _priceParser;
  final OcrImagePreprocessor _preprocessor;
  final OcrProductMatcher _matcher;

  const OcrService({
    OcrTextParser? textParser,
    OcrPriceParser? priceParser,
    OcrImagePreprocessor? preprocessor,
    OcrProductMatcher? matcher,
  })  : _textParser = textParser ?? const OcrTextParser(),
        _priceParser = priceParser ?? const OcrPriceParser(),
        _preprocessor = preprocessor ?? const OcrImagePreprocessor(),
        _matcher = matcher ?? const OcrProductMatcher(
          verifier: OcrExcelVerifier(),
        );

  /// Görüntüden ürün kataloğu oluşturur.
  Future<Result<OcrCatalogResult>> analyzeImage(Uint8List imageBytes, {String scanMode = 'receipt'}) async {
    try {
      // 1. OCR ile metni oku (preprocessing olmadan — test için)
      final textResult = await _textParser.parseFromImage(imageBytes, scanMode: scanMode);
      
      if (kDebugMode) {
        debugPrint('=== OCR RAW TEXT START ===');
        debugPrint(textResult.rawText);
        debugPrint('=== OCR RAW TEXT END ===');
        debugPrint('OCR Lines: ${textResult.lines.length}');
        for (final line in textResult.lines) {
          debugPrint('LINE [${line.lineIndex}]: "${line.text}"');
        }
      }

      // 2. Fiyatları çıkar
      final prices = _priceParser.extractPrices(textResult.rawText);
      
      if (kDebugMode) {
        debugPrint('Extracted prices: ${prices.length}');
        for (final p in prices) {
          debugPrint('PRICE: ${p.rawText} → ${p.amount}');
        }
      }

      // 3. Ürünleri eşleştir
      final products = await _matcher.matchProducts(textResult.lines, prices, scanMode: scanMode);
      
      if (kDebugMode) {
        debugPrint('Matched products: ${products.length}');
      }

      return Result.success(OcrCatalogResult(
        rawText: textResult.rawText,
        products: products,
        confidence: _calculateConfidence(products),
      ));
    } catch (e, s) {
      if (kDebugMode) debugPrint('OCR ERROR: $e');
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// Ürün adaylarını listele (kullanıcı seçimi için).
  Future<Result<List<DetectedProduct>>> extractProducts(Uint8List imageBytes, {String scanMode = 'receipt'}) async {
    try {
      final preprocessed = await _preprocessor.preprocess(imageBytes);
      final textResult = await _textParser.parseFromImage(preprocessed, scanMode: scanMode);
      final prices = _priceParser.extractPrices(textResult.rawText);
      final products = await _matcher.matchProducts(textResult.lines, prices, scanMode: scanMode);

      return Result.success(products);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// Güvenilirlik oranını hesapla.
  double _calculateConfidence(List<DetectedProduct> products) {
    if (products.isEmpty) return 0.0;
    double total = 0;
    for (final p in products) {
      total += p.confidence;
    }
    return total / products.length;
  }
}
