import 'package:flutter/foundation.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/services/bulk_product_upload_service.dart';

/// Toplu ürün yükleme akışının state yönetimi.
class BulkProductUploadController extends ChangeNotifier {
  final BulkProductUploadService _uploadService;

  BulkProductUploadController({
    BulkProductUploadService? uploadService,
  }) : _uploadService = uploadService ?? const BulkProductUploadService();

  // ─── State ─────────────────────────────────────────────────────
  BulkUploadState _state = BulkUploadState.initial;
  BulkParseResult? _parseResult;
  String? _errorMessage;
  bool _isSaving = false;
  int _savedCount = 0;

  // ─── Getters ───────────────────────────────────────────────────
  BulkUploadState get state => _state;
  BulkParseResult? get parseResult => _parseResult;
  String? get errorMessage => _errorMessage;
  bool get isSaving => _isSaving;
  int get savedCount => _savedCount;
  List<Product> get products => _parseResult?.products ?? [];
  bool get hasProducts => products.isNotEmpty;

  // ─── Dosya Seçimi ve Parse ────────────────────────────────────

  /// Seçilen dosyayı parse et.
  Future<void> parseFile(Uint8List bytes, {required String fileName}) async {
    _state = BulkUploadState.parsing;
    _errorMessage = null;
    _parseResult = null;
    notifyListeners();

    try {
      final result = _uploadService.parse(bytes, fileName: fileName);
      _parseResult = result;

      if (!result.isSuccess) {
        _errorMessage = result.errorMessage;
        _state = BulkUploadState.error;
      } else if (result.products.isEmpty) {
        _errorMessage = 'Dosyada geçerli ürün bulunamadı.';
        _state = BulkUploadState.error;
      } else {
        _state = BulkUploadState.review;
      }
    } catch (e) {
      _errorMessage = 'Dosya işlenirken hata oluştu: $e';
      _state = BulkUploadState.error;
    }

    notifyListeners();
  }

  // ─── Ürün Düzenleme ───────────────────────────────────────────

  /// Tek bir ürünü güncelle.
  void updateProduct(int index, Product updated) {
    if (_parseResult == null || index < 0 || index >= _parseResult!.products.length) return;
    _parseResult!.products[index] = updated;
    notifyListeners();
  }

  /// Ürünü listeden kaldır.
  void removeProduct(int index) {
    if (_parseResult == null || index < 0 || index >= _parseResult!.products.length) return;
    _parseResult!.products.removeAt(index);
    if (_parseResult!.products.isEmpty) {
      _state = BulkUploadState.review;
      _errorMessage = 'Tüm ürünler kaldırıldı.';
    }
    notifyListeners();
  }

  /// Tüm ürünleri onayla.
  void approveAll() {
    if (_parseResult == null) return;
    for (final product in _parseResult!.products) {
      product.isVisible = true;
    }
    notifyListeners();
  }

  /// Tüm ürünleri gizle.
  void hideAll() {
    if (_parseResult == null) return;
    for (final product in _parseResult!.products) {
      product.isVisible = false;
    }
    notifyListeners();
  }

  /// Tümünü seç (tümünü sil için).
  void selectAllForRemoval() {
    // Bu özellik isteğe bağlı — products listesini temizler
    _parseResult?.products.clear();
    _state = BulkUploadState.review;
    notifyListeners();
  }

  // ─── Kaydetme ──────────────────────────────────────────────────

  /// Onaylanan ürünleri geri çağrım fonksiyonuna aktar.
  Future<bool> saveProducts({
    required Future<void> Function(List<Product> products) onSave,
  }) async {
    if (_isSaving || !hasProducts) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Sadece görünür ürünleri kaydet
      final visibleProducts = products.where((p) => p.isVisible).toList();
      if (visibleProducts.isEmpty) {
        _errorMessage = 'Görünen ürün yok. En az bir ürünü vitrinde gösterilmek üzere işaretleyin.';
        _isSaving = false;
        notifyListeners();
        return false;
      }

      await onSave(visibleProducts);
      _savedCount = visibleProducts.length;
      _state = BulkUploadState.saved;
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Ürünler kaydedilemedi: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Sıfırlama ─────────────────────────────────────────────────

  void reset() {
    _state = BulkUploadState.initial;
    _parseResult = null;
    _errorMessage = null;
    _isSaving = false;
    _savedCount = 0;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

enum BulkUploadState {
  initial,
  parsing,
  review,
  saving,
  saved,
  error,
}
