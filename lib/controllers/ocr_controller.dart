import 'package:flutter/foundation.dart';
import 'package:vixrex/models/detected_product.dart';
import 'package:vixrex/models/ocr_catalog_result.dart';
import 'package:vixrex/services/ocr/ocr_service.dart';
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

  OcrCatalogResult? get result => _result;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  bool get hasResult => _result != null;

  /// Görüntüyü analiz et.
  Future<void> analyzeImage(Uint8List imageBytes) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _ocrService.analyzeImage(imageBytes);

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

    for (final product in approved) {
      await _editorController?.addProduct(
        _convertToProduct(product),
      );
    }

    // Sonucu temizle
    _result = null;
    notifyListeners();
  }

  /// DetectedProduct'ı Product'a çevir.
  dynamic _convertToProduct(DetectedProduct detected) {
    return {
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'name': detected.name,
      'price': detected.price?.toString() ?? '',
      'category': detected.category,
      'stockStatus': 'Mevcut',
      'isVisible': true,
    };
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
