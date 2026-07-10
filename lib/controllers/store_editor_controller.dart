import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/models/editor_gallery_item.dart';
import 'package:vixrex/services/store_publish_service.dart';
import 'package:vixrex/services/store_local_storage_service.dart';
import 'package:vixrex/services/seo_service.dart';
import 'package:vixrex/services/location_service.dart';
import 'package:vixrex/services/store_shelf_upload_service.dart';
import 'package:vixrex/utils/secure_token_generator.dart';

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
  final SupabaseClient? supabaseClient;

  StoreData _data;
  PublishedVitrinInfo? _publishedInfo;

  StoreEditorController({
    StoreLocalStorageService? storage,
    LocationService? locationService,
    StorePublishService? publishService,
    StoreShelfUploadService? uploadService,
    this.supabaseClient,
    StoreData? initialData,
  })  : storage = storage ?? const StoreLocalStorageService(),
        locationService = locationService ?? const LocationService(),
        publishService = publishService ?? const StorePublishService(),
        uploadService = uploadService ?? const StoreShelfUploadService(),
        _data = initialData ?? StoreData(kategori: 'Diğer', status: 'Açık') {
    _syncInitialData();
  }

  // --- Getters (UI Uyumluluğu için) ---
  StoreData get data => _data;
  PublishedVitrinInfo? get publishedInfo => _publishedInfo;

  bool get bookingIsEnabled => _data.bookingSettings?.isEnabled ?? false;
  int get bookingCapacity => _data.bookingSettings?.capacity ?? 1;
  Map<String, dynamic> get bookingWorkingHours => _data.bookingSettings?.workingHours ?? {};
  Map<String, dynamic> get bookingLunchBreak => _data.bookingSettings?.lunchBreak ?? {};
  List<StoreOffering> get offerings => _data.offerings;
  List<Product> get products => _data.products;
  bool get hasProducts => _data.products.isNotEmpty;

  String get selectedKategori => _data.kategori;
  String get selectedStatus => _data.status;

  double? get latitude => _data.latitude;
  double? get longitude => _data.longitude;
  double? get locationAccuracyMeters => _data.locationAccuracyMeters;
  String? get locationStatusMessage => null;

  String? get selectedProvinceCode => _data.provinceCode.isNotEmpty ? _data.provinceCode : null;
  String? get selectedProvinceName => _data.provinceName.isNotEmpty ? _data.provinceName : null;
  String? get selectedDistrictCode => _data.districtCode.isNotEmpty ? _data.districtCode : null;
  String? get selectedDistrictName => _data.districtName.isNotEmpty ? _data.districtName : null;

  bool get privacyNoticeAcknowledged => _data.privacyNoticeAcknowledged;
  bool get termsAccepted => _data.termsAccepted;
  bool get publicationConsentAccepted => _data.publicationConsentAccepted;
  bool get isLoadingLegalDocuments => isLoading;
  @override
  String? get legalDocumentsError => null;

  List<MarketplaceLink> get marketplaceLinks => _data.marketplaceLinks;
  Set<String> get customPlatformLinkIds => {};

  bool get isLegalPublishReady =>
      _data.privacyNoticeAcknowledged && _data.termsAccepted && _data.publicationConsentAccepted;

  bool get isWithdrawingConsent => isLoading;

  // --- Core Lifecycle ---
  void _syncInitialData() {
    setGalleryItems(_data.galleryItems.map((item) => EditorGalleryItem.fromStoreItem(item)).toList());
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

      if (_publishedInfo == null) {
        await _fetchPublishedInfoFromSupabase();
      }

      _syncInitialData();
      if (_publishedInfo != null) {
        await fetchArticles(slug: _publishedInfo!.slug, supabaseClient: _resolveClient());
      }
    } catch (e) {
      if (kDebugMode) debugPrint('StoreEditorController.initialize failed: $e');
    } finally {
      setLoading(false);
    }
  }

  SupabaseClient? _resolveClient() {
    if (supabaseClient != null) return supabaseClient;
    try { return Supabase.instance.client; } catch (_) { return null; }
  }

  // --- Delegated Methods (UI Compatibility) ---
  void setName(String name) { _data.name = name; notifyListeners(); }
  void updateName(String name) => setName(name);
  void selectCategory(String kategori) { _data.kategori = kategori; notifyListeners(); }
  void setDescription(String description) { _data.description = description; notifyListeners(); }
  void updateWhatsapp(String w) { _data.whatsapp = w; notifyListeners(); }
  void selectStatus(String status) { _data.status = status; notifyListeners(); }
  void updateGoogleBusinessLink(String v) { _data.googleBusinessLink = v; notifyListeners(); }

  void addMarketplaceLink(MarketplaceLink link) { _data.marketplaceLinks.add(link); notifyListeners(); }
  void removeMarketplaceLink(int index) {
    if (index >= 0 && index < _data.marketplaceLinks.length) {
      _data.marketplaceLinks.removeAt(index);
      notifyListeners();
    }
  }
  void toggleCustomPlatformLinkId(String id, bool val) { notifyListeners(); }

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
  void _ensureBookingSettings() { _data.bookingSettings ??= BookingSettings(); }

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

  Future<void> triggerFetchLocation() => fetchLocation(data: _data, locationService: locationService);

  void setPrivacyNoticeAcknowledged(bool v) {
    _data.privacyNoticeAcknowledged = v;
    _data.privacyNoticeAcknowledgedAt = v ? DateTime.now() : null;
    notifyListeners();
  }
  void setTermsAccepted(bool v) {
    _data.termsAccepted = v;
    _data.termsAcceptedAt = v ? DateTime.now() : null;
    notifyListeners();
  }
  void setPublicationConsentAccepted(bool v) {
    _data.publicationConsentAccepted = v;
    _data.publicationConsentAcceptedAt = v ? DateTime.now() : null;
    notifyListeners();
  }

  Future<void> addProduct(Product p) async {
    _data.products.add(p);
    notifyListeners();
    await syncProductsToSupabase(data: _data, publishService: publishService, editToken: _publishedInfo?.editToken);
  }
  Future<void> removeProduct(int i) async {
    if (i >= 0 && i < _data.products.length) {
      _data.products.removeAt(i);
      notifyListeners();
      await syncProductsToSupabase(data: _data, publishService: publishService, editToken: _publishedInfo?.editToken);
    }
  }
  Future<void> updateProduct(int i, Product p) async {
    if (i >= 0 && i < _data.products.length) {
      _data.products[i] = p;
      notifyListeners();
      await syncProductsToSupabase(data: _data, publishService: publishService, editToken: _publishedInfo?.editToken);
    }
  }
  Future<void> updateProductImported(Product product) async {
    final index = _data.products.indexWhere((p) => p.id == product.id);
    if (index >= 0) { _data.products[index] = product; }
    else { _data.products.add(product); }
    notifyListeners();
    await syncProductsToSupabase(data: _data, publishService: publishService, editToken: _publishedInfo?.editToken);
  }

  Future<void> withdrawPublicationConsent() async {
    final slug = _publishedInfo?.slug ?? _data.slug;
    final editToken = _publishedInfo?.editToken;
    if (slug.isEmpty || editToken == null) return;

    final result = await publishService.withdrawPublicationConsent(slug: slug, editToken: editToken);
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
      final slug = _publishedInfo?.slug;
      final editToken = _publishedInfo?.editToken;
      if (slug != null && editToken != null) {
        await publishService.withdrawPublicationConsent(slug: slug, editToken: editToken);
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
      await uploadMedia(storeData: _data, uploadService: uploadService, publishService: publishService);
      final String effectiveEditToken = (_publishedInfo != null && _publishedInfo!.editToken.isNotEmpty)
          ? _publishedInfo!.editToken
          : SecureTokenGenerator.generateUuid();
      final result = await publishService.publishStore(_data, editToken: effectiveEditToken);
      return result.when(
        success: (publishResult) async {
          final publicLink = 'https://vixrex.app${publishResult.publicPath}';
          _publishedInfo = PublishedVitrinInfo(
            publicLink: publicLink, slug: publishResult.slug,
            name: _data.name, editToken: publishResult.editToken,
          );
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
        slug: _publishedInfo!.slug, publicLink: _publishedInfo!.publicLink,
        name: _publishedInfo!.name, editToken: _publishedInfo!.editToken,
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
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;
      final response = await client.from('stores').select('slug, edit_token, name')
          .eq('user_id', userId).eq('is_published', true).maybeSingle();
      if (response != null) {
        _publishedInfo = PublishedVitrinInfo(
          publicLink: 'https://vixrex.app/v/${response['slug']}',
          slug: response['slug'], name: response['name'], editToken: response['edit_token'],
        );
        await saveLocally();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('_fetchPublishedInfoFromSupabase: $e');
    }
  }
}
