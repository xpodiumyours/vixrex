import 'package:flutter/foundation.dart';
import 'package:vixrex/config/business_category_config.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/repositories/explore_repository.dart';
import 'package:vixrex/services/premium_service.dart';

class ExploreController extends ChangeNotifier {
  final ExploreRepository _repository;
  final PremiumService _premiumService;

  ExploreController({
    required ExploreRepository repository,
    PremiumService premiumService = const PremiumService(),
    bool onlyRentalTemplates = false,
  }) : _repository = repository,
       _premiumService = premiumService,
       _onlyRentalTemplates = onlyRentalTemplates;

  /// Onboarding'in "Hazır Vitrin Seç" akışı için: yalnız kiralık şablonları
  /// gösterir (gerçek yayındaki işletmeler karışmaz). Sabit bir başlangıç
  /// modu — ekran içinde açılıp kapanan bir filtre değil, bu ekranın NEDEN
  /// açıldığını belirler.
  final bool _onlyRentalTemplates;

  List<StoreData> _allStores = [];
  bool _isLoading = true;
  String? _loadErrorMessage;
  String _selectedCategory = 'Tümü';
  String _selectedTemplateGroup = 'Tümü';
  bool _onlyFavorites = false;
  bool _showingExampleStores = false;
  List<String> _favoritedStoreNames = [];
  String? _localPublishedSlug;
  StorePremiumStatus? _ownStorePremium;

  // Getters
  List<StoreData> get allStores => _allStores;
  bool get isLoading => _isLoading;
  String? get loadErrorMessage => _loadErrorMessage;
  String get selectedCategory => _selectedCategory;
  String get selectedTemplateGroup => _selectedTemplateGroup;
  bool get onlyFavorites => _onlyFavorites;
  bool get showingExampleStores => _showingExampleStores;
  List<String> get favoritedStoreNames => _favoritedStoreNames;
  String? get localPublishedSlug => _localPublishedSlug;

  /// Kendi vitrininin premium durumu (yalnız kendi vitrini; başkasının
  /// vitrininde asla dolu gelmez). edit_token yoksa veya okuma başarısızsa
  /// null kalır — UI o zaman premium bilgisini göstermez.
  StorePremiumStatus? get ownStorePremium => _ownStorePremium;

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
        } else {
          final ownStore = await _repository.fetchStoreBySlug(
            _localPublishedSlug!,
          );
          if (ownStore != null) {
            loadedStores.insert(0, ownStore);
          }
        }
      }
      _allStores = loadedStores;
      _showingExampleStores = false;
      _isLoading = false;
      await _refreshOwnStorePremium();
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

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setCategory(String value) {
    _selectedCategory = value;
    notifyListeners();
  }

  void setTemplateGroup(String value) {
    _selectedTemplateGroup = value;
    // When changing template group, reset category to 'Tümü'
    // (only show categories belonging to the selected group)
    _selectedCategory = 'Tümü';
    notifyListeners();
  }

  /// Returns categories filtered by the selected template group.
  List<BusinessCategoryConfig> get filteredCategories {
    if (_selectedTemplateGroup == 'Tümü') {
      return BusinessCategoryConfig.categories;
    }
    return BusinessCategoryConfig.categoriesByGroup(_selectedTemplateGroup);
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

  /// Kendi vitrininin premium durumunu best-effort okur. edit_token
  /// yerelde yoksa veya RPC başarısız olursa sessizce null bırakır —
  /// Keşfet akışını ASLA bozmaz (servis hataları Result.failure döner,
  /// fırlatmaz).
  Future<void> _refreshOwnStorePremium() async {
    _ownStorePremium = null;
    final slug = _localPublishedSlug;
    if (slug == null || slug.isEmpty) return;
    final editToken =
        (await _repository.loadLastPublishedEditToken() ?? '').trim();
    if (editToken.isEmpty) return;

    final result = await _premiumService.getPremiumStatus(
      slug: slug,
      editToken: editToken,
    );
    if (result.isSuccess) {
      _ownStorePremium = result.data;
    }
  }

  List<StoreData> get filteredStores {
    final query = _searchQuery.toLowerCase().trim();
    return _allStores.where((store) {
      // -1. "Hazır Vitrin Seç" modu — yalnız kiralık şablonlar.
      if (_onlyRentalTemplates && !store.isRentalTemplate) {
        return false;
      }
      // 0. Template group filter
      if (_selectedTemplateGroup != 'Tümü') {
        final storeCat = BusinessCategoryConfig.fromCategoryLabel(
          store.kategori,
        );
        if (storeCat.templateGroup != _selectedTemplateGroup) {
          return false;
        }
      }
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
