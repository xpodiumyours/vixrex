import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vitrinx/models/chat_message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vitrinx/config/public_site_config.dart';
import 'package:vitrinx/config/business_category_config.dart';
import 'package:vitrinx/config/turkey_cities_config.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/screens/blog_editor_screen.dart';
import 'package:vitrinx/screens/landing_screen.dart';
import 'package:vitrinx/screens/public_vitrin_screen.dart';
import 'package:vitrinx/screens/booking_management_screen.dart';
import 'package:vitrinx/services/location_service.dart';
import 'package:vitrinx/services/store_local_storage_service.dart';
import 'package:vitrinx/services/store_publish_payload_builder.dart';
import 'package:vitrinx/services/revalidation_service.dart';
import 'package:vitrinx/services/store_publish_service.dart';
import 'package:vitrinx/services/store_shelf_upload_service.dart';
import 'package:vitrinx/utils/gallery_image_file_validator.dart';
import 'package:vitrinx/utils/token_generator.dart';
import 'package:vitrinx/utils/whatsapp_link_helper.dart';
import 'package:vitrinx/widgets/gallery_delete_confirmation_dialog.dart';
import 'package:vitrinx/theme/app_colors.dart';


// ─── Gallery item helper ───────────────────────────────────────────────────
class _GalleryItem {
  String id;
  Uint8List? bytes;
  String imageUrl;
  String extension;
  String contentType;

  _GalleryItem({
    required this.id,
    this.bytes,
    required this.imageUrl,
    this.extension = 'jpg',
    this.contentType = 'image/jpeg',
  });

  bool get hasLocalBytes => bytes != null;
  bool get hasUrl => imageUrl.trim().isNotEmpty;

  static _GalleryItem fromStoreItem(StoreGalleryItem item) =>
      _GalleryItem(id: item.id, imageUrl: item.imageUrl);

  StoreGalleryItem toStoreItem() =>
      StoreGalleryItem(id: id, imageUrl: imageUrl);
}

// ─── Main Widget ──────────────────────────────────────────────────────────
class MyVitrinScreen extends StatefulWidget {
  final String? initialName;
  final VoidCallback? onPublished;
  final VoidCallback? onOpenExplore;

  const MyVitrinScreen({
    super.key,
    this.initialName,
    this.onPublished,
    this.onOpenExplore,
  });

  @override
  State<MyVitrinScreen> createState() => MyVitrinScreenState();
}

class MyVitrinScreenState extends State<MyVitrinScreen> {
  // Keys for Scroll-to-Section
  final GlobalKey _coverPhotoKey = GlobalKey();
  final GlobalKey _galleryKey = GlobalKey();
  final GlobalKey _nameKey = GlobalKey();
  final GlobalKey _whatsappKey = GlobalKey();
  final GlobalKey _addressKey = GlobalKey();
  final GlobalKey _descriptionKey = GlobalKey();
  final GlobalKey _productsKey = GlobalKey();

  // FocusNodes
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _whatsappFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();

  // ─── Colors ─────────────────────────────────────────────────────────────
  static const Color primaryColor = AppColors.primary;
  static const Color bgColor = AppColors.bgEditor;
  static const Color darkText = AppColors.darkText;
  static const Color mutedText = AppColors.mutedText;
  static const Color softText = AppColors.softText;
  static const Color cardBorder = AppColors.cardBorderDark;
  static const Color inputBg = AppColors.inputBg;
  static const Color dangerColor = Color(0xFFDC2626);

  // ─── Services ───────────────────────────────────────────────────────────
  final _storage = const StoreLocalStorageService();

  // ─── Controllers ────────────────────────────────────────────────────────
  final _nameController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instagramController = TextEditingController();
  final _websiteController = TextEditingController();
  final _googleBusinessLinkController = TextEditingController();

  // ─── State ──────────────────────────────────────────────────────────────
  StoreData _data = StoreData(isEsnafMode: false, isStore: false);
  PublishedVitrinInfo? _publishedInfo;

  // Location and Google link
  String? _selectedProvinceCode;
  String? _selectedProvinceName;
  String? _selectedDistrictCode;
  String? _selectedDistrictName;
  String? _provinceError;
  String? _districtError;
  String? _googleLinkError;

  bool _googleBusinessCreated = false;
  bool _isQrCodeHung = false;

  // Blog articles
  List<Map<String, dynamic>> _articles = [];
  bool _isLoadingArticles = false;

  // Cover photo
  Uint8List? _coverBytes;
  String? _coverUrl;
  String? _coverFileName;
  String _coverExtension = 'jpg';
  String _coverContentType = 'image/jpeg';

  // Gallery
  final List<_GalleryItem> _galleryItems = [];
  static const int _maxGalleryPhotos = 12;

  // Marketplace links
  final List<MarketplaceLink> _marketplaceLinks = [];
  final Set<String> _customPlatformLinkIds = {};
  final List<StoreOffering> _offerings = [];

  // Location
  double? _latitude;
  double? _longitude;
  double? _locationAccuracyMeters;
  bool _isLocating = false;
  String? _locationStatusMessage;

  // Category / status
  String _selectedKategori = 'Diğer';
  String _selectedStatus = 'Açık';

  // Booking settings state
  bool _bookingIsEnabled = false;
  int _bookingCapacity = 1;
  Map<String, dynamic> _bookingWorkingHours = {
    '1': {'start': '09:00', 'end': '19:00', 'active': true},
    '2': {'start': '09:00', 'end': '19:00', 'active': true},
    '3': {'start': '09:00', 'end': '19:00', 'active': true},
    '4': {'start': '09:00', 'end': '19:00', 'active': true},
    '5': {'start': '09:00', 'end': '19:00', 'active': true},
    '6': {'start': '09:00', 'end': '16:00', 'active': true},
    '7': {'start': '00:00', 'end': '00:00', 'active': false},
  };
  Map<String, dynamic> _bookingLunchBreak = {
    'start': '12:00',
    'end': '13:00',
    'active': true,
  };

  static final List<String> _categories =
      BusinessCategoryConfig.categories.map((c) => c.label).toList();

  static const List<String> _statuses = [
    'Açık',
    'Bugün kampanya var',
    'Yeni ürünler geldi',
    'Stok sınırlı',
    'Kapalı',
  ];

  static const List<String> _platformOptions = [
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
    'Özel...', // Serbest metin girişi
  ];

  // UI state
  String? _nameError;
  String? _whatsappError;
  String? _addressError;
  bool _isLoading = true;
  bool _isPublishing = false;
  bool _isDeleting = false;

  // ─── Lifecycle ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _instagramController.dispose();
    _websiteController.dispose();
    _googleBusinessLinkController.dispose();
    _nameFocusNode.dispose();
    _whatsappFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  /// Xrex aksiyonuna göre ilgili forma otomatik kaydırır ve odaklanır.
  void scrollToXrexAction(XrexAction action) {
    GlobalKey? key;
    FocusNode? focus;

    switch (action) {
      case XrexAction.scrollToCover:
        key = _coverPhotoKey;
        break;
      case XrexAction.scrollToGallery:
        key = _galleryKey;
        break;
      case XrexAction.scrollToName:
        key = _nameKey;
        focus = _nameFocusNode;
        break;
      case XrexAction.scrollToWhatsapp:
        key = _whatsappKey;
        focus = _whatsappFocusNode;
        break;
      case XrexAction.scrollToAddress:
        key = _addressKey;
        break;
      case XrexAction.scrollToDesc:
        key = _descriptionKey;
        focus = _descriptionFocusNode;
        break;
      case XrexAction.scrollToProducts:
        key = _productsKey;
        break;
      default:
        return;
    }

    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }

    if (focus != null) {
      Future.delayed(const Duration(milliseconds: 550), () {
        focus?.requestFocus();
      });
    }
  }

  // ─── Data Loading ────────────────────────────────────────────────────────
  Future<void> _loadState() async {
    try {
      final savedData = await _storage.loadVitrinData();
      final publishedInfo = await _storage.loadPublishedVitrinInfo();
      final data = savedData ?? StoreData(isEsnafMode: false, isStore: false);
      final initialName = widget.initialName?.trim() ?? '';
      if (data.name.trim().isEmpty && initialName.isNotEmpty) {
        data.name = initialName;
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

      bool googleBusinessCreated = false;
      bool isQrCodeHung = false;

      if (publishedInfo?.slug != null && publishedInfo!.slug.isNotEmpty) {
        try {
          final client = Supabase.instance.client;
          final settingsRes = await client
              .from('booking_settings')
              .select()
              .eq('store_slug', publishedInfo.slug)
              .maybeSingle();
          if (settingsRes != null) {
            bookingIsEnabled = (settingsRes['is_enabled'] ?? false) as bool;
            bookingCapacity = (settingsRes['capacity'] ?? 1) as int;
            if (settingsRes['working_hours'] != null) {
              bookingWorkingHours = Map<String, dynamic>.from(settingsRes['working_hours'] as Map);
            }
            if (settingsRes['lunch_break'] != null) {
              bookingLunchBreak = Map<String, dynamic>.from(settingsRes['lunch_break'] as Map);
            }
          }
        } catch (e) {
          debugPrint('Booking settings load error: $e');
        }

        try {
          final prefs = await SharedPreferences.getInstance();
          googleBusinessCreated = prefs.getBool('google_business_created_${publishedInfo.slug}') ?? false;
          isQrCodeHung = prefs.getBool('is_qr_code_hung_${publishedInfo.slug}') ?? false;
        } catch (e) {
          debugPrint('Checklist load error: $e');
        }
      }

      if (!mounted) return;
      setState(() {
        _data = data..isStore = false;
        _publishedInfo = publishedInfo;
        _nameController.text =
            data.name.trim().isNotEmpty
                ? data.name
                : (publishedInfo?.name ?? initialName);
        _whatsappController.text = data.whatsapp;
        _addressController.text = data.address;
        _descriptionController.text = data.description;
        _instagramController.text = data.instagram;
        _websiteController.text =
            publishedInfo?.publicLink.trim().isNotEmpty == true
                ? publishedInfo!.publicLink
                : data.website;
        _googleBusinessLinkController.text = data.googleBusinessLink;
        _selectedProvinceCode = data.provinceCode.isNotEmpty ? data.provinceCode : null;
        _selectedProvinceName = data.provinceName.isNotEmpty ? data.provinceName : null;
        _selectedDistrictCode = data.districtCode.isNotEmpty ? data.districtCode : null;
        _selectedDistrictName = data.districtName.isNotEmpty ? data.districtName : null;
        _googleBusinessCreated = googleBusinessCreated;
        _isQrCodeHung = isQrCodeHung;

        _coverUrl =
            data.shelfImageUrl.trim().isNotEmpty
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
                .map(_GalleryItem.fromStoreItem),
        );

        _marketplaceLinks.clear();
        _marketplaceLinks.addAll(data.marketplaceLinks);
        _customPlatformLinkIds.clear();
        for (final link in _marketplaceLinks) {
          if (!_platformOptions.contains(link.platform) && link.platform.isNotEmpty) {
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
      });

      if (publishedInfo?.slug != null && publishedInfo!.slug.isNotEmpty) {
        _fetchArticles();
      }
    } catch (error) {
      debugPrint('MyVitrinScreen load error: $error');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchArticles() async {
    final slug = _publishedInfo?.slug ?? _data.slug;
    if (slug.isEmpty) return;
    setState(() => _isLoadingArticles = true);
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('store_articles')
          .select()
          .eq('store_slug', slug)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _articles = List<Map<String, dynamic>>.from(res as List);
          _isLoadingArticles = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching articles: $e');
      if (mounted) {
        setState(() => _isLoadingArticles = false);
      }
    }
  }

  // ─── Cover Photo ─────────────────────────────────────────────────────────
  Future<void> _pickCoverPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final validation = GalleryImageFileValidator.validate(
      bytes: file.bytes,
      reportedSize: file.size,
    );

    if (!validation.isValid || file.bytes == null) {
      _showSnackBar('Fotoğraf eklenemedi. JPG, PNG veya WEBP, en fazla 15 MB.');
      return;
    }

    setState(() {
      _coverBytes = file.bytes;
      _coverFileName = file.name;
      _coverExtension = validation.fileInfo!.extension;
      _coverContentType = validation.fileInfo!.contentType;
    });
  }

  // ─── Gallery ─────────────────────────────────────────────────────────────
  Future<void> _pickGalleryPhotos() async {
    final remaining = _maxGalleryPhotos - _galleryItems.length;
    if (remaining <= 0) {
      _showSnackBar(
        'En fazla $_maxGalleryPhotos galeri fotoğrafı eklenebilir.',
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    var rejected = 0;
    final newItems = <_GalleryItem>[];
    for (final file in result.files.take(remaining)) {
      final validation = GalleryImageFileValidator.validate(
        bytes: file.bytes,
        reportedSize: file.size,
      );
      if (!validation.isValid || file.bytes == null) {
        rejected++;
        continue;
      }
      newItems.add(
        _GalleryItem(
          id: '${DateTime.now().microsecondsSinceEpoch}_${newItems.length}',
          bytes: file.bytes,
          imageUrl: '',
          extension: validation.fileInfo!.extension,
          contentType: validation.fileInfo!.contentType,
        ),
      );
    }

    setState(() => _galleryItems.addAll(newItems));
    if (rejected > 0) {
      _showSnackBar(
        '$rejected fotoğraf eklenemedi. Geçerli format: JPG, PNG, WEBP, maks 15 MB.',
      );
    }
  }

  Future<void> _removeGalleryItem(int index) async {
    if (index < 0 || index >= _galleryItems.length) return;

    final confirmed = await showGalleryDeleteConfirmationDialog(
      context,
      isCover: index == 0,
    );
    if (!confirmed || !mounted) return;

    setState(() => _galleryItems.removeAt(index));
  }

  // ─── Location ─────────────────────────────────────────────────────────────
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _locationStatusMessage = 'Konum aranıyor...';
    });

    final result = await const LocationService().getCurrentLocation();
    if (!mounted) return;

    if (!result.isSuccess && !result.hasApproximatePosition) {
      setState(() {
        _isLocating = false;
        _locationStatusMessage = result.errorMessage;
      });
      return;
    }

    final position = result.position ?? result.approximatePosition!;
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
      _locationAccuracyMeters = position.accuracy;
      _locationStatusMessage = 'Adres çözümleniyor...';
    });

    final geoAddress = await const LocationService().getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (!mounted) return;

    setState(() {
      _isLocating = false;
      _locationStatusMessage = LocationService.buildAccuracyMessage(
        position.accuracy,
      );
      if (geoAddress != null && geoAddress.isNotEmpty) {
        _addressController.text = geoAddress;
        _addressError = null;

        // Auto-detect Province and District
        final normalizedAddress = _normalizeTurkish(geoAddress);
        Province? matchedProvince;
        for (final province in turkeyProvinces) {
          final normalizedProvince = _normalizeTurkish(province.name);
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
            final normalizedDistrict = _normalizeTurkish(district);
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
    });
  }

  String _normalizeTurkish(String text) {
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

  // ─── Marketplace Links ────────────────────────────────────────────────────
  void _addMarketplaceLink() {
    setState(() {
      _marketplaceLinks.add(
        MarketplaceLink(id: DateTime.now().millisecondsSinceEpoch.toString()),
      );
    });
  }

  void _removeMarketplaceLink(int index) {
    setState(() => _marketplaceLinks.removeAt(index));
  }

  // ─── Publish ─────────────────────────────────────────────────────────────
  Future<void> _publishVitrin() async {
    if (_isPublishing) return;

    final name = _nameController.text.trim();
    final whatsapp = _whatsappController.text.trim();
    final address = _addressController.text.trim();
    final googleLink = _googleBusinessLinkController.text.trim();
    final hasValidWhatsapp = WhatsAppLinkHelper.isValidTurkeyMobile(whatsapp);

    bool isGoogleLinkValid = true;
    if (googleLink.isNotEmpty) {
      final googleRegex = RegExp(r'^https:\/\/(www\.)?(search\.google\.com|g\.page|maps\.google\.com|maps\.app\.goo\.gl)\/.*$');
      isGoogleLinkValid = googleRegex.hasMatch(googleLink);
    }

    final provinceOk = _selectedProvinceCode != null;
    final districtOk = _selectedDistrictName != null;

    // Validate required fields
    setState(() {
      _nameError = name.isEmpty ? 'İşletme adı zorunludur' : null;
      _whatsappError =
          whatsapp.isEmpty
              ? 'WhatsApp numarası zorunludur'
              : hasValidWhatsapp
              ? null
              : WhatsAppLinkHelper.invalidNumberMessage;
      _addressError =
          address.isEmpty ? 'Konum / adres bilgisi zorunludur' : null;
      _provinceError = _selectedProvinceCode == null ? 'İl seçimi zorunludur' : null;
      _districtError = _selectedDistrictName == null ? 'İlçe seçimi zorunludur' : null;
      _googleLinkError = isGoogleLinkValid ? null : 'Lütfen geçerli bir Google Haritalar veya Google Yorum bağlantısı girin.';
    });

    if (name.isEmpty ||
        whatsapp.isEmpty ||
        !hasValidWhatsapp ||
        address.isEmpty ||
        !provinceOk ||
        !districtOk ||
        !isGoogleLinkValid) {
      _showSnackBar(
        !isGoogleLinkValid
            ? 'Lütfen Google Yorum bağlantısını doğru formatta girin.'
            : whatsapp.isNotEmpty && !hasValidWhatsapp
            ? WhatsAppLinkHelper.invalidNumberMessage
            : 'Lütfen zorunlu alanları doldurun: ad, WhatsApp, il, ilçe ve adres.',
      );
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    try {
      final slug = const StorePublishPayloadBuilder().generateSlug(name);
      var coverUrl = _coverUrl?.trim() ?? '';

      // Upload cover
      if (_coverBytes != null) {
        try {
          coverUrl = await const StoreShelfUploadService().uploadShelfImage(
            _coverBytes!,
            '$slug/cover',
            fileExtension: _coverExtension,
            contentType: _coverContentType,
          );
        } catch (_) {
          _showSnackBar(
            'Kapak fotoğrafı yüklenemedi, vitrin yayını devam ediyor.',
          );
          coverUrl = _coverUrl?.trim() ?? '';
        }
      }

      // Upload gallery
      final uploadService = const StoreShelfUploadService();
      var galleryFailures = 0;
      for (final item in _galleryItems) {
        if (item.hasLocalBytes) {
          try {
            final url = await uploadService.uploadGalleryImage(
              item.bytes!,
              slug,
              fileExtension: item.extension,
              contentType: item.contentType,
            );
            item.imageUrl = url;
            item.bytes = null;
          } catch (_) {
            galleryFailures++;
          }
        }
      }
      if (galleryFailures > 0) {
        _showSnackBar('$galleryFailures galeri fotoğrafı yüklenemedi.');
      }

      final publishedGallery =
          _galleryItems
              .where((i) => i.hasUrl)
              .take(_maxGalleryPhotos)
              .map((i) => i.toStoreItem())
              .toList();

      if (_selectedKategori != 'Kuaför') {
        _bookingIsEnabled = false;
        for (final offering in _offerings) {
          offering.isBookable = false;
        }
      }

      final data =
          _data
            ..name = name
            ..whatsapp = whatsapp
            ..address = address
            ..description = _descriptionController.text.trim()
            ..instagram = _instagramController.text.trim()
            ..website = ''
            ..googleBusinessLink = googleLink
            ..provinceCode = _selectedProvinceCode ?? ''
            ..provinceName = _selectedProvinceName ?? ''
            ..districtCode = _selectedDistrictCode ?? ''
            ..districtName = _selectedDistrictName ?? ''
            ..kategori = _selectedKategori
            ..status = _selectedStatus
            ..isStore = false
            ..shelfImageUrl = coverUrl
            ..galleryItems = publishedGallery
            ..offerings = _offerings
            ..marketplaceLinks =
                _marketplaceLinks.map((link) {
                  var url = link.url.trim();
                  if (url.isNotEmpty &&
                      !url.startsWith('http://') &&
                      !url.startsWith('https://') &&
                      !url.startsWith('tel:') &&
                      !url.startsWith('mailto:')) {
                    url = 'https://$url';
                  }
                  return MarketplaceLink(
                    id: link.id,
                    platform: link.platform,
                    url: url,
                    subtitle: link.subtitle,
                  );
                }).toList()
            ..latitude = _latitude
            ..longitude = _longitude
            ..locationAccuracyMeters = _locationAccuracyMeters;

      await _storage.saveVitrinData(data);
      final editToken = await _loadOrCreateEditToken();
      final result = await const StorePublishService().publishStore(
        data,
        editToken: editToken,
      );
      final publicLink = PublicSiteConfig.buildPublicLink(result.publicPath);

      // Save booking settings to Supabase
      try {
        final client = Supabase.instance.client;
        await client.from('booking_settings').upsert({
          'store_slug': result.slug,
          'is_enabled': _bookingIsEnabled,
          'capacity': _bookingCapacity,
          'working_hours': _bookingWorkingHours,
          'lunch_break': _bookingLunchBreak,
        });
      } catch (e) {
        debugPrint('Booking settings save error: $e');
      }

      await _storage.savePublishedVitrinInfo(
        slug: result.slug,
        publicLink: publicLink,
        name: data.name,
        editToken: editToken,
      );

      if (!mounted) return;
      setState(() {
        _data = data..slug = result.slug;
        _publishedInfo = PublishedVitrinInfo(
          slug: result.slug,
          publicLink: publicLink,
          name: data.name,
          editToken: editToken,
        );
        _websiteController.text = publicLink;
        _coverUrl = coverUrl;
        _coverBytes = null;
        _coverFileName = null;
      });

      // Next.js ISR önbelleğini arka planda temizle (hata kullanıcıyı etkilemez)
      const RevalidationService().revalidateStore(result.slug);

      widget.onPublished?.call();
      _showSnackBar('Vitrinin yayında! Keşfet\'te görünürsün.');
    } catch (error) {
      debugPrint('Publish error: $error');
      if (!mounted) return;
      _showSnackBar(
        error is StorePublishException
            ? error.message
            : 'Vitrin yayına alınamadı. Lütfen tekrar deneyin.',
      );
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  // ─── Delete Vitrin ────────────────────────────────────────────────────────
  Future<void> _deleteVitrin() async {
    if (_isDeleting) return;
    setState(() => _isDeleting = true);

    try {
      final token = _publishedInfo?.editToken;
      if (token != null && token.trim().isNotEmpty) {
        final client = Supabase.instance.client;
        await client.from('stores').delete().eq('edit_token', token);
      }
      await _storage.clearVitrinData();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LandingScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Delete error: $e');
      if (!mounted) return;
      _showSnackBar('Vitrin silinirken bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showDeleteConfirmation() {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: dangerColor, size: 22),
                SizedBox(width: 8),
                Text(
                  'Vitrini Sil',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: darkText,
                  ),
                ),
              ],
            ),
            content: const Text(
              'Bu işlem geri alınamaz. Vitrininiz kalıcı olarak silinecektir.',
              style: TextStyle(color: softText, fontSize: 14, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Vazgeç',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: mutedText,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _deleteVitrin();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: dangerColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Sil',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Future<String> _loadOrCreateEditToken() async {
    final saved = await _storage.loadVitrinEditToken();
    if (saved != null && saved.trim().isNotEmpty) return saved;
    final token = TokenGenerator.generate();
    await _storage.saveVitrinEditToken(token);
    return token;
  }

  Future<void> _copyLink() async {
    final link = _publishedInfo?.publicLink;
    if (link == null || link.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    _showSnackBar('Vitrin linki kopyalandı.');
  }

  Future<void> _openPublicWebsiteLink() async {
    final link = _publishedInfo?.publicLink.trim();
    if (link == null || link.isEmpty) {
      _showSnackBar(
        'Vitrininizi yayına aldığınızda size özel web linkiniz oluşacak. Hazırsanız "Vitrinimi Yayına Al" butonuyla linki oluşturalım.',
      );
      return;
    }

    final uri = Uri.tryParse(link);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      _showSnackBar('Vitrin linki açılamadı.');
      return;
    }

    try {
      final didLaunch = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!didLaunch && mounted) {
        _showSnackBar('Tarayıcı açılamadı, linki kopyalayabilirsin.');
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar('Tarayıcı açılamadı, linki kopyalayabilirsin.');
      }
    }
  }

  Future<void> _sharePublicWebsiteLink() async {
    final link = _publishedInfo?.publicLink.trim();
    if (link == null || link.isEmpty) {
      _showSnackBar(
        'Vitrininizi yayına aldığınızda size özel web linkiniz oluşacak. Hazırsanız "Vitrinimi Yayına Al" butonuyla linki oluşturalım.',
      );
      return;
    }

    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          text: 'VitrinX web linkim:\n$link',
          title: 'VitrinX Web Linki',
        ),
      );
      if (result.status != ShareResultStatus.unavailable) return;
    } catch (_) {
      // Paylaşım desteklenmeyen cihazlarda kopyalama yedeği kullanılır.
    }

    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    _showSnackBar('Paylaşım açılamadı, link panoya kopyalandı.');
  }

  void _openPublicVitrin() {
    final slug = _publishedInfo?.slug;
    if (slug == null || slug.trim().isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PublicVitrinScreen(slug: slug)),
    );
  }

  void _openBookingManagement() {
    final slug = _publishedInfo?.slug ?? _data.slug;
    if (slug.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingManagementScreen(storeSlug: slug),
      ),
    );
  }

  void _showQrSheet() {
    final link = _publishedInfo?.publicLink;
    if (link == null || link.trim().isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'QR Kod',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 220,
                  height: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cardBorder),
                  ),
                  child: QrImageView(
                    data: link,
                    version: QrVersions.auto,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  link,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    final hasPublished = _publishedInfo?.isComplete == true;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 720;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 16,
                vertical: isDesktop ? 28 : 18,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: _buildContent(hasPublished),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(bool hasPublished) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),

        // ── Header ──────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Text(
                hasPublished ? 'VitrinX Düzenle' : 'VitrinX Oluştur',
                style: const TextStyle(
                  color: darkText,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.storefront_rounded, color: Colors.white, size: 13),
                  SizedBox(width: 4),
                  Text(
                    'VitrinX ile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          hasPublished
              ? 'Düzenledikten sonra kaydet, linkin ve QR kodun güncellenir.'
              : 'Ad, WhatsApp ve konumunu gir — vitrin hazır. Diğer detayları sonra ekleyebilirsin.',
          style: const TextStyle(
            color: mutedText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),

        // ── Main Form Card ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Kapak Fotoğrafı ──────────────────────────────────
              KeyedSubtree(key: _coverPhotoKey, child: _buildCoverPicker()),
              const SizedBox(height: 10),

              // ── Galeri (kapak altında, kompakt) ─────────────────
              KeyedSubtree(key: _galleryKey, child: _buildCompactGalleryRow()),
              const SizedBox(height: 18),

              // ── Zorunlu Alanlar (* ile işaretli) ─────────────────
              KeyedSubtree(
                key: _nameKey,
                child: _buildTextField(
                  label: 'İşletme / VitrinX Adı',
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  hint: 'Örn: Aymira Butik',
                  icon: Icons.storefront_rounded,
                  errorText: _nameError,
                  required: true,
                ),
              ),
              const SizedBox(height: 14),

              KeyedSubtree(
                key: _whatsappKey,
                child: _buildTextField(
                  label: 'WhatsApp Numarası',
                  controller: _whatsappController,
                  focusNode: _whatsappFocusNode,
                  hint: '05xx xxx xx xx',
                  icon: Icons.chat_bubble_rounded,
                  keyboardType: TextInputType.phone,
                  errorText:
                      _whatsappError ??
                      (_whatsappController.text.trim().isNotEmpty &&
                              !WhatsAppLinkHelper.isValidTurkeyMobile(
                                _whatsappController.text,
                              )
                          ? WhatsAppLinkHelper.invalidNumberMessage
                          : null),
                  required: true,
                  validateWhatsapp: true,
                ),
              ),
              const SizedBox(height: 14),

              KeyedSubtree(key: _addressKey, child: _buildLocationField()),
              const SizedBox(height: 14),

              // ── İsteğe Bağlı Alanlar ─────────────────────────────
              KeyedSubtree(
                key: _descriptionKey,
                child: _buildTextField(
                  label: 'Kısa Açıklama',
                  controller: _descriptionController,
                  focusNode: _descriptionFocusNode,
                  hint: 'Bugün vitrinde ne var? Kısa bir tanıtım yaz.',
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 14),

              _buildDropdown(
                label: 'Kategori',
                value: _selectedKategori,
                items: _categories,
                icon: Icons.category_rounded,
                onChanged: (val) {
                  setState(() {
                    _selectedKategori = val ?? 'Diğer';
                    if (_selectedKategori != 'Kuaför') {
                      _bookingIsEnabled = false;
                      for (final offering in _offerings) {
                        offering.isBookable = false;
                      }
                    }
                  });
                },
              ),
              const SizedBox(height: 14),

              KeyedSubtree(key: _productsKey, child: _buildOfferingsSection()),
              const SizedBox(height: 14),

              if (_selectedKategori == 'Kuaför') ...[
                _buildBookingSettingsSection(),
                const SizedBox(height: 14),
              ],

              _buildDropdown(
                label: 'Vitrin Durumu',
                value: _selectedStatus,
                items: _statuses,
                icon: Icons.info_outline_rounded,
                onChanged:
                    (val) => setState(() => _selectedStatus = val ?? 'Açık'),
              ),
              const SizedBox(height: 14),

              _buildTextField(
                label: 'Instagram',
                controller: _instagramController,
                hint: '@kullanici_adi veya profil linki',
                icon: Icons.camera_alt_rounded,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 14),

              _buildPublicWebsiteLinkCard(),
              const SizedBox(height: 14),

              _buildTextField(
                label: 'Google Yorum Bağlantısı',
                controller: _googleBusinessLinkController,
                hint: 'https://search.google.com/local/writereview?placeid=...',
                icon: Icons.rate_review_rounded,
                keyboardType: TextInputType.url,
                errorText: _googleLinkError,
              ),
              const SizedBox(height: 14),

              _buildMarketplaceSection(),
              const SizedBox(height: 24),

              // ── Publish Button ─────────────────────────────────────────
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isPublishing ? null : _publishVitrin,
                  icon:
                      _isPublishing
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Icon(
                            hasPublished
                                ? Icons.cloud_upload_rounded
                                : Icons.rocket_launch_rounded,
                            size: 19,
                          ),
                  label: Text(
                    _isPublishing
                        ? 'Yayına alınıyor...'
                        : hasPublished
                        ? 'Değişiklikleri Kaydet & Yayına Al'
                        : 'Vitrinimi Yayına Al',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasPublished
                    ? 'Mevcut linkin korunur, Keşfet görünümün güncellenir.'
                    : 'Linkin oluşur, Keşfet\'te görünürsün.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // ── Published Summary Card ────────────────────────────────────────
        if (hasPublished) ...[
          const SizedBox(height: 16),
          _buildPublishedSummary(),
          const SizedBox(height: 16),
          _buildActionButtons(),
          const SizedBox(height: 16),
          _buildBlogManagementCard(),
          const SizedBox(height: 16),
          _buildVisibilityChecklistCard(),
        ],

        // ── Danger Zone ────────────────────────────────────────────────────
        if (hasPublished) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _isDeleting ? null : _showDeleteConfirmation,
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 16,
                color: dangerColor,
              ),
              label: const Text(
                'Vitrini Sil',
                style: TextStyle(
                  color: dangerColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildPublicWebsiteLinkCard() {
    final publicLink = _publishedInfo?.publicLink.trim();
    final hasPublicLink = publicLink != null && publicLink.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Website',
          style: TextStyle(
            color: softText,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _websiteController,
          keyboardType: TextInputType.url,
          style: const TextStyle(
            color: darkText,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            prefixIcon: IconButton(
              tooltip: 'Web linkini aç',
              onPressed: _openPublicWebsiteLink,
              icon: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.language_rounded,
                  color: primaryColor,
                  size: 18,
                ),
              ),
            ),
            suffixIcon:
                hasPublicLink
                    ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Linki kopyala',
                          onPressed: _copyLink,
                          icon: const Icon(
                            Icons.copy_rounded,
                            color: mutedText,
                            size: 18,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Linki paylaş',
                          onPressed: _sharePublicWebsiteLink,
                          icon: const Icon(
                            Icons.ios_share_rounded,
                            color: primaryColor,
                            size: 18,
                          ),
                        ),
                      ],
                    )
                    : null,
            hintText: 'Yayına aldığınızda özel web linkiniz burada oluşur.',
            hintStyle: TextStyle(
              color: mutedText.withValues(alpha: 0.62),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: primaryColor, width: 1.4),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Location Field ───────────────────────────────────────────────────────
  // ─── Location Field ───────────────────────────────────────────────────────
  Widget _buildLocationField() {
    final districts = _selectedProvinceCode != null
        ? (turkeyDistricts[_selectedProvinceCode] ?? [])
        : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown: İl
        Row(
          children: [
            const Text(
              'İl',
              style: TextStyle(
                color: softText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedProvinceCode,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.map_rounded, color: mutedText, size: 18),
            filled: true,
            fillColor: inputBg,
            errorText: _provinceError,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: cardBorder),
            ),
          ),
          hint: const Text('İl Seçiniz', style: TextStyle(fontSize: 14, color: mutedText)),
          items: turkeyProvinces.map((p) {
            return DropdownMenuItem<String>(
              value: p.code,
              child: Text(
                p.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: darkText),
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedProvinceCode = val;
              _selectedProvinceName = val != null ? turkeyProvinces.firstWhere((p) => p.code == val).name : '';
              _selectedDistrictCode = null;
              _selectedDistrictName = null;
              _provinceError = null;
            });
          },
        ),
        const SizedBox(height: 14),

        // Dropdown: İlçe
        Row(
          children: [
            const Text(
              'İlçe',
              style: TextStyle(
                color: softText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedDistrictName,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.location_city_rounded, color: mutedText, size: 18),
            filled: true,
            fillColor: inputBg,
            errorText: _districtError,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: cardBorder),
            ),
          ),
          hint: const Text('İlçe Seçiniz', style: TextStyle(fontSize: 14, color: mutedText)),
          disabledHint: const Text('Önce İl Seçiniz', style: TextStyle(fontSize: 14, color: mutedText)),
          items: districts.map((d) {
            return DropdownMenuItem<String>(
              value: d,
              child: Text(
                d,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: darkText),
              ),
            );
          }).toList(),
          onChanged: _selectedProvinceCode == null
              ? null
              : (val) {
                  setState(() {
                    _selectedDistrictCode = val;
                    _selectedDistrictName = val;
                    _districtError = null;
                  });
                },
        ),
        const SizedBox(height: 14),

        // Detailed Address Field
        Row(
          children: [
            const Text(
              'Açık Adres (Mahalle, Cadde, Sokak, No)',
              style: TextStyle(
                color: softText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _addressController,
          style: const TextStyle(
            color: darkText,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.location_on_rounded,
              color: mutedText,
              size: 18,
            ),
            hintText: 'Örn: Atatürk Mah. Fatih Cad. No:12 D:4',
            hintStyle: TextStyle(
              color: mutedText.withValues(alpha: 0.62),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: inputBg,
            errorText: _addressError,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: primaryColor, width: 1.4),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: OutlinedButton.icon(
            onPressed: _isLocating ? null : _getCurrentLocation,
            icon:
                _isLocating
                    ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryColor,
                      ),
                    )
                    : const Icon(
                      Icons.my_location_rounded,
                      size: 16,
                      color: primaryColor,
                    ),
            label: Text(
              _isLocating ? 'Konum alınıyor...' : '📡 GPS ile Konumumu Al',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
          ),
        ),
        if (_locationStatusMessage != null) ...[
          const SizedBox(height: 6),
          Text(
            _locationStatusMessage!,
            style: const TextStyle(
              color: mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (_latitude != null && _longitude != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 13,
                color: Color(0xFF10B981),
              ),
              const SizedBox(width: 4),
              Text(
                'Koordinat kaydedildi (${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)})',
                style: const TextStyle(
                  color: Color(0xFF047857),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildVisibilityChecklistCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.checklist_rounded, color: primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                'Google Görünürlük Kontrol Listesi',
                style: TextStyle(
                  color: darkText,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Arama motorlarında ve Google Haritalar\'da üst sıralara çıkmak için aşağıdaki adımları tamamlayın:',
            style: TextStyle(
              color: mutedText.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          CheckboxListTile(
            value: _googleBusinessCreated,
            title: const Text(
              'Google Benim İşletmem profilinizi oluşturup tüm bilgilerinizi eksiksiz doldurdunuz mu?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkText),
            ),
            activeColor: primaryColor,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) async {
              setState(() {
                _googleBusinessCreated = val ?? false;
              });
              final slug = _publishedInfo?.slug ?? _data.slug;
              if (slug.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('google_business_created_$slug', _googleBusinessCreated);
              }
            },
          ),
          CheckboxListTile(
            value: _isQrCodeHung,
            title: const Text(
              'Google Yorum QR kodunu dükkanınızda müşterilerinizin görebileceği bir yere astınız mı?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkText),
            ),
            activeColor: primaryColor,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) async {
              setState(() {
                _isQrCodeHung = val ?? false;
              });
              final slug = _publishedInfo?.slug ?? _data.slug;
              if (slug.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('is_qr_code_hung_$slug', _isQrCodeHung);
              }
            },
          ),
          if (_googleBusinessLinkController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _showGoogleReviewQrSheet,
              icon: const Icon(Icons.qr_code_2_rounded, size: 18),
              label: const Text(
                'Google Yorum QR Kodu Göster',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: const BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBlogManagementCard() {
    final slug = _publishedInfo?.slug ?? _data.slug;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: primaryColor, size: 22),
                  SizedBox(width: 8),
                  Text(
                    '✍️ Blog Yönetimi',
                    style: TextStyle(
                      color: darkText,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlogEditorScreen(storeSlug: slug),
                    ),
                  );
                  if (result == true) {
                    _fetchArticles();
                  }
                },
                icon: const Icon(Icons.add_rounded, size: 16, color: primaryColor),
                label: const Text(
                  'Yeni Yazı',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Google\'da görünürlüğünüzü ve organik trafiğinizi artırmak için SEO uyumlu blog yazıları yayınlayın.',
            style: TextStyle(
              color: mutedText.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          if (_isLoadingArticles)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: CircularProgressIndicator(color: primaryColor),
              ),
            )
          else if (_articles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Henüz eklenmiş blog yazısı bulunmuyor.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: mutedText.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _articles.length,
              separatorBuilder: (_, __) => const Divider(color: cardBorder, height: 16),
              itemBuilder: (context, index) {
                final art = _articles[index];
                final title = art['title'] ?? '';
                final status = art['status'] ?? 'draft';
                final cover = art['cover_image_url'] as String?;

                String statusText = 'Taslak';
                Color badgeBg = Colors.grey.shade100;
                Color badgeText = Colors.grey.shade700;

                if (status == 'review') {
                  statusText = 'Onay Bekliyor';
                  badgeBg = Colors.amber.shade50;
                  badgeText = Colors.amber.shade800;
                } else if (status == 'published') {
                  statusText = 'Yayında';
                  badgeBg = const Color(0xFFEFFDF5);
                  badgeText = const Color(0xFF047857);
                } else if (status == 'rejected') {
                  statusText = 'Reddedildi';
                  badgeBg = const Color(0xFFFEF2F2);
                  badgeText = const Color(0xFFDC2626);
                }

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cardBorder),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: cover != null && cover.isNotEmpty
                        ? Image.network(cover, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.article_rounded, color: mutedText))
                        : const Icon(Icons.article_rounded, color: mutedText),
                  ),
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkText),
                  ),
                  subtitle: Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(fontSize: 10, color: badgeText, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'SEO Skoru: ${art['seo_score'] ?? 0}',
                          style: const TextStyle(fontSize: 10, color: mutedText, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: mutedText),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlogEditorScreen(
                          storeSlug: slug,
                          initialArticle: art,
                        ),
                      ),
                    );
                    if (result == true) {
                      _fetchArticles();
                    }
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  void _showGoogleReviewQrSheet() {
    final link = _googleBusinessLinkController.text.trim();
    if (link.isEmpty) {
      _showSnackBar('Lütfen önce Google Yorum Bağlantısı girin ve vitrininizi kaydedin.');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Google Yorum QR Kodu',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Google politikaları gereği yorum karşılığında ödül veya hediye teklif edilmesi yasaktır. Lütfen QR kodunu müşterilerinizden tarafsız ve organik geri bildirimler almak üzere kullanın.',
                          style: TextStyle(
                            color: Color(0xFF991B1B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 220,
                  height: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cardBorder),
                  ),
                  child: QrImageView(
                    data: link,
                    version: QrVersions.auto,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  link,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // ─── Marketplace Section ──────────────────────────────────────────────────
  Widget _buildMarketplaceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Bağlantılar',
              style: TextStyle(
                color: softText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _addMarketplaceLink,
              icon: const Icon(
                Icons.add_rounded,
                size: 16,
                color: primaryColor,
              ),
              label: const Text(
                'Ekle',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        if (_marketplaceLinks.isEmpty)
          Text(
            'Trendyol, Instagram gibi linkleri veya özel bağlantıları buraya ekleyebilirsiniz.',
            style: TextStyle(
              color: mutedText.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        for (int i = 0; i < _marketplaceLinks.length; i++) ...[
          const SizedBox(height: 8),
          _buildMarketplaceLinkRow(i),
        ],
      ],
    );
  }

  Widget _buildMarketplaceLinkRow(int index) {
    final link = _marketplaceLinks[index];
    final isCustom = _customPlatformLinkIds.contains(link.id) ||
        link.platform == 'Özel...' ||
        (!_platformOptions.contains(link.platform) && link.platform.isNotEmpty);
    final dropdownValue =
        isCustom
            ? 'Özel...'
            : (_platformOptions.contains(link.platform) ? link.platform : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Platform seçici
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: dropdownValue,
                hint: const Text('Platform', style: TextStyle(fontSize: 13)),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: inputBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: cardBorder),
                  ),
                ),
                items:
                    _platformOptions
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(
                              p,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (val) {
                  setState(() {
                    if (val == 'Özel...') {
                      link.platform = 'Özel...';
                      _customPlatformLinkIds.add(link.id);
                    } else {
                      link.platform = val ?? '';
                      _customPlatformLinkIds.remove(link.id);
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            // URL alanı
            Expanded(
              flex: 3,
              child: TextFormField(
                key: ValueKey('${link.id}-url'),
                initialValue: link.url,
                onChanged: (val) => _marketplaceLinks[index].url = val,
                style: const TextStyle(
                  fontSize: 13,
                  color: darkText,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: () {
                    final p = link.platform.toLowerCase();
                    if (p.contains('trendyol')) {
                      return 'trendyol.com/magaza/...';
                    }
                    if (p.contains('hepsiburada')) {
                      return 'hepsiburada.com/magaza/...';
                    }
                    if (p.contains('instagram')) return 'instagram.com/...';
                    if (p.contains('google')) return 'g.page/...';
                    if (p.contains('whatsapp')) return 'wa.me/...';
                    return 'https://...';
                  }(),
                  hintStyle: TextStyle(
                    color: mutedText.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  filled: true,
                  fillColor: inputBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: cardBorder),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: () => _removeMarketplaceLink(index),
              icon: const Icon(Icons.close_rounded, size: 18, color: mutedText),
              style: IconButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(28, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        // Özel... modu: platform başlığı metin alanı
        if (isCustom) ...[
          const SizedBox(height: 6),
          TextFormField(
            key: ValueKey('${link.id}-platform'),
            initialValue: link.platform == 'Özel...' ? '' : link.platform,
            onChanged: (val) => setState(() => _marketplaceLinks[index].platform = val.trim()),
            style: const TextStyle(
              fontSize: 13,
              color: darkText,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'Bağlantı başlığı (ör. Randevu al)',
              hintStyle: TextStyle(
                color: mutedText.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              prefixIcon: Icon(
                Icons.edit_rounded,
                size: 16,
                color: primaryColor.withValues(alpha: 0.7),
              ),
              filled: true,
              fillColor: inputBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: primaryColor.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ],
        // Kısa açıklama (isteğe bağlı)
        const SizedBox(height: 6),
        TextFormField(
          key: ValueKey('${link.id}-subtitle'),
          initialValue: link.subtitle,
          onChanged: (val) => _marketplaceLinks[index].subtitle = val.trim(),
          style: const TextStyle(
            fontSize: 12,
            color: darkText,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Kısa açıklama (isteğe bağlı)',
            hintStyle: TextStyle(
              color: mutedText.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: cardBorder),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfferingsSection() {
    final config = BusinessCategoryConfig.fromCategoryLabel(_selectedKategori);
    final sectionTitle = config.sectionTitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              sectionTitle,
              style: const TextStyle(
                color: softText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            if (_offerings.length < 6)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _offerings.add(
                      StoreOffering(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: '',
                        description: '',
                        price: '',
                      ),
                    );
                  });
                },
                icon: const Icon(Icons.add_rounded, size: 16, color: primaryColor),
                label: const Text(
                  'Ekle',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (config.suggestedOfferings.isNotEmpty && _offerings.length < 6) ...[
          const Text(
            'Önerilenler (Eklemek için dokunun):',
            style: TextStyle(
              color: mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: config.suggestedOfferings.map((sug) {
              return ActionChip(
                backgroundColor: Colors.white,
                side: const BorderSide(color: cardBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                label: Text(
                  '${config.emoji} ${sug.title}',
                  style: const TextStyle(fontSize: 11, color: darkText, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  if (_offerings.length >= 6) {
                    _showSnackBar('En fazla 6 adet hizmet ekleyebilirsiniz.');
                    return;
                  }
                  final trimmedTitle = sug.title.trim().toLowerCase();
                  final isDuplicate = _offerings.any(
                    (o) => o.title.trim().toLowerCase() == trimmedTitle,
                  );
                  if (isDuplicate) {
                    _showSnackBar('Bu hizmet zaten eklenmiş.');
                    return;
                  }
                  setState(() {
                    _offerings.add(
                      StoreOffering(
                        id: '${DateTime.now().millisecondsSinceEpoch}_${sug.title.hashCode}',
                        title: sug.title,
                        description: sug.description,
                        price: sug.price,
                        durationMinutes: sug.durationMinutes,
                        isBookable: sug.isBookable,
                      ),
                    );
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
        ],
        if (_offerings.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Henüz eklenmiş hizmet veya öne çıkan bulunmuyor. Müşterilerinize sunduğunuz hizmetleri veya ürünleri buradan ekleyebilirsiniz (en fazla 6 adet).',
              style: TextStyle(
                color: mutedText.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        for (int i = 0; i < _offerings.length; i++) ...[
          _buildOfferingRow(i),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildOfferingRow(int index) {
    final offering = _offerings[index];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  key: ValueKey('${offering.id}-title'),
                  initialValue: offering.title,
                  onChanged: (val) => offering.title = val,
                  maxLength: 60,
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                  style: const TextStyle(fontSize: 13, color: darkText, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'Hizmet / Ürün Adı (örn: Saç Kesimi)',
                    hintStyle: TextStyle(
                      color: mutedText.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  key: ValueKey('${offering.id}-price'),
                  initialValue: offering.price,
                  onChanged: (val) => offering.price = val,
                  maxLength: 30,
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                  style: const TextStyle(fontSize: 13, color: primaryColor, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'Fiyat (örn: 150 TL)',
                    hintStyle: TextStyle(
                      color: mutedText.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _offerings.removeAt(index);
                  });
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: dangerColor),
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(28, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const Divider(height: 1, color: cardBorder),
          TextFormField(
            key: ValueKey('${offering.id}-desc'),
            initialValue: offering.description,
            onChanged: (val) => offering.description = val,
            maxLength: 120,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
            maxLines: 2,
            style: const TextStyle(fontSize: 12, color: softText, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Kısa açıklama (örn: Yıkama ve fön dahil hizmet)',
              hintStyle: TextStyle(
                color: mutedText.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: InputBorder.none,
            ),
          ),
          if (_selectedKategori == 'Kuaför') ...[
            const Divider(height: 1, color: cardBorder),
            const SizedBox(height: 4),
            Row(
              children: [
                const SizedBox(width: 8),
                const Icon(Icons.calendar_today_rounded, size: 14, color: mutedText),
                const SizedBox(width: 4),
                const Text(
                  'Randevuya Açık',
                  style: TextStyle(fontSize: 12, color: softText, fontWeight: FontWeight.w600),
                ),
                Switch(
                  value: offering.isBookable,
                  activeColor: primaryColor,
                  onChanged: (val) {
                    setState(() {
                      offering.isBookable = val;
                    });
                  },
                ),
                const Spacer(),
                if (offering.isBookable) ...[
                  const Icon(Icons.timer_rounded, size: 14, color: mutedText),
                  const SizedBox(width: 4),
                  DropdownButton<int>(
                    value: offering.durationMinutes,
                    items: [15, 30, 45, 60, 90, 120, 180, 240].map((int val) {
                      return DropdownMenuItem<int>(
                        value: val,
                        child: Text(
                          '$val dk',
                          style: const TextStyle(fontSize: 12, color: darkText, fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        if (val != null) {
                          offering.durationMinutes = val;
                        }
                      });
                    },
                    underline: const SizedBox(),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookingSettingsSection() {

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: ExpansionTile(
        title: const Text(
          '📅 Randevu Ayarları',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: darkText,
          ),
        ),
        subtitle: Text(
          _bookingIsEnabled ? 'Aktif · Kapasite: $_bookingCapacity kişi' : 'Pasif',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _bookingIsEnabled ? primaryColor : mutedText,
          ),
        ),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8, bottom: 8),
        shape: const Border(),
        children: [
          Row(
            children: [
              const Text(
                'Randevu Alınabilsin',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: softText),
              ),
              const Spacer(),
              Switch(
                value: _bookingIsEnabled,
                activeColor: primaryColor,
                onChanged: (val) {
                  setState(() {
                    _bookingIsEnabled = val;
                  });
                },
              ),
            ],
          ),
          if (_bookingIsEnabled) ...[
            const Divider(color: cardBorder),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Aynı Anda Kapasite',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: softText),
                ),
                const Spacer(),
                DropdownButton<int>(
                  value: _bookingCapacity,
                  items: [1, 2, 3, 4, 5].map((int val) {
                    return DropdownMenuItem<int>(
                      value: val,
                      child: Text(
                        '$val kişi',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkText),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      if (val != null) {
                        _bookingCapacity = val;
                      }
                    });
                  },
                ),
              ],
            ),
            const Divider(color: cardBorder),
            const SizedBox(height: 8),
            const Text(
              'Öğle Arası Saatleri',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: softText),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _bookingLunchBreak['start'] ?? '12:00',
                    decoration: const InputDecoration(labelText: 'Başlangıç', isDense: true),
                    items: ['11:00', '11:30', '12:00', '12:30', '13:00', '13:30'].map((String val) {
                      return DropdownMenuItem<String>(
                        value: val,
                        child: Text(val, style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        if (val != null) {
                          _bookingLunchBreak['start'] = val;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _bookingLunchBreak['end'] ?? '13:00',
                    decoration: const InputDecoration(labelText: 'Bitiş', isDense: true),
                    items: ['12:00', '12:30', '13:00', '13:30', '14:00', '14:30'].map((String val) {
                      return DropdownMenuItem<String>(
                        value: val,
                        child: Text(val, style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        if (val != null) {
                          _bookingLunchBreak['end'] = val;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Aktif', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Checkbox(
                  value: _bookingLunchBreak['active'] ?? true,
                  activeColor: primaryColor,
                  onChanged: (val) {
                    setState(() {
                      _bookingLunchBreak['active'] = val ?? false;
                    });
                  },
                ),
              ],
            ),
            const Divider(color: cardBorder),
            const SizedBox(height: 8),
            const Text(
              'Çalışma Gün ve Saatleri',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: softText),
            ),
            const SizedBox(height: 8),
            for (String day in ['1', '2', '3', '4', '5', '6', '7']) ...[
              _buildDayRow(day),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDayRow(String day) {
    final dayNames = {
      '1': 'Pazartesi',
      '2': 'Salı',
      '3': 'Çarşamba',
      '4': 'Perşembe',
      '5': 'Cuma',
      '6': 'Cumartesi',
      '7': 'Pazar',
    };
    final dayHours = _bookingWorkingHours[day] ?? {'start': '09:00', 'end': '19:00', 'active': true};
    final isActive = dayHours['active'] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              dayNames[day]!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? darkText : mutedText,
              ),
            ),
          ),
          Checkbox(
            value: isActive,
            activeColor: primaryColor,
            onChanged: (val) {
              setState(() {
                dayHours['active'] = val ?? false;
                _bookingWorkingHours[day] = dayHours;
              });
            },
          ),
          if (isActive) ...[
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButton<String>(
                value: dayHours['start'] ?? '09:00',
                items: ['07:00', '08:00', '08:30', '09:00', '09:30', '10:00'].map((String val) {
                  return DropdownMenuItem<String>(
                    value: val,
                    child: Text(val, style: const TextStyle(fontSize: 11)),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    if (val != null) {
                      dayHours['start'] = val;
                      _bookingWorkingHours[day] = dayHours;
                    }
                  });
                },
                underline: const SizedBox(),
              ),
            ),
            const Text('-', style: TextStyle(color: mutedText)),
            Expanded(
              child: DropdownButton<String>(
                value: dayHours['end'] ?? '19:00',
                items: ['16:00', '17:00', '18:00', '19:00', '20:00', '21:00', '22:00', '23:00'].map((String val) {
                  return DropdownMenuItem<String>(
                    value: val,
                    child: Text(val, style: const TextStyle(fontSize: 11)),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    if (val != null) {
                      dayHours['end'] = val;
                      _bookingWorkingHours[day] = dayHours;
                    }
                  });
                },
                underline: const SizedBox(),
              ),
            ),
          ] else ...[
            const Expanded(
              child: Text(
                'Kapalı',
                style: TextStyle(fontSize: 12, color: mutedText, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Published Summary ────────────────────────────────────────────────────
  Widget _buildPublishedSummary() {
    final info = _publishedInfo!;
    final cover = _coverUrl?.trim() ?? '';

    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cover image area
          AspectRatio(
            aspectRatio: 16 / 9,
            child:
                cover.isNotEmpty
                    ? Image.network(
                      cover,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _coverPlaceholder(),
                    )
                    : _coverPlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFFDF5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        '✅ Keşfet\'te yayında',
                        style: TextStyle(
                          color: Color(0xFF047857),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: widget.onOpenExplore,
                      icon: const Icon(Icons.travel_explore_rounded, size: 18),
                      color: primaryColor,
                      tooltip: 'Keşfet\'te Gör',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFFFF4EF),
                        minimumSize: const Size(36, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  info.name.trim().isNotEmpty ? info.name : 'Vitrinim',
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  info.publicLink,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final buttonWidth =
            constraints.maxWidth < 520
                ? constraints.maxWidth
                : (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (_bookingIsEnabled)
              _actionButton(
                width: buttonWidth,
                label: 'Randevuları Yönet',
                icon: Icons.calendar_month_rounded,
                onPressed: _openBookingManagement,
              ),
            _actionButton(
              width: buttonWidth,
              label: 'Yayındaki Vitrini Aç',
              icon: Icons.open_in_new_rounded,
              onPressed: _openPublicVitrin,
            ),
            _actionButton(
              width: buttonWidth,
              label: 'Linki Kopyala',
              icon: Icons.copy_rounded,
              onPressed: _copyLink,
            ),
            _actionButton(
              width: buttonWidth,
              label: 'QR Göster',
              icon: Icons.qr_code_2_rounded,
              onPressed: _showQrSheet,
            ),
          ],
        );
      },
    );
  }

  Widget _actionButton({
    required double width,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: width,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: darkText,
          backgroundColor: Colors.white,
          side: const BorderSide(color: cardBorder),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ─── Cover Picker ─────────────────────────────────────────────────────────
  Widget _buildCoverPicker() {
    final hasCover =
        _coverBytes != null || (_coverUrl?.trim().isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kapak Fotoğrafı',
          style: TextStyle(
            color: softText,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickCoverPhoto,
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 7,
            child: Container(
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child:
                  hasCover
                      ? Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_coverBytes != null)
                            Image.memory(_coverBytes!, fit: BoxFit.cover)
                          else
                            Image.network(
                              _coverUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _coverPlaceholder(),
                            ),
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: _badge(
                              _coverFileName == null
                                  ? 'Fotoğrafı değiştir'
                                  : _coverFileName!,
                            ),
                          ),
                        ],
                      )
                      : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_rounded,
                            color: primaryColor,
                            size: 30,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Kapak fotoğrafı ekle',
                            style: TextStyle(
                              color: darkText,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'İsteğe bağlı — sonra da eklenebilir',
                            style: TextStyle(
                              color: mutedText,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Compact Gallery Row (kapak altında, yatay scroll) ─────────────────
  Widget _buildCompactGalleryRow() {
    const double thumbSize = 68.0;
    final canAdd = _galleryItems.length < _maxGalleryPhotos;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add button
        if (canAdd)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: _pickGalleryPhotos,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: thumbSize,
                height: thumbSize,
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_photo_alternate_rounded,
                      color: primaryColor,
                      size: 22,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _galleryItems.isEmpty ? 'Galeri' : '+',
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Thumbnails
        Expanded(
          child:
              _galleryItems.isEmpty
                  ? Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: Text(
                      'Galeri fotoğrafı ekleyebilirsin',
                      style: TextStyle(
                        color: mutedText.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                  : SizedBox(
                    height: thumbSize,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _galleryItems.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, index) {
                        final item = _galleryItems[index];
                        Widget img;
                        if (item.hasLocalBytes) {
                          img = Image.memory(item.bytes!, fit: BoxFit.cover);
                        } else if (item.hasUrl) {
                          img = Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => const Icon(
                                  Icons.broken_image_rounded,
                                  color: mutedText,
                                  size: 20,
                                ),
                          );
                        } else {
                          img = const Icon(
                            Icons.image_rounded,
                            color: mutedText,
                            size: 20,
                          );
                        }

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: thumbSize,
                              height: thumbSize,
                              decoration: BoxDecoration(
                                color: inputBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: cardBorder),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: img,
                            ),
                            if (index == 0)
                              Positioned(
                                bottom: 3,
                                left: 3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Kapak',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              top: -4,
                              right: -4,
                              child: GestureDetector(
                                onTap: () => _removeGalleryItem(index),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
        ),
        // Count badge
        if (_galleryItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 24),
            child: Text(
              '${_galleryItems.length}/$_maxGalleryPhotos',
              style: const TextStyle(
                color: mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFEFE7), Color(0xFFF8FAFC)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.storefront_rounded, color: primaryColor, size: 38),
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ─── Dropdown ─────────────────────────────────────────────────────────────
  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: softText,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: items.contains(value) ? value : items.first,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: mutedText, size: 18),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: cardBorder),
            ),
          ),
          items:
              items
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: darkText,
                        ),
                      ),
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ─── Text Field ───────────────────────────────────────────────────────────
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? errorText,
    bool validateWhatsapp = false,
    FocusNode? focusNode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: softText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: darkText,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          onChanged: (value) {
            if (errorText != null || validateWhatsapp) {
              setState(() {
                _nameError = null;
                _addressError = null;
                if (validateWhatsapp) {
                  _whatsappError =
                      value.trim().isEmpty ||
                              WhatsAppLinkHelper.isValidTurkeyMobile(value)
                          ? null
                          : WhatsAppLinkHelper.invalidNumberMessage;
                } else {
                  _whatsappError = null;
                }
              });
            }
          },
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: mutedText, size: 18),
            hintText: hint,
            hintStyle: TextStyle(
              color: mutedText.withValues(alpha: 0.62),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: inputBg,
            errorText: errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: primaryColor, width: 1.4),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }
}
