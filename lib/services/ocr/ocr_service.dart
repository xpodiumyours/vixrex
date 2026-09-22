import 'package:flutter/foundation.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/core/supabase_error_mapper.dart';
import 'package:vixrex/models/detected_product.dart';
import 'package:vixrex/models/ocr_catalog_result.dart';
import 'package:vixrex/models/ocr_line.dart';
import 'invoice_row_parser.dart';
import 'ocr_image_preprocessor.dart';
import 'ocr_price_parser.dart';
import 'ocr_product_matcher.dart';
import 'ocr_text_parser.dart';

/// Ana OCR servisi. Tüm OCR işlemlerini koordine eder.
class OcrService {
  final OcrTextParser _textParser;
  final OcrPriceParser _priceParser;
  final OcrImagePreprocessor _preprocessor;
  final OcrProductMatcher _matcher;
  final InvoiceRowParser _invoiceRowParser;

  const OcrService({
    OcrTextParser? textParser,
    OcrPriceParser? priceParser,
    OcrImagePreprocessor? preprocessor,
    OcrProductMatcher? matcher,
    InvoiceRowParser? invoiceRowParser,
  }) : _textParser = textParser ?? const OcrTextParser(),
       _priceParser = priceParser ?? const OcrPriceParser(),
       _preprocessor = preprocessor ?? const OcrImagePreprocessor(),
       _matcher = matcher ?? const OcrProductMatcher(),
       _invoiceRowParser = invoiceRowParser ?? const InvoiceRowParser();

  /// Görüntüden ürün kataloğu oluşturur.
  Future<Result<OcrCatalogResult>> analyzeImage(
    Uint8List imageBytes, {
    String scanMode = 'receipt',
  }) async {
    try {
      if (scanMode == 'invoice') {
        return await _analyzeInvoice(imageBytes);
      }

      final textResult = await _textParser.parseFromImage(
        imageBytes,
        scanMode: scanMode,
      );

      if (kDebugMode) {
        _debugTextResult(textResult.rawText, textResult.lines);
      }

      final prices = _priceParser.extractPrices(textResult.rawText);

      if (kDebugMode) {
        debugPrint('Extracted prices: ${prices.length}');
        for (final price in prices) {
          debugPrint('PRICE: ${price.rawText} → ${price.amount}');
        }
      }

      final products = await _matcher.matchProducts(
        textResult.lines,
        prices,
        scanMode: scanMode,
      );

      if (kDebugMode) {
        debugPrint('Matched products: ${products.length}');
      }

      return Result.success(
        OcrCatalogResult(
          rawText: textResult.rawText,
          products: products,
          confidence: _calculateConfidence(products),
        ),
      );
    } catch (e, s) {
      if (kDebugMode) debugPrint('OCR ERROR: $e');
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  Future<Result<OcrCatalogResult>> _analyzeInvoice(Uint8List imageBytes) async {
    // Yerel ve ücretsiz yol: önce görüntüyü okunaklı hale getir, ardından
    // cihazdaki ML Kit ile kelime konumlarını çıkar.
    final preprocessed = await _preprocessor.preprocess(imageBytes);

    var best = await _invoiceAttempt(preprocessed);

    // Fotoğrafın piksel ölçüsü yönü söylemez; kullanıcı telefonu yan tutmuş
    // olabilir. İlk okuma zayıfsa iki dik yönü de cihazda deneriz.
    if (!_isStrongInvoiceAttempt(best)) {
      final clockwise = await _preprocessor.rotateClockwise90(preprocessed);
      final clockwiseAttempt = await _invoiceAttempt(clockwise);
      if (_invoiceAttemptScore(clockwiseAttempt) > _invoiceAttemptScore(best)) {
        best = clockwiseAttempt;
      }

      final counterClockwise = await _preprocessor.rotateCounterClockwise90(
        preprocessed,
      );
      final counterAttempt = await _invoiceAttempt(counterClockwise);
      if (_invoiceAttemptScore(counterAttempt) > _invoiceAttemptScore(best)) {
        best = counterAttempt;
      }
    }

    if (kDebugMode) {
      _debugTextResult(best.rawText, best.lines);
      debugPrint('Invoice products: ${best.products.length}');
    }

    return Result.success(
      OcrCatalogResult(
        rawText: best.rawText,
        products: best.products,
        confidence: best.confidence,
      ),
    );
  }

  Future<_InvoiceAttempt> _invoiceAttempt(Uint8List imageBytes) async {
    final textResult = await _textParser.parseFromImage(
      imageBytes,
      scanMode: 'invoice',
    );
    final products = _invoiceRowParser.parse(textResult);
    return _InvoiceAttempt(
      rawText: textResult.rawText,
      lines: textResult.lines,
      products: products,
      confidence: _calculateConfidence(products),
    );
  }

  bool _isStrongInvoiceAttempt(_InvoiceAttempt attempt) {
    if (attempt.products.isEmpty) return false;
    if (attempt.products.length >= 3 && attempt.confidence >= 0.72) return true;
    return attempt.products.isNotEmpty && attempt.confidence >= 0.88;
  }

  double _invoiceAttemptScore(_InvoiceAttempt attempt) {
    final validRows =
        attempt.products.where((product) => product.issues.isEmpty).length;
    return attempt.products.length * 10 + validRows * 3 + attempt.confidence;
  }

  /// Ürün adaylarını listele (kullanıcı seçimi için).
  Future<Result<List<DetectedProduct>>> extractProducts(
    Uint8List imageBytes, {
    String scanMode = 'receipt',
  }) async {
    try {
      if (scanMode == 'invoice') {
        final catalog = await _analyzeInvoice(imageBytes);
        if (catalog.isFailure) {
          return Result.failure(catalog.failure!);
        }
        return Result.success(catalog.data!.products);
      }

      final preprocessed = await _preprocessor.preprocess(imageBytes);
      final textResult = await _textParser.parseFromImage(
        preprocessed,
        scanMode: scanMode,
      );
      final prices = _priceParser.extractPrices(textResult.rawText);
      final products = await _matcher.matchProducts(
        textResult.lines,
        prices,
        scanMode: scanMode,
      );

      return Result.success(products);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  void _debugTextResult(String rawText, List<OcrLine> lines) {
    debugPrint('=== OCR RAW TEXT START ===');
    debugPrint(rawText);
    debugPrint('=== OCR RAW TEXT END ===');
    debugPrint('OCR Lines: ${lines.length}');
    for (final line in lines) {
      debugPrint('LINE [${line.lineIndex}]: "${line.text}"');
    }
  }

  /// Güvenilirlik oranını hesapla.
  double _calculateConfidence(List<DetectedProduct> products) {
    if (products.isEmpty) return 0.0;
    var total = 0.0;
    for (final product in products) {
      total += product.confidence;
    }
    return total / products.length;
  }
}

class _InvoiceAttempt {
  final String rawText;
  final List<OcrLine> lines;
  final List<DetectedProduct> products;
  final double confidence;

  const _InvoiceAttempt({
    required this.rawText,
    required this.lines,
    required this.products,
    required this.confidence,
  });
}
