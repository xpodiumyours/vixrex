import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/config/app_constants.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/services/store_publish_service.dart';
import 'package:vitrinx/utils/image_helper.dart';

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
  final StoreData _data;
  StorePublishedInfo? _publishedInfo;
  bool _isLoading = false;

  Uint8List? _coverBytes;
  String? _coverFileName;
  String? _coverUrl;

  List<EditorGalleryItem> _editorGalleryItems = [];
  int _maxGalleryPhotos = AppConstants.maxGalleryPhotos;

  String? _nameError;
  String? _whatsappError;
  String? _provinceError;
  String? _districtError;
  String? _addressError;
  String? _googleLinkError;
  String? _legalDocumentsError;

  bool _isPublishing = false;
  bool _isLoadingLegalDocuments = false;
  dynamic _legalDocuments;

  bool _bookingIsEnabled = false;
  int _bookingCapacity = 0;
  List<String> _bookingWorkingHours = [];
  String? _bookingLunchBreak;

  final Set<String> _customPlatformLinkIds = {};

  StoreEditorController(this._data) {
    _initialize();
  }

  StoreData get data => _data;
  StorePublishedInfo? get publishedInfo => _publishedInfo;
  bool get isLoading => _isLoading;
  int get maxGalleryPhotos => _maxGalleryPhotos;

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
  String get selectedProvinceCode => _data.provinceCode;
  String get selectedProvinceName => _data.provinceName;
  String get selectedDistrictCode => _data.districtCode;
  String get selectedDistrictName => _data.districtName;
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
    final client = Supabase.instance.client;
    await client.storage.from(bucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );
    return client.storage.from(bucket).getPublicUrl(path);
  }

  /// Tüm yeni medyalari (kapak + galeri) upload et ve StoreData'ya URL'leri yaz
  Future<void> _uploadPendingMedia() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw const StorePublishException('Oturum acik degil.');

    final storeSlug = _data.slug.isNotEmpty
        ? _data.slug
        : _data.name.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '-');
    final ts = DateTime.now().millisecondsSinceEpoch;

    // 1. Kapak upload
    if (_coverBytes != null && _coverFileName != null) {
      final ext = (_coverFileName!.split('.').lastOrNull ?? 'jpg').toLowerCase();
      final mime = ext == 'png' ? 'image/png' : ext == 'webp' ? 'image/webp' : 'image/jpeg';
      final path = 'covers/$userId/${storeSlug}_cover_$ts.$ext';
      final url = await _uploadMedia(bucket: 'store-images', path: path, bytes: _coverBytes!, contentType: mime);
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
    _isPublishing = true;
    notifyListeners();

    try {
      await _uploadPendingMedia();

      // Guncelleme modu: mevcut editToken'i koru
      // Ilk yayin: slug'i editToken olarak kullan
      final String effectiveEditToken;
      final bool isUpdate = _publishedInfo != null && _publishedInfo!.editToken.isNotEmpty;
      if (isUpdate) {
        effectiveEditToken = _publishedInfo!.editToken;
      } else {
        effectiveEditToken = _data.slug.isNotEmpty
            ? _data.slug
            : _data.name.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '-');
      }

      final service = StorePublishService();
      final result = await service.publishStore(_data, editToken: effectiveEditToken);
      final publicLink = 'https://vitrinx.app${result.publicPath}';

      _publishedInfo = StorePublishedInfo(
        publicLink: publicLink,
        slug: result.slug,
        editToken: effectiveEditToken,
        isComplete: true,
      );

      await saveLocally();
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

  /// Yayinlama rızasını geri cek
  /// editToken ve slug ayrı degerler - editToken auth icin, slug public path icin
  Future<void> withdrawPublicationConsent() async {
    final slug = _publishedInfo?.slug ?? _data.slug;
    final editToken = _publishedInfo?.editToken;

    if (slug.isEmpty || editToken == null || editToken.isEmpty) {
      throw const StorePublishException(
        'Yayindaki vitrin bilgileri eksik. Lutfen once vitrininizi yayinlayin.',
      );
    }

    final service = StorePublishService();
    await service.withdrawPublicationConsent(slug: slug, editToken: editToken);
    _data.publicationConsentAccepted = false;
    _data.publicationConsentWithdrawnAt = DateTime.now();
    notifyListeners();
  }

  Future<void> deleteVitrin() async {
    throw const StorePublishException('Vitrin silme henuz desteklenmiyor.');
  }

  // YASAL ONAYLAR
  bool get privacyNoticeAcknowledged => _data.privacyNoticeAcknowledged;
  bool get termsAccepted => _data.termsAccepted;
  bool get publicationConsentAccepted => _data.publicationConsentAccepted;

  void setPrivacyNoticeAcknowledged(bool v) { _data.privacyNoticeAcknowledged = v; notifyListeners(); }
  void setTermsAccepted(bool v) { _data.termsAccepted = v; notifyListeners(); }
  void setPublicationConsentAccepted(bool v) { _data.publicationConsentAccepted = v; notifyListeners(); }

  // BOOKING
  bool get bookingIsEnabled => _bookingIsEnabled;
  int get bookingCapacity => _bookingCapacity;
  List<String> get bookingWorkingHours => _bookingWorkingHours;
  String? get bookingLunchBreak => _bookingLunchBreak;
  List<StoreOffering> get offerings => _data.offerings;
  void setBookingIsEnabled(bool v) { _bookingIsEnabled = v; notifyListeners(); }
  void setBookingCapacity(int v) { _bookingCapacity = v; notifyListeners(); }

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
    if (isCustom) _customPlatformLinkIds.add(id); else _customPlatformLinkIds.remove(id);
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
  void updateProductImported() { notifyListeners(); }

  // VALIDATION - DUZELTME: _legalDocumentsError de temizleniyor
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
    _coverUrl = url; _coverBytes = null; _coverFileName = null; notifyListeners();
  }
  void clearCoverBytes() { _coverBytes = null; _coverFileName = null; notifyListeners(); }

  // GALERI ISLEMLERI
  void setGalleryItems(List<EditorGalleryItem> items) { _editorGalleryItems = items; notifyListeners(); }
  void addGalleryItem(EditorGalleryItem item) {
    if (_editorGalleryItems.length < _maxGalleryPhotos) { _editorGalleryItems.add(item); notifyListeners(); }
  }
  void removeGalleryItem(int index) {
    if (index >= 0 && index < _editorGalleryItems.length) {
      final item = _editorGalleryItems[index];
      if (item.isFromUrl) { _editorGalleryItems[index] = item.markRemoved(); }
      else { _editorGalleryItems.removeAt(index); }
      notifyListeners();
    }
  }

  // LOKAL KAYIT (SharedPreferences)
  static const _prefsKey = 'store_editor_data';

  Future<void> saveLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_data.toJson()));
    } catch (e) { debugPrint('saveLocally error: $e'); }
    notifyListeners();
  }

  static Future<StoreData?> loadLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString(_prefsKey);
      if (s == null || s.isEmpty) return null;
      return StoreData.fromJson(jsonDecode(s));
    } catch (e) { debugPrint('loadLocalData error: $e'); return null; }
  }

  // GENEL
  void _initialize() {
    _coverUrl = _data.shelfImageUrl.isNotEmpty ? _data.shelfImageUrl : null;
    _editorGalleryItems = _data.galleryItems.map((item) => EditorGalleryItem.fromStoreItem(item)).toList();
  }

  void setPublishedInfo(StorePublishedInfo? info) { _publishedInfo = info; notifyListeners(); }
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
