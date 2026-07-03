import 'dart:typed_data';
import 'package:flutter/material.dart';
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

  /// Yeni fotoğraf ekleme (cihazdan seçim)
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

  /// Var olan URL'den (DB'den gelen)
  factory EditorGalleryItem.fromUrl(String url, {String? id}) {
    return EditorGalleryItem._(
      id: id ?? url,
      imageUrl: url,
    );
  }

  /// StoreGalleryItem'dan
  factory EditorGalleryItem.fromStoreItem(StoreGalleryItem item) {
    return EditorGalleryItem._(
      id: item.id,
      imageUrl: item.imageUrl,
    );
  }

  /// Kaldırma işareti
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

  /// Kapak fotoğrafı kontrolü
  bool get isFromUrl => imageUrl != null && imageUrl!.isNotEmpty;
  bool get isFromBytes => bytes != null;
  bool get isEmpty => !isFromUrl && !isFromBytes;
}

class StoreEditorController extends ChangeNotifier {
  final StoreData _data;
  StorePublishedInfo? _publishedInfo;
  bool _isLoading = false;

  // Kapak Fotoğrafı
  Uint8List? _coverBytes;
  String? _coverFileName;
  String? _coverUrl;

  // Galeri
  List<EditorGalleryItem> _editorGalleryItems = [];
  int _maxGalleryPhotos = AppConstants.maxGalleryPhotos;

  // Validation hataları
  String? _nameError;
  String? _whatsappError;
  String? _provinceError;
  String? _districtError;
  String? _addressError;
  String? _googleLinkError;
  String? _legalDocumentsError;

  // Publishing durumu
  bool _isPublishing = false;
  bool _isLoadingLegalDocuments = false;
  dynamic _legalDocuments;

  // Booking durumu
  bool _bookingIsEnabled = false;
  int _bookingCapacity = 0;
  List<String> _bookingWorkingHours = [];
  String? _bookingLunchBreak;

  // Marketplace
  final Set<String> _customPlatformLinkIds = {};

  StoreEditorController(this._data) {
    _initialize();
  }

  StoreData get data => _data;
  StorePublishedInfo? get publishedInfo => _publishedInfo;
  bool get isLoading => _isLoading;
  int get maxGalleryPhotos => _maxGalleryPhotos;

  // ═══════════════════════════════════════════════════════════════════
  // KAPAK FOTOĞRAFI
  // ═══════════════════════════════════════════════════════════════════
  Uint8List? get coverBytes => _coverBytes;
  String? get coverFileName => _coverFileName;
  String? get coverUrl => _coverUrl;
  String? get coverUrlOrNull => _coverUrl;
  bool get hasCover => _coverBytes != null || (_coverUrl != null && _coverUrl!.isNotEmpty);

  // ═══════════════════════════════════════════════════════════════════
  // GALERİ
  // ═══════════════════════════════════════════════════════════════════
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

  // ═══════════════════════════════════════════════════════════════════
  // İŞLETME ADI
  // ═══════════════════════════════════════════════════════════════════
  String get currentName => _data.name;
  String? get nameError => _nameError;

  void setName(String name) {
    _data.name = name;
    notifyListeners();
  }

  void updateName(String name) => setName(name);

  // ═══════════════════════════════════════════════════════════════════
  // KATEGORİ
  // ═══════════════════════════════════════════════════════════════════
  String get selectedKategori => _data.kategori;

