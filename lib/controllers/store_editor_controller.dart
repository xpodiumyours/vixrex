import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/config/public_site_config.dart';
import 'package:vitrinx/config/turkey_cities_config.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/services/location_service.dart';
import 'package:vitrinx/services/seo_service.dart';
import 'package:vitrinx/services/store_local_storage_service.dart';
import 'package:vitrinx/services/store_publish_service.dart';
import 'package:vitrinx/services/store_shelf_upload_service.dart';
import 'package:vitrinx/utils/token_generator.dart';
import 'package:vitrinx/utils/whatsapp_link_helper.dart';
import 'editor_gallery_item.dart';

class StoreEditorController extends ChangeNotifier {
  final StoreLocalStorageService _storage;
  final LocationService _locationService;
  final StorePublishService _publishService;
  final StoreShelfUploadService _uploadService;
  final SeoService _seoService;
  final SupabaseClient? _supabaseClient;

  StoreEditorController({
    StoreLocalStorageService storage = const StoreLocalStorageService(),
    LocationService locationService = const LocationService(),
    StorePublishService publishService = const StorePublishService(),
    StoreShelfUploadService uploadService = const StoreShelfUploadService(),
    SeoService seoService = const SeoService(),
    SupabaseClient? supabaseClient,
  })  : _storage = storage,
        _locationService = locationService,
        _publishService = publishService,
        _uploadService = uploadService,
        _seoService = seoService,
        _supabaseClient = supabaseClient;

  SupabaseClient get _client => _supabaseClient ?? Supabase.instance.client;

  StoreData _data = StoreData(isEsnafMode: false, isStore: false);
  StoreData get data => _data;

  PublishedVitrinInfo? _publishedInfo;
  PublishedVitrinInfo? get publishedInfo => _publishedInfo;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isPublishing = false;
  bool get isPublishing => _isPublishing;

  bool _isDeleting = false;
  bool get isDeleting => _isDeleting;

  bool _isWithdrawingConsent = false;
  bool get isWithdrawingConsent => _isWithdrawingConsent;

  // Selected Province/District
  String? _selectedProvinceCode;
  String? get selectedProvinceCode => _selectedProvinceCode;

  String? _selectedProvinceName;
  String? get selectedProvinceName => _selectedProvinceName;

  String? _selectedDistrictCode;
  String? get selectedDistrictCode => _selectedDistrictCode;

  String? _selectedDistrictName;
  String? get selectedDistrictName => _selectedDistrictName;

  // Cover photo state
  Uint8List? _coverBytes;
  Uint8List? get coverBytes => _coverBytes;

  String? _coverUrl;
  String? get coverUrl => _coverUrl;

  String? _coverFileName;
  String? get coverFileName => _coverFileName;

  String _coverExtension = 'jpg';
  String get coverExtension => _coverExtension;

  String _coverContentType = 'image/jpeg';
  String get coverContentType => _coverContentType;

  // Gallery
  final List<EditorGalleryItem> _galleryItems = [];
  List<EditorGalleryItem> get galleryItems => _galleryItems;
  static const int _maxGalleryPhotos = 12;
  int get maxGalleryPhotos => _maxGalleryPhotos;

  // Marketplace links & Offerings
  final List<MarketplaceLink> _marketplaceLinks = [];
  List<MarketplaceLink> get marketplaceLinks => _marketplaceLinks;

  final Set<String> _customPlatformLinkIds = {};
  Set<String> get customPlatformLinkIds => _customPlatformLinkIds;

  final List<StoreOffering> _offerings = [];
  List<StoreOffering> get offerings => _offerings;

  // Location search status
  double? _latitude;
  double? get latitude => _latitude;

  double? _longitude;
  double? get longitude => _longitude;

  double? _locationAccuracyMeters;
  double? get locationAccuracyMeters => _locationAccuracyMeters;

  bool _isLocating = false;
  bool get isLocating => _isLocating;

  String? _locationStatusMessage;
  String? get locationStatusMessage => _locationStatusMessage;

  // Category / status
  String _selectedKategori = 'Diğer';
  String get selectedKategori => _selectedKategori;

