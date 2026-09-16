import 'package:flutter/foundation.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/services/bulk_product_upload_service.dart';
import 'package:vixrex/services/product_batch_import_service.dart';

/// Toplu ürün yükleme akışının state yönetimi.
class BulkProductUploadController extends ChangeNotifier {
  final BulkProductUploadService _uploadService;

  BulkProductUploadController({BulkProductUploadService? uploadService})
    : _uploadService = uploadService ?? const BulkProductUploadService();

  BulkUploadState _state = BulkUploadState.initial;
  BulkParseResult? _parseResult;
  ProductBatchImportResult? _saveResult;
  String? _errorMessage;
  bool _isSaving = false;
  int _savedCount = 0;

  BulkUploadState get state => _state;
  BulkParseResult? get parseResult => _parseResult;
  ProductBatchImportResult? get saveResult => _saveResult;
  String? get errorMessage => _errorMessage;
  bool get isSaving => _isSaving;
  int get savedCount => _savedCount;
  List<Product> get products => _parseResult?.products ?? [];
  bool get hasProducts => products.isNotEmpty;

  Future<void> parseFile(Uint8List bytes, {required String fileName}) async {
    _state = BulkUploadState.parsing;
    _errorMessage = null;
    _parseResult = null;
    _saveResult = null;
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

  void updateProduct(int index, Product updated) {
    if (_parseResult == null ||
        index < 0 ||
        index >= _parseResult!.products.length) {
      return;
    }
    _parseResult!.products[index] = updated;
    notifyListeners();
  }

  void removeProduct(int index) {
    if (_parseResult == null ||
        index < 0 ||
        index >= _parseResult!.products.length) {
      return;
    }
    _parseResult!.products.removeAt(index);
    if (_parseResult!.products.isEmpty) {
      _state = BulkUploadState.review;
      _errorMessage = 'Tüm ürünler kaldırıldı.';
    }
    notifyListeners();
  }

  void clearAllProducts() {
    _parseResult?.products.clear();
    _state = BulkUploadState.review;
    notifyListeners();
  }

  /// Ürünleri gerçek batch Product CORE kaydına aktarır. Callback sonucu
  /// inserted/updated/unchanged/errors sayaçlarını taşır; liste uzunluğu başarı
  /// sayısı gibi kullanılmaz.
  Future<bool> saveProducts({
    required Future<ProductBatchImportResult> Function(List<Product> products)
    onSave,
  }) async {
    if (_isSaving || !hasProducts) return false;

    _isSaving = true;
    _errorMessage = null;
    _saveResult = null;
    notifyListeners();

    try {
      final toSave = List<Product>.of(products);
      final result = await onSave(toSave);
      _saveResult = result;

      if (!result.isSuccess) {
        _errorMessage = result.errorMessage ?? 'Ürünler kaydedilemedi.';
        _isSaving = false;
        notifyListeners();
        return false;
      }

      _savedCount = result.changed;
      if (result.total > 0 &&
          result.errors >= result.total &&
          result.changed == 0 &&
          result.unchanged == 0) {
        _errorMessage =
            'Hiçbir ürün kaydedilemedi. Satır hatalarını kontrol edin.';
        _isSaving = false;
        notifyListeners();
        return false;
      }

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

  void reset() {
    _state = BulkUploadState.initial;
    _parseResult = null;
    _saveResult = null;
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

enum BulkUploadState { initial, parsing, review, saving, saved, error }