  void selectCategory(String kategori) {
    _data.kategori = kategori;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  // AÇIKLAMA
  // ═══════════════════════════════════════════════════════════════════
  String get currentDescription => _data.description;

  void setDescription(String description) {
    _data.description = description;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  // WHATSAPP
  // ═══════════════════════════════════════════════════════════════════
  String get currentWhatsapp => _data.whatsapp;
  String? get whatsappError => _whatsappError;

  void updateWhatsapp(String w) {
    _data.whatsapp = w;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  // KONUM / PROVİNS / İLÇE
  // ═══════════════════════════════════════════════════════════════════
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

  // ═══════════════════════════════════════════════════════════════════
  // DURUM (STATUS)
  // ═══════════════════════════════════════════════════════════════════
  String get selectedStatus => _data.status;

  void selectStatus(String status) {
    _data.status = status;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  // YAYINLAMA (PUBLISHING)
  // ═══════════════════════════════════════════════════════════════════
  bool get isPublishing => _isPublishing;
  bool get isLegalPublishReady =>
      _data.privacyNoticeAcknowledged &&
      _data.termsAccepted &&
      _data.publicationConsentAccepted;
  bool get isLoadingLegalDocuments => _isLoadingLegalDocuments;
  dynamic get legalDocuments => _legalDocuments;
  String? get legalDocumentsError => _legalDocumentsError;

  /// GERÇEK PUBLISH: StorePublishService.publishStore() çağırır
  Future<String?> publish() async {
    if (_isPublishing) return null;
    _isPublishing = true;
    notifyListeners();

    try {
      // Controller'daki değişiklikleri StoreData'ya uygula
      final dataToPublish = applyChangesToData();
      final editToken = _publishedInfo?.editToken ?? dataToPublish.slug;

      final service = StorePublishService();
      final result = await service.publishStore(
        dataToPublish,
        editToken: editToken,
      );

      // Public link oluştur
      final publicLink = 'https://vitrinx.app${result.publicPath}';

      _publishedInfo = StorePublishedInfo(
        publicLink: publicLink,
        slug: result.slug,
        editToken: editToken,
        isComplete: true,
      );

      notifyListeners();
      return publicLink;
    } on StorePublishException {
      rethrow;
    } catch (e) {
      throw StorePublishException('Vitrin yayınlanamadı: $e');
    } finally {
      _isPublishing = false;
      notifyListeners();
    }
  }

  /// Yayınlama rızasını geri çek
  Future<void> withdrawPublicationConsent() async {
    final slug = _publishedInfo?.slug ?? _data.slug;
    final editToken = _publishedInfo?.editToken ?? '';

    if (slug.isEmpty || editToken.isEmpty) {
      throw const StorePublishException(
        'Yayındaki vitrin bilgileri eksik.',
      );
    }

    final service = StorePublishService();
    await service.withdrawPublicationConsent(
      slug: slug,
      editToken: editToken,
    );

    _data.publicationConsentAccepted = false;
    _data.publicationConsentWithdrawnAt = DateTime.now();
    notifyListeners();
  }

  /// Vitrini sil (henüz implemente edilmedi)
  Future<void> deleteVitrin() async {
    throw const StorePublishException(
      'Vitrin silme henüz desteklenmiyor.',
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // YASAL ONAYLAR (LEGAL CONSENT)
  // ═══════════════════════════════════════════════════════════════════
  bool get privacyNoticeAcknowledged => _data.privacyNoticeAcknowledged;
  bool get termsAccepted => _data.termsAccepted;
  bool get publicationConsentAccepted => _data.publicationConsentAccepted;

  void setPrivacyNoticeAcknowledged(bool v) {
    _data.privacyNoticeAcknowledged = v;
    notifyListeners();
  }

  void setTermsAccepted(bool v) {
    _data.termsAccepted = v;
    notifyListeners();
  }

  void setPublicationConsentAccepted(bool v) {
    _data.publicationConsentAccepted = v;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  // RANDEVU / BOOKING (sadece Kuaför)
  // ═══════════════════════════════════════════════════════════════════
  bool get bookingIsEnabled => _bookingIsEnabled;
  int get bookingCapacity => _bookingCapacity;
  List<String> get bookingWorkingHours => _bookingWorkingHours;
  String? get bookingLunchBreak => _bookingLunchBreak;
  List<StoreOffering> get offerings => _data.offerings;

  void setBookingIsEnabled(bool v) {
    _bookingIsEnabled = v;
    notifyListeners();
  }

  void setBookingCapacity(int v) {
    _bookingCapacity = v;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  // MARKETPLACE LİNKLER
  // ═══════════════════════════════════════════════════════════════════
  List<MarketplaceLink> get marketplaceLinks => _data.marketplaceLinks;
  Set<String> get customPlatformLinkIds => _customPlatformLinkIds;

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

  void toggleCustomPlatformLinkId(String id, bool isCustom) {
    if (isCustom) {
      _customPlatformLinkIds.add(id);
    } else {
      _customPlatformLinkIds.remove(id);
    }
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  // GOOGLE BUSINESS
  // ═══════════════════════════════════════════════════════════════════
  String? get googleLinkError => _googleLinkError;

  void updateGoogleBusinessLink(String v) {
    _data.googleBusinessLink = v;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  // ÜRÜN / HİZMET
  // ═══════════════════════════════════════════════════════════════════
  List<Product> get products => _data.products;
  bool get hasProducts => _data.products.isNotEmpty;

  void addProduct(Product product) {
    _data.products.add(product);
    notifyListeners();
  }

  void removeProduct(int index) {
    if (index >= 0 && index < _data.products.length) {
      _data.products.removeAt(index);
      notifyListeners();
    }
  }

  void updateProduct(int index, Product product) {
    if (index >= 0 && index < _data.products.length) {
      _data.products[index] = product;
      notifyListeners();
    }
  }

  void updateProductImported() {
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  // VALIDATION
  // ═══════════════════════════════════════════════════════════════════
  void clearValidationErrors() {
    _nameError = null;
    _whatsappError = null;
    _provinceError = null;
    _districtError = null;
    _addressError = null;
    _googleLinkError = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  // KAPAK FOTOĞRAFI İŞLEMLERİ
  // ═══════════════════════════════════════════════════════════════════
  void setCoverBytes(Uint8List bytes, String fileName,
      [String? ext, String? contentType]) {
    _coverBytes = bytes;
    _coverFileName = fileName;
    _coverUrl = null;
    notifyListeners();
  }

  void setCoverUrl(String url) {
    _coverUrl = url;
    _coverBytes = null;
    _coverFileName = null;
    notifyListeners();
  }

  void clearCoverBytes() {
    _coverBytes = null;
    _coverFileName = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  // GALERİ İŞLEMLERİ
  // ═══════════════════════════════════════════════════════════════════
  void setGalleryItems(List<EditorGalleryItem> items) {
    _editorGalleryItems = items;
    notifyListeners();
  }

  void addGalleryItem(EditorGalleryItem item) {
    if (_editorGalleryItems.length < _maxGalleryPhotos) {
      _editorGalleryItems.add(item);
      notifyListeners();
    }
  }

  void removeGalleryItem(int index) {
    if (index >= 0 && index < _editorGalleryItems.length) {
      final item = _editorGalleryItems[index];
      if (item.isFromUrl) {
        _editorGalleryItems[index] = item.markRemoved();
      } else {
        _editorGalleryItems.removeAt(index);
      }
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // LOKAL KAYIT
  // ═══════════════════════════════════════════════════════════════════
  Future<void> saveLocally() async {
    // TODO: SharedPreferences'a serileştirme eklenecek
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  // GENEL
  // ═══════════════════════════════════════════════════════════════════
  void _initialize() {
    _coverUrl = _data.shelfImageUrl.isNotEmpty ? _data.shelfImageUrl : null;
    _editorGalleryItems = _data.galleryItems
        .map((item) => EditorGalleryItem.fromStoreItem(item))
        .toList();
  }

  void setPublishedInfo(StorePublishedInfo? info) {
    _publishedInfo = info;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Controller'daki tüm değişiklikleri StoreData'ya uygula
  StoreData applyChangesToData() {
    // Kapak bytes varsa - servis katmanı yükleyecek
    if (_coverUrl != null) {
      _data.coverImageUrl = _coverUrl!;
      _data.shelfImageUrl = _coverUrl!;
    }

    // Galeri güncelle
    _data.galleryItems = _editorGalleryItems
        .where((item) => !item.isRemoved)
        .map((item) {
          if (item.isFromUrl) {
            return StoreGalleryItem(
              id: item.id,
              imageUrl: item.imageUrl!,
            );
          }
          return StoreGalleryItem(id: item.id);
        })
        .toList();

    return _data;
  }

  bool get hasChanges {
    return _coverBytes != null ||
        _editorGalleryItems.any((item) => item.isRemoved || item.isFromBytes);
  }

  void reset() {
    _coverBytes = null;
    _coverFileName = null;
    _coverUrl = _data.shelfImageUrl.isNotEmpty ? _data.shelfImageUrl : null;
    _editorGalleryItems = _data.galleryItems
        .map((item) => EditorGalleryItem.fromStoreItem(item))
        .toList();
    notifyListeners();
  }
}
