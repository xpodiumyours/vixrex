import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/config/app_constants.dart';
import 'package:vitrinx/config/turkey_cities_config.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/services/store_publish_service.dart';
import 'package:vitrinx/services/store_local_storage_service.dart';
import 'package:vitrinx/services/location_service.dart';
import 'package:vitrinx/services/store_shelf_upload_service.dart';
import 'package:vitrinx/utils/secure_token_generator.dart';

class EditorGalleryItem {
  final String id;
  final Uint8List? bytes;
  final String? imageUrl;
  final String? extension;
  final String? contentType;
  final int? originalWidth;
  final int? originalHeight;
  final bool isRemoved;

  const EditorGalleryItem._({
    required this.id,
    this.bytes,
    this.imageUrl,
    this.extension,
    this.contentType,
    this.originalWidth,
    this.originalHeight,
    this.isRemoved = false,
  });

  factory EditorGalleryItem.fromBytes({
    required String id,
    required Uint8List bytes,
    required String extension,
    required String contentType,
    int? originalWidth,
    int? originalHeight,
  }) {
    return EditorGalleryItem._(
      id: id,
      bytes: bytes,
      extension: extension,
      contentType: contentType,
      originalWidth: originalWidth,
      originalHeight: originalHeight,
    );
  }

  factory EditorGalleryItem.fromUrl(String url, {String? id}) {
    return EditorGalleryItem._(
      id: id ?? url,
      imageUrl: url,
    );
  }

  factory EditorGalleryItem.fromStoreItem(StoreGalleryItem item) {
    return EditorGalleryItem._(
      id: item.id,
      imageUrl: item.imageUrl,
    );
  }

  EditorGalleryItem markRemoved() {
    return EditorGalleryItem._(
      id: id,
      bytes: bytes,
      imageUrl: imageUrl,
      extension: extension,
      contentType: contentType,
      originalWidth: originalWidth,
      originalHeight: originalHeight,
      isRemoved: true,
    );
  }

  bool get isFromUrl => imageUrl != null && imageUrl!.isNotEmpty;
  bool get isFromBytes => bytes != null;
  bool get isEmpty => !isFromUrl && !isFromBytes;
}

class StoreEditorController extends ChangeNotifier {
  final StoreLocalStorageService storage;
  final LocationService locationService;
  final StorePublishService publishService;
  final StoreShelfUploadService uploadService;
  final SupabaseClient? supabaseClient;

  StoreData _data;
  PublishedVitrinInfo? _publishedInfo;
  bool _isLoading = false;

  Uint8List? _coverBytes;
  String? _coverFileName;
  String? _coverUrl;

  List<EditorGalleryItem> _editorGalleryItems = [];
  final int _maxGalleryPhotos = AppConstants.maxGalleryPhotos;

  String? _nameError;
  String? _whatsappError;
  String? _provinceError;
  String? _districtError;
  String? _addressError;
  String? _googleLinkError;
  String? _legalDocumentsError;

  bool _isPublishing = false;
  final bool _isLoadingLegalDocuments = false;
  dynamic _legalDocuments;

  final Set<String> _customPlatformLinkIds = {};

  List<Map<String, dynamic>> _articles = [];
  bool _isLoadingArticles = false;

