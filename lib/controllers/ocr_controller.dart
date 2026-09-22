import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:vixrex/models/detected_product.dart';
import 'package:vixrex/models/ocr_catalog_result.dart';
import 'package:vixrex/models/product_rich_data.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/services/ocr/invoice_row_parser.dart';
import 'package:vixrex/services/ocr/ocr_service.dart';
import 'package:vixrex/services/ocr/ocr_feedback_service.dart';
import 'package:vixrex/services/product_conversation_logger.dart';
import 'store_editor_controller.dart';

/// OCR state yönetimi controller'ı.
class OcrController extends ChangeNotifier {
  final OcrService _ocrService;
  final StoreEditorController? _editorController;

  OcrCatalogResult? _result;
  bool _isProcessing = false;
  String? _errorMessage;

  OcrController({
    required OcrService ocrService,
    StoreEditorController? editorController,
  }) : _ocrService = ocrService,
       _editorController = editorController;

  String _scanMode = 'receipt';
  String get scanMode => _scanMode;

  set scanMode(String mode) {
    if (_scanMode == mode) return;
    _scanMode = mode;
    notifyListeners();
  }

  OcrCatalogResult? get result => _result;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  bool get hasResult => _result != null;

  /// Görüntüyü analiz et.
  Future<void> analyzeImage(Uint8List imageBytes) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _ocrService.analyzeImage(
      imageBytes,
      scanMode: _scanMode,
    );

