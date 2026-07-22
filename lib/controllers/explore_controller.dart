import 'package:flutter/foundation.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/repositories/explore_repository.dart';
import 'package:vixrex/services/product_service.dart';

class ExploreController extends ChangeNotifier {
  final ExploreRepository _repository;
  final ProductService _productService;

  ExploreController({
    required ExploreRepository repository,
    ProductService? productService,
  }) : _repository = repository,
       _productService = productService ?? ProductService();

  List<StoreData> _allStores = [];
  bool _isLoading = true;
  String? _loadErrorMessage;
  String _selectedCategory = 'Tümü';
  bool _onlyFavorites = false;
  bool _showingExampleStores = false;
  List<String> _favoritedStoreNames = [];
  String? _localPublishedSlug;

  // Getters
  List<StoreData> get allStores => _allStores;
  bool get isLoading => _isLoading;
  String? get loadErrorMessage => _loadErrorMessage;
  String get selectedCategory => _selectedCategory;
  bool get onlyFavorites => _onlyFavorites;
  bool get showingExampleStores => _showingExampleStores;
  List<String> get favoritedStoreNames => _favoritedStoreNames;
  String? get localPublishedSlug => _localPublishedSlug;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  Future<void> initialize() async {
    _favoritedStoreNames = await _repository.loadFavoriteStoreNames();
    _localPublishedSlug = await _repository.loadLastPublishedSlug();
    notifyListeners();
    await reloadStores();
  }

  Future<void> reloadStores() async {
    _isLoading = true;
    _loadErrorMessage = null;
    notifyListeners();

    try {
      final loadedStores = await _repository.fetchPublishedStores();

      // Re-load slug in case it changed
      _localPublishedSlug = await _repository.loadLastPublishedSlug();

      if (_localPublishedSlug != null && _localPublishedSlug!.isNotEmpty) {
        final int index = loadedStores.indexWhere(
          (store) => store.slug == _localPublishedSlug,
        );
        if (index != -1) {
          final ownStore = loadedStores.removeAt(index);
          loadedStores.insert(0, ownStore);
        }
      }
      await _hydrateTableProducts(loadedStores);
      _allStores = loadedStores;
      _showingExampleStores = false;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ExploreController.reloadStores: $e');
      }
      _allStores = [];
      _showingExampleStores = false;
      _loadErrorMessage =
          'Vitrinler yüklenemedi. İnternet bağlantınızı kontrol edin.';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// v2 mağazalarda kart/özet için tablodaki görünür ürünleri doldurur.
  /// JSON dolu v1 mağazalara dokunmaz (tablo boşsa JSON kalır).
  Future<void> _hydrateTableProducts(List<StoreData> stores) async {
    final tasks = <Future<void>>[];
    for (final store in stores) {
      final storeId = store.id?.trim() ?? '';
      if (storeId.isEmpty) continue;
      tasks.add(() async {
        try {
          final remote = await _productService.fetchVisibleProducts(storeId);
          if (remote.isNotEmpty) {
            store.products = remote;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('ExploreController._hydrateTableProducts: $e');
          }
        }
      }());
    }
    if (tasks.isEmpty) return;
    await Future.wait(tasks);
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setCategory(String value) {
    _selectedCategory = value;
    notifyListeners();
  }

  void setOnlyFavorites(bool value) {
    _onlyFavorites = value;
    notifyListeners();
  }

  Future<void> toggleFavorite(String storeName) async {
    final updated = List<String>.from(_favoritedStoreNames);
    if (updated.contains(storeName)) {
      updated.remove(storeName);
    } else {
      updated.add(storeName);
    }
    await _repository.saveFavoriteStoreNames(updated);
    _favoritedStoreNames = updated;
    notifyListeners();
  }

  bool isFavorite(StoreData store) {
    return _favoritedStoreNames.contains(store.name);
  }

  bool isOwnStore(StoreData store) {
    return _localPublishedSlug != null &&
        _localPublishedSlug!.isNotEmpty &&
        store.slug == _localPublishedSlug;
  }

  List<StoreData> get filteredStores {
    final query = _searchQuery.toLowerCase().trim();
    return _allStores.where((store) {
      // 1. Category filter
      if (_selectedCategory != 'Tümü' && store.kategori != _selectedCategory) {
        return false;
      }
      // 2. Favorites filter
      if (_onlyFavorites && !_favoritedStoreNames.contains(store.name)) {
        return false;
      }
      // 3. Search query filter (vitrin, kategori, ürün)
      if (query.isNotEmpty) {
        final matchName = store.name.toLowerCase().contains(query);
        final matchDesc = store.description.toLowerCase().contains(query);
        final matchCat = store.kategori.toLowerCase().contains(query);
        final matchProduct = store.products.any(
          (p) => p.name.toLowerCase().contains(query),
        );
        return matchName || matchDesc || matchCat || matchProduct;
      }
      return true;
    }).toList();
  }
}