  bool _isWithdrawingConsent = false;
  bool _isDeleting = false;

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
    _initialize();
  }

  StoreData get data => _data;
  PublishedVitrinInfo? get publishedInfo => _publishedInfo;
  bool get isLoading => _isLoading;
  int get maxGalleryPhotos => _maxGalleryPhotos;

  bool get bookingIsEnabled => _data.bookingSettings?.isEnabled ?? false;
  int get bookingCapacity => _data.bookingSettings?.capacity ?? 1;
  Map<String, dynamic> get bookingWorkingHours => _data.bookingSettings?.workingHours ?? {};
  Map<String, dynamic> get bookingLunchBreak => _data.bookingSettings?.lunchBreak ?? {};
  List<StoreOffering> get offerings => _data.offerings;

  List<Map<String, dynamic>> get articles => _articles;
  bool get isLoadingArticles => _isLoadingArticles;

  bool get isWithdrawingConsent => _isWithdrawingConsent;
  bool get isDeleting => _isDeleting;

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

  void _ensureBookingSettings() {
    _data.bookingSettings ??= BookingSettings();
  }

  Future<void> initialize(String? initialName) async {
    _isLoading = true;
    notifyListeners();
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

      // Eger local'de publishedInfo yoksa, Supabase'den mevcut vitrini cek
      if (_publishedInfo == null) {
        await _fetchPublishedInfoFromSupabase();
      }

      _initialize();
      if (_publishedInfo != null) {
        await fetchArticles();
      }
    } catch (_) {} finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Supabase'den mevcut yayinlanmis vitrini cek ve _publishedInfo'yu doldur
  Future<void> _fetchPublishedInfoFromSupabase() async {
    try {
      final client = _resolveClient();
      if (client == null) return;

      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      // Son yayinlanmis vitrini cek
      final response = await client
          .from('stores')
          .select('slug, edit_token, name')
          .eq('user_id', userId)
          .eq('is_published', true)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final slug = (response['slug'] as String?)?.trim() ?? '';
        final editToken = (response['edit_token'] as String?)?.trim() ?? '';
        final name = (response['name'] as String?)?.trim() ?? '';

        if (slug.isNotEmpty && editToken.isNotEmpty) {
          _publishedInfo = PublishedVitrinInfo(
            publicLink: 'https://vitrinx.app/v/$slug',
            slug: slug,
            name: name,
            editToken: editToken,
          );
          // Local storage'a da kaydet
          await storage.savePublishedVitrinInfo(
            slug: slug,
            publicLink: 'https://vitrinx.app/v/$slug',
            name: name,
            editToken: editToken,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> fetchLocation() async {
    final result = await locationService.getCurrentLocation();
    if (result.isSuccess && result.position != null) {
      final pos = result.position!;
      _data.latitude = pos.latitude;
      _data.longitude = pos.longitude;
      _data.locationAccuracyMeters = pos.accuracy;
      _data.locationSource = 'device';
      _data.locationConsentAt = DateTime.now();

      final address = await locationService.getAddressFromCoordinates(pos.latitude, pos.longitude);
      if (address != null && address.trim().isNotEmpty) {
        _data.address = address;
        for (final province in turkeyProvinces) {
          if (address.toLowerCase().contains(province.name.toLowerCase())) {
            _data.provinceCode = province.code;
            _data.provinceName = province.name;
            final districts = turkeyDistricts[province.code];
            if (districts != null) {
              for (final district in districts) {
                if (address.toLowerCase().contains(district.toLowerCase())) {
                  _data.districtCode = district;
                  _data.districtName = district;
                  break;
                }
              }
            }
            break;
          }
        }
      }
      notifyListeners();
    }
  }

  void updateAddress(String address) {
    _data.address = address;
    notifyListeners();
  }

  SupabaseClient? _resolveClient() {
    if (supabaseClient != null) return supabaseClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchArticles() async {
    final slug = _publishedInfo?.slug;
    if (slug == null || slug.trim().isEmpty) return;

    _isLoadingArticles = true;
    notifyListeners();
    try {
      final client = _resolveClient();
      if (client == null) {
        _articles = [];
        return;
      }
      final response = await client
          .from('store_articles')
          .select()
          .eq('store_slug', slug)
          .order('created_at', ascending: false);
      _articles = List<Map<String, dynamic>>.from(response as List);
    } catch (_) {
      _articles = [];
    } finally {
      _isLoadingArticles = false;
      notifyListeners();
    }
  }

  // KAPAK
  Uint8List? get coverBytes => _coverBytes;
  String? get coverFileName => _coverFileName;
  String? get coverUrl => _coverUrl;
  String? get coverUrlOrNull => _coverUrl;
  bool get hasCover => _coverBytes != null || (_coverUrl != null && _coverUrl!.isNotEmpty);

  // GALERI
  List<EditorGalleryItem> get editorGalleryItems => _editorGalleryItems;
  List<EditorGalleryItem> get galleryItems => _editorGalleryItems;
  List<EditorGalleryItem> get activeGalleryItems =>
      _editorGalleryItems.where((item) => !item.isRemoved).toList();
  List<String> get removedGalleryUrls => _editorGalleryItems
      .where((item) => item.isRemoved && item.imageUrl != null)
      .map((item) => item.imageUrl!)
      .toList();
  List<String> get galleryPhotoUrls => _editorGalleryItems
      .where((item) => item.imageUrl != null && !item.isRemoved)
      .map((item) => item.imageUrl!)
      .toList();

  // ISIM
  String get currentName => _data.name;
  String? get nameError => _nameError;
  void setName(String name) { _data.name = name; notifyListeners(); }
  void updateName(String name) => setName(name);

  // KATEGORI
  String get selectedKategori => _data.kategori;
  void selectCategory(String kategori) { _data.kategori = kategori; notifyListeners(); }

  // ACIKLAMA
  String get currentDescription => _data.description;
  void setDescription(String description) { _data.description = description; notifyListeners(); }

  // WHATSAPP
  String get currentWhatsapp => _data.whatsapp;
  String? get whatsappError => _whatsappError;
  void updateWhatsapp(String w) { _data.whatsapp = w; notifyListeners(); }

  // KONUM
  String? get selectedProvinceCode => _data.provinceCode.isNotEmpty ? _data.provinceCode : null;
  String? get selectedProvinceName => _data.provinceName.isNotEmpty ? _data.provinceName : null;
  String? get selectedDistrictCode => _data.districtCode.isNotEmpty ? _data.districtCode : null;
  String? get selectedDistrictName => _data.districtName.isNotEmpty ? _data.districtName : null;
  double? get latitude => _data.latitude;
  double? get longitude => _data.longitude;
  double? get locationAccuracyMeters => _data.locationAccuracyMeters;
  String? get locationStatusMessage => null;
  bool get isLocating => false;
  String? get provinceError => _provinceError;
  String? get districtError => _districtError;
  String? get addressError => _addressError;

  void selectProvince(String? code, String? name) {
    _data.provinceCode = code ?? '';
    _data.provinceName = name ?? '';
    notifyListeners();
  }

  void selectDistrict(String? code, String? name) {
    _data.districtCode = code ?? '';
    _data.districtName = name ?? '';
    notifyListeners();
  }

  // DURUM
  String get selectedStatus => _data.status;
  void selectStatus(String status) { _data.status = status; notifyListeners(); }

  // PUBLISHING
  bool get isPublishing => _isPublishing;
  bool get isLegalPublishReady =>
      _data.privacyNoticeAcknowledged && _data.termsAccepted && _data.publicationConsentAccepted;
  bool get isLoadingLegalDocuments => _isLoadingLegalDocuments;
  dynamic get legalDocuments => _legalDocuments;
  String? get legalDocumentsError => _legalDocumentsError;

  /// Medya upload: Supabase Storage -> public URL
  Future<String> _uploadMedia({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final client = _resolveClient();
    if (client == null) throw const StorePublishException('Supabase bağlı değil.');
    await client.storage.from(bucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );
    return client.storage.from(bucket).getPublicUrl(path);
  }

  Future<void> _uploadPendingMedia() async {
    final hasPendingCover = _coverBytes != null && _coverFileName != null;
    final hasPendingGallery = _editorGalleryItems.any((item) => !item.isRemoved && item.isFromBytes && item.bytes != null);
    if (!hasPendingCover && !hasPendingGallery) {
      return;
    }

    final client = _resolveClient();
    if (client == null) throw const StorePublishException('Supabase bağlı değil.');
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw const StorePublishException('Oturum acik degil.');

    final storeSlug = _data.slug.isNotEmpty
        ? _data.slug
        : publishService.payloadBuilder.generateSlug(_data.name);
    final ts = DateTime.now().millisecondsSinceEpoch;

    // 1. Kapak upload
    if (_coverBytes != null && _coverFileName != null) {
      final ext = (_coverFileName!.split('.').lastOrNull ?? 'jpg').toLowerCase();
      final mime = ext == 'png' ? 'image/png' : ext == 'webp' ? 'image/webp' : 'image/jpeg';
      final url = await uploadService.uploadShelfImage(_coverBytes!, storeSlug, fileExtension: ext, contentType: mime);
      _data.coverImageUrl = url;
      _data.shelfImageUrl = url;
      _coverUrl = url;
      _coverBytes = null;
    }

    // 2. Galeri upload
    final updatedGallery = <StoreGalleryItem>[];
    var gi = 0;
    for (final item in _editorGalleryItems) {
      if (item.isRemoved) continue;
      if (item.isFromBytes && item.bytes != null) {
        final ext = (item.extension ?? 'jpg').toLowerCase();
        final mime = item.contentType ?? (ext == 'png' ? 'image/png' : ext == 'webp' ? 'image/webp' : 'image/jpeg');
        final path = 'gallery/$userId/${storeSlug}_gallery_${ts}_$gi.$ext';
        final url = await _uploadMedia(bucket: 'store-images', path: path, bytes: item.bytes!, contentType: mime);
        updatedGallery.add(StoreGalleryItem(id: item.id, imageUrl: url, title: 'Galeri ${gi + 1}'));
        gi++;
      } else if (item.isFromUrl && item.imageUrl != null && item.imageUrl!.isNotEmpty) {
        updatedGallery.add(StoreGalleryItem(id: item.id, imageUrl: item.imageUrl!));
      }
    }
    if (updatedGallery.isNotEmpty) {
      _data.galleryItems = updatedGallery;
      _editorGalleryItems = updatedGallery.map((i) => EditorGalleryItem.fromStoreItem(i)).toList();
    }
  }

  /// GERCEK PUBLISH: Medya upload -> StorePublishService -> public link
  /// editToken/slug ayrimi: guncelleme modu vs ilk yayin
  Future<String?> publish() async {
    if (_isPublishing) return null;

    // Misafir modda publish icin giris zorunlu
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw const StorePublishException(
          'Vitrinizi yayınlamak için lütfen giriş yapın veya hesap oluşturun.',
        );
      }
    } catch (e) {
      if (e is StorePublishException) rethrow;
      // Supabase bagli degilse bile devam et (test ortami)
    }

    _isPublishing = true;
    notifyListeners();

    try {
      await _uploadPendingMedia();

      // Guncelleme modu: mevcut editToken'i koru
      // Ilk yayin: UUID uret (slug 24 karakter minimumunu karsilamaz)
      final String effectiveEditToken;
      final bool isUpdate = _publishedInfo != null && _publishedInfo!.editToken.isNotEmpty;
      if (isUpdate) {
        effectiveEditToken = _publishedInfo!.editToken;
      } else {
        effectiveEditToken = SecureTokenGenerator.generateUuid();
      }

      final result = await publishService.publishStore(_data, editToken: effectiveEditToken);
      final publicLink = 'https://vitrinx.app${result.publicPath}';

      _publishedInfo = PublishedVitrinInfo(
        publicLink: publicLink,
        slug: result.slug,
        name: _data.name,
        editToken: result.editToken,
      );

      await saveLocally();

      // Explicitly save editToken to local storage so it persists
      await storage.savePublishedVitrinInfo(
        slug: result.slug,
        publicLink: publicLink,
        name: _data.name,
        editToken: result.editToken,
      );
      notifyListeners();
      return publicLink;
    } on StorePublishException {
      rethrow;
    } catch (e) {
      throw StorePublishException('Vitrin yayinlanamadi: $e');
    } finally {
      _isPublishing = false;
      notifyListeners();
    }
  }

  /// Yayinlama rizasini geri cek
  /// editToken ve slug ayrı degerler - editToken auth icin, slug public path icin
  Future<void> withdrawPublicationConsent() async {
    final slug = _publishedInfo?.slug ?? _data.slug;
    final editToken = _publishedInfo?.editToken;

    if (slug.isEmpty || editToken == null || editToken.isEmpty) {
      throw const StorePublishException(
        'Yayindaki vitrin bilgileri eksik. Lutfen once vitrininizi yayinlayin.',
      );
    }

    _isWithdrawingConsent = true;
    notifyListeners();
    try {
      await publishService.withdrawPublicationConsent(slug: slug, editToken: editToken);
      await storage.clearPublishedVitrinInfo();
      _publishedInfo = null;
      _data.publicationConsentAccepted = false;
      _data.publicationConsentWithdrawnAt = DateTime.now();
      await storage.saveVitrinData(_data);
    } finally {
      _isWithdrawingConsent = false;
      notifyListeners();
    }
  }

  Future<void> deleteVitrin() async {
    _isDeleting = true;
    notifyListeners();
    try {
      final slug = _publishedInfo?.slug;
      final editToken = _publishedInfo?.editToken;
      if (slug != null && editToken != null) {
        try {
          await publishService.withdrawPublicationConsent(slug: slug, editToken: editToken);
        } catch (_) {}
      }
      await storage.clearVitrinData();
      _data = StoreData(
        name: '',
        kategori: 'Diğer',
        status: 'Açık',
        isStore: false,
      );
      _publishedInfo = null;
      _initialize();
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  // YASAL ONAYLAR
  bool get privacyNoticeAcknowledged => _data.privacyNoticeAcknowledged;
  bool get termsAccepted => _data.termsAccepted;
  bool get publicationConsentAccepted => _data.publicationConsentAccepted;

  void setPrivacyNoticeAcknowledged(bool v) {
    _data.privacyNoticeAcknowledged = v;
    if (v) {
      _data.privacyNoticeVersion = '1.0';
      _data.privacyNoticeHash = 'acknowledged';
      _data.privacyNoticeAcknowledgedAt = DateTime.now();
    } else {
      _data.privacyNoticeVersion = '';
      _data.privacyNoticeHash = '';
      _data.privacyNoticeAcknowledgedAt = null;
    }
    notifyListeners();
  }

  void setTermsAccepted(bool v) {
    _data.termsAccepted = v;
    if (v) {
      _data.termsVersion = '1.0';
      _data.termsHash = 'accepted';
      _data.termsAcceptedAt = DateTime.now();
    } else {
      _data.termsVersion = '';
      _data.termsHash = '';
      _data.termsAcceptedAt = null;
    }
    notifyListeners();
  }

  void setPublicationConsentAccepted(bool v) {
    _data.publicationConsentAccepted = v;
    if (v) {
      _data.publicationConsentVersion = '1.0';
      _data.publicationConsentHash = 'consented';
      _data.publicationConsentAcceptedAt = DateTime.now();
    } else {
      _data.publicationConsentVersion = '';
      _data.publicationConsentHash = '';
      _data.publicationConsentAcceptedAt = null;
    }
    notifyListeners();
  }

  // MARKETPLACE
  List<MarketplaceLink> get marketplaceLinks => _data.marketplaceLinks;
  Set<String> get customPlatformLinkIds => _customPlatformLinkIds;
  void addMarketplaceLink(MarketplaceLink link) { _data.marketplaceLinks.add(link); notifyListeners(); }
  void removeMarketplaceLink(int index) {
    if (index >= 0 && index < _data.marketplaceLinks.length) {
      _data.marketplaceLinks.removeAt(index);
      notifyListeners();
    }
  }
  void toggleCustomPlatformLinkId(String id, bool isCustom) {
    if (isCustom) {
      _customPlatformLinkIds.add(id);
    } else {
      _customPlatformLinkIds.remove(id);
    }
    notifyListeners();
  }

  // GOOGLE
  String? get googleLinkError => _googleLinkError;
  void updateGoogleBusinessLink(String v) { _data.googleBusinessLink = v; notifyListeners(); }

  // URUN
  List<Product> get products => _data.products;
  bool get hasProducts => _data.products.isNotEmpty;
  void addProduct(Product p) { _data.products.add(p); notifyListeners(); }
  void removeProduct(int i) { if (i >= 0 && i < _data.products.length) { _data.products.removeAt(i); notifyListeners(); } }
  void updateProduct(int i, Product p) { if (i >= 0 && i < _data.products.length) { _data.products[i] = p; notifyListeners(); } }

  void updateProductImported(Product product) {
    final index = _data.products.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _data.products[index] = product;
    } else {
      _data.products.add(product);
    }
    notifyListeners();
  }

  // VALIDATION
  void clearValidationErrors() {
    _nameError = null;
    _whatsappError = null;
    _provinceError = null;
    _districtError = null;
    _addressError = null;
    _googleLinkError = null;
    _legalDocumentsError = null;
    notifyListeners();
  }

  // KAPAK ISLEMLERI
  void setCoverBytes(Uint8List bytes, String fileName, [String? ext, String? contentType]) {
    _coverBytes = bytes; _coverFileName = fileName; _coverUrl = null; notifyListeners();
  }
  void setCoverUrl(String url) {
    _coverUrl = url;
    _coverBytes = null;
    _coverFileName = null;
    _data.shelfImageUrl = url;
    notifyListeners();
  }
  void clearCoverBytes() { _coverBytes = null; _coverFileName = null; notifyListeners(); }

  // GALERI ISLEMLERI
  void setGalleryItems(List<EditorGalleryItem> items) { _editorGalleryItems = items; notifyListeners(); }
  void addGalleryItem(EditorGalleryItem item) {
    if (_editorGalleryItems.length < _maxGalleryPhotos) { _editorGalleryItems.add(item); notifyListeners(); }
  }
  void addGalleryUrl(String url, {String? title}) {
    if (_editorGalleryItems.length >= _maxGalleryPhotos) {
      return;
    }
    final item = EditorGalleryItem.fromUrl(url);
    _editorGalleryItems.add(item);
    _data.galleryItems = _editorGalleryItems
        .where((i) => !i.isRemoved)
        .map((i) => StoreGalleryItem(
              id: i.id,
              imageUrl: i.imageUrl ?? '',
              title: title ?? '',
            ))
        .toList();
    saveLocally();
    notifyListeners();
  }
  void removeGalleryItem(int index) {
    if (index >= 0 && index < _editorGalleryItems.length) {
      final item = _editorGalleryItems[index];
      if (item.isFromUrl) { _editorGalleryItems[index] = item.markRemoved(); }
      else { _editorGalleryItems.removeAt(index); }
      notifyListeners();
    }
  }

  /// Kategori sablonundan gelen gorselleri local olarak uygular.
  /// Vitrin henuz kaydedilmemisse bu metod kullanilir.
  void applyCategoryTemplateLocal({
    String? coverImageUrl,
    List<String> galleryImageUrls = const [],
    List<Map<String, dynamic>> productTemplates = const [],
  }) {
    var hasChanges = false;

    // Kapak gorseli
    if (coverImageUrl != null && coverImageUrl.isNotEmpty) {
      setCoverUrl(coverImageUrl);
      _data.shelfImageUrl = coverImageUrl;
      hasChanges = true;
    }

    // Galeri gorselleri
    if (galleryImageUrls.isNotEmpty) {
      final currentCount = _editorGalleryItems.where((item) => !item.isRemoved).length;
      final remainingSpace = _maxGalleryPhotos - currentCount;

      if (remainingSpace > 0) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        final newItems = galleryImageUrls
            .take(remainingSpace)
            .toList()
            .asMap()
            .entries
            .map((entry) => EditorGalleryItem.fromUrl(
                  entry.value,
                  id: 'local_template_${ts}_${entry.key}',
                ))
            .toList();
        _editorGalleryItems = [..._editorGalleryItems, ...newItems];
        hasChanges = true;
      }
    }

    // Urun sablonlari
    if (productTemplates.isNotEmpty) {
      for (final template in productTemplates) {
        final name = template['name'] as String? ?? '';
        if (name.isNotEmpty) {
          _data.products.add(Product(
            id: 'local_product_${DateTime.now().millisecondsSinceEpoch}_${_data.products.length}',
            name: name,
            description: template['description'] as String? ?? '',
            price: template['price'] as String? ?? '',
            category: template['category'] as String? ?? 'Diğer',
            isVisible: true,
          ));
          hasChanges = true;
        }
      }
    }

    if (hasChanges) {
      saveLocally();
      notifyListeners();
    }
  }

  /// Yayinlanmis vitrinin galeri verisini Supabase'den senkronize eder.
  /// Auto-fill service DB'yi guncelledikten sonra controller'i senkronize etmek icin kullanilir.
  Future<void> syncGalleryFromSupabase() async {
    try {
      final slug = _publishedInfo?.slug ?? _data.slug;
      if (slug.trim().isEmpty) return;

      final client = _resolveClient();
      if (client == null) return;

      final response = await client
          .from('stores')
          .select('gallery_items, shelf_image_url')
          .eq('slug', slug)
          .maybeSingle();

      if (response == null) return;

      // Galeri items senkronizasyonu
      final rawGallery = response['gallery_items'];
      if (rawGallery != null) {
        final parsed = _parseGalleryItems(rawGallery);
        if (parsed.isNotEmpty) {
          _data.galleryItems = parsed;
          _editorGalleryItems = parsed
              .map((i) => EditorGalleryItem.fromStoreItem(i))
              .toList();
        }
      }

      // Kapak gorseli senkronizasyonu
      final shelfUrl = response['shelf_image_url'] as String?;
      if (shelfUrl != null && shelfUrl.isNotEmpty) {
        _data.shelfImageUrl = shelfUrl;
        _coverUrl = shelfUrl;
      }

      await saveLocally();
      notifyListeners();
    } catch (_) {}
  }

  /// JSON'dan gallery items parse eder
  List<StoreGalleryItem> _parseGalleryItems(Object? rawItems) {
    try {
      final decodedItems = rawItems is String ? jsonDecode(rawItems) : rawItems;
      if (decodedItems is! List) return [];
      return decodedItems
          .whereType<Map>()
          .map((item) => StoreGalleryItem.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.imageUrl.trim().isNotEmpty)
          .take(12)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // LOKAL KAYIT
  Future<void> saveLocally() async {
    try {
      await storage.saveVitrinData(_data);
      if (_publishedInfo != null) {
        await storage.savePublishedVitrinInfo(
          slug: _publishedInfo!.slug,
          publicLink: _publishedInfo!.publicLink,
          name: _publishedInfo!.name,
          editToken: _publishedInfo!.editToken,
        );
      }
    } catch (_) {}
    notifyListeners();
  }

  static Future<StoreData?> loadLocalData() async {
    final storage = const StoreLocalStorageService();
    return storage.loadVitrinData();
  }

  // GENEL
  void _initialize() {
    _coverUrl = _data.shelfImageUrl.isNotEmpty ? _data.shelfImageUrl : null;
    _editorGalleryItems = _data.galleryItems.map((item) => EditorGalleryItem.fromStoreItem(item)).toList();
  }

  void setPublishedInfo(PublishedVitrinInfo? info) { _publishedInfo = info; notifyListeners(); }
  void setLoading(bool value) { _isLoading = value; notifyListeners(); }

  StoreData applyChangesToData() {
    if (_coverUrl != null) { _data.coverImageUrl = _coverUrl!; _data.shelfImageUrl = _coverUrl!; }
    _data.galleryItems = _editorGalleryItems.where((item) => !item.isRemoved).map((item) {
      if (item.isFromUrl) return StoreGalleryItem(id: item.id, imageUrl: item.imageUrl!);
      return StoreGalleryItem(id: item.id);
    }).toList();
    return _data;
  }

  bool get hasChanges {
    return _coverBytes != null || _editorGalleryItems.any((item) => item.isRemoved || item.isFromBytes);
  }

  void reset() {
    _coverBytes = null; _coverFileName = null;
    _coverUrl = _data.shelfImageUrl.isNotEmpty ? _data.shelfImageUrl : null;
    _editorGalleryItems = _data.galleryItems.map((item) => EditorGalleryItem.fromStoreItem(item)).toList();
    notifyListeners();
  }
}
