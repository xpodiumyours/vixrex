import 'package:flutter/foundation.dart';
import 'package:vixrex/models/detected_product.dart';
import 'package:vixrex/models/ocr_catalog_result.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/services/ocr/ocr_service.dart';
import 'package:vixrex/services/ocr/ocr_feedback_service.dart';
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
  })  : _ocrService = ocrService,
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

    final result = await _ocrService.analyzeImage(imageBytes, scanMode: _scanMode);

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
    _result!.products[index] = updated;
    notifyListeners();
  }

  /// Tümünü onayla.
  void approveAll() {
    if (_result == null) return;
    for (final product in _result!.products) {
      product.isApproved = true;
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
    final validProducts = approved.where((p) {
      if (p.name.trim().isEmpty) return false;
      if (p.price != null && p.price! < 0) return false;
      return true;
    }).toList();

    if (validProducts.isEmpty) {
      _errorMessage = 'Kaydedilecek geçerli ürün yok. Ürün adı boş veya fiyat geçersiz.';
      notifyListeners();
      return;
    }

    try {
      // 1. Düzeltilmiş feedback verilerini Supabase'e gönder (Active Learning Loop)
      final feedbackList = _result!.products.map((p) => {
        'name': p.name,
        'price': p.price,
        'is_approved': p.isApproved,
        'confidence': p.confidence,
      }).toList();

      final parsedList = _result!.products.map((p) => {
        'name': p.name,
        'price': p.price,
        'confidence': p.confidence,
      }).toList();

      await const OcrFeedbackService().saveFeedback(
        rawOcrText: _result!.rawText,
        parsedProducts: parsedList,
        correctedProducts: feedbackList,
        scanMode: _scanMode,
        imageHash: 'hash_${_result!.rawText.hashCode.abs()}',
      );

      // 2. Ürünleri editör kontrolcüsüne ekle
      for (final product in validProducts) {
        await _editorController?.addProduct(
          _convertToProduct(product),
        );
      }
      _result = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Ürünler kaydedilemedi: $e';
      notifyListeners();
    }
  }

  /// DetectedProduct'ı Product'a çevir.
  Product _convertToProduct(DetectedProduct detected) {
    // Benzersiz ID: timestamp + random + name hash
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = (timestamp * 7 + detected.name.hashCode).abs();
    return Product(
      id: 'ocr_${timestamp}_$random',
      name: detected.name,
      price: detected.price?.toStringAsFixed(2) ?? '',
      description: detected.description ?? '',
      category: detected.category,
      stockStatus: StockStatus.available.label,
      isVisible: true,
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