  String _selectedStatus = 'Açık';
  String get selectedStatus => _selectedStatus;

  // Booking settings
  bool _bookingIsEnabled = false;
  bool get bookingIsEnabled => _bookingIsEnabled;

  int _bookingCapacity = 1;
  int get bookingCapacity => _bookingCapacity;

  Map<String, dynamic> _bookingWorkingHours = {
    '1': {'start': '09:00', 'end': '19:00', 'active': true},
    '2': {'start': '09:00', 'end': '19:00', 'active': true},
    '3': {'start': '09:00', 'end': '19:00', 'active': true},
    '4': {'start': '09:00', 'end': '19:00', 'active': true},
    '5': {'start': '09:00', 'end': '19:00', 'active': true},
    '6': {'start': '09:00', 'end': '16:00', 'active': true},
    '7': {'start': '00:00', 'end': '00:00', 'active': false},
  };
  Map<String, dynamic> get bookingWorkingHours => _bookingWorkingHours;

  Map<String, dynamic> _bookingLunchBreak = {
    'start': '12:00',
    'end': '13:00',
    'active': true,
  };
  Map<String, dynamic> get bookingLunchBreak => _bookingLunchBreak;

  // Validation Errors
  String? _nameError;
  String? get nameError => _nameError;

  String? _whatsappError;
  String? get whatsappError => _whatsappError;

  String? _addressError;
  String? get addressError => _addressError;

  String? _provinceError;
  String? get provinceError => _provinceError;

  String? _districtError;
  String? get districtError => _districtError;

  String? _googleLinkError;
  String? get googleLinkError => _googleLinkError;

  // Legal Documents
  dynamic _legalDocuments;
  dynamic get legalDocuments => _legalDocuments;

  final bool _isLoadingLegalDocuments = true;
  bool get isLoadingLegalDocuments => _isLoadingLegalDocuments;

  String? _legalDocumentsError;
  String? get legalDocumentsError => _legalDocumentsError;

  bool _privacyNoticeAcknowledged = false;
  bool get privacyNoticeAcknowledged => _privacyNoticeAcknowledged;

  bool _termsAccepted = false;
  bool get termsAccepted => _termsAccepted;

  bool _publicationConsentAccepted = false;
  bool get publicationConsentAccepted => _publicationConsentAccepted;

  // Blog Articles
  List<Map<String, dynamic>> _articles = [];
  List<Map<String, dynamic>> get articles => _articles;

  bool _isLoadingArticles = false;
  bool get isLoadingArticles => _isLoadingArticles;

  // ─── Computed ────────────────────────────────────────────────────────────

  bool get isLegalPublishReady =>
      _legalDocuments != null &&
      _privacyNoticeAcknowledged &&
      _termsAccepted &&
      _publicationConsentAccepted;

  // ─── Actions ─────────────────────────────────────────────────────────────

