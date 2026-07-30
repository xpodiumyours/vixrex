import 'package:flutter/foundation.dart';

/// Temel dükkan bilgileri, yasal onaylar ve yayınlama akışını yöneten Mixin.
mixin StoreCoreMixin on ChangeNotifier {
  // --- States ---
  bool _isLoading = false;
  bool _isPublishing = false;
  final bool _isDeleting = false;
  bool _isLoadingArticles = false;
  bool _isLoadingLegalDocuments = false;
  List<Map<String, dynamic>> _articles = [];

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
