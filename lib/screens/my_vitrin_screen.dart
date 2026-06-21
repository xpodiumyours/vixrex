import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/config/public_site_config.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/screens/landing_screen.dart';
import 'package:vitrinx/screens/public_vitrin_screen.dart';
import 'package:vitrinx/services/location_service.dart';
import 'package:vitrinx/services/store_local_storage_service.dart';
import 'package:vitrinx/services/store_publish_payload_builder.dart';
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
  State<MyVitrinScreen> createState() => _MyVitrinScreenState();
}

class _MyVitrinScreenState extends State<MyVitrinScreen> {
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

  // ─── State ──────────────────────────────────────────────────────────────
  StoreData _data = StoreData(isEsnafMode: false, isStore: false);
  PublishedVitrinInfo? _publishedInfo;

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

  // Location
  double? _latitude;
  double? _longitude;
  double? _locationAccuracyMeters;
  bool _isLocating = false;
  String? _locationStatusMessage;

  // Category / status
  String _selectedKategori = 'Diğer';
  String _selectedStatus = 'Açık';

  static const List<String> _categories = [
    'Giyim & Butik',
    'Gıda & Fırın',
    'Kozmetik',
    'Dekorasyon',
    'Elektronik',
    'Kırtasiye',
    'Kafe / Lokanta',
    'Kuaför',
    'Diğer',
  ];

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
    'Diğer',
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
    super.dispose();
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
        _websiteController.text = data.website;
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

        _isLoading = false;
      });
    } catch (error) {
      debugPrint('MyVitrinScreen load error: $error');
      if (!mounted) return;
      setState(() => _isLoading = false);
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
      }
    });
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
    final hasValidWhatsapp = WhatsAppLinkHelper.isValidTurkeyMobile(whatsapp);

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
    });

    if (name.isEmpty ||
        whatsapp.isEmpty ||
        !hasValidWhatsapp ||
        address.isEmpty) {
      _showSnackBar(
        whatsapp.isNotEmpty && !hasValidWhatsapp
            ? WhatsAppLinkHelper.invalidNumberMessage
            : 'Lütfen zorunlu alanları doldurun: ad, WhatsApp ve konum.',
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

      final data =
          _data
            ..name = name
            ..whatsapp = whatsapp
            ..address = address
            ..description = _descriptionController.text.trim()
            ..instagram = _instagramController.text.trim()
            ..website = _websiteController.text.trim()
            ..kategori = _selectedKategori
            ..status = _selectedStatus
            ..isStore = false
            ..shelfImageUrl = coverUrl
            ..galleryItems = publishedGallery
            ..marketplaceLinks = List.from(_marketplaceLinks)
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
        _coverUrl = coverUrl;
        _coverBytes = null;
        _coverFileName = null;
      });

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

  void _openPublicVitrin() {
    final slug = _publishedInfo?.slug;
    if (slug == null || slug.trim().isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PublicVitrinScreen(slug: slug)),
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
              _buildCoverPicker(),
              const SizedBox(height: 10),

              // ── Galeri (kapak altında, kompakt) ─────────────────
              _buildCompactGalleryRow(),
              const SizedBox(height: 18),

              // ── Zorunlu Alanlar (* ile işaretli) ─────────────────
              _buildTextField(
                label: 'İşletme / VitrinX Adı',
                controller: _nameController,
                hint: 'Örn: Aymira Butik',
                icon: Icons.storefront_rounded,
                errorText: _nameError,
                required: true,
              ),
              const SizedBox(height: 14),

              _buildTextField(
                label: 'WhatsApp Numarası',
                controller: _whatsappController,
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
              const SizedBox(height: 14),

              _buildLocationField(),
              const SizedBox(height: 14),

              // ── İsteğe Bağlı Alanlar ─────────────────────────────
              _buildTextField(
                label: 'Kısa Açıklama',
                controller: _descriptionController,
                hint: 'Bugün vitrinde ne var? Kısa bir tanıtım yaz.',
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 14),

              _buildDropdown(
                label: 'Kategori',
                value: _selectedKategori,
                items: _categories,
                icon: Icons.category_rounded,
                onChanged:
                    (val) => setState(() => _selectedKategori = val ?? 'Diğer'),
              ),
              const SizedBox(height: 14),

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

              _buildTextField(
                label: 'Website',
                controller: _websiteController,
                hint: 'https://...',
                icon: Icons.language_rounded,
                keyboardType: TextInputType.url,
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

  // ─── Location Field ───────────────────────────────────────────────────────
  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Konum / Adres',
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
            hintText: 'Mahalle, cadde, ilçe/il — veya GPS ile al',
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

  // ─── Marketplace Section ──────────────────────────────────────────────────
  Widget _buildMarketplaceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Pazar Yeri Linkleri',
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
            'Trendyol, Hepsiburada gibi linkleri buraya ekleyebilirsiniz.',
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
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value:
                _platformOptions.contains(link.platform) ? link.platform : null,
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
                        child: Text(p, style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
            onChanged: (val) {
              setState(() => _marketplaceLinks[index].platform = val ?? '');
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: TextField(
            onChanged: (val) => _marketplaceLinks[index].url = val,
            style: const TextStyle(
              fontSize: 13,
              color: darkText,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'https://...',
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
