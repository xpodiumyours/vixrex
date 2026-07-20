import 'package:flutter/foundation.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/repositories/supabase_product_repository.dart';
import 'package:vixrex/services/product_service.dart';
import 'package:vixrex/utils/failure.dart';

/// Ürün CRUD state yönetimi.
/// StoreEditorController'dan bağımsız çalışabilir veya ona bağlanabilir.
class ProductController extends ChangeNotifier {
  final ProductService _service;

  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  ProductController({ProductService? service})
    : _service = service ?? ProductService(
        repository: SupabaseProductRepository(),
      );

  List<Product> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get count => _products.length;

  /// Mağazadan ürünleri çeker.
  Future<void> loadProducts(String storeId) async {
    if (storeId.trim().isEmpty) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _service.fetchProducts(storeId);
    } catch (e) {
      _error = 'Ürünler yüklenemedi.';
      if (kDebugMode) debugPrint('loadProducts hatası: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Yeni ürün ekler.
  Future<Result<String>> addProduct({
    required String storeId,
    required String editToken,
    required String name,
    required String slug,
    String description = '',
    String priceText = '',
    double? priceAmount,
    List<String> imageUrls = const [],
    String? categoryId,
    String sourceType = 'manual',
    String? externalProductId,
    bool isVisible = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.addProduct(
        storeId: storeId,
        editToken: editToken,
        name: name,
        slug: slug,
        description: description,
        priceText: priceText,
        priceAmount: priceAmount,
        imageUrls: imageUrls,
        categoryId: categoryId,
        sourceType: sourceType,
        externalProductId: externalProductId,
        isVisible: isVisible,
        sortOrder: _products.length,
      );

      if (result.isSuccess) {
        _products.add(Product(
          id: result.data!,
          name: name,
          slug: slug,
          description: description,
          price: priceText,
          imageUrls: imageUrls,
          categoryId: categoryId ?? '',
          source: sourceType,
          isVisible: isVisible,
        ));
      } else {
        _error = result.failure?.message ?? 'Ürün eklenemedi.';
      }
      return result;
    } catch (e) {
      _error = 'Ürün eklenemedi.';
      if (kDebugMode) debugPrint('addProduct hatası: $e');
      return Result.failure(Failure(_error!));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ürün günceller.
  Future<Result<void>> updateProduct({
    required String productId,
    String? editToken,
    String? name,
    String? slug,
    String? description,
    String? priceText,
    double? priceAmount,
    List<String>? imageUrls,
    String? categoryId,
    bool? isVisible,
    int? sortOrder,
    int? stockQuantity,
    String? stockStatus,
    bool clearCategory = false,
    bool clearPriceAmount = false,
    bool clearStockQuantity = false,
    bool clearStockStatus = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.updateProduct(
        productId: productId,
        editToken: editToken,
        name: name,
        slug: slug,
        description: description,
        priceText: priceText,
        priceAmount: priceAmount,
        imageUrls: imageUrls,
        categoryId: categoryId,
        isVisible: isVisible,
        sortOrder: sortOrder,
        stockQuantity: stockQuantity,
        stockStatus: stockStatus,
        clearCategory: clearCategory,
        clearPriceAmount: clearPriceAmount,
        clearStockQuantity: clearStockQuantity,
        clearStockStatus: clearStockStatus,
      );

      if (result.isSuccess) {
        final index = _products.indexWhere((p) => p.id == productId);
        if (index >= 0) {
          final old = _products[index];
          _products[index] = old.copyWith(
            name: name,
            slug: slug,
            description: description,
            price: priceText,
            imageUrls: imageUrls,
            categoryId: categoryId,
            isVisible: isVisible,
            stockStatus: stockStatus,
          );
        }
      } else {
        _error = result.failure?.message ?? 'Ürün güncellenemedi.';
      }
      return result;
    } catch (e) {
      _error = 'Ürün güncellenemedi.';
      if (kDebugMode) debugPrint('updateProduct hatası: $e');
      return Result.failure(Failure(_error!));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ürün siler.
  Future<Result<void>> deleteProduct(String productId, {String? editToken}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.deleteProduct(productId, editToken: editToken);
      if (result.isSuccess) {
        _products.removeWhere((p) => p.id == productId);
      } else {
        _error = result.failure?.message ?? 'Ürün silinemedi.';
      }
      return result;
    } catch (e) {
      _error = 'Ürün silinemedi.';
      if (kDebugMode) debugPrint('deleteProduct hatası: $e');
      return Result.failure(Failure(_error!));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ürün sırasını değiştirir.
  Future<Result<void>> reorderProducts(String storeId, String editToken, List<String> productIds) async {
    try {
      final result = await _service.reorderProducts(storeId, editToken, productIds);
      if (result.isSuccess) {
        final reordered = <Product>[];
        for (final id in productIds) {
          final match = _products.where((p) => p.id == id);
          if (match.isNotEmpty) reordered.add(match.first);
        }
        _products = reordered;
      }
      return result;
    } catch (e) {
      _error = 'Sıralama değiştirilemedi.';
      if (kDebugMode) debugPrint('reorderProducts hatası: $e');
      return Result.failure(Failure(_error!));
    } finally {
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }
}
