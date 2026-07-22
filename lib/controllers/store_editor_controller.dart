import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/config/business_category_config.dart';
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/models/editor_gallery_item.dart';
import 'package:vixrex/services/store_publish_service.dart';
import 'package:vixrex/services/store_local_storage_service.dart';
import 'package:vixrex/services/seo_service.dart';
import 'package:vixrex/services/location_service.dart';
import 'package:vixrex/services/store_shelf_upload_service.dart';
import 'package:vixrex/services/legal_document_service.dart';
import 'package:vixrex/services/product_service.dart';
import 'package:vixrex/repositories/supabase_product_repository.dart';
import 'package:vixrex/utils/secure_token_generator.dart';
import 'package:vixrex/utils/failure.dart';

import 'mixins/store_media_mixin.dart';
import 'mixins/store_location_mixin.dart';
import 'mixins/store_core_mixin.dart';

/// VixRex Vitrin Editörü Ana Controller'ı.
/// UI ile iş mantığı arasındaki köprüdür. Alt görevleri Mixin'lere delege eder.
class StoreEditorController extends ChangeNotifier
    with StoreMediaMixin, StoreLocationMixin, StoreCoreMixin {
  final StoreLocalStorageService storage;
  final LocationService locationService;
  final StorePublishService publishService;
  final StoreShelfUploadService uploadService;
  final LegalDocumentService legalDocumentService;
  final ProductService productService;
  final SupabaseClient? supabaseClient;

  StoreData _data;
  PublishedVitrinInfo? _publishedInfo;

  StoreEditorController({
    StoreLocalStorageService? storage,
    LocationService? locationService,
    StorePublishService? publishService,
    StoreShelfUploadService? uploadService,
    LegalDocumentService? legalDocumentService,
    ProductService? productService,
    this.supabaseClient,
    StoreData? initialData,
  }) : storage = storage ?? const StoreLocalStorageService(),
       locationService = locationService ?? const LocationService(),
       publishService = publishService ?? const StorePublishService(),
       uploadService = uploadService ?? const StoreShelfUploadService(),
       legalDocumentService =
           legalDocumentService ?? const LegalDocumentService(),
       productService =
           productService ??
           ProductService(repository: SupabaseProductRepository()),
       _data = initialData ?? StoreData(kategori: 'Diğer', status: 'Açık') {
    _syncInitialData();
  }

  // --- Getters (UI Uyumluluğu için) ---
  StoreData get data => _data;
  PublishedVitrinInfo? get publishedInfo => _publishedInfo;

  bool get bookingIsEnabled => _data.bookingSettings?.isEnabled ?? false;
  int get bookingCapacity => _data.bookingSettings?.capacity ?? 1;
  Map<String, dynamic> get bookingWorkingHours =>
      _data.bookingSettings?.workingHours ?? {};
  Map<String, dynamic> get bookingLunchBreak =>
      _data.bookingSettings?.lunchBreak ?? {};
  List<StoreOffering> get offerings => _data.offerings;
  List<Product> get products => _data.products;
  bool get hasProducts => _data.products.isNotEmpty;

  String get selectedKategori => _data.kategori;
  String get selectedStatus => _data.status;

  double? get latitude => _data.latitude;
  double? get longitude => _data.longitude;
  double? get locationAccuracyMeters => _data.locationAccuracyMeters;
  String? get locationStatusMessage => null;

  String? get selectedProvinceCode =>
      _data.provinceCode.isNotEmpty ? _data.provinceCode : null;
  String? get selectedProvinceName =>
      _data.provinceName.isNotEmpty ? _data.provinceName : null;
  String? get selectedDistrictCode =>
      _data.districtCode.isNotEmpty ? _data.districtCode : null;
  String? get selectedDistrictName =>
      _data.districtName.isNotEmpty ? _data.districtName : null;

  bool get privacyNoticeAcknowledged => _data.privacyNoticeAcknowledged;
  bool get termsAccepted => _data.termsAccepted;
  bool get publicationConsentAccepted => _data.publicationConsentAccepted;

  List<MarketplaceLink> get marketplaceLinks => _data.marketplaceLinks;
  Set<String> get customPlatformLinkIds => {};

  bool get isLegalPublishReady =>
      _data.privacyNoticeAcknowledged &&
      _data.termsAccepted &&
      _data.publicationConsentAccepted;

  bool get isWithdrawingConsent => isLoading;

  // --- Core Lifecycle ---
  void _syncInitialData() {
    setGalleryItems(
      _data.galleryItems
          .map((item) => EditorGalleryItem.fromStoreItem(item))
          .toList(),
    );
    if (_data.shelfImageUrl.isNotEmpty) {
      setCoverUrl(_data.shelfImageUrl);
    }
  }

  Future<void> initialize(String? initialName) async {
    setLoading(true);
    try {
      final localData = await storage.loadVitrinData();
      if (localData != null) {
        _data = localData;
      } else {
        _data = StoreData(
          name: initialName ?? '',
          kategori: 'Diğer',
          status: 'Açık',
          isStore: false,
        );
      }
      _publishedInfo = await storage.loadPublishedVitrinInfo();

      if (_publishedInfo == null || !_publishedInfo!.canEditRemote) {
        await _fetchPublishedInfoFromSupabase();
      }

      _syncInitialData();
      if (_publishedInfo != null) {
        await ensureRemoteStoreId();
        await _loadRemoteProductsIfReady();
        await fetchArticles(
          slug: _publishedInfo!.slug,
          supabaseClient: _resolveClient(),
        );
      }
      // Onaylı kutular için version damgasını arka planda doldur
      await _stampAcceptedLegalDocuments();
    } catch (e) {
      if (kDebugMode) debugPrint('StoreEditorController.initialize failed: $e');
    } finally {
      setLoading(false);
    }
  }

  SupabaseClient? _resolveClient() {
    if (supabaseClient != null) return supabaseClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // --- Delegated Methods (UI Compatibility) ---
  /// Hazır şablon kapak URL'sini hem editör state'ine hem StoreData.shelfImageUrl'e yazar.
  @override
  void setCoverUrl(String url) {
    final trimmed = url.trim();
    super.setCoverUrl(trimmed);
    if (trimmed.isNotEmpty) {
      _data.shelfImageUrl = trimmed;
    }
  }

  void setName(String name) {
    _data.name = name;
    notifyListeners();
  }

  void updateName(String name) => setName(name);

  /// Kategori seçimi: özellik paketini sessiz uygular (randevu vb.).
  void selectCategory(String kategori) {
    _data.kategori = kategori;
    _applyCategoryFeaturePackage(kategori);
    notifyListeners();
  }

  void _applyCategoryFeaturePackage(String kategori) {
    final supportsBooking = BusinessCategoryConfig.supportsBookingPackage(
      kategori,
    );
    _ensureBookingSettings();
    _data.bookingSettings!.isEnabled = supportsBooking;
  }

  void setDescription(String description) {
    _data.description = description;
    notifyListeners();
  }

  void updateWhatsapp(String w) {
    _data.whatsapp = w;
    notifyListeners();
  }

  void updateInstagram(String value) {
    _data.instagram = value.trim();
    notifyListeners();
  }

  /// Instagram OAuth sonrası kullanıcı adını forma ve (yayındaysa) Supabase'e yazar.
  Future<Result<void>> applyConnectedInstagramUsername(String username) async {
    final cleaned = username.trim().replaceFirst('@', '');
    if (cleaned.isEmpty) return const Result.success(null);
    final handle = '@$cleaned';
    updateInstagram(handle);

    final info = _publishedInfo;
    if (info == null ||
        info.slug.trim().isEmpty ||
        info.editToken.trim().isEmpty) {
      return const Result.success(null);
    }

    final result = await publishService.updateStorePatch(
      slug: info.slug,
      editToken: info.editToken,
      patch: {'instagram': handle},
    );
    if (result.isSuccess) {
      await saveLocally();
    }
    return result;
  }

  void updateWebsite(String value) {
    _data.website = value.trim();
    notifyListeners();
  }

  void selectStatus(String status) {
    _data.status = status;
    notifyListeners();
  }

  void updateGoogleBusinessLink(String v) {
    _data.googleBusinessLink = v;
    notifyListeners();
  }

  void addMarketplaceLink(MarketplaceLink link) {
    _data.marketplaceLinks.add(link);
    notifyListeners();
  }

  void removeMarketplaceLink(int index) {
    if (index >= 0 && index < _data.marketplaceLinks.length) {
      _data.marketplaceLinks.removeAt(index);
      notifyListeners();
    }
  }

  void toggleCustomPlatformLinkId(String id, bool val) {
    notifyListeners();
  }

  void setBookingIsEnabled(bool val) {
    _ensureBookingSettings();
    _data.bookingSettings!.isEnabled = val;
    notifyListeners();
  }

  void setBookingCapacity(int val) {
    _ensureBookingSettings();
    _data.bookingSettings!.capacity = val;
    notifyListeners();
  }

  /// WorkingHoursEditor in-place mutasyon sonrası UI yenileme.
  void refreshBookingEditor() => notifyListeners();

  void _ensureBookingSettings() {
    _data.bookingSettings ??= BookingSettings();
  }

  @override
  void updateAddress(StoreData data, String address) {
    data.address = address;
    notifyListeners();
  }

  @override
  void selectProvince(StoreData data, String? code, String? name) {
    data.provinceCode = code ?? '';
    data.provinceName = name ?? '';
    notifyListeners();
  }

  @override
  void selectDistrict(StoreData data, String? code, String? name) {
    data.districtCode = code ?? '';
    data.districtName = name ?? '';
    notifyListeners();
  }

  Future<void> triggerFetchLocation() =>
      fetchLocation(data: _data, locationService: locationService);

  void setPrivacyNoticeAcknowledged(bool v) {
    _data.privacyNoticeAcknowledged = v;
    _data.privacyNoticeAcknowledgedAt = v ? DateTime.now() : null;
    if (v) {
      _stampAcceptedLegalDocuments();
    } else {
      _data.privacyNoticeVersion = '';
      _data.privacyNoticeHash = '';
    }
    notifyListeners();
  }

  void setTermsAccepted(bool v) {
    _data.termsAccepted = v;
    _data.termsAcceptedAt = v ? DateTime.now() : null;
    if (v) {
      _stampAcceptedLegalDocuments();
    } else {
      _data.termsVersion = '';
      _data.termsHash = '';
    }
    notifyListeners();
  }

  void setPublicationConsentAccepted(bool v) {
    _data.publicationConsentAccepted = v;
    _data.publicationConsentAcceptedAt = v ? DateTime.now() : null;
    if (v) {
      _stampAcceptedLegalDocuments();
    } else {
      _data.publicationConsentVersion = '';
      _data.publicationConsentHash = '';
    }
    notifyListeners();
  }

  /// Kullanıcı "Belgeleri Tekrar Yükle" dediğinde loading + error state ile yükler.
  Future<void> reloadLegalDocuments() async {
    setLoadingLegalDocuments(true);
    setLegalDocumentsError(null);
    try {
      await _stampAcceptedLegalDocuments(reportError: true);
    } finally {
      setLoadingLegalDocuments(false);
    }
  }

  /// Aktif yasal belgelerden version/hash damgala (hash DB'de boş olabilir).
  /// API başarısız olsa bile bilinen aktif sürümlerle boşluk doldurulur.
  Future<void> _stampAcceptedLegalDocuments({bool reportError = false}) async {
    try {
      final result = await legalDocumentService.loadPublishingDocuments();
      result.when(
        success: (docs) {
          setLegalDocumentsError(null);
          if (_data.privacyNoticeAcknowledged) {
            _data.privacyNoticeVersion = docs.privacy.version;
            _data.privacyNoticeHash = docs.privacy.contentHash;
            _data.privacyNoticeAcknowledgedAt ??= DateTime.now();
          }
          if (_data.termsAccepted) {
            _data.termsVersion = docs.terms.version;
            _data.termsHash = docs.terms.contentHash;
            _data.termsAcceptedAt ??= DateTime.now();
          }
          if (_data.publicationConsentAccepted) {
            _data.publicationConsentVersion = docs.consent.version;
            _data.publicationConsentHash = docs.consent.contentHash;
            _data.publicationConsentAcceptedAt ??= DateTime.now();
          }
        },
        failure: (f) {
          if (kDebugMode) {
            debugPrint('_stampAcceptedLegalDocuments: ${f.message}');
          }
          if (reportError) {
            setLegalDocumentsError(
              'Belgeler yüklenemedi. İnternet bağlantınızı kontrol edin',
            );
          }
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('_stampAcceptedLegalDocuments failed: $e');
      if (reportError) {
        setLegalDocumentsError('Belgeler yüklenemedi. Lütfen tekrar deneyin');
      }
    }
    _ensureFallbackLegalStamps();
    notifyListeners();
  }

  /// Supabase'teki aktif legal_documents sürümleri (2026-07-05).
  void _ensureFallbackLegalStamps() {
    if (_data.privacyNoticeAcknowledged &&
        _data.privacyNoticeVersion.trim().isEmpty) {
      _data.privacyNoticeVersion = 'privacy-2026-07-05';
      _data.privacyNoticeHash = '';
      _data.privacyNoticeAcknowledgedAt ??= DateTime.now();
    }
    if (_data.termsAccepted && _data.termsVersion.trim().isEmpty) {
      _data.termsVersion = 'terms-2026-07-05';
      _data.termsHash = '';
      _data.termsAcceptedAt ??= DateTime.now();
    }
    if (_data.publicationConsentAccepted &&
        _data.publicationConsentVersion.trim().isEmpty) {
      _data.publicationConsentVersion = 'consent-2026-07-05';
      _data.publicationConsentHash = '';
      _data.publicationConsentAcceptedAt ??= DateTime.now();
    }
  }

  Future<bool> ensureRemoteStoreId() async {
    final existing = _data.id?.trim() ?? '';
    if (existing.isNotEmpty && _isUuid(existing)) return true;

    final slug = (_publishedInfo?.slug ?? _data.slug).trim();
    if (slug.isEmpty) return false;

    final client = _resolveClient();
    if (client == null) return false;

    try {
      final row =
          await client
              .from('stores')
              .select('id')
              .eq('slug', slug)
              .maybeSingle();
      final id = (row?['id'] ?? '').toString().trim();
      if (id.isEmpty || !_isUuid(id)) return false;
      _data.id = id;
      if (_data.slug.trim().isEmpty) _data.slug = slug;
      await saveLocally();
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('ensureRemoteStoreId: $e');
      return false;
    }
  }

  Future<void> _loadRemoteProductsIfReady() async {
    final storeId = _data.id?.trim() ?? '';
    if (storeId.isEmpty || !_isUuid(storeId)) return;
    try {
      final remote = await productService.fetchProducts(storeId);
      if (remote.isEmpty) return;
      _data.products = remote;
      await saveLocally();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('_loadRemoteProductsIfReady: $e');
    }
  }

  /// Panel/OCR/bulk: yerel katalogu `products` tablosuna yazar (JSON sync değil).
  Future<Result<void>> syncCatalogToRemote({
    required List<Product> products,
    required List<ProductCategory> categories,
  }) async {
    final editToken = _publishedInfo?.editToken.trim() ?? '';
    if (editToken.isEmpty) {
      return Result.failure(
        Failure('Ürünleri kaydetmek için önce vitrini yayınlayın.'),
      );
    }

    final ready = await ensureRemoteStoreId();
    final storeId = _data.id?.trim() ?? '';
    if (!ready || storeId.isEmpty) {
      return Result.failure(
        Failure('Mağaza kimliği bulunamadı. Yayınlayıp tekrar deneyin.'),
      );
    }

    try {
      _data.productCategories = List.of(categories);

      final remote = await productService.fetchProducts(storeId);
      final remoteIds = remote.map((p) => p.id).toSet();
      final nextProducts = <Product>[];

      for (var i = 0; i < products.length; i++) {
        final product = products[i];
        final name = product.name.trim();
        if (name.isEmpty) continue;

        final rawCatId = product.categoryId.trim();
        final categoryUuid =
            rawCatId.isNotEmpty && _isUuid(rawCatId) ? rawCatId : null;

        final slug = (product.slug ?? _generateSlug(name)).trim();
        final safeSlug = slug.isEmpty ? 'urun-$i' : slug;

        if (_isUuid(product.id) && remoteIds.contains(product.id)) {
          final updated = await productService.updateProduct(
            productId: product.id,
            editToken: editToken,
            name: name,
            slug: safeSlug,
            description: product.description,
            priceText: product.price,
            imageUrls: product.displayImageUrls,
            categoryId: categoryUuid,
            clearCategory: categoryUuid == null || categoryUuid.isEmpty,
            isVisible: product.isVisible,
            stockStatus: product.stockStatus,
            sortOrder: i,
          );
          if (updated.isFailure) {
            return Result.failure(
              Failure(updated.failure?.message ?? 'Ürün güncellenemedi.'),
            );
          }
          product.categoryId = categoryUuid ?? '';
          nextProducts.add(product);
        } else {
          final created = await productService.addProduct(
            storeId: storeId,
            editToken: editToken,
            name: name,
            slug: safeSlug,
            description: product.description,
            priceText: product.price,
            imageUrls: product.displayImageUrls,
            categoryId: categoryUuid,
            sourceType: product.source ?? 'manual',
            isVisible: product.isVisible,
            sortOrder: i,
          );
          if (created.isFailure || created.data == null) {
            return Result.failure(
              Failure(created.failure?.message ?? 'Ürün eklenemedi.'),
            );
          }
          product.id = created.data!;
          product.slug = safeSlug;
          product.categoryId = categoryUuid ?? '';
          nextProducts.add(product);
        }
      }

      final keepIds = nextProducts.map((p) => p.id).toSet();
      for (final remoteProduct in remote) {
        if (keepIds.contains(remoteProduct.id)) continue;
        final deleted = await productService.deleteProduct(
          remoteProduct.id,
          editToken: editToken,
        );
        if (deleted.isFailure) {
          return Result.failure(
            Failure(deleted.failure?.message ?? 'Ürün silinemedi.'),
          );
        }
      }

      _data.products = nextProducts;
      await saveLocally();
      notifyListeners();
      _revalidateStoreCache();
      return const Result.success(null);
    } catch (e) {
      if (kDebugMode) debugPrint('syncCatalogToRemote: $e');
      return Result.failure(
        Failure('Ürünler kaydedilemedi, lütfen tekrar deneyin.'),
      );
    }
  }

  /// Yeni ürün ekler (ilişkisel `products` tablosuna senkronize eder).
  Future<Result<void>> addProduct(Product p) async {
    final editToken = _publishedInfo?.editToken.trim() ?? '';
    final ready = editToken.isNotEmpty ? await ensureRemoteStoreId() : false;
    final storeId = _data.id?.trim() ?? '';

    if (editToken.isNotEmpty && ready && storeId.isNotEmpty) {
      final result = await productService.addProduct(
        storeId: storeId,
        editToken: editToken,
        name: p.name,
        slug: p.slug ?? _generateSlug(p.name),
        description: p.description,
        priceText: p.price,
        imageUrls: p.displayImageUrls,
        categoryId:
            p.categoryId.isNotEmpty && _isUuid(p.categoryId)
                ? p.categoryId
                : null,
        sourceType: p.source ?? 'manual',
        isVisible: p.isVisible,
        sortOrder: _data.products.length,
      );

      if (result.isSuccess && result.data != null) {
        p.id = result.data!;
      }
    }

    _data.products.add(p);
    await saveLocally();
    notifyListeners();
    _revalidateStoreCache();
    return const Result.success(null);
  }

  /// Ürün siler (ilişkisel `products` tablosu).
  Future<Result<void>> removeProduct(int i) async {
    if (i < 0 || i >= _data.products.length) {
      return const Result.success(null);
    }
    final product = _data.products[i];
    final editToken = _publishedInfo?.editToken.trim() ?? '';

    if (_isUuid(product.id) && editToken.isNotEmpty) {
      await productService.deleteProduct(
        product.id,
        editToken: editToken,
      );
    }
    _data.products.removeAt(i);
    await saveLocally();
    notifyListeners();
    _revalidateStoreCache();
    return const Result.success(null);
  }

  /// Ürün günceller (ilişkisel `products` tablosu).
  Future<Result<void>> updateProduct(int i, Product p) async {
    if (i < 0 || i >= _data.products.length) {
      return const Result.success(null);
    }
    final editToken = _publishedInfo?.editToken.trim() ?? '';
    final storeId = _data.id?.trim() ?? '';

    if (editToken.isNotEmpty && storeId.isNotEmpty && _isUuid(p.id)) {
      await productService.updateProduct(
        productId: p.id,
        editToken: editToken,
        name: p.name,
        slug: p.slug ?? _generateSlug(p.name),
        description: p.description,
        priceText: p.price,
        imageUrls: p.displayImageUrls,
        categoryId:
            p.categoryId.isNotEmpty && _isUuid(p.categoryId)
                ? p.categoryId
                : null,
        isVisible: p.isVisible,
        stockStatus: p.stockStatus,
      );
    }

    _data.products[i] = p;
    await saveLocally();
    notifyListeners();
    _revalidateStoreCache();
    return const Result.success(null);
  }

  /// İçe aktarılan ürün günceller (ilişkisel `products` tablosu).
  Future<Result<void>> updateProductImported(Product product) async {
    final index = _data.products.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      return updateProduct(index, product);
    }
    return addProduct(product);
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value.trim());
  }

  String _generateSlug(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  /// Public vitrin sayfasının ISR cache'ini yeniler.
  void _revalidateStoreCache() {
    final slug = _publishedInfo?.slug ?? _data.slug;
    if (slug.trim().isEmpty) return;
    SeoService().revalidateStore(slug);
  }

  Future<void> withdrawPublicationConsent() async {
    final slug = _publishedInfo?.slug ?? _data.slug;
    final editToken = _publishedInfo?.editToken;
    if (slug.isEmpty || editToken == null) return;

    final result = await publishService.withdrawPublicationConsent(
      slug: slug,
      editToken: editToken,
    );
    result.when(
      success: (_) async {
        await storage.clearPublishedVitrinInfo();
        _publishedInfo = null;
        notifyListeners();
      },
      failure: (f) => throw f.message,
    );
  }

  Future<void> deleteVitrin() async {
    setLoading(true);
    try {
      final slug = (_publishedInfo?.slug ?? _data.slug).trim();
      final editToken = _publishedInfo?.editToken;
      if (slug.isEmpty) {
        throw 'Silinecek vitrin bilgisi bulunamadı.';
      }

      final result = await publishService.deleteStore(
        slug: slug,
        editToken: editToken,
      );
      if (result.isFailure) {
        throw result.failure!.message;
      }

      await storage.clearVitrinData();
      _data = StoreData(kategori: 'Diğer', status: 'Açık');
      _publishedInfo = null;
      _syncInitialData();
    } finally {
      setLoading(false);
    }
  }

  void addGalleryUrl(String url) {
    final item = EditorGalleryItem.fromUrl(url);
    addGalleryItem(item);
  }

  Future<void> fetchArticlesUI() async {
    final slug = _publishedInfo?.slug;
    if (slug == null) return;
    await fetchArticles(slug: slug, supabaseClient: _resolveClient());
  }

  Future<String?> publish() async {
    if (isPublishing) return null;
    setPublishing(true);
    try {
      // Kutular işaretli olsa bile version damgası yoksa yayın reddedilir
      await _stampAcceptedLegalDocuments();
      await uploadMedia(
        storeData: _data,
        uploadService: uploadService,
        publishService: publishService,
      );
      final String effectiveEditToken =
          (_publishedInfo != null && _publishedInfo!.editToken.isNotEmpty)
              ? _publishedInfo!.editToken
              : SecureTokenGenerator.generateUuid();
      final result = await publishService.publishStore(
        _data,
        editToken: effectiveEditToken,
      );
      return result.when(
        success: (publishResult) async {
          final publicLink = PublicSiteConfig.buildPublicLink(
            publishResult.publicPath,
          );
          _publishedInfo = PublishedVitrinInfo(
            publicLink: publicLink,
            slug: publishResult.slug,
            name: _data.name,
            editToken: publishResult.editToken,
          );
          _data.slug = publishResult.slug;
          await ensureRemoteStoreId();
          if (_data.products.isNotEmpty) {
            await syncCatalogToRemote(
              products: List.of(_data.products),
              categories: List.of(_data.productCategories),
            );
          }
          await saveLocally();
          // Next.js cache'ini yenile
          SeoService().revalidateStore(publishResult.slug);
          notifyListeners();
          return publicLink;
        },
        failure: (failure) => throw StorePublishException(failure.message),
      );
    } catch (e) {
      throw StorePublishException('Vitrin yayınlanamadı: $e');
    } finally {
      setPublishing(false);
    }
  }

  Future<void> saveLocally() async {
    await storage.saveVitrinData(_data);
    if (_publishedInfo != null) {
      await storage.savePublishedVitrinInfo(
        slug: _publishedInfo!.slug,
        publicLink: _publishedInfo!.publicLink,
        name: _publishedInfo!.name,
        editToken: _publishedInfo!.editToken,
      );
    }
  }

  void clearValidationErrors() {
    clearCoreErrors();
    clearLocationErrors();
  }

  Future<void> _fetchPublishedInfoFromSupabase() async {
    final client = _resolveClient();
    if (client == null) return;
    try {
      Map<String, dynamic>? response;
      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        response =
            await client
                .from('stores')
                .select('slug, name')
                .eq('user_id', userId)
                .eq('is_published', true)
                .maybeSingle();
      }

      if (response == null) {
        final localSlug =
            _data.slug.trim().isNotEmpty
                ? _data.slug.trim()
                : (await storage.loadLastPublishedSlug() ?? '').trim();
        if (localSlug.isNotEmpty) {
          response =
              await client
                  .from('stores')
                  .select('slug, name')
                  .eq('slug', localSlug)
                  .eq('is_published', true)
                  .maybeSingle();
        }
      }

      if (response == null) return;

      final slug = (response['slug'] ?? '').toString().trim();
      if (slug.isEmpty) return;

      final editToken =
          (await storage.loadVitrinEditToken())?.trim() ??
          (await storage.loadStoreEditToken())?.trim() ??
          '';

      _publishedInfo = PublishedVitrinInfo(
        publicLink: PublicSiteConfig.buildVitrinLink(slug),
        slug: slug,
        name: (response['name'] ?? '').toString(),
        editToken: editToken,
      );
      await saveLocally();
    } catch (e) {
      if (kDebugMode) debugPrint('_fetchPublishedInfoFromSupabase: $e');
    }
  }
}