  Future<void> initialize(String? initialName) async {
    _isLoading = true;
    notifyListeners();
    try {
      final savedData = await _storage.loadVitrinData();
      final publishedInfo = await _storage.loadPublishedVitrinInfo();
      final data = savedData ?? StoreData(isEsnafMode: false, isStore: false);

      final name = initialName?.trim() ?? '';
      if (data.name.trim().isEmpty) {
        if (name.isNotEmpty) {
          data.name = name;
        } else if (publishedInfo?.name != null &&
            publishedInfo!.name.trim().isNotEmpty) {
          data.name = publishedInfo.name;
        }
      }

      bool bookingIsEnabled = false;
      int bookingCapacity = 1;
      Map<String, dynamic> bookingWorkingHours = {
        '1': {'start': '09:00', 'end': '19:00', 'active': true},
        '2': {'start': '09:00', 'end': '19:00', 'active': true},
        '3': {'start': '09:00', 'end': '19:00', 'active': true},
        '4': {'start': '09:00', 'end': '19:00', 'active': true},
        '5': {'start': '09:00', 'end': '19:00', 'active': true},
        '6': {'start': '09:00', 'end': '16:00', 'active': true},
        '7': {'start': '00:00', 'end': '00:00', 'active': false},
      };
      Map<String, dynamic> bookingLunchBreak = {
        'start': '12:00',
        'end': '13:00',
        'active': true,
      };

      if (publishedInfo?.slug != null && publishedInfo!.slug.isNotEmpty) {
        try {
          final settingsRes = await _client
              .from('booking_settings')
              .select()
              .eq('store_slug', publishedInfo.slug)
              .maybeSingle();
          if (settingsRes != null) {
            bookingIsEnabled = (settingsRes['is_enabled'] ?? false) as bool;
            bookingCapacity = (settingsRes['capacity'] ?? 1) as int;
            if (settingsRes['working_hours'] != null) {
              bookingWorkingHours = Map<String, dynamic>.from(
                settingsRes['working_hours'] as Map,
              );
            }
            if (settingsRes['lunch_break'] != null) {
              bookingLunchBreak = Map<String, dynamic>.from(
                settingsRes['lunch_break'] as Map,
              );
            }
          }
        } catch (e) {
          debugPrint('Booking settings load error: \$e');
        }
      }

      _data = data..isStore = false;
      _publishedInfo = publishedInfo;
      _selectedProvinceCode =
          data.provinceCode.isNotEmpty ? data.provinceCode : null;
      _selectedProvinceName =
          data.provinceName.isNotEmpty ? data.provinceName : null;
      _selectedDistrictCode =
          data.districtCode.isNotEmpty ? data.districtCode : null;
      _selectedDistrictName =
          data.districtName.isNotEmpty ? data.districtName : null;

      _coverUrl = data.shelfImageUrl.trim().isNotEmpty
          ? data.shelfImageUrl
          : data.coverImageUrl;
      _selectedKategori =
          data.kategori.trim().isEmpty ? 'Diğer' : data.kategori;
      _selectedStatus = data.status.trim().isEmpty ? 'Açık' : data.status;
      _latitude = data.latitude;
      _longitude = data.longitude;
      _locationAccuracyMeters = data.locationAccuracyMeters;

      _galleryItems.clear();
      _galleryItems.addAll(
        data.displayGalleryItems
            .take(_maxGalleryPhotos)
            .map(EditorGalleryItem.fromStoreItem),
      );

      _marketplaceLinks.clear();
      _marketplaceLinks.addAll(data.marketplaceLinks);
      _customPlatformLinkIds.clear();
      const platformOptions = [
        'Trendyol',
        'Hepsiburada',
        'N11',
        'Amazon',
        'Çiçeksepeti',
        'Shopier',
        'Google İşletme',
        'Instagram',
        'WhatsApp',
        'Diğer',
        'Özel...',
      ];
      for (final link in _marketplaceLinks) {
        if (!platformOptions.contains(link.platform) &&
            link.platform.isNotEmpty) {
          _customPlatformLinkIds.add(link.id);
        }
      }
      _offerings.clear();
      _offerings.addAll(data.offerings);

      _bookingIsEnabled = bookingIsEnabled;
      _bookingCapacity = bookingCapacity;
      _bookingWorkingHours = bookingWorkingHours;
      _bookingLunchBreak = bookingLunchBreak;

      _isLoading = false;
      notifyListeners();

      if (publishedInfo?.slug != null && publishedInfo!.slug.isNotEmpty) {
        fetchArticles();
      }
    } catch (e) {
      debugPrint('Initialization error: \$e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchArticles() async {
    final slug = _publishedInfo?.slug ?? _data.slug;
    if (slug.isEmpty) return;
    _isLoadingArticles = true;
    notifyListeners();
    try {
      final res = await _client
          .from('store_articles')
          .select()
          .eq('store_slug', slug)
          .order('created_at', ascending: false);
      _articles = List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint('Error fetching articles: \$e');
    } finally {
      _isLoadingArticles = false;
      notifyListeners();
    }
  }

  // ─── Validation ──────────────────────────────────────────────────────────

  void clearValidationErrors() {
    _nameError = null;
    _whatsappError = null;
    _addressError = null;
    _provinceError = null;
    _districtError = null;
    _googleLinkError = null;
    notifyListeners();
  }

  String? validateWhatsapp(String value) {
    if (value.trim().isEmpty) return 'WhatsApp numarası zorunludur';
    return WhatsAppLinkHelper.isValidTurkeyMobile(value)
        ? null
        : WhatsAppLinkHelper.invalidNumberMessage;
  }

  String? validateGoogleReviewLink(String value) {
    if (value.trim().isEmpty) return null;
    final googleRegex = RegExp(
      r'^https:\/\/(www\.)?(search\.google\.com|g\.page|maps\.google\.com|maps\.app\.goo\.gl)\/.*\$',
    );
    return googleRegex.hasMatch(value)
        ? null
        : 'Lütfen geçerli bir Google Haritalar veya Google Yorum bağlantısı girin.';
  }

  bool validatePublishForm() {
    final name = _data.name.trim();
    final whatsapp = _data.whatsapp.trim();
    final address = _data.address.trim();
    final googleLink = _data.googleBusinessLink.trim();
    final hasValidWhatsapp = WhatsAppLinkHelper.isValidTurkeyMobile(whatsapp);
    final isGoogleLinkValid =
        googleLink.isEmpty || validateGoogleReviewLink(googleLink) == null;

    _nameError = name.isEmpty ? 'İşletme adı zorunludur' : null;
    _whatsappError = whatsapp.isEmpty
        ? 'WhatsApp numarası zorunludur'
        : hasValidWhatsapp
            ? null
            : WhatsAppLinkHelper.invalidNumberMessage;
    _addressError = address.isEmpty ? 'Konum / adres bilgisi zorunludur' : null;
    _provinceError =
        _selectedProvinceCode == null ? 'İl seçimi zorunludur' : null;
    _districtError =
        _selectedDistrictName == null ? 'İlçe seçimi zorunludur' : null;
    _googleLinkError = isGoogleLinkValid
        ? null
        : validateGoogleReviewLink(googleLink);

    notifyListeners();

    return name.isNotEmpty &&
        whatsapp.isNotEmpty &&
        hasValidWhatsapp &&
        address.isNotEmpty &&
        _selectedProvinceCode != null &&
        _selectedDistrictName != null &&
        isGoogleLinkValid;
  }

  // ─── Field Updates ───────────────────────────────────────────────────────

  void updateName(String name) {
    _data.name = name;
    _nameError = null;
    notifyListeners();
  }

  void updateWhatsapp(String whatsapp) {
    _data.whatsapp = whatsapp;
    _whatsappError = null;
    notifyListeners();
  }

  void updateAddress(String address) {
    _data.address = address;
    _addressError = null;
    notifyListeners();
  }

  void updateDescription(String desc) {
    _data.description = desc;
    notifyListeners();
  }

  void updateInstagram(String handle) {
    _data.instagram = handle;
    notifyListeners();
  }

  void updateWebsite(String url) {
    _data.website = url;
    notifyListeners();
  }

  void updateGoogleBusinessLink(String url) {
    _data.googleBusinessLink = url;
    _googleLinkError = null;
    notifyListeners();
  }

  void selectProvince(String? code, String? name) {
    _selectedProvinceCode = code;
    _selectedProvinceName = name;
    _provinceError = null;
    _selectedDistrictCode = null;
    _selectedDistrictName = null;
    notifyListeners();
  }

  void selectDistrict(String? code, String? name) {
    _selectedDistrictCode = code;
    _selectedDistrictName = name;
    _districtError = null;
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedKategori = category;
    _data.kategori = category;
    if (category != 'Kuaför') {
      _bookingIsEnabled = false;
      for (final offering in _offerings) {
        offering.isBookable = false;
      }
    }
    notifyListeners();
  }

  void selectStatus(String status) {
    _selectedStatus = status;
    _data.status = status;
    notifyListeners();
  }

  void setPrivacyNoticeAcknowledged(bool value) {
    _privacyNoticeAcknowledged = value;
    notifyListeners();
  }

  void setTermsAccepted(bool value) {
    _termsAccepted = value;
    notifyListeners();
  }

  void setPublicationConsentAccepted(bool value) {
    _publicationConsentAccepted = value;
    notifyListeners();
  }

  void setBookingIsEnabled(bool val) {
    _bookingIsEnabled = val;
    notifyListeners();
  }

  void setBookingCapacity(int val) {
    _bookingCapacity = val;
    notifyListeners();
  }

  void updateBookingWorkingHours(Map<String, dynamic> hours) {
    _bookingWorkingHours = hours;
    notifyListeners();
  }

  void updateBookingLunchBreak(Map<String, dynamic> lunch) {
    _bookingLunchBreak = lunch;
    notifyListeners();
  }

  void addOffering(StoreOffering offering) {
    _offerings.add(offering);
    notifyListeners();
  }

  void removeOffering(int index) {
    if (index >= 0 && index < _offerings.length) {
      _offerings.removeAt(index);
      notifyListeners();
    }
  }

  void addMarketplaceLink(MarketplaceLink link) {
    _marketplaceLinks.add(link);
    notifyListeners();
  }

  void removeMarketplaceLink(int index) {
    if (index >= 0 && index < _marketplaceLinks.length) {
      _marketplaceLinks.removeAt(index);
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

  void setCoverBytes(
    Uint8List bytes,
    String fileName,
    String extension,
    String contentType,
  ) {
    _coverBytes = bytes;
    _coverFileName = fileName;
    _coverExtension = extension;
    _coverContentType = contentType;
    notifyListeners();
  }

  void clearCoverBytes() {
    _coverBytes = null;
    _coverFileName = null;
    notifyListeners();
  }

  void setGalleryItems(List<EditorGalleryItem> items) {
    _galleryItems.clear();
    _galleryItems.addAll(items);
    notifyListeners();
  }

  void removeGalleryItem(int index) {
    if (index >= 0 && index < _galleryItems.length) {
      _galleryItems.removeAt(index);
      notifyListeners();
    }
  }

  void updateProductImported(Product product) {
    final existingIndex = _data.products.indexWhere(
      (item) =>
          item.id == product.id ||
          (product.sourceMediaId?.isNotEmpty == true &&
              item.sourceMediaId == product.sourceMediaId),
    );

    if (existingIndex >= 0) {
      _data.products[existingIndex] = product;
    } else {
      _data.products.insert(0, product);
    }
    notifyListeners();
  }

  // ─── Location ────────────────────────────────────────────────────────────

  Future<void> fetchLocation() async {
    _isLocating = true;
    _locationStatusMessage = 'Konum aranıyor...';
    notifyListeners();

    final result = await _locationService.getCurrentLocation();
    if (!result.isSuccess && !result.hasApproximatePosition) {
      _isLocating = false;
      _locationStatusMessage = result.errorMessage;
      notifyListeners();
      return;
    }

    final position = result.position ?? result.approximatePosition!;
    _latitude = position.latitude;
    _longitude = position.longitude;
    _locationAccuracyMeters = position.accuracy;
    _locationStatusMessage = 'Adres çözümleniyor...';
    notifyListeners();

    final geoAddress = await _locationService.getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    _isLocating = false;
    _locationStatusMessage =
        LocationService.buildAccuracyMessage(position.accuracy);

    if (geoAddress != null && geoAddress.isNotEmpty) {
      _data.address = geoAddress;
      _addressError = null;

      final normalizedAddress = _normalizeText(geoAddress);
      Province? matchedProvince;
      for (final province in turkeyProvinces) {
        final normalizedProvince = _normalizeText(province.name);
        if (normalizedAddress.contains(normalizedProvince)) {
          matchedProvince = province;
          break;
        }
      }

      if (matchedProvince != null) {
        _selectedProvinceCode = matchedProvince.code;
        _selectedProvinceName = matchedProvince.name;
        _provinceError = null;

        final districts = turkeyDistricts[matchedProvince.code] ?? [];
        String? matchedDistrict;
        for (final district in districts) {
          final normalizedDistrict = _normalizeText(district);
          if (normalizedAddress.contains(normalizedDistrict)) {
            matchedDistrict = district;
            break;
          }
        }
        if (matchedDistrict != null) {
          _selectedDistrictCode = matchedDistrict;
          _selectedDistrictName = matchedDistrict;
          _districtError = null;
        } else {
          _selectedDistrictCode = null;
          _selectedDistrictName = null;
        }
      }
    }
    notifyListeners();
  }

  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll('i', 'i')
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  // ─── Persistence ─────────────────────────────────────────────────────────

  Future<void> saveLocally() async {
    _syncDataFields();
    await _storage.saveVitrinData(_data);
  }

  void _syncDataFields() {
    _data
      ..provinceCode = _selectedProvinceCode ?? ''
      ..provinceName = _selectedProvinceName ?? ''
      ..districtCode = _selectedDistrictCode ?? ''
      ..districtName = _selectedDistrictName ?? ''
      ..kategori = _selectedKategori
      ..status = _selectedStatus
      ..latitude = _latitude
      ..longitude = _longitude
      ..locationAccuracyMeters = _locationAccuracyMeters
      ..galleryItems = _galleryItems
          .where((i) => i.hasUrl)
          .map((i) => i.toStoreItem())
          .toList()
      ..offerings = _offerings
      ..marketplaceLinks = _marketplaceLinks.map((link) {
        var url = link.url.trim();
        if (url.isNotEmpty &&
            !url.startsWith('http://') &&
            !url.startsWith('https://') &&
            !url.startsWith('tel:') &&
            !url.startsWith('mailto:')) {
          url = 'https://\$url';
        }
        return MarketplaceLink(
          id: link.id,
          platform: link.platform,
          url: url,
          subtitle: link.subtitle,
        );
      }).toList();
  }

  Future<String?> publish() async {
    if (_isPublishing) return null;

    final name = _data.name.trim();
    final whatsapp = _data.whatsapp.trim();
    final address = _data.address.trim();
    final googleLink = _data.googleBusinessLink.trim();
    final hasValidWhatsapp = WhatsAppLinkHelper.isValidTurkeyMobile(whatsapp);

    bool isGoogleLinkValid = true;
    if (googleLink.isNotEmpty) {
      final googleRegex = RegExp(
        r'^https:\/\/(www\.)?(search\.google\.com|g\.page|maps\.google\.com|maps\.app\.goo\.gl)\/.*\$',
      );
      isGoogleLinkValid = googleRegex.hasMatch(googleLink);
    }

    final provinceOk = _selectedProvinceCode != null;
    final districtOk = _selectedDistrictName != null;

    _nameError = name.isEmpty ? 'İşletme adı zorunludur' : null;
    _whatsappError = whatsapp.isEmpty
        ? 'WhatsApp numarası zorunludur'
        : hasValidWhatsapp
            ? null
            : WhatsAppLinkHelper.invalidNumberMessage;
    _addressError = address.isEmpty ? 'Konum / adres bilgisi zorunludur' : null;
    _provinceError =
        _selectedProvinceCode == null ? 'İl seçimi zorunludur' : null;
    _districtError =
        _selectedDistrictName == null ? 'İlçe seçimi zorunludur' : null;
    _googleLinkError = isGoogleLinkValid
        ? null
        : 'Lütfen geçerli bir Google Haritalar veya Google Yorum bağlantısı girin.';

    notifyListeners();

    if (name.isEmpty ||
        whatsapp.isEmpty ||
        !hasValidWhatsapp ||
        address.isEmpty ||
        !provinceOk ||
        !districtOk ||
        !isGoogleLinkValid) {
      throw Exception(
        !isGoogleLinkValid
            ? 'Lütfen Google Yorum bağlantısını doğru formatta girin.'
            : whatsapp.isNotEmpty && !hasValidWhatsapp
                ? WhatsAppLinkHelper.invalidNumberMessage
                : 'Lütfen zorunlu alanları doldurun: ad, WhatsApp, il, ilçe ve adres.',
      );
    }

    final shouldPublishBooking =
        _selectedKategori == 'Kuaför' && _bookingIsEnabled;
    final bookingServices = _offerings
        .where((offering) => offering.title.trim().isNotEmpty)
        .take(6)
        .map((offering) => offering.copyWith(isBookable: true))
        .toList();

    if (shouldPublishBooking && bookingServices.isEmpty) {
      throw Exception(
        'Randevu açıkken en az bir randevu hizmeti eklemelisiniz.',
      );
    }

    _isPublishing = true;
    notifyListeners();

    try {
      final slug = const StorePublishPayloadBuilder().generateSlug(name);
      var coverUrl = _coverUrl?.trim() ?? '';

      if (_coverBytes != null) {
        try {
          coverUrl = await _uploadService.uploadShelfImage(
            _coverBytes!,
            '\$slug/cover',
            fileExtension: _coverExtension,
            contentType: _coverContentType,
          );
        } catch (_) {
          coverUrl = _coverUrl?.trim() ?? '';
        }
      }

      for (final item in _galleryItems) {
        if (item.hasLocalBytes) {
          try {
            final url = await _uploadService.uploadGalleryImage(
              item.bytes!,
              slug,
              fileExtension: item.extension,
              contentType: item.contentType,
            );
            item.imageUrl = url;
            item.bytes = null;
          } catch (_) {
            // Suppress image failures
          }
        }
      }

      final publishedGallery = _galleryItems
          .where((i) => i.hasUrl)
          .take(_maxGalleryPhotos)
          .map((i) => i.toStoreItem())
          .toList();

      if (_selectedKategori != 'Kuaför') {
        _bookingIsEnabled = false;
        for (final offering in _offerings) {
          offering.isBookable = false;
        }
      } else if (_bookingIsEnabled) {
        for (final offering in _offerings) {
          if (offering.title.trim().isNotEmpty) {
            offering.isBookable = true;
          }
        }
      }

      _syncDataFields();
      _data
        ..shelfImageUrl = coverUrl
        ..galleryItems = publishedGallery
        ..offerings = shouldPublishBooking ? bookingServices : [];

      await _storage.saveVitrinData(_data);
      final editToken = await _loadOrCreateEditToken();
      final result = await _publishService.publishStore(
        _data,
        editToken: editToken,
      );

      final publicLink = PublicSiteConfig.buildPublicLink(result.publicPath);

      try {
        await _client.from('booking_settings').upsert({
          'store_slug': result.slug,
          'is_enabled': _bookingIsEnabled,
          'capacity': _bookingCapacity,
          'working_hours': _bookingWorkingHours,
          'lunch_break': _bookingLunchBreak,
        });
      } catch (e) {
        debugPrint('Booking settings save error: \$e');
      }

      await _storage.savePublishedVitrinInfo(
        slug: result.slug,
        publicLink: publicLink,
        name: _data.name,
        editToken: editToken,
      );

      _data.slug = result.slug;
      _publishedInfo = PublishedVitrinInfo(
        slug: result.slug,
        publicLink: publicLink,
        name: _data.name,
        editToken: editToken,
      );
      _coverUrl = coverUrl;
      _coverBytes = null;
      _coverFileName = null;

      notifyListeners();

      _seoService.revalidateStore(result.slug);

      return publicLink;
    } finally {
      _isPublishing = false;
      notifyListeners();
    }
  }

  Future<void> withdrawPublicationConsent() async {
    final info = _publishedInfo;
    if (info == null || _isWithdrawingConsent) return;

    _isWithdrawingConsent = true;
    notifyListeners();

    try {
      await _publishService.withdrawPublicationConsent(
        slug: info.slug,
        editToken: info.editToken,
      );
      _data.publicationConsentAccepted = false;
      _data.publicationConsentWithdrawnAt = DateTime.now().toUtc();
      await _storage.saveVitrinData(_data);
      await _storage.clearPublishedVitrinInfo();

      _publishedInfo = null;
      _publicationConsentAccepted = false;
      notifyListeners();
    } finally {
      _isWithdrawingConsent = false;
      notifyListeners();
    }
  }

  Future<void> deleteVitrin() async {
    if (_isDeleting) return;
    _isDeleting = true;
    notifyListeners();

    try {
      final token = _publishedInfo?.editToken;
      if (token != null && token.trim().isNotEmpty) {
        await _client.from('stores').delete().eq('edit_token', token);
      }
      await _storage.clearVitrinData();
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  Future<String> _loadOrCreateEditToken() async {
    final saved = await _storage.loadVitrinEditToken();
    if (saved != null && saved.trim().isNotEmpty) return saved;
    final token = TokenGenerator.generate();
    await _storage.saveVitrinEditToken(token);
    return token;
  }
}
