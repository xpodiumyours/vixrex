import 'package:flutter/foundation.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/store_publish_service.dart';
import 'package:vixrex/utils/failure.dart';

/// Temel dükkan bilgileri, yasal onaylar ve yayınlama akışını yöneten Mixin.
mixin StoreCoreMixin on ChangeNotifier {
  // --- States ---
  bool _isLoading = false;
  bool _isPublishing = false;
  final bool _isDeleting = false;
  bool _isLoadingArticles = false;
  bool _isLoadingLegalDocuments = false;
  List<Map<String, dynamic>> _articles = [];
  String? _productSyncError;

  // Validation Errors
  String? _nameError;
  String? _whatsappError;
  String? _googleLinkError;
  String? _legalDocumentsError;

  // --- Getters ---
  bool get isLoading => _isLoading;
  bool get isPublishing => _isPublishing;
  bool get isDeleting => _isDeleting;
  bool get isLoadingArticles => _isLoadingArticles;
  bool get isLoadingLegalDocuments => _isLoadingLegalDocuments;
  List<Map<String, dynamic>> get articles => _articles;
  String? get productSyncError => _productSyncError;

  String? get nameError => _nameError;
  String? get whatsappError => _whatsappError;
  String? get googleLinkError => _googleLinkError;
  String? get legalDocumentsError => _legalDocumentsError;

  // --- Methods ---
  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void setPublishing(bool val) {
    _isPublishing = val;
    notifyListeners();
  }

  void setLoadingLegalDocuments(bool val) {
    _isLoadingLegalDocuments = val;
    notifyListeners();
  }

  void clearProductSyncError() {
    if (_productSyncError == null) return;
    _productSyncError = null;
    notifyListeners();
  }

  void setLegalDocumentsError(String? message) {
    _legalDocumentsError = message;
    notifyListeners();
  }

  void clearCoreErrors() {
    _nameError = null;
    _whatsappError = null;
    _googleLinkError = null;
    _legalDocumentsError = null;
    notifyListeners();
  }

  /// Emekli: JSON ürün sync. Yerine [StoreEditorController.syncCatalogToRemote].
  @Deprecated('Use StoreEditorController.syncCatalogToRemote')
  Future<Result<void>> syncProductsToSupabase({
    required StoreData data,
    required StorePublishService publishService,
    String? editToken,
  }) async {
    _productSyncError =
        'Ürünler products tablosuna yazılır. syncCatalogToRemote kullanın.';
    notifyListeners();
    return Result.failure(Failure(_productSyncError!));
  }

  /// Blog yazılarını çeker.
  Future<void> fetchArticles({
    required String slug,
    required dynamic supabaseClient,
  }) async {
    if (slug.trim().isEmpty) return;
    _isLoadingArticles = true;
    notifyListeners();
    try {
      final response = await supabaseClient
          .from('store_articles')
          .select()
          .eq('store_slug', slug)
          .order('created_at', ascending: false);
      _articles = List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      if (kDebugMode) debugPrint('fetchArticles hatası: $e');
      _articles = [];
    } finally {
      _isLoadingArticles = false;
      notifyListeners();
    }
  }
}
