import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vitrinx/models/chat_message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vitrinx/config/public_site_config.dart';
import 'package:vitrinx/config/instagram_sync_config.dart';
import 'package:vitrinx/config/business_category_config.dart';
import 'package:vitrinx/config/turkey_cities_config.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/models/legal_document.dart';
import 'package:vitrinx/screens/legal_screen.dart';
import 'package:vitrinx/services/legal_document_service.dart';
import 'package:vitrinx/services/location_service.dart';
import 'package:vitrinx/services/store_local_storage_service.dart';
import 'package:vitrinx/services/seo_service.dart';
import 'package:vitrinx/services/store_publish_service.dart';
import 'package:vitrinx/services/store_shelf_upload_service.dart';
import 'package:vitrinx/utils/gallery_image_file_validator.dart';
import 'package:vitrinx/utils/token_generator.dart';
import 'package:vitrinx/utils/whatsapp_link_helper.dart';
import 'package:vitrinx/widgets/gallery_delete_confirmation_dialog.dart';
import 'package:vitrinx/widgets/instagram_sync_section.dart';
import 'package:vitrinx/theme/app_colors.dart';
import 'package:vitrinx/theme/app_text_styles.dart';
import 'package:vitrinx/controllers/store_editor_controller.dart';
import 'package:vitrinx/config/app_router.dart';
import 'package:vitrinx/config/legal_config.dart';

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
  final LegalDocumentService? legalDocumentService;

  const MyVitrinScreen({
    super.key,
    this.initialName,
    this.onPublished,
    this.onOpenExplore,
    this.legalDocumentService,
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
  bool _isWithdrawingConsent = false;

  PublishingLegalDocuments? _legalDocuments;
  bool _isLoadingLegalDocuments = true;
  String? _legalDocumentsError;
  bool _privacyNoticeAcknowledged = false;
  bool _termsAccepted = false;
  bool _publicationConsentAccepted = false;

  late final StoreEditorController _controller;

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
      _controller = StoreEditorController();
      await _controller.initialize(widget.initialName);

      if (!mounted) return;
      setState(() {
        _data = _controller.data;
        _publishedInfo = _controller.publishedInfo;
        _nameController.text = _data.name;
        _whatsappController.text = _data.whatsapp;
        _addressController.text = _data.address;
        _descriptionController.text = _data.description;
        _instagramController.text = _data.instagram;
        _websiteController.text = _publishedInfo?.publicLink ?? _data.website;
        _googleBusinessLinkController.text = _data.googleBusinessLink;
        _selectedProvinceCode = _controller.selectedProvinceCode;
        _selectedProvinceName = _controller.selectedProvinceName;
        _selectedDistrictCode = _controller.selectedDistrictCode;
        _selectedDistrictName = _controller.selectedDistrictName;

        _coverUrl = _controller.coverUrl;
        _selectedKategori = _controller.selectedKategori;
        _selectedStatus = _controller.selectedStatus;
        _latitude = _controller.latitude;
        _longitude = _controller.longitude;
        _locationAccuracyMeters = _controller.locationAccuracyMeters;

        _galleryItems.clear();
        _galleryItems.addAll(
          _data.displayGalleryItems
              .take(_maxGalleryPhotos)
              .map(_GalleryItem.fromStoreItem),
        );

        _marketplaceLinks.clear();
        _marketplaceLinks.addAll(_data.marketplaceLinks);
        _customPlatformLinkIds.clear();
        for (final link in _marketplaceLinks) {
          if (!_platformOptions.contains(link.platform) &&
              link.platform.isNotEmpty) {
            _customPlatformLinkIds.add(link.id);
          }
        }
        _offerings.clear();
        _offerings.addAll(_data.offerings);

        _bookingIsEnabled = _controller.bookingIsEnabled;
        _bookingCapacity = _controller.bookingCapacity;
        _bookingWorkingHours = _controller.bookingWorkingHours;
        _bookingLunchBreak = _controller.bookingLunchBreak;

        _isLoading = false;
      });

      if (_publishedInfo?.slug != null && _publishedInfo!.slug.isNotEmpty) {
        _fetchArticles();
      }
      await _loadLegalDocuments();
    } catch (e) {
      debugPrint('MyVitrinScreen load error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      await _loadLegalDocuments();
    }
  }

  Future<void> _loadLegalDocuments() async {
    if (!mounted) return;
    if (!LegalConfig.hasCompleteDataControllerIdentity) {
      setState(() {
        _legalDocuments = null;
        _legalDocumentsError = 'Yasal işletme bilgileri henüz tamamlanmadı.';
        _isLoadingLegalDocuments = false;
      });
      return;
    }
    setState(() {
      _isLoadingLegalDocuments = true;
      _legalDocumentsError = null;
    });

    try {
      final service =
          widget.legalDocumentService ?? const LegalDocumentService();
      final documents = await service.loadPublishingDocuments();
      if (!mounted) return;
      setState(() {
        _legalDocuments = documents;
        _privacyNoticeAcknowledged =
            _data.privacyNoticeAcknowledged &&
            _data.privacyNoticeVersion == documents.privacy.version &&
            _data.privacyNoticeHash == documents.privacy.contentHash;
        _termsAccepted =
            _data.termsAccepted &&
            _data.termsVersion == documents.terms.version &&
            _data.termsHash == documents.terms.contentHash;
        _publicationConsentAccepted =
            _data.publicationConsentAccepted &&
            _data.publicationConsentVersion == documents.consent.version &&
            _data.publicationConsentHash == documents.consent.contentHash;
        _isLoadingLegalDocuments = false;
      });
    } catch (e) {
      debugPrint('Legal documents load error: $e');
      if (!mounted) return;
      setState(() {
        _legalDocuments = null;
        _legalDocumentsError =
            'Güncel yasal belgeler yüklenemedi. Yayınlamadan önce tekrar deneyin.';
        _isLoadingLegalDocuments = false;
      });
    }
  }

  bool get _isLegalPublishReady =>
      LegalConfig.hasCompleteDataControllerIdentity &&
      _legalDocuments?.isComplete == true &&
      _privacyNoticeAcknowledged &&
      _termsAccepted &&
      _publicationConsentAccepted;

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

    if (!LegalConfig.hasCompleteDataControllerIdentity) {
      _showSnackBar(
        'Yasal işletme bilgileri tamamlanmadan vitrin yayınlanamaz.',
      );
      return;
    }
    if (_legalDocuments == null) {
      _showSnackBar(
        _legalDocumentsError ??
            'Güncel yasal belgeler yüklenmeden vitrin yayınlanamaz.',
      );
      return;
    }
    if (!_privacyNoticeAcknowledged ||
        !_termsAccepted ||
        !_publicationConsentAccepted) {
      _showSnackBar(
        'Yayınlamak için yasal bilgilendirme ve onayları tamamlayın.',
      );
      return;
    }

    final name = _nameController.text.trim();
    final whatsapp = _whatsappController.text.trim();
    final address = _addressController.text.trim();
    final googleLink = _googleBusinessLinkController.text.trim();
    final hasValidWhatsapp = WhatsAppLinkHelper.isValidTurkeyMobile(whatsapp);

    bool isGoogleLinkValid = true;
    if (googleLink.isNotEmpty) {
      final googleRegex = RegExp(
        r'^https:\/\/(www\.)?(search\.google\.com|g\.page|maps\.google\.com|maps\.app\.goo\.gl)\/.*$',
      );
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
      _provinceError =
          _selectedProvinceCode == null ? 'İl seçimi zorunludur' : null;
      _districtError =
          _selectedDistrictName == null ? 'İlçe seçimi zorunludur' : null;
      _googleLinkError =
          isGoogleLinkValid
              ? null
              : 'Lütfen geçerli bir Google Haritalar veya Google Yorum bağlantısı girin.';
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

    final shouldPublishBooking =
        _selectedKategori == 'Kuaför' && _bookingIsEnabled;
    final bookingServices =
        _offerings
            .where((offering) => offering.title.trim().isNotEmpty)
            .take(6)
            .map((offering) => offering.copyWith(isBookable: true))
            .toList();

    if (shouldPublishBooking && bookingServices.isEmpty) {
      _showSnackBar('Randevu açıkken en az bir randevu hizmeti eklemelisiniz.');
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
      } else if (_bookingIsEnabled) {
        for (final offering in _offerings) {
          if (offering.title.trim().isNotEmpty) {
            offering.isBookable = true;
          }
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
            ..offerings = shouldPublishBooking ? bookingServices : []
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
            ..locationAccuracyMeters = _locationAccuracyMeters
            ..privacyNoticeAcknowledged = _privacyNoticeAcknowledged
            ..privacyNoticeVersion = _legalDocuments!.privacy.version
            ..privacyNoticeHash = _legalDocuments!.privacy.contentHash
            ..termsAccepted = _termsAccepted
            ..termsVersion = _legalDocuments!.terms.version
            ..termsHash = _legalDocuments!.terms.contentHash
            ..publicationConsentAccepted = _publicationConsentAccepted
            ..publicationConsentVersion = _legalDocuments!.consent.version
            ..publicationConsentHash = _legalDocuments!.consent.contentHash;

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
      const SeoService().revalidateStore(result.slug);

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
  Future<void> _withdrawPublicationConsent() async {
    final info = _publishedInfo;
    if (info == null || _isWithdrawingConsent) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Vitrini Yayından Kaldır'),
            content: const Text(
              'Yayınlama rızanız geri çekilecek ve vitrininiz herkese açık görünümden kaldırılacak. Yerel taslağınız silinmeyecek.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Yayından Kaldır'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isWithdrawingConsent = true);
    try {
      await const StorePublishService().withdrawPublicationConsent(
        slug: info.slug,
        editToken: info.editToken,
      );
      _data.publicationConsentAccepted = false;
      _data.publicationConsentWithdrawnAt = DateTime.now().toUtc();
      await _storage.saveVitrinData(_data);
      await _storage.clearPublishedVitrinInfo();
      if (!mounted) return;
      setState(() {
        _publishedInfo = null;
        _websiteController.clear();
        _publicationConsentAccepted = false;
      });
      _showSnackBar(
        'Yayınlama rızanız geri çekildi ve vitrininiz yayından kaldırıldı.',
      );
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(
        error is StorePublishException
            ? error.message
            : 'Vitrin yayından kaldırılamadı. Lütfen tekrar deneyin.',
      );
    } finally {
      if (mounted) setState(() => _isWithdrawingConsent = false);
    }
  }

  Future<void> _deleteVitrin() async {
    if (_isDeleting) return;
    setState(() => _isDeleting = true);

    try {
      await _controller.deleteVitrin();
      if (!mounted) return;
      AppRouter.navigateToLanding(context);
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

  Future<void> _handleInstagramProductImported(Product product) async {
    final existingIndex = _data.products.indexWhere(
      (item) =>
          item.id == product.id ||
          (product.sourceMediaId?.isNotEmpty == true &&
              item.sourceMediaId == product.sourceMediaId),
    );

    setState(() {
      if (existingIndex >= 0) {
        _data.products[existingIndex] = product;
      } else {
        _data.products.insert(0, product);
      }
    });
    await _storage.saveVitrinData(_data);
    if (!mounted) return;
    _showSnackBar('${product.name} vitrininize eklendi.');
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
    Navigator.pushNamed(context, '/v/$slug');
  }

  void _openBookingManagement() {
    final slug = _publishedInfo?.slug ?? _data.slug;
    if (slug.isEmpty) return;
    AppRouter.navigateToBookingManagement(context, slug: slug);
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

              if (_selectedKategori == 'Kuaför') ...[
                KeyedSubtree(
                  key: _productsKey,
                  child: _buildBookingSettingsSection(),
                ),
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

              if (hasPublished && InstagramSyncConfig.enabled) ...[
                InstagramSyncSection(
                  storeSlug: _publishedInfo!.slug,
                  editToken: _publishedInfo!.editToken,
                  defaultCategory: _selectedKategori,
                  onProductImported: _handleInstagramProductImported,
                  onMessage: _showSnackBar,
                ),
                const SizedBox(height: 14),
              ],

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

              _buildLegalConsentSection(),
              const SizedBox(height: 16),

              // ── Publish Button ─────────────────────────────────────────
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed:
                      _isPublishing || !_isLegalPublishReady
                          ? null
                          : _publishVitrin,
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
          _buildVisibilityHubCard(),
        ],

        // ── Danger Zone ────────────────────────────────────────────────────
        if (hasPublished) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed:
                  _isWithdrawingConsent ? null : _withdrawPublicationConsent,
              icon: const Icon(Icons.visibility_off_outlined, size: 16),
              label: Text(
                _isWithdrawingConsent
                    ? 'Yayından kaldırılıyor...'
                    : 'Yayınlama Rızasını Geri Çek',
                style: AppTextStyles.labelBold,
              ),
            ),
          ),
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

  Widget _buildLegalConsentSection() {
    final canAccept =
        !_isLoadingLegalDocuments &&
        _legalDocuments != null &&
        LegalConfig.hasCompleteDataControllerIdentity;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: primaryColor, size: 21),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Yasal Bilgilendirme ve Yayınlama Onayı',
                  style: AppTextStyles.subTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Taslağınızı onay vermeden düzenleyebilirsiniz. Bu beyanlar yalnızca herkese açık yayınlama için gereklidir.',
            style: AppTextStyles.caption,
          ),
          if (!LegalConfig.hasCompleteDataControllerIdentity) ...[
            const SizedBox(height: 12),
            const Text(
              'Xpodiumyours resmî unvan ve adres bilgileri tamamlanmadığı için yayınlama geçici olarak kapalıdır.',
              style: AppTextStyles.errorText,
            ),
          ] else if (_isLoadingLegalDocuments) ...[
            const SizedBox(height: 14),
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ] else if (_legalDocumentsError != null) ...[
            const SizedBox(height: 12),
            Text(_legalDocumentsError!, style: AppTextStyles.errorText),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _loadLegalDocuments,
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('Belgeleri Tekrar Yükle'),
              ),
            ),
          ],
          const SizedBox(height: 8),
          CheckboxListTile(
            key: const ValueKey('privacy-notice-checkbox'),
            value: _privacyNoticeAcknowledged,
            onChanged:
                canAccept
                    ? (value) => setState(
                      () => _privacyNoticeAcknowledged = value ?? false,
                    )
                    : null,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'Aydınlatma Metni’ni okudum ve bilgilendirildim.',
              style: AppTextStyles.formLabel,
            ),
          ),
          _legalLink(label: 'Aydınlatma Metni', type: LegalPageType.privacy),
          CheckboxListTile(
            key: const ValueKey('terms-checkbox'),
            value: _termsAccepted,
            onChanged:
                canAccept
                    ? (value) => setState(() => _termsAccepted = value ?? false)
                    : null,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'Kullanım Şartları’nı kabul ediyorum.',
              style: AppTextStyles.formLabel,
            ),
          ),
          _legalLink(label: 'Kullanım Şartları', type: LegalPageType.terms),
          CheckboxListTile(
            key: const ValueKey('publication-consent-checkbox'),
            value: _publicationConsentAccepted,
            onChanged:
                canAccept
                    ? (value) => setState(
                      () => _publicationConsentAccepted = value ?? false,
                    )
                    : null,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'Verilerimin dijital vitrinimde kamuya açık yayınlanmasına açık rıza veriyorum.',
              style: AppTextStyles.formLabel,
            ),
          ),
          _legalLink(label: 'Açık Rıza Beyanı', type: LegalPageType.consent),
        ],
      ),
    );
  }

  Widget _legalLink({required String label, required LegalPageType type}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => AppRouter.navigateToLegal(context, type),
        icon: const Icon(Icons.open_in_new_rounded, size: 15),
        label: Text(label),
      ),
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
    final districts =
        _selectedProvinceCode != null
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
          initialValue: _selectedProvinceCode,
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.map_rounded,
              color: mutedText,
              size: 18,
            ),
            filled: true,
            fillColor: inputBg,
            errorText: _provinceError,
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
          hint: const Text(
            'İl Seçiniz',
            style: TextStyle(fontSize: 14, color: mutedText),
          ),
          items:
              turkeyProvinces.map((p) {
                return DropdownMenuItem<String>(
                  value: p.code,
                  child: Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                );
              }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedProvinceCode = val;
              _selectedProvinceName =
                  val != null
                      ? turkeyProvinces.firstWhere((p) => p.code == val).name
                      : '';
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
          initialValue: _selectedDistrictName,
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.location_city_rounded,
              color: mutedText,
              size: 18,
            ),
            filled: true,
            fillColor: inputBg,
            errorText: _districtError,
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
          hint: const Text(
            'İlçe Seçiniz',
            style: TextStyle(fontSize: 14, color: mutedText),
          ),
          disabledHint: const Text(
            'Önce İl Seçiniz',
            style: TextStyle(fontSize: 14, color: mutedText),
          ),
          items:
              districts.map((d) {
                return DropdownMenuItem<String>(
                  value: d,
                  child: Text(
                    d,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                );
              }).toList(),
          onChanged:
              _selectedProvinceCode == null
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

  Future<void> _openBlogEditor({Map<String, dynamic>? initialArticle}) async {
    final slug = _publishedInfo?.slug ?? _data.slug;
    if (slug.trim().isEmpty) {
      _showSnackBar('Önce vitrini yayına almanız gerekir.');
      return;
    }

    final result = await AppRouter.navigateToBlogEditor(
      context,
      slug: slug,
      article: initialArticle,
    );

    if (result == true) {
      await _fetchArticles();
    }
  }

  Widget _buildVisibilityHubCard() {
    final publicLink =
        (_publishedInfo?.publicLink.trim().isNotEmpty == true)
            ? _publishedInfo!.publicLink.trim()
            : _websiteController.text.trim();
    final hasPublished = _publishedInfo?.isComplete == true;
    final hasWebLink = publicLink.isNotEmpty;
    final hasLocation =
        _addressController.text.trim().isNotEmpty ||
        (_latitude != null && _longitude != null);
    final hasGoogleReview =
        _googleBusinessLinkController.text.trim().isNotEmpty;
    final hasProfileDescription = _descriptionController.text.trim().isNotEmpty;
    final publishedArticles =
        _articles
            .where((article) => article['status']?.toString() == 'published')
            .toList();
    final hasPublishedArticle = publishedArticles.isNotEmpty;
    final completedCount =
        [
          hasPublished,
          hasWebLink,
          hasLocation,
          hasGoogleReview,
          hasProfileDescription,
          hasPublishedArticle,
        ].where((value) => value).length;

    final hasCoreInfo =
        hasPublished && hasWebLink && hasLocation && hasProfileDescription;
    final isReady = hasCoreInfo && hasGoogleReview;
    final statusLabel =
        isReady
            ? 'Hazır'
            : hasCoreInfo
            ? 'Geliştirilebilir'
            : 'Eksik bilgi var';
    final statusColor =
        isReady
            ? const Color(0xFF047857)
            : hasCoreInfo
            ? const Color(0xFFB45309)
            : const Color(0xFFDC2626);
    final statusBg =
        isReady
            ? const Color(0xFFEFFDF5)
            : hasCoreInfo
            ? const Color(0xFFFFF7ED)
            : const Color(0xFFFEF2F2);
    final helperText =
        isReady
            ? 'Temel bilgiler tamam. Güncel içerik ekledikçe görünürlük güçlenir.'
            : hasCoreInfo
            ? 'Temel bilgiler hazır. Google yorum linki ve içerik eklemek vitrini güçlendirir.'
            : 'Google için önce yayın linki, adres/konum ve kısa açıklamayı tamamla.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.travel_explore_rounded,
                color: primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Google Görünürlük',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Vitrin bilgilerinden otomatik hazırlanır. Sıralama garantisi vermez; doğru bilgi, erişilebilir sayfa ve güncel içerik görünürlüğü destekler.',
            style: TextStyle(
              color: mutedText.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: primaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$completedCount/6 kontrol tamamlandı. $helperText',
                    style: const TextStyle(
                      color: darkText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 520;
              final tileWidth =
                  isNarrow
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 16) / 3;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildVisibilityCheckTile(
                    width: tileWidth,
                    icon: Icons.public_rounded,
                    title: 'Vitrin yayında',
                    isComplete: hasPublished,
                  ),
                  _buildVisibilityCheckTile(
                    width: tileWidth,
                    icon: Icons.link_rounded,
                    title: 'Web linki hazır',
                    isComplete: hasWebLink,
                  ),
                  _buildVisibilityCheckTile(
                    width: tileWidth,
                    icon: Icons.place_rounded,
                    title: 'Adres veya konum',
                    isComplete: hasLocation,
                  ),
                  _buildVisibilityCheckTile(
                    width: tileWidth,
                    icon: Icons.rate_review_rounded,
                    title: 'Google yorum linki',
                    isComplete: hasGoogleReview,
                  ),
                  _buildVisibilityCheckTile(
                    width: tileWidth,
                    icon: Icons.notes_rounded,
                    title: 'Kısa açıklama',
                    isComplete: hasProfileDescription,
                  ),
                  _buildVisibilityCheckTile(
                    width: tileWidth,
                    icon: Icons.article_rounded,
                    title: 'Yayında içerik',
                    isComplete: hasPublishedArticle,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (hasGoogleReview)
                OutlinedButton.icon(
                  onPressed: _showGoogleReviewQrSheet,
                  icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                  label: const Text(
                    'Yorum QR kodu',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: const BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              else
                _buildVisibilityHintChip(
                  icon: Icons.rate_review_rounded,
                  text: 'Google yorum linki ekle',
                ),
              TextButton.icon(
                onPressed: () => _openBlogEditor(),
                icon: const Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: primaryColor,
                ),
                label: const Text(
                  'Yeni Yazı',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          if (_isLoadingArticles) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              minHeight: 2,
              color: primaryColor,
              backgroundColor: Color(0xFFE5E7EB),
            ),
          ] else if (publishedArticles.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'İçerik ve Duyurular',
              style: TextStyle(
                color: darkText,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            ...publishedArticles.take(2).map(_buildArticleSummaryRow),
          ],
        ],
      ),
    );
  }

  Widget _buildVisibilityCheckTile({
    required double width,
    required IconData icon,
    required String title,
    required bool isComplete,
  }) {
    final color = isComplete ? const Color(0xFF047857) : mutedText;

    return SizedBox(
      width: width,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isComplete ? const Color(0xFFEFFDF5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isComplete ? const Color(0xFFBBF7D0) : cardBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isComplete ? const Color(0xFF065F46) : darkText,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              isComplete
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: color,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityHintChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFFB45309)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Color(0xFF9A3412),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleSummaryRow(Map<String, dynamic> article) {
    final title = article['title']?.toString().trim() ?? '';
    final seoScore = article['seo_score'] ?? 0;

    return InkWell(
      onTap: () => _openBlogEditor(initialArticle: article),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.article_rounded,
                color: primaryColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title.isEmpty ? 'Yayınlanan yazı' : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: darkText,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'SEO $seoScore',
              style: const TextStyle(
                color: mutedText,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoogleReviewQrSheet() {
    final link = _googleBusinessLinkController.text.trim();
    if (link.isEmpty) {
      _showSnackBar(
        'Lütfen önce Google Yorum Bağlantısı girin ve vitrininizi kaydedin.',
      );
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
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFDC2626),
                        size: 20,
                      ),
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
    final isCustom =
        _customPlatformLinkIds.contains(link.id) ||
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
                initialValue: dropdownValue,
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
            onChanged:
                (val) => setState(
                  () => _marketplaceLinks[index].platform = val.trim(),
                ),
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

  Widget _buildBookingServicesSection() {
    final config = BusinessCategoryConfig.fromCategoryLabel(_selectedKategori);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Randevu Hizmetleri',
              style: TextStyle(
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
                        isBookable: true,
                      ),
                    );
                  });
                },
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (config.suggestedOfferings.isNotEmpty && _offerings.length < 6) ...[
          const Text(
            'Hazır hizmetler (eklemek için dokunun):',
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
            children:
                config.suggestedOfferings.map((sug) {
                  return ActionChip(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: cardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    label: Text(
                      '${config.emoji} ${sug.title}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: darkText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      if (_offerings.length >= 6) {
                        _showSnackBar(
                          'En fazla 6 adet hizmet ekleyebilirsiniz.',
                        );
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
                            id:
                                '${DateTime.now().millisecondsSinceEpoch}_${sug.title.hashCode}',
                            title: sug.title,
                            description: sug.description,
                            price: sug.price,
                            durationMinutes: sug.durationMinutes,
                            isBookable: true,
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
              'Müşterinin randevu alırken seçeceği hizmetleri ekleyin. Bu liste public profilde görünmez.',
              style: TextStyle(
                color: mutedText.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        for (int i = 0; i < _offerings.length; i++) ...[
          _buildBookingServiceRow(i),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildBookingServiceRow(int index) {
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
                  buildCounter:
                      (
                        context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
                  style: const TextStyle(
                    fontSize: 13,
                    color: darkText,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Randevu hizmeti (örn: Saç Kesimi)',
                    hintStyle: TextStyle(
                      color: mutedText.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
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
                  buildCounter:
                      (
                        context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
                  style: const TextStyle(
                    fontSize: 13,
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Fiyat (örn: 150 TL)',
                    hintStyle: TextStyle(
                      color: mutedText.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
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
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: dangerColor,
                ),
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
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) => null,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 12,
              color: softText,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Kısa açıklama (örn: Yıkama ve fön dahil hizmet)',
              hintStyle: TextStyle(
                color: mutedText.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              border: InputBorder.none,
            ),
          ),
          const Divider(height: 1, color: cardBorder),
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 8),
              const Icon(Icons.timer_rounded, size: 14, color: mutedText),
              const SizedBox(width: 4),
              const Text(
                'Süre',
                style: TextStyle(
                  fontSize: 12,
                  color: softText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              DropdownButton<int>(
                value: offering.durationMinutes,
                items:
                    [15, 30, 45, 60, 90, 120, 180, 240].map((int val) {
                      return DropdownMenuItem<int>(
                        value: val,
                        child: Text(
                          '$val dk',
                          style: const TextStyle(
                            fontSize: 12,
                            color: darkText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: (val) {
                  setState(() {
                    if (val != null) {
                      offering.durationMinutes = val;
                    }
                    offering.isBookable = true;
                  });
                },
                underline: const SizedBox(),
              ),
              const SizedBox(width: 8),
            ],
          ),
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
          _bookingIsEnabled
              ? 'Aktif · Kapasite: $_bookingCapacity kişi'
              : 'Pasif',
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
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: softText,
                ),
              ),
              const Spacer(),
              Switch(
                value: _bookingIsEnabled,
                activeThumbColor: primaryColor,
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
            _buildBookingServicesSection(),
            const Divider(color: cardBorder),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Aynı Anda Kapasite',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: softText,
                  ),
                ),
                const Spacer(),
                DropdownButton<int>(
                  value: _bookingCapacity,
                  items:
                      [1, 2, 3, 4, 5].map((int val) {
                        return DropdownMenuItem<int>(
                          value: val,
                          child: Text(
                            '$val kişi',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: darkText,
                            ),
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
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: softText,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _bookingLunchBreak['start'] ?? '12:00',
                    decoration: const InputDecoration(
                      labelText: 'Başlangıç',
                      isDense: true,
                    ),
                    items:
                        [
                          '11:00',
                          '11:30',
                          '12:00',
                          '12:30',
                          '13:00',
                          '13:30',
                        ].map((String val) {
                          return DropdownMenuItem<String>(
                            value: val,
                            child: Text(
                              val,
                              style: const TextStyle(fontSize: 12),
                            ),
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
                    initialValue: _bookingLunchBreak['end'] ?? '13:00',
                    decoration: const InputDecoration(
                      labelText: 'Bitiş',
                      isDense: true,
                    ),
                    items:
                        [
                          '12:00',
                          '12:30',
                          '13:00',
                          '13:30',
                          '14:00',
                          '14:30',
                        ].map((String val) {
                          return DropdownMenuItem<String>(
                            value: val,
                            child: Text(
                              val,
                              style: const TextStyle(fontSize: 12),
                            ),
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
                const Text(
                  'Aktif',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
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
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: softText,
              ),
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
    final dayHours =
        _bookingWorkingHours[day] ??
        {'start': '09:00', 'end': '19:00', 'active': true};
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
                items:
                    ['07:00', '08:00', '08:30', '09:00', '09:30', '10:00'].map((
                      String val,
                    ) {
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
                items:
                    [
                      '16:00',
                      '17:00',
                      '18:00',
                      '19:00',
                      '20:00',
                      '21:00',
                      '22:00',
                      '23:00',
                    ].map((String val) {
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
                style: TextStyle(
                  fontSize: 12,
                  color: mutedText,
                  fontStyle: FontStyle.italic,
                ),
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
          initialValue: items.contains(value) ? value : items.first,
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