    result.when(
      success: (catalog) {
        _result = catalog;
        _isProcessing = false;
        notifyListeners();
      },
      failure: (failure) {
        _errorMessage = failure.message;
        _isProcessing = false;
        notifyListeners();
      },
    );
  }

  /// Ürünü onayla.
  void approveProduct(int index) {
    if (_result == null) return;
    if (index < 0 || index >= _result!.products.length) return;
    _result!.products[index].isApproved = true;
    notifyListeners();
  }

  /// Ürünü reddet.
  void rejectProduct(int index) {
    if (_result == null) return;
    if (index < 0 || index >= _result!.products.length) return;
    _result!.products[index].isApproved = false;
    notifyListeners();
  }

  /// Ürünü düzenle.
  void updateProduct(int index, DetectedProduct updated) {
    if (_result == null) return;
    if (index < 0 || index >= _result!.products.length) return;
    if (updated.isInvoiceSource) {
      updated.issues = InvoiceRowParser.validateProduct(updated);
    }
    _result!.products[index] = updated;
    notifyListeners();
  }

  /// Tümünü onayla.
  ///
  /// Faturada doğrulama sorunu olan satırlar toplu onaya dahil edilmez;
  /// esnaf o satırı ayrıca kontrol eder.
  void approveAll() {
    if (_result == null) return;
    for (final product in _result!.products) {
      product.isApproved = !product.isInvoiceSource || product.issues.isEmpty;
    }
    notifyListeners();
  }

  /// Tümünü reddet.
  void rejectAll() {
    if (_result == null) return;
    for (final product in _result!.products) {
      product.isApproved = false;
    }
    notifyListeners();
  }

  /// Onaylanan ürünleri kaydet.
  Future<void> saveApprovedProducts() async {
    final approved = _result?.approvedProducts;
    if (approved == null || approved.isEmpty) return;

    // Validation: boş isim veya negatif fiyat filtresi
    final validProducts =
        approved.where((p) {
          if (p.name.trim().isEmpty) return false;
          if (p.price != null && p.price! < 0) return false;
          return true;
        }).toList();

    if (validProducts.isEmpty) {
      _errorMessage =
          'Kaydedilecek geçerli ürün yok. Ürün adı boş veya fiyat geçersiz.';
      notifyListeners();
      return;
    }

    try {
      // 1. Düzeltilmiş feedback verilerini Supabase'e gönder (Active Learning Loop)
      final feedbackList =
          _result!.products
              .map(
                (p) => {
                  'name': p.name,
                  'price': p.price,
                  'is_approved': p.isApproved,
                  'confidence': p.confidence,
                },
              )
              .toList();

      final parsedList =
          _result!.products
              .map(
                (p) => {
                  'name': p.name,
                  'price': p.price,
                  'confidence': p.confidence,
                },
              )
              .toList();

      // Fatura metni firma/tedarikçi/ticari fiyat gibi özel bilgiler
      // içerebilir. Açık bir saklama politikası kurulana kadar fatura OCR
      // ham metni feedback veri setine yazılmaz.
      if (_scanMode != 'invoice') {
        await const OcrFeedbackService().saveFeedback(
          rawOcrText: _result!.rawText,
          parsedProducts: parsedList,
          correctedProducts: feedbackList,
          scanMode: _scanMode,
          imageHash: 'hash_${_result!.rawText.hashCode.abs()}',
        );
      }

      // 2. Ürünleri editör kontrolcüsüne ekle (uzak yazma başarısızsa yerelde yok)
      final editor = _editorController;
      if (editor == null) {
        _errorMessage =
            'Vitrin düzenleyici hazır değil. Ürünler kaydedilemedi.';
        notifyListeners();
        return;
      }

      var savedCount = 0;
      for (final product in validProducts) {
        final result = await editor.addProduct(_convertToProduct(product));
        if (result.isFailure) {
          final detail =
              result.failure?.message ?? 'Ürün müşteri vitrine yazılamadı.';
          _errorMessage =
              savedCount > 0
                  ? '$savedCount ürün kaydedildi, sonra hata: $detail'
                  : detail;
          notifyListeners();
          return;
        }
        product.isApproved = false;
        savedCount++;
      }
      _result = null;
      notifyListeners();
      // Faz 4: ortak konuşmaya log — Next.js sahip paneli 15sn poll ile görür
      unawaited(
        ProductConversationLogger.log(
          count: savedCount,
          source: 'ocr',
          scope: editor.publishedInfo?.publicLink,
          extra: _scanMode == 'shelf_label' ? 'raf/etiket' : 'fiş/fatura',
        ),
      );
    } catch (e) {
      _errorMessage = 'Ürünler kaydedilemedi: $e';
      notifyListeners();
    }
  }

  /// DetectedProduct'ı Product'a çevir.
  ///
  /// Fatura alış fiyatı müşteriye gösterilecek satış fiyatı DEĞİLDİR.
  /// Bu nedenle purchaseUnitPrice burada Product.price alanına asla yazılmaz.
  Product _convertToProduct(DetectedProduct detected) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = (timestamp * 7 + detected.name.hashCode).abs();
    final id = 'ocr_${timestamp}_$random';

    final options = <String, String>{};
    final variant = detected.variant?.trim();
    final size = detected.size?.trim();
    if (variant != null && variant.isNotEmpty) options['color'] = variant;
    if (size != null && size.isNotEmpty) options['size'] = size;

    final variants =
        options.isEmpty
            ? <ProductVariantData>[]
            : <ProductVariantData>[
              ProductVariantData(
                id: '$id-variant-1',
                options: options,
                sku: detected.sku,
                barcode: detected.barcode,
                priceAmount: detected.price,
                stockQuantity:
                    detected.isInvoiceSource
                        ? detected.documentQuantity
                        : detected.quantity,
                stockStatus: StockStatus.available.label,
              ),
            ];

    return Product(
      id: id,
      name: detected.name,
      // Yalnız esnafın girdiği/var olan satış fiyatı kullanılır.
      price: detected.price?.toStringAsFixed(2) ?? '',
      description: detected.description ?? '',
      category: detected.category,
      stockStatus: StockStatus.available.label,
      // Faturadan gelen ürün doğrudan müşteriye açılmaz; önce esnaf satış
      // fiyatını ve şüpheli alanları kontrol eder.
      isVisible: !detected.isInvoiceSource,
      source: detected.source,
      barcode: detected.barcode,
      sku: detected.sku,
      stockQuantity:
          detected.isInvoiceSource
              ? detected.documentQuantity
              : detected.quantity,
      variants: variants,
    );
  }

  /// Sonucu temizle.
  void clearResult() {
    _result = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Hata mesajını temizle.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
