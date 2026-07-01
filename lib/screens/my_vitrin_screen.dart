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
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/models/legal_document.dart';
import 'package:vitrinx/screens/legal_screen.dart';
import 'package:vitrinx/services/legal_document_service.dart';
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
import 'package:vitrinx/widgets/product/product_management_entry_card.dart';
import 'package:vitrinx/widgets/product/product_management_sheet.dart';
import 'package:vitrinx/config/legal_config.dart';
import 'package:vitrinx/widgets/editor/working_hours_editor.dart';
import 'package:vitrinx/widgets/editor/location_editor_section.dart';
import 'package:vitrinx/widgets/editor/store_theme_picker.dart';
import 'package:vitrinx/widgets/editor/gallery_editor_section.dart';
import 'package:vitrinx/widgets/editor/legal_consent_section.dart';
import 'package:vitrinx/widgets/editor/public_link_card.dart';
import 'package:vitrinx/widgets/editor/visibility_hub_card.dart';
import 'package:vitrinx/widgets/editor/marketplace_links_section.dart';
import 'package:vitrinx/widgets/editor/publish_actions_section.dart';

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
  final List<GalleryItem> _galleryItems = [];
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
              .map((item) => GalleryItem(id: item.id, imageUrl: item.imageUrl)),
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
    final newItems = <GalleryItem>[];
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
        GalleryItem(
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
              .map((i) => StoreGalleryItem(id: i.id, imageUrl: i.imageUrl))
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
            backgroundColor: AppColors.surface,
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
    var category = _data.productCategories.where(
      (item) =>
          item.name.trim().toLowerCase() ==
          product.category.trim().toLowerCase(),
    );
    if (category.isEmpty) {
      final created = ProductCategory(
        id: 'category-${DateTime.now().microsecondsSinceEpoch}',
        name:
            product.category.trim().isEmpty ||
                    product.category.trim().toLowerCase() == 'tümü'
                ? 'Genel'
                : product.category.trim(),
        sortOrder: _data.productCategories.length,
      );
      _data.productCategories.add(created);
      category = [created];
    }
    product.categoryId = category.first.id;
    product.category = category.first.name;
    if (product.imagePath?.trim().isNotEmpty == true &&
        product.imageUrls.isEmpty) {
      product.imageUrls = [product.imagePath!.trim()];
    }
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
    AppRouter.navigateToPublicVitrin(context, slug);
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
      backgroundColor: AppColors.surface,
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
                  Icon(Icons.storefront_rounded, color: Colors.black, size: 13),
                  SizedBox(width: 4),
                  Text(
                    'VitrinX ile',
                    style: TextStyle(
                      color: Colors.black,
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

              StoreThemePicker(
                selectedTheme: _data.theme,
                onThemeChanged: (val) {
                  setState(() {
                    _data.theme = val;
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
              ProductManagementEntryCard(
                productCount: _data.products.length,
                onTap: _showProductManagementPlaceholder,
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
                              color: Colors.black,
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
    return LegalConsentSection(
      canAccept:
          !_isLoadingLegalDocuments &&
          _legalDocuments != null &&
          LegalConfig.hasCompleteDataControllerIdentity,
      hasCompleteIdentity: LegalConfig.hasCompleteDataControllerIdentity,
      isLoading: _isLoadingLegalDocuments,
      errorText: _legalDocumentsError,
      privacyNoticeAcknowledged: _privacyNoticeAcknowledged,
      termsAccepted: _termsAccepted,
      publicationConsentAccepted: _publicationConsentAccepted,
      onPrivacyChanged:
          (value) => setState(() => _privacyNoticeAcknowledged = value),
      onTermsChanged: (value) => setState(() => _termsAccepted = value),
      onPublicationChanged:
          (value) => setState(() => _publicationConsentAccepted = value),
      onReloadDocuments: _loadLegalDocuments,
      onOpenLegalPage: (type) => AppRouter.navigateToLegal(context, type),
    );
  }

  Widget _buildPublicWebsiteLinkCard() {
    return PublicLinkCard(
      controller: _websiteController,
      publicLink: _publishedInfo?.publicLink,
      onOpenLink: _openPublicWebsiteLink,
      onCopyLink: _copyLink,
      onShareLink: _sharePublicWebsiteLink,
    );
  }

  Widget _buildVisibilityHubCard() {
    final publicLink =
        (_publishedInfo?.publicLink.trim().isNotEmpty == true)
            ? _publishedInfo!.publicLink.trim()
            : _websiteController.text.trim();
    final publishedArticles =
        _articles
            .where((article) => article['status']?.toString() == 'published')
            .toList();

    return VisibilityHubCard(
      hasPublished: _publishedInfo?.isComplete == true,
      hasWebLink: publicLink.isNotEmpty,
      hasLocation:
          _addressController.text.trim().isNotEmpty ||
          (_latitude != null && _longitude != null),
      hasGoogleReview: _googleBusinessLinkController.text.trim().isNotEmpty,
      hasProfileDescription: _descriptionController.text.trim().isNotEmpty,
      hasPublishedArticle: publishedArticles.isNotEmpty,
      isLoadingArticles: _isLoadingArticles,
      publishedArticles: publishedArticles,
      onShowGoogleReviewQr: _showGoogleReviewQrSheet,
      onCreateArticle: _openBlogEditor,
      onOpenArticle: (article) => _openBlogEditor(initialArticle: article),
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
      backgroundColor: AppColors.surface,
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
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Google politikaları gereği yorum karşılığında ödül veya hediye teklif edilmesi yasaktır. Lütfen QR kodunu müşterilerinizden tarafsız ve organik geri bildirimler almak üzere kullanın.',
                          style: TextStyle(
                            color: AppColors.darkTextAlt,
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
    return MarketplaceLinksSection(
      links: _marketplaceLinks,
      customPlatformLinkIds: _customPlatformLinkIds,
      platformOptions: _platformOptions,
      onAddLink: _addMarketplaceLink,
      onRemoveLink: _removeMarketplaceLink,
      onPlatformChanged: (index, value) {
        setState(() {
          if (value == 'Özel...') {
            _marketplaceLinks[index].platform = 'Özel...';
            _customPlatformLinkIds.add(_marketplaceLinks[index].id);
          } else {
            _marketplaceLinks[index].platform = value ?? '';
            _customPlatformLinkIds.remove(_marketplaceLinks[index].id);
          }
        });
      },
      onUrlChanged: (index, value) => _marketplaceLinks[index].url = value,
      onCustomPlatformChanged:
          (index, value) =>
              setState(() => _marketplaceLinks[index].platform = value.trim()),
      onSubtitleChanged:
          (index, value) => _marketplaceLinks[index].subtitle = value.trim(),
    );
  }

  Widget _buildBookingSettingsSection() {
    return WorkingHoursEditor(
      bookingIsEnabled: _bookingIsEnabled,
      bookingCapacity: _bookingCapacity,
      bookingWorkingHours: _bookingWorkingHours,
      bookingLunchBreak: _bookingLunchBreak,
      offerings: _offerings,
      selectedKategori: _selectedKategori,
      onBookingEnabledChanged: (val) {
        setState(() {
          _bookingIsEnabled = val;
        });
      },
      onBookingCapacityChanged: (val) {
        setState(() {
          _bookingCapacity = val;
        });
      },
      onStateChanged: () {
        setState(() {});
      },
      showSnackBar: _showSnackBar,
    );
  }

  // ─── Published Summary ────────────────────────────────────────────────────
  Widget _buildPublishedSummary() {
    return PublishedSummaryCard(
      info: _publishedInfo!,
      coverUrl: _coverUrl?.trim() ?? '',
      onOpenExplore: widget.onOpenExplore,
    );
  }

  Widget _buildActionButtons() {
    return PublishActionsSection(
      bookingIsEnabled: _bookingIsEnabled,
      onOpenBookingManagement: _openBookingManagement,
      onOpenPublicVitrin: _openPublicVitrin,
      onCopyLink: _copyLink,
      onShowQrSheet: _showQrSheet,
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }

  void _showProductManagementPlaceholder() {
    final storeSlug =
        _data.slug.trim().isNotEmpty
            ? _data.slug.trim()
            : const StorePublishPayloadBuilder().generateSlug(
              _nameController.text.trim(),
            );
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return ProductManagementSheet(
          products: _data.products,
          categories: _data.productCategories,
          storeSlug: storeSlug,
          showMessage: _showPlaceholderSnackBar,
          onCatalogChanged: (products, categories) async {
            if (!mounted) return;
            setState(() {
              _data.products = products;
              _data.productCategories = categories;
            });
            await _storage.saveVitrinData(_data);
          },
        );
      },
    );
  }

  void _showPlaceholderSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
