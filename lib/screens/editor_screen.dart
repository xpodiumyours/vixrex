import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitrinx/config/public_site_config.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/services/store_publish_service.dart';
import 'package:vitrinx/services/store_publish_validator.dart';
import 'package:vitrinx/services/store_shelf_upload_service.dart';
import 'package:vitrinx/services/vitrin_view_service.dart';
import 'package:vitrinx/theme/vitrin_theme_preset.dart';
import 'package:vitrinx/utils/gallery_image_file_validator.dart';
import 'package:vitrinx/widgets/vitrin_view.dart';
import 'package:vitrinx/screens/preview_screen.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TabController _mobileTabController;
  final StoreData _data = StoreData(isEsnafMode: false);
  bool _isLoading = true;
  bool _isPublishing = false;
  bool _isUploadingGallery = false;
  int _selectedGalleryIndex = 0;
  int _todayViewCount = 0;
  bool _isTodayViewCountLoading = false;
  final List<_EditorGalleryItem> _galleryItems = [];
  String? _publishedLink;
  String? _publishError;
  String? _lastViewCountSlug;
  Timer? _viewCountDebounce;
  _VitrinScoreTarget? _highlightedScoreTarget;
  int _scoreTargetHighlightToken = 0;

  final Map<_VitrinScoreTarget, GlobalKey> _scoreTargetKeys = {
    _VitrinScoreTarget.storeName: GlobalKey(),
    _VitrinScoreTarget.whatsapp: GlobalKey(),
    _VitrinScoreTarget.description: GlobalKey(),
    _VitrinScoreTarget.social: GlobalKey(),
    _VitrinScoreTarget.address: GlobalKey(),
    _VitrinScoreTarget.marketplace: GlobalKey(),
    _VitrinScoreTarget.about: GlobalKey(),
    _VitrinScoreTarget.gallery: GlobalKey(),
  };

  // Premium light editor palette
  static const Color primaryColor = Color(0xFFFF4D00);
  static const Color secondaryColor = Color(0xFFB200FF);
  static const Color bgColor = Color(0xFFF6F8FC);
  static const Color cardBorder = Color.fromRGBO(15, 23, 42, 0.10);
  static const Color inputBg = Color(0xFFF1F5F9);
  static const Color darkText = Color(0xFF111827);
  static const Color mutedText = Color(0xFF64748B);
  static const Color softText = Color(0xFF334155);
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, secondaryColor],
  );
  static const String _editTokenPrefsKey = 'vitrin_edit_token';
  static const int _maxGalleryPhotos = 12;
  static const int _maxGalleryPhotoBytes = GalleryImageFileValidator.maxBytes;

  final List<String> businessTypes = const [
    'Butik',
    'İç giyim',
    'Kozmetik',
    'Hediyelik',
    'Market',
    'Telefon aksesuarı',
    'Kafe / Lokanta',
    'Kuaför',
    'Diğer',
  ];
  final List<String> statuses = const [
    'Açık',
    'Bugün kampanya var',
    'Yeni ürünler geldi',
    'Stok sınırlı',
  ];

  final List<String> platforms = const [
    'Trendyol',
    'Hepsiburada',
    'N11',
    'Amazon',
    'Çiçeksepeti',
    'Shopier',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    _mobileTabController = TabController(length: 2, vsync: this);
    _loadSavedData();
  }

  @override
  void dispose() {
    _viewCountDebounce?.cancel();
    _mobileTabController.dispose();
    for (final item in _galleryItems) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedJson = prefs.getString('vitrin_data');
      if (savedJson != null) {
        final Map<String, dynamic> jsonData = jsonDecode(savedJson);
        final loadedData = StoreData.fromJson(jsonData);
        setState(() {
          _data.name = loadedData.name;
          _data.businessType = loadedData.businessType;
          _data.description = loadedData.description;
          _data.whatsapp = loadedData.whatsapp;
          _data.instagram = loadedData.instagram;
          _data.website = loadedData.website;
          _data.address = loadedData.address;
          _data.theme = loadedData.theme;
          _data.status = loadedData.status;
          _data.isEsnafMode = loadedData.isEsnafMode;
          _data.corporateBio = loadedData.corporateBio;
          _data.referencesLink = loadedData.referencesLink;
          _data.shelfImageUrl = loadedData.shelfImageUrl;
          _data.galleryItems = loadedData.galleryItems;
          _data.marketplaceLinks = loadedData.marketplaceLinks;
          _data.products = loadedData.products;
          _replaceEditorGalleryItems(loadedData.displayGalleryItems);
          _isLoading = false;
        });
        unawaited(_refreshTodayViewCount());
      } else {
        setState(() => _isLoading = false);
        unawaited(_refreshTodayViewCount());
      }
    } catch (e) {
      debugPrint('Data load error: $e');
      if (!mounted) return;

      setState(() => _isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Vitrin verileri yüklenemedi, varsayılan değerler kullanılıyor.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      });
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonData = jsonEncode(_data.toJson());
      await prefs.setString('vitrin_data', jsonData);
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.cloud_done_outlined, color: Colors.white),
                SizedBox(width: 12),
                Text('Vitrin başarıyla kaydedildi'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: primaryColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _publishStore() async {
    if (_isPublishing) return;

    final validationMessage = const StorePublishValidator().validate(_data);
    if (validationMessage != null) {
      setState(() {
        _publishedLink = null;
        _publishError = validationMessage;
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationMessage),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isPublishing = true;
      _isUploadingGallery = _galleryItems.any((item) => item.hasLocalBytes);
      _publishedLink = null;
      _publishError = null;
    });

    var failedUploadCount = 0;

    try {
      if (_galleryItems.any((item) => item.hasLocalBytes)) {
        failedUploadCount = await _uploadPendingGalleryImages();
        if (mounted) {
          setState(() => _isUploadingGallery = false);
        }
        if (failedUploadCount > 0) {
          throw StorePublishException(
            '$failedUploadCount fotoğraf yüklenemedi. Vitrin yayınlanmadı. Lütfen tekrar deneyin veya sorunlu fotoğrafı kaldırın.',
          );
        }
      }

      _syncPublishedGalleryData();

      final editToken = await _loadOrCreateEditToken();
      final publishResult = await const StorePublishService().publishStore(
        _data,
        editToken: editToken,
      );
      final publicLink = _buildFullPublicLink(publishResult.publicPath);
      if (!mounted) return;

      final publishSnackMessage =
          publishResult.wasUpdated
              ? 'Vitrininiz güncellendi.'
              : 'Vitrin linkiniz hazırlandı.';
      setState(() => _publishedLink = publicLink);
      unawaited(_refreshTodayViewCount(force: true));
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(publishSnackMessage),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (error) {
      debugPrint('Publish store error: $error');
      if (!mounted) return;

      final userMessage =
          error is StorePublishException
              ? error.message
              : 'Vitrin bağlantısı hazırlanamadı. Supabase ayarlarını veya izinleri kontrol edin.';
      setState(() {
        _publishError = userMessage;
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userMessage),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
          _isUploadingGallery = false;
        });
      }
    }
  }

  Future<void> _copyPublishedLink(String message) async {
    final link = _publishedLink;
    if (link == null || link.trim().isEmpty) return;

    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<String> _loadOrCreateEditToken() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_editTokenPrefsKey);
    if (savedToken != null && savedToken.trim().isNotEmpty) {
      return savedToken;
    }

    final token = _generateEditToken();
    await prefs.setString(_editTokenPrefsKey, token);
    return token;
  }

  String _generateEditToken() {
    Random random;
    try {
      random = Random.secure();
    } catch (_) {
      random = Random();
    }

    final randomBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final timestampBytes = utf8.encode(
      DateTime.now().microsecondsSinceEpoch.toString(),
    );
    return base64Url
        .encode([...timestampBytes, ...randomBytes])
        .replaceAll('=', '');
  }

  void _handleStoreNameChanged(String value) {
    setState(() => _data.name = value);
    _scheduleTodayViewCountRefresh();
  }

  void _scheduleTodayViewCountRefresh() {
    _viewCountDebounce?.cancel();
    _viewCountDebounce = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      unawaited(_refreshTodayViewCount());
    });
  }

  Future<void> _refreshTodayViewCount({bool force = false}) async {
    final slug = _generateStoreSlug(_data.name);

    if (_data.name.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _todayViewCount = 0;
        _isTodayViewCountLoading = false;
        _lastViewCountSlug = null;
      });
      return;
    }

    if (!force && _lastViewCountSlug == slug) return;

    setState(() {
      _isTodayViewCountLoading = true;
      _lastViewCountSlug = slug;
    });

    try {
      final editToken = await _loadOrCreateEditToken();
      final count = await const VitrinViewService().fetchTodayViewCount(
        slug: slug,
        editToken: editToken,
      );

      if (!mounted || _generateStoreSlug(_data.name) != slug) return;

      setState(() {
        _todayViewCount = count;
        _isTodayViewCountLoading = false;
      });
    } catch (error) {
      debugPrint('Today view count refresh error: $error');
      if (!mounted || _generateStoreSlug(_data.name) != slug) return;

      setState(() {
        _todayViewCount = 0;
        _isTodayViewCountLoading = false;
      });
    }
  }

  void _showPremiumVisibilityInfo() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'SEO anahtar kelime ve blog fikirleri premium özellik olarak hazırlanıyor.',
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _replaceEditorGalleryItems(List<StoreGalleryItem> items) {
    for (final item in _galleryItems) {
      item.dispose();
    }

    _galleryItems
      ..clear()
      ..addAll(
        items
            .where((item) => item.imageUrl.trim().isNotEmpty)
            .take(_maxGalleryPhotos)
            .map(_EditorGalleryItem.fromStoreItem),
      );
    _selectedGalleryIndex = 0;
  }

  void _syncPublishedGalleryData() {
    final publishedItems =
        _galleryItems
            .where((item) => item.imageUrl.trim().isNotEmpty)
            .take(_maxGalleryPhotos)
            .map((item) => item.toStoreItem())
            .toList();

    _data.galleryItems = publishedItems;
    _data.shelfImageUrl =
        publishedItems.isEmpty ? '' : publishedItems.first.imageUrl.trim();
  }

  List<VitrinGalleryPreviewItem> _galleryPreviewItems() {
    return _galleryItems
        .where((item) => item.hasPreviewImage)
        .take(_maxGalleryPhotos)
        .map((item) => item.toPreviewItem())
        .toList();
  }

  String _galleryPreviewKey() {
    return _galleryItems
        .map(
          (item) =>
              '${item.id}_${item.imageUrl}_${item.hasLocalBytes}_${item.title}_${item.description}',
        )
        .join('|');
  }

  Future<int> _uploadPendingGalleryImages() async {
    var failedUploadCount = 0;
    final uploadService = const StoreShelfUploadService();
    final slug = _generateStoreSlug(_data.name);

    for (final item in _galleryItems) {
      final bytes = item.bytes;
      if (bytes == null) continue;

      try {
        final uploadedUrl = await uploadService.uploadGalleryImage(
          bytes,
          slug,
          fileExtension: item.extension,
          contentType: item.contentType,
        );
        item.markUploaded(uploadedUrl);
      } catch (uploadError) {
        failedUploadCount += 1;
        debugPrint('Gallery image upload error: $uploadError');
      }
    }

    return failedUploadCount;
  }

  Future<void> _pickGalleryPhotos() async {
    final remainingSlots = _maxGalleryPhotos - _galleryItems.length;
    if (remainingSlots <= 0) {
      _showInfoSnackBar(
        'En fazla $_maxGalleryPhotos fotoğraf ekleyebilirsiniz.',
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    var rejectedCount = 0;
    GalleryImageValidationFailure? firstFailure;
    final newItems = <_EditorGalleryItem>[];
    final selectedFiles = result.files.take(remainingSlots).toList();

    for (final file in selectedFiles) {
      final result = _editorGalleryItemFromFile(file);
      if (!result.isValid) {
        rejectedCount += 1;
        firstFailure ??= result.failure;
        continue;
      }
      newItems.add(result.item!);
    }

    if (result.files.length > remainingSlots) {
      rejectedCount += result.files.length - remainingSlots;
    }

    if (newItems.isEmpty) {
      _showInfoSnackBar(
        rejectedCount > 0
            ? _galleryImageFailureMessage(firstFailure)
            : 'Fotoğraf eklenmedi.',
      );
      return;
    }

    setState(() {
      final firstNewIndex = _galleryItems.length;
      _galleryItems.addAll(newItems);
      _selectedGalleryIndex = firstNewIndex;
    });

    if (rejectedCount > 0) {
      _showInfoSnackBar(
        '$rejectedCount fotoğraf eklenemedi. Sınır: $_maxGalleryPhotos fotoğraf, dosya başı ${_maxGalleryPhotoBytes ~/ (1024 * 1024)} MB.',
      );
    }
  }

  Future<void> _replaceGalleryPhoto(int index) async {
    if (index < 0 || index >= _galleryItems.length) return;

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final replacement = _editorGalleryItemFromFile(result.files.single);
    if (!replacement.isValid) {
      _showInfoSnackBar(_galleryImageFailureMessage(replacement.failure));
      return;
    }

    setState(() {
      _galleryItems[index].replaceImageFrom(replacement.item!);
      replacement.item!.dispose();
    });
  }

  _GalleryFilePickResult _editorGalleryItemFromFile(PlatformFile file) {
    final bytes = file.bytes;
    final validation = GalleryImageFileValidator.validate(
      bytes: bytes,
      reportedSize: file.size,
    );
    final fileInfo = validation.fileInfo;
    if (fileInfo == null) {
      return _GalleryFilePickResult.failure(validation.failure);
    }

    return _GalleryFilePickResult.success(
      _EditorGalleryItem(
        id: _newGalleryItemId(),
        bytes: bytes,
        fileName: file.name,
        extension: fileInfo.extension,
        contentType: fileInfo.contentType,
      ),
    );
  }

  String _newGalleryItemId() {
    final random = Random();
    return '${DateTime.now().microsecondsSinceEpoch}_${random.nextInt(999999)}';
  }

  void _removeGalleryPhoto(int index) {
    if (index < 0 || index >= _galleryItems.length) return;

    setState(() {
      final removedItem = _galleryItems.removeAt(index);
      removedItem.dispose();
      _normalizeGallerySelection();
      _syncPublishedGalleryData();
    });
  }

  void _makeGalleryCover(int index) {
    if (index <= 0 || index >= _galleryItems.length) return;

    setState(() {
      final item = _galleryItems.removeAt(index);
      _galleryItems.insert(0, item);
      _selectedGalleryIndex = 0;
      _syncPublishedGalleryData();
    });
  }

  void _selectGalleryItem(int index) {
    if (index < 0 || index >= _galleryItems.length) return;
    setState(() => _selectedGalleryIndex = index);
  }

  void _normalizeGallerySelection() {
    if (_galleryItems.isEmpty) {
      _selectedGalleryIndex = 0;
      return;
    }

    if (_selectedGalleryIndex >= _galleryItems.length) {
      _selectedGalleryIndex = _galleryItems.length - 1;
    }
  }

  String _galleryImageFailureMessage(GalleryImageValidationFailure? failure) {
    if (failure == GalleryImageValidationFailure.unreadable) {
      return 'Fotoğraf tarayıcı tarafından okunamadı. Lütfen galeriden tekrar seçin.';
    }

    return 'Seçilen fotoğraflar eklenemedi. JPG, PNG veya WEBP ve en fazla ${_maxGalleryPhotoBytes ~/ (1024 * 1024)} MB olmalı.';
  }

  void _showInfoSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addMarketplaceLink() {
    setState(() {
      _data.marketplaceLinks.add(
        MarketplaceLink(id: DateTime.now().millisecondsSinceEpoch.toString()),
      );
    });
  }

  void _removeMarketplaceLink(int index) {
    setState(() {
      _data.marketplaceLinks.removeAt(index);
    });
  }

  int _calculateVitrinScore(StoreData data) {
    final score = _buildVitrinScoreTasks(data).fold<int>(
      0,
      (total, task) => task.isComplete ? total + task.points : total,
    );

    return score.clamp(0, 100).toInt();
  }

  bool _hasCompleteMarketplaceLink(StoreData data) {
    return _completeMarketplaceLinks(data).isNotEmpty;
  }

  List<MarketplaceLink> _completeMarketplaceLinks(StoreData data) {
    return data.marketplaceLinks
        .where(
          (link) =>
              link.platform.trim().isNotEmpty && link.url.trim().isNotEmpty,
        )
        .toList();
  }

  bool _hasSupportingVitrinContent(StoreData data) {
    final hasLogo = data.logoUrl?.trim().isNotEmpty ?? false;
    final hasCorporateInfo = data.corporateBio.trim().isNotEmpty;
    final hasCatalogItem = data.products.any(
      (product) =>
          product.name.trim().isNotEmpty ||
          product.price.trim().isNotEmpty ||
          product.description.trim().isNotEmpty ||
          product.imagePath?.trim().isNotEmpty == true,
    );

    return hasLogo || hasCorporateInfo || hasCatalogItem;
  }

  List<_VitrinScoreTask> _buildVitrinScoreTasks(StoreData data) {
    final descriptionLength = data.description.trim().length;

    return [
      _VitrinScoreTask(
        points: 20,
        isComplete: data.name.trim().isNotEmpty,
        suggestion: 'Mağaza adını ekle',
        target: _VitrinScoreTarget.storeName,
      ),
      _VitrinScoreTask(
        points: 15,
        isComplete: data.whatsapp.trim().isNotEmpty,
        suggestion: 'WhatsApp numarası ekle',
        target: _VitrinScoreTarget.whatsapp,
      ),
      _VitrinScoreTask(
        points: 15,
        isComplete: descriptionLength >= 10,
        suggestion:
            descriptionLength == 0
                ? 'Kısa açıklama yaz'
                : 'Kısa açıklamayı güçlendir $descriptionLength/10',
        target: _VitrinScoreTarget.description,
      ),
      _VitrinScoreTask(
        points: 10,
        isComplete:
            data.instagram.trim().isNotEmpty || data.website.trim().isNotEmpty,
        suggestion: 'Instagram veya web sitesi ekle',
        target: _VitrinScoreTarget.social,
      ),
      _VitrinScoreTask(
        points: 10,
        isComplete: data.address.trim().isNotEmpty,
        suggestion: 'Adres bilgisini ekle',
        target: _VitrinScoreTarget.address,
      ),
      _VitrinScoreTask(
        points: 15,
        isComplete: _hasCompleteMarketplaceLink(data),
        suggestion: 'En az 1 pazaryeri linki ekle',
        target: _VitrinScoreTarget.marketplace,
      ),
      _VitrinScoreTask(
        points: 15,
        isComplete: _hasSupportingVitrinContent(data),
        suggestion: 'Logo, ürün veya hakkımızda bilgisi ekle',
        target: _VitrinScoreTarget.about,
      ),
    ];
  }

  String _vitrinScoreStatusText(int score) {
    if (score < 40) return 'Vitrinin henüz hazır değil.';
    if (score < 70) return 'Vitrinin gelişiyor.';
    if (score < 90) return 'Vitrinin iyi durumda.';
    return 'Vitrinin güçlü görünüyor.';
  }

  Color _vitrinScoreTone(int score) {
    if (score < 40) return const Color(0xFFEA580C);
    if (score < 80) return const Color(0xFFD97706);
    return const Color(0xFF059669);
  }

  String _vitrinScoreLabel(int score) {
    if (score < 40) return 'Eksik';
    if (score < 80) return 'Gelişiyor';
    return 'Güçlü';
  }

  List<_VitrinScoreTask> _buildVitrinScoreActionTasks() {
    final tasks =
        _buildVitrinScoreTasks(
          _data,
        ).where((task) => !task.isComplete).toList();

    final hasGalleryPhoto =
        _galleryItems.isNotEmpty || _data.displayGalleryItems.isNotEmpty;
    if (!hasGalleryPhoto) {
      tasks.add(
        const _VitrinScoreTask(
          points: 0,
          isComplete: false,
          suggestion: 'Galeri fotoğrafı ekle',
          target: _VitrinScoreTarget.gallery,
        ),
      );
    }

    return tasks;
  }

  Future<void> _focusMobileEditTab() async {
    if (_mobileTabController.index != 0) {
      _mobileTabController.animateTo(0);
      await Future<void>.delayed(const Duration(milliseconds: 280));
    }
  }

  Future<void> _handleScoreTaskCompleteTap(
    _VitrinScoreTarget target, {
    bool closeSheet = false,
  }) async {
    if (closeSheet) {
      await Navigator.of(context).maybePop();
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }

    await _goToScoreTarget(target);
  }

  Future<void> _goToScoreTarget(_VitrinScoreTarget target) async {
    if (!mounted) return;

    final isMobile = MediaQuery.of(context).size.width <= 900;
    if (isMobile) {
      await _focusMobileEditTab();
    }

    BuildContext? targetContext;
    for (var attempt = 0; attempt < 5; attempt++) {
      targetContext = _scoreTargetKeys[target]?.currentContext;
      if (targetContext != null) break;
      await Future<void>.delayed(const Duration(milliseconds: 90));
    }

    if (!mounted || targetContext == null || !targetContext.mounted) return;

    _highlightScoreTarget(target);

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  void _highlightScoreTarget(_VitrinScoreTarget target) {
    final token = ++_scoreTargetHighlightToken;
    setState(() => _highlightedScoreTarget = target);

    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted || token != _scoreTargetHighlightToken) return;
      setState(() => _highlightedScoreTarget = null);
    });
  }

  Future<void> _showVitrinScoreSheet() async {
    final score = _calculateVitrinScore(_data);
    final tone = _vitrinScoreTone(score);
    final tasks = _buildVitrinScoreActionTasks();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 14,
              bottom: 18 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 32,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              tone.withValues(alpha: 0.16),
                              tone.withValues(alpha: 0.06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: tone.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          color: tone,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vitrin Skoru',
                              style: TextStyle(
                                color: darkText,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Vitrininizi güçlendirmek için eksik adımları tamamlayın.',
                              style: TextStyle(
                                color: softText.withValues(alpha: 0.75),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$score/100',
                        style: const TextStyle(
                          color: darkText,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: score / 100,
                      minHeight: 5,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(tone),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _vitrinScoreStatusText(score),
                    style: TextStyle(
                      color: tone,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    tasks.isEmpty ? 'Her şey hazır' : 'Eksik adımlar',
                    style: const TextStyle(
                      color: darkText,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (tasks.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Text(
                        'Vitrinin güçlü görünüyor. Yayınla sekmesinden public linkini hazırlayabilirsin.',
                        style: TextStyle(
                          color: Color(0xFF166534),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    )
                  else
                    ...tasks.map(
                      (task) =>
                          _buildScoreTaskRow(task, tone, closeSheet: true),
                    ),
                  if (score >= 60) ...[
                    const SizedBox(height: 12),
                    _buildGoogleVisibilityCta(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreTaskRow(
    _VitrinScoreTask task,
    Color tone, {
    bool closeSheet = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.checklist_rounded, color: tone, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task.suggestion,
              style: TextStyle(
                color: softText.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed:
                () => _handleScoreTaskCompleteTap(
                  task.target,
                  closeSheet: closeSheet,
                ),
            style: TextButton.styleFrom(
              foregroundColor: tone,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              minimumSize: const Size(44, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Tamamla',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayViewBadge({bool compact = false}) {
    final text =
        _isTodayViewCountLoading
            ? '...'
            : compact
            ? '$_todayViewCount'
            : 'Bugün $_todayViewCount';

    return Padding(
      padding: EdgeInsets.only(right: compact ? 6 : 8),
      child: Tooltip(
        message: 'Bugünkü tekil vitrin görüntülenmesi',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => unawaited(_refreshTodayViewCount(force: true)),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: compact ? 36 : 38,
              padding: EdgeInsets.only(
                left: compact ? 8 : 11,
                right: compact ? 10 : 13,
              ),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(14, 165, 233, 0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color.fromRGBO(14, 165, 233, 0.22),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(14, 165, 233, 0.08),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: compact ? 23 : 25,
                    height: compact ? 23 : 25,
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(255, 255, 255, 0.86),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.visibility_rounded,
                      color: Color(0xFF0284C7),
                      size: 15,
                    ),
                  ),
                  SizedBox(width: compact ? 6 : 8),
                  Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: darkText,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVitrinScoreBadge() {
    final score = _calculateVitrinScore(_data);
    final tone = _vitrinScoreTone(score);

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showVitrinScoreSheet,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 38,
            padding: const EdgeInsets.only(left: 8, right: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tone.withValues(alpha: 0.14),
                  tone.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: tone.withValues(alpha: 0.22)),
              boxShadow: [
                BoxShadow(
                  color: tone.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.84),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: tone,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 7),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$score/100',
                      style: const TextStyle(
                        color: darkText,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _vitrinScoreLabel(score),
                      style: TextStyle(
                        color: tone,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _premiumCardDecoration({double radius = 24}) {
    return BoxDecoration(
      color: const Color.fromRGBO(255, 255, 255, 0.94),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: cardBorder, width: 1),
      boxShadow: const [
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.38),
          blurRadius: 24,
          offset: Offset(0, 12),
        ),
        BoxShadow(
          color: Color.fromRGBO(178, 0, 255, 0.08),
          blurRadius: 38,
          offset: Offset(0, 0),
        ),
      ],
    );
  }

  BoxDecoration _studioFrameDecoration() {
    return BoxDecoration(
      color: const Color.fromRGBO(255, 255, 255, 0.92),
      borderRadius: BorderRadius.circular(32),
      border: Border.all(color: cardBorder),
      boxShadow: const [
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.46),
          blurRadius: 34,
          offset: Offset(0, 18),
        ),
        BoxShadow(
          color: Color.fromRGBO(255, 77, 0, 0.10),
          blurRadius: 56,
          offset: Offset(-16, 0),
        ),
        BoxShadow(
          color: Color.fromRGBO(178, 0, 255, 0.10),
          blurRadius: 70,
          offset: Offset(18, 20),
        ),
      ],
    );
  }

  Widget _buildEditorBackdrop({required Widget child}) {
    return Stack(
      children: [
        const Positioned.fill(
          child: CustomPaint(painter: _EditorGridPainter()),
        ),
        Positioned(
          top: -180,
          left: -170,
          child: IgnorePointer(
            child: Container(
              width: 460,
              height: 460,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x2AFF5E1A), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: -180,
          bottom: -210,
          child: IgnorePointer(
            child: Container(
              width: 520,
              height: 520,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x22B200FF), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _gradientUnderline({double width = 58}) {
    return Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        gradient: ctaGradient,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _buildStudioTopBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color.fromRGBO(255, 255, 255, 0.035),
        border: Border(bottom: BorderSide(color: cardBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: ctaGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: secondaryColor.withValues(alpha: 0.24),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'VX',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VitrinX Studio',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Esnaf vitrini için canlı editör',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: cardBorder),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, color: primaryColor, size: 15),
                SizedBox(width: 7),
                Text(
                  'Premium vitrin oluşturucu',
                  style: TextStyle(
                    color: softText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    Widget? child,
    bool expand = false,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 28,
      vertical: 12,
    ),
  }) {
    final content =
        child ??
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );

    final button = Opacity(
      opacity: onPressed == null ? 0.62 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: ctaGradient,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: secondaryColor.withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(40),
            child: Padding(padding: padding, child: content),
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(255, 255, 255, 0.94),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: darkText,
        shape: const Border(bottom: BorderSide(color: cardBorder)),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: darkText,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title:
            isWide
                ? Row(
                  children: [
                    const Text(
                      'Vitrin Düzenle',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: darkText,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'VITRINX',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: primaryColor.withValues(alpha: 0.62),
                        fontSize: 12,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                )
                : const Text(
                  'Vitrin Düzenle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: darkText,
                    fontSize: 17,
                  ),
                ),
        actions:
            isWide
                ? [
                  _buildTodayViewBadge(),
                  _buildVitrinScoreBadge(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: _buildGradientButton(
                      label: 'Kaydet',
                      onPressed: _saveData,
                      icon: Icons.cloud_done_outlined,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 12.0,
                    ),
                    child: _buildGradientButton(
                      label: 'Ã–nizle & PaylaÅŸ',
                      icon: Icons.visibility_rounded,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => PreviewScreen(
                                  storeData: _data,
                                  previewGalleryItems: _galleryPreviewItems(),
                                ),
                          ),
                        );
                      },
                      child: const Text(
                        'Önizle & Paylaş',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ]
                : [
                  _buildTodayViewBadge(compact: true),
                  _buildVitrinScoreBadge(),
                ],
      ),
      bottomNavigationBar: !isWide ? _buildMobileBottomActions() : null,
      body: _buildEditorBackdrop(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;

            if (!isWide) {
              return DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(22, 22, 36, 0.88),
                        border: Border(bottom: BorderSide(color: cardBorder)),
                      ),
                      child: TabBar(
                        controller: _mobileTabController,
                        labelColor: primaryColor,
                        unselectedLabelColor: mutedText,
                        indicatorColor: primaryColor,
                        tabs: const [
                          Tab(text: 'Düzenle'),
                          Tab(text: 'Yayınla'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _mobileTabController,
                        children: [
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 800,
                                ),
                                child: _buildForm(),
                              ),
                            ),
                          ),
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 800,
                                ),
                                child: _buildPublishPanel(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: min(constraints.maxWidth - 48, 1360),
                  height: max(0, constraints.maxHeight - 48),
                  clipBehavior: Clip.antiAlias,
                  decoration: _studioFrameDecoration(),
                  child: Column(
                    children: [
                      _buildStudioTopBar(),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  34,
                                  30,
                                  28,
                                  34,
                                ),
                                child: Center(
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: 780,
                                    ),
                                    child: _buildForm(
                                      showDesktopPublishCard: true,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const VerticalDivider(width: 1, color: cardBorder),
                            Expanded(
                              flex: 4,
                              child: LayoutBuilder(
                                builder: (context, previewConstraints) {
                                  return Center(
                                    child: _buildLivePreviewMockup(
                                      previewConstraints,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildScoreTargetAnchor(_VitrinScoreTarget target, Widget child) {
    final isHighlighted = _highlightedScoreTarget == target;

    return AnimatedContainer(
      key: _scoreTargetKeys[target],
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color:
            isHighlighted
                ? primaryColor.withValues(alpha: 0.08)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isHighlighted
                  ? primaryColor.withValues(alpha: 0.42)
                  : Colors.transparent,
          width: 1.4,
        ),
        boxShadow:
            isHighlighted
                ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.16),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ]
                : null,
      ),
      child: child,
    );
  }

  Widget _buildForm({bool showDesktopPublishCard = false}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showDesktopPublishCard) ...[
            _buildPublishPanel(compact: true, includeBottomSpacing: false),
          ],
          SizedBox(height: showDesktopPublishCard ? 24 : 0),
          _buildEditCard(
            title: 'Mağaza Görünümü',
            headerWidget: _buildCompactStatusDropdown(),
            children: [
              _buildScoreTargetAnchor(
                _VitrinScoreTarget.gallery,
                _buildGalleryStudio(),
              ),
              const SizedBox(height: 20),
              _buildScoreTargetAnchor(
                _VitrinScoreTarget.storeName,
                _buildTextField(
                  'Mağaza adı',
                  _handleStoreNameChanged,
                  initial: _data.name,
                ),
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                'İşletme türü',
                _data.businessType,
                businessTypes,
                (v) => setState(() => _data.businessType = v!),
              ),
              const SizedBox(height: 16),
              _buildScoreTargetAnchor(
                _VitrinScoreTarget.description,
                _buildTextField(
                  'Kısa açıklama (Vitrin Altı)',
                  (v) => setState(() => _data.description = v),
                  maxLines: 2,
                  initial: _data.description,
                  hintText: 'İşletmenizi kısaca anlatın',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildEditCard(
            title: 'Kurumsal Bilgiler',
            children: [
              _buildScoreTargetAnchor(
                _VitrinScoreTarget.about,
                _buildTextField(
                  'Hakkımızda Metni',
                  (v) => setState(() => _data.corporateBio = v),
                  maxLines: 4,
                  initial: _data.corporateBio,
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                'Referans / yorum linki',
                (v) => setState(() => _data.referencesLink = v),
                prefixIcon: Icons.verified_rounded,
                initial: _data.referencesLink,
                hintText:
                    'Örn: Google yorumları, Instagram öne çıkanlar veya web sayfanız',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildEditCard(
            title: 'İletişim & Sosyal',
            children: [
              _buildScoreTargetAnchor(
                _VitrinScoreTarget.whatsapp,
                _buildTextField(
                  'WhatsApp',
                  (v) => setState(() => _data.whatsapp = v),
                  prefixIcon: Icons.phone_rounded,
                  initial: _data.whatsapp,
                  hintText: 'Örn: 05xx xxx xx xx',
                ),
              ),
              const SizedBox(height: 12),
              _buildScoreTargetAnchor(
                _VitrinScoreTarget.social,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      'Instagram',
                      (v) => setState(() => _data.instagram = v),
                      prefixIcon: Icons.camera_alt_rounded,
                      initial: _data.instagram,
                      hintText: 'Örn: instagram.com/magazaniz',
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      'Web sitesi',
                      (v) => setState(() => _data.website = v),
                      prefixIcon: Icons.language_rounded,
                      initial: _data.website,
                      hintText: 'Örn: www.magazaniz.com',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildScoreTargetAnchor(
                _VitrinScoreTarget.address,
                _buildTextField(
                  'Adres',
                  (v) => setState(() => _data.address = v),
                  prefixIcon: Icons.location_on_rounded,
                  maxLines: 2,
                  initial: _data.address,
                  hintText: 'Örn: Mahalle, cadde, ilçe',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildScoreTargetAnchor(
            _VitrinScoreTarget.marketplace,
            _buildEditCard(
              title: 'Pazaryeri Linkleri',
              onAction: _addMarketplaceLink,
              children: [
                ...List.generate(
                  _data.marketplaceLinks.length,
                  (index) => _buildMarketplaceLinkItem(index),
                ),
                if (_data.marketplaceLinks.isEmpty)
                  Center(
                    child: Text(
                      'Henüz link eklenmedi.',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPublishPanel({
    bool compact = false,
    bool includeBottomSpacing = true,
  }) {
    final checklist = _buildPublishChecklistItems();
    final panelChildren =
        compact
            ? <Widget>[
              _buildPublishCard(
                children: [
                  _buildPublishIntro(),
                  const SizedBox(height: 18),
                  _buildPublishSectionTitle('Yayın öncesi kontrol'),
                  const SizedBox(height: 10),
                  ...checklist.map(_buildPublishChecklistRow),
                  const SizedBox(height: 10),
                  _buildPublishSectionTitle('Bu link nerede kullanılabilir?'),
                  const SizedBox(height: 10),
                  _buildPublishUsageList(),
                  const SizedBox(height: 16),
                  _buildPublishActionArea(),
                ],
              ),
            ]
            : <Widget>[
              _buildPublishCard(children: [_buildPublishIntro()]),
              const SizedBox(height: 16),
              _buildPublishCard(
                children: [
                  _buildPublishSectionTitle('Yayın öncesi kontrol'),
                  const SizedBox(height: 10),
                  ...checklist.map(_buildPublishChecklistRow),
                ],
              ),
              const SizedBox(height: 16),
              _buildPublishCard(
                children: [
                  _buildPublishSectionTitle('Bu link nerede kullanılabilir?'),
                  const SizedBox(height: 10),
                  _buildPublishUsageList(),
                  const SizedBox(height: 16),
                  _buildPublishActionArea(),
                ],
              ),
            ];

    if (includeBottomSpacing) {
      panelChildren.add(const SizedBox(height: 100));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: panelChildren,
    );
  }

  String _buildFullPublicLink(String path) {
    return PublicSiteConfig.buildPublicLink(path);
  }

  String _buildPublicLinkWithSource(String link, String source) {
    try {
      final uri = Uri.parse(link);
      final query = Map<String, String>.from(uri.queryParameters);
      query['src'] = source;
      return uri.replace(queryParameters: query).toString();
    } catch (_) {
      final separator = link.contains('?') ? '&' : '?';
      return '$link${separator}src=$source';
    }
  }

  String _generateStoreSlug(String name) {
    var slug = name.trim().toLowerCase();
    if (slug.isEmpty) return 'magazaniz';

    const replacements = {
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
    };

    replacements.forEach((source, target) {
      slug = slug.replaceAll(source, target);
    });

    slug = slug.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    slug = slug.replaceAll(RegExp(r'\s+'), '-');
    slug = slug.replaceAll(RegExp(r'-+'), '-');
    slug = slug.replaceAll(RegExp(r'^-|-$'), '');

    return slug.isEmpty ? 'magazaniz' : slug;
  }

  Widget _buildPublishIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vitrininizi yayınlayın',
          style: TextStyle(
            color: darkText,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        _gradientUnderline(width: 64),
        const SizedBox(height: 8),
        Text(
          'VitrinX linkiniz hazır olduğunda müşteriler bu adrese girerek canlı vitrininizi görebilecek.',
          style: TextStyle(
            color: softText.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildPublishUsageList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPublishBulletRow('WhatsApp mesajı'),
        _buildPublishBulletRow('Instagram bio'),
        _buildPublishBulletRow('Google İşletme profili'),
        _buildPublishBulletRow('QR kart / mağaza içi afiş'),
      ],
    );
  }

  Widget _buildPublishActionArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_publishedLink != null) ...[
          _buildPublishedLinkBlock(_publishedLink!),
          const SizedBox(height: 12),
        ],
        if (_publishError != null) ...[
          _buildPublishErrorBlock(_publishError!),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isPublishing ? null : _publishStore,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 13),
              minimumSize: const Size(44, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            child:
                _isPublishing
                    ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _isUploadingGallery
                              ? 'Galeri yükleniyor...'
                              : 'Hazırlanıyor...',
                        ),
                      ],
                    )
                    : Text(
                      _publishedLink == null
                          ? 'Vitrin linkini oluştur'
                          : 'Vitrini güncelle',
                    ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Galeri fotoğrafları Supabase Storage’a yüklenir ve public vitrinde görünür.',
          style: TextStyle(
            color: mutedText,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilityBoostIcon() {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.14)),
      ),
      child: const Icon(
        Icons.travel_explore_rounded,
        color: primaryColor,
        size: 18,
      ),
    );
  }

  Widget _buildPublishedLinkBlock(String link) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(45, 212, 191, 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color.fromRGBO(45, 212, 191, 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hazırlanan vitrin linki',
                  style: TextStyle(
                    color: const Color(0xFF5EEAD4),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _copyPublishedLink('Vitrin linki kopyalandı.'),
                tooltip: 'Linki kopyala',
                icon: Icon(
                  Icons.copy_rounded,
                  color: Colors.teal.shade800,
                  size: 17,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(255, 255, 255, 0.08),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(32, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: const BorderSide(
                    color: Color.fromRGBO(45, 212, 191, 0.22),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            link,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: darkText,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _buildPublishedQrBlock(link),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  () => _copyPublishedLink('Paylaşım için link kopyalandı.'),
              icon: const Icon(Icons.share_outlined, size: 16),
              label: const Text('Paylaş'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF5EEAD4),
                side: const BorderSide(
                  color: Color.fromRGBO(45, 212, 191, 0.32),
                ),
                padding: const EdgeInsets.symmetric(vertical: 11),
                minimumSize: const Size(44, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishedQrBlock(String link) {
    final qrLink = _buildPublicLinkWithSource(link, 'qr');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(31, 28, 44, 0.86),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: QrImageView(
              data: qrLink,
              version: QrVersions.auto,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QR ile paylaş',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Müşteriler bu kodu okutarak vitrininize ulaşabilir.',
                  style: TextStyle(
                    color: softText.withValues(alpha: 0.86),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mağaza içine, paket üzerine veya sosyal medya görseline ekleyebilirsiniz.',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishErrorBlock(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 77, 0, 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromRGBO(255, 77, 0, 0.28)),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: const Color(0xFFFFB085),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }

  List<_PublishChecklistItem> _buildPublishChecklistItems() {
    final hasMarketplaceLink = _hasCompleteMarketplaceLink(_data);

    return [
      _PublishChecklistItem(
        isReady: _data.name.trim().isNotEmpty,
        readyText: 'Mağaza adı hazır',
        missingText: 'Mağaza adı eksik',
      ),
      _PublishChecklistItem(
        isReady: _data.whatsapp.trim().isNotEmpty,
        readyText: 'WhatsApp iletişimi hazır',
        missingText: 'WhatsApp eklenmemiş',
      ),
      _PublishChecklistItem(
        isReady: _data.description.trim().isNotEmpty,
        readyText: 'Kısa açıklama hazır',
        missingText: 'Kısa açıklama eksik',
      ),
      _PublishChecklistItem(
        isReady: hasMarketplaceLink,
        readyText: 'Pazaryeri linki hazır',
        missingText: 'Pazaryeri linki eklenmemiş',
      ),
      _PublishChecklistItem(
        isReady: _data.address.trim().isNotEmpty,
        readyText: 'Adres bilgisi hazır',
        missingText: 'Adres bilgisi eksik',
      ),
    ];
  }

  Widget _buildPublishCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _premiumCardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildPublishSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: darkText,
        fontSize: 15,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }

  Widget _buildPublishChecklistRow(_PublishChecklistItem item) {
    final color = item.isReady ? const Color(0xFF2DD4BF) : mutedText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.isReady
                ? Icons.check_circle_rounded
                : Icons.info_outline_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.isReady ? item.readyText : item.missingText,
              style: TextStyle(
                color: softText.withValues(alpha: 0.88),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishBulletRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: softText.withValues(alpha: 0.72),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: softText.withValues(alpha: 0.88),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleVisibilityCta() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 430;

        final textContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daha çok kişi görsün mü?',
              style: TextStyle(
                color: darkText,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'SEO anahtar kelimeleri ve içerik fikirleriyle vitrininizi güçlendirin.',
              style: TextStyle(
                color: softText.withValues(alpha: 0.78),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
        );

        final action = TextButton.icon(
          onPressed: _showPremiumVisibilityInfo,
          icon: const Icon(Icons.auto_awesome_rounded, size: 15),
          label: const Text('Görünürlüğü artır'),
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            minimumSize: const Size(44, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor.withValues(alpha: 0.08),
                secondaryColor.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryColor.withValues(alpha: 0.18)),
          ),
          child:
              isNarrow
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildVisibilityBoostIcon(),
                          const SizedBox(width: 10),
                          Expanded(child: textContent),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(alignment: Alignment.centerLeft, child: action),
                    ],
                  )
                  : Row(
                    children: [
                      _buildVisibilityBoostIcon(),
                      const SizedBox(width: 10),
                      Expanded(child: textContent),
                      const SizedBox(width: 10),
                      action,
                    ],
                  ),
        );
      },
    );
  }

  Widget _buildEditCard({
    required String title,
    required List<Widget> children,
    VoidCallback? onAction,
    Widget? headerWidget,
  }) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Container(
      decoration: _premiumCardDecoration(radius: 24),
      padding: EdgeInsets.all(isWide ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: darkText,
                    letterSpacing: 0,
                  ),
                ),
              ),
              if (headerWidget != null)
                headerWidget
              else if (onAction != null)
                IconButton(
                  onPressed: onAction,
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: primaryColor,
                  ),
                  tooltip: 'Yeni Ekle',
                ),
            ],
          ),
          const SizedBox(height: 8),
          _gradientUnderline(width: 52),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMarketplaceLinkItem(int index) {
    final link = _data.marketplaceLinks[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  'Platform',
                  link.platform,
                  platforms,
                  (v) => setState(() => link.platform = v!),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _removeMarketplaceLink(index),
                icon: const Icon(
                  Icons.remove_circle_outline_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            'Mağaza Linki',
            (v) => setState(() => link.url = v),
            prefixIcon: Icons.link_rounded,
            initial: link.url,
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreviewMockup(BoxConstraints constraints) {
    final isMobilePreview = constraints.maxWidth < 520;

    if (isMobilePreview) {
      return _buildMobileLivePreview();
    }

    return _buildDesktopLivePreview(constraints);
  }

  Widget _buildPremium3DDeviceFrame({
    required Widget child,
    required double width,
    required double height,
    required bool isDarkTheme,
    bool isMobilePreview = false,
  }) {
    final statusColor =
        isDarkTheme
            ? Colors.white.withValues(alpha: 0.75)
            : Colors.black.withValues(alpha: 0.75);
    final indicatorColor =
        isDarkTheme
            ? Colors.white.withValues(alpha: 0.32)
            : Colors.black.withValues(alpha: 0.28);
    final frameRadius = isMobilePreview ? 46.0 : 52.0;
    final framePadding = isMobilePreview ? 2.2 : 3.0;
    final shellRadius = frameRadius - 3;
    final screenRadius = frameRadius - 5;
    final statusBarHeight = isMobilePreview ? 38.0 : 44.0;
    final bottomInset = isMobilePreview ? 16.0 : 20.0;
    final statusHorizontalPadding = isMobilePreview ? 20.0 : 22.0;
    final islandWidth = isMobilePreview ? 92.0 : 110.0;
    final islandHeight = isMobilePreview ? 23.0 : 26.0;
    final homeIndicatorWidth = isMobilePreview ? 92.0 : 120.0;
    // Titanium frame gradient (silver/matte like iPhone 15 Pro)
    const titaniumGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF9EA5AD), // top-left highlight
        Color(0xFF6B7480), // mid
        Color(0xFF4A5260), // shadow
        Color(0xFF7E8898), // bottom-right partial light
      ],
      stops: [0.0, 0.35, 0.65, 1.0],
    );

    return Stack(
      children: [
        // Outer titanium body with gradient border
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: titaniumGradient,
            borderRadius: BorderRadius.circular(frameRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.62),
                blurRadius: isMobilePreview ? 42 : 52,
                offset: Offset(0, isMobilePreview ? 22 : 28),
              ),
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.18),
                blurRadius: isMobilePreview ? 38 : 48,
                offset: const Offset(-12, 8),
              ),
              BoxShadow(
                color: secondaryColor.withValues(alpha: 0.22),
                blurRadius: isMobilePreview ? 48 : 60,
                offset: Offset(14, isMobilePreview ? 22 : 28),
              ),
              BoxShadow(
                color: const Color.fromRGBO(255, 255, 255, 0.94),
                blurRadius: 12,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          padding: EdgeInsets.all(framePadding),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0F),
              borderRadius: BorderRadius.circular(shellRadius),
              border: Border.all(
                color: const Color(0xFF1A1A22),
                width: isMobilePreview ? 1.1 : 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(screenRadius),
              child: Stack(
                children: [
                  // Screen background (black behind VitrinView)
                  const Positioned.fill(
                    child: ColoredBox(color: Color(0xFF000000)),
                  ),
                  // Main phone screen content
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: statusBarHeight,
                        bottom: bottomInset,
                      ),
                      child: child,
                    ),
                  ),

                  // Gentle inner screen depth so the mockup feels less flat.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(screenRadius),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(
                                alpha: isMobilePreview ? 0.12 : 0.08,
                              ),
                              Colors.transparent,
                              Colors.black.withValues(
                                alpha: isMobilePreview ? 0.10 : 0.08,
                              ),
                            ],
                            stops: const [0.0, 0.18, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Glossy edge-glow reflection (left)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(screenRadius),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.06),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.08),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Status Bar background blur
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: statusBarHeight,
                    child: Container(
                      color:
                          isDarkTheme
                              ? const Color(0xCC000000)
                              : Colors.white.withValues(alpha: 0.82),
                    ),
                  ),

                  // Status Bar content
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: statusBarHeight,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: statusHorizontalPadding,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '9:41',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: isMobilePreview ? 12 : 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.signal_cellular_4_bar_rounded,
                                size: 12,
                                color: statusColor,
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.wifi_rounded,
                                size: 14,
                                color: statusColor,
                              ),
                              const SizedBox(width: 4),
                              // Battery icon
                              SizedBox(
                                width: 24,
                                height: 12,
                                child: Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    Container(
                                      width: 21,
                                      height: 11,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: statusColor,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          2.5,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(1.5),
                                      child: Container(
                                        width: 14,
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          borderRadius: BorderRadius.circular(
                                            1,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      child: Container(
                                        width: 2,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(1),
                                            bottomRight: Radius.circular(1),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Dynamic Island (pill-shaped, modern)
                  Positioned(
                    top: isMobilePreview ? 8 : 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: islandWidth,
                        height: islandHeight,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(islandHeight / 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Front camera dot
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1C28),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF2C2C3E),
                                  width: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Home Indicator (swipe bar)
                  Positioned(
                    bottom: 5,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: homeIndicatorWidth,
                        height: 4,
                        decoration: BoxDecoration(
                          color: indicatorColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Physical side buttons — Volume Up
        Positioned(
          left: 0,
          top: height * 0.22,
          child: Container(
            width: 4,
            height: height * 0.07,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF8A929C), Color(0xFF5A6270)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                bottomLeft: Radius.circular(3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 4,
                  offset: const Offset(-2, 0),
                ),
              ],
            ),
          ),
        ),

        // Physical side buttons — Volume Down
        Positioned(
          left: 0,
          top: height * 0.315,
          child: Container(
            width: 4,
            height: height * 0.07,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF8A929C), Color(0xFF5A6270)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                bottomLeft: Radius.circular(3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 4,
                  offset: const Offset(-2, 0),
                ),
              ],
            ),
          ),
        ),

        // Physical side buttons — Power/Lock
        Positioned(
          right: 0,
          top: height * 0.265,
          child: Container(
            width: 4,
            height: height * 0.10,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF8A929C), Color(0xFF5A6270)],
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(3),
                bottomRight: Radius.circular(3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 4,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLivePreview() {
    final preset = vitrinThemePresetFor(_data.theme);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Column(
        children: [
          _buildLivePreviewBadge(),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, phoneConstraints) {
                final maxPhoneWidth = min(
                  phoneConstraints.maxWidth * 0.92,
                  342.0,
                );
                final maxPhoneHeight = phoneConstraints.maxHeight;
                const targetRatio = 2.14;
                var phoneHeight = min(
                  maxPhoneHeight,
                  maxPhoneWidth * targetRatio,
                );
                var phoneWidth = phoneHeight / targetRatio;

                if (phoneWidth < 286.0 &&
                    maxPhoneWidth >= 286.0 &&
                    maxPhoneHeight >= 286.0 * targetRatio) {
                  phoneWidth = 286.0;
                  phoneHeight = phoneWidth * targetRatio;
                }

                phoneWidth = phoneWidth.clamp(260.0, maxPhoneWidth).toDouble();
                phoneHeight = min(maxPhoneHeight, phoneWidth * targetRatio);

                return Center(
                  child: _buildPremium3DDeviceFrame(
                    width: phoneWidth,
                    height: phoneHeight,
                    isDarkTheme: preset.isDark,
                    isMobilePreview: true,
                    child: VitrinView(
                      key: ValueKey(
                        'mobile_preview_${_data.name}_${_data.marketplaceLinks.length}_${_data.description}_${_data.theme}_${_galleryPreviewKey()}',
                      ),
                      storeData: _data,
                      isEmbedded: true,
                      compactEmbeddedHeader: true,
                      previewGalleryItems: _galleryPreviewItems(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreviewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_rounded, size: 14, color: primaryColor),
          SizedBox(width: 7),
          Text(
            'CANLI ÖNİZLEME',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              color: softText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLivePreview(BoxConstraints constraints) {
    final preset = vitrinThemePresetFor(_data.theme);

    return Stack(
      children: [
        // Lighter 3D background with radial depth effects
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E2235), // lighter navy-slate
                  Color(0xFF252842), // mid blue-slate
                  Color(0xFF1A1D30), // slightly deeper
                ],
              ),
              border: Border.all(color: Color.fromRGBO(255, 255, 255, 0.10)),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.52),
                  blurRadius: 34,
                  offset: Offset(0, 18),
                ),
              ],
            ),
          ),
        ),
        // Radial top-left glow (accent light)
        Positioned(
          top: 24,
          left: 24,
          child: IgnorePointer(
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x22FF4D00), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        // Radial bottom-right glow (secondary light)
        Positioned(
          bottom: 24,
          right: 24,
          child: IgnorePointer(
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x1AB200FF), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        // Main content column
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                _buildLivePreviewBadge(),
                const SizedBox(height: 12),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, phoneConstraints) {
                      // Modern 9:19.5 aspect ratio (iPhone 15 Pro-like)
                      final availableH = phoneConstraints.maxHeight;
                      final availableW = phoneConstraints.maxWidth;
                      // Fit phone to fill available space, respecting ratio
                      double phoneHeight = availableH * 0.96;
                      double phoneWidth = phoneHeight / 2.17;
                      if (phoneWidth > availableW * 0.88) {
                        phoneWidth = availableW * 0.88;
                        phoneHeight = phoneWidth * 2.17;
                      }
                      phoneWidth = max(260.0, min(phoneWidth, 390.0));
                      phoneHeight = max(520.0, min(phoneHeight, availableH));

                      return Center(
                        child: _buildPremium3DDeviceFrame(
                          width: phoneWidth,
                          height: phoneHeight,
                          isDarkTheme: preset.isDark,
                          child: VitrinView(
                            key: ValueKey(
                              'preview_${_data.name}_${_data.marketplaceLinks.length}_${_data.description}_${_data.theme}_${_galleryPreviewKey()}',
                            ),
                            storeData: _data,
                            isEmbedded: true,
                            previewGalleryItems: _galleryPreviewItems(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryStudio() {
    _normalizeGallerySelection();
    final selectedItem =
        _galleryItems.isEmpty ? null : _galleryItems[_selectedGalleryIndex];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: secondaryColor.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: ctaGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Galeri Stüdyosu',
                      style: TextStyle(
                        color: darkText,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Kapak, fotoğraflar ve kısa açıklamalar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cardBorder),
                ),
                child: Text(
                  '${_galleryItems.length} / $_maxGalleryPhotos',
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_galleryItems.isEmpty)
            _buildGalleryEmptyState()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 620;
                if (!isWide) {
                  return Column(
                    children: [
                      _buildGalleryMainStage(selectedItem!),
                      const SizedBox(height: 14),
                      _buildGalleryGrid(),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildGalleryMainStage(selectedItem!)),
                    const SizedBox(width: 16),
                    SizedBox(width: 230, child: _buildGalleryGrid()),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildGalleryEmptyState() {
    return InkWell(
      onTap: _pickGalleryPhotos,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: ctaGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_photo_alternate_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'İlk fotoğrafı ekle',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: darkText,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Mağazanı, ürünlerini veya rafını gösteren güçlü görseller seç. İlk fotoğraf kapak olur.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: softText.withValues(alpha: 0.74),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            const Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                _ShelfHintChip(label: 'Kapak fotoğrafı'),
                _ShelfHintChip(label: 'Ürün alanı'),
                _ShelfHintChip(label: 'Mağaza atmosferi'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryMainStage(_EditorGalleryItem item) {
    final isCover = _selectedGalleryIndex == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildEditorGalleryImage(item),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.08),
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.48),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: _GalleryPill(
                    label:
                        isCover
                            ? 'Kapak'
                            : '${_selectedGalleryIndex + 1}. fotoğraf',
                    icon: isCover ? Icons.star_rounded : Icons.image_rounded,
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      if (!isCover)
                        _buildGalleryToolbarButton(
                          label: 'Kapak yap',
                          icon: Icons.star_rounded,
                          onPressed:
                              () => _makeGalleryCover(_selectedGalleryIndex),
                        ),
                      _buildGalleryToolbarButton(
                        label: 'Değiştir',
                        icon: Icons.swap_horiz_rounded,
                        onPressed:
                            () => _replaceGalleryPhoto(_selectedGalleryIndex),
                      ),
                      _buildGalleryToolbarButton(
                        label: 'Sil',
                        icon: Icons.close_rounded,
                        onPressed:
                            () => _removeGalleryPhoto(_selectedGalleryIndex),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildGalleryMetaFields(item),
      ],
    );
  }

  Widget _buildGalleryMetaFields(_EditorGalleryItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCompactGalleryTextField(
          label: 'Kısa başlık',
          controller: item.titleController,
          hintText: 'Örn: Yeni sezon rafı',
          maxLength: 40,
        ),
        const SizedBox(height: 10),
        _buildCompactGalleryTextField(
          label: 'Açıklama',
          controller: item.descriptionController,
          hintText: 'Örn: El yapımı ürünlerin yer aldığı ana vitrin.',
          maxLength: 120,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildCompactGalleryTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required int maxLength,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: softText.withValues(alpha: 0.82),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          onChanged: (_) {
            _syncPublishedGalleryData();
            setState(() {});
          },
          decoration: InputDecoration(
            counterText: '',
            hintText: hintText,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.86),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Color(0x66FF4D00)),
            ),
            hintStyle: TextStyle(
              color: mutedText.withValues(alpha: 0.62),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: const TextStyle(
            color: darkText,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 420 ? 3 : 2;
        const gap = 9.0;
        final tileWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        final children = <Widget>[
          ...List.generate(
            _galleryItems.length,
            (index) => SizedBox(
              width: tileWidth,
              child: _buildGalleryThumbnailTile(index),
            ),
          ),
          if (_galleryItems.length < _maxGalleryPhotos)
            SizedBox(width: tileWidth, child: _buildGalleryAddTile()),
        ];

        return Wrap(spacing: gap, runSpacing: gap, children: children);
      },
    );
  }

  Widget _buildGalleryThumbnailTile(int index) {
    final item = _galleryItems[index];
    final isSelected = _selectedGalleryIndex == index;

    return InkWell(
      onTap: () => _selectGalleryItem(index),
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.all(isSelected ? 2 : 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? primaryColor : cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ]
                  : null,
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(isSelected ? 12 : 15),
                child: _buildEditorGalleryImage(item),
              ),
              Positioned(
                left: 6,
                top: 6,
                child: _GalleryPill(
                  label: index == 0 ? 'Kapak' : '${index + 1}',
                  icon: index == 0 ? Icons.star_rounded : Icons.image_rounded,
                  compact: true,
                ),
              ),
              Positioned(
                right: 5,
                top: 5,
                child: GestureDetector(
                  onTap: () => _removeGalleryPhoto(index),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      border: Border.all(color: cardBorder),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: darkText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryAddTile() {
    return InkWell(
      onTap: _pickGalleryPhotos,
      borderRadius: BorderRadius.circular(15),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: cardBorder),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_rounded, color: primaryColor),
              SizedBox(height: 6),
              Text(
                'Ekle',
                style: TextStyle(
                  color: darkText,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryToolbarButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: darkText),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: darkText,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditorGalleryImage(_EditorGalleryItem item) {
    final bytes = item.bytes;
    if (bytes != null) {
      return Image.memory(
        bytes,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }

    return Image.network(
      item.imageUrl.trim(),
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildShelfImageError(),
    );
  }

  Widget _buildShelfImageError() {
    return Container(
      color: inputBg,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, color: mutedText, size: 28),
          const SizedBox(height: 8),
          Text(
            'Fotoğraf önizlenemedi',
            style: TextStyle(
              color: softText.withValues(alpha: 0.72),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    Function(String) onChanged, {
    int maxLines = 1,
    IconData? prefixIcon,
    String? initial,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: softText.withValues(alpha: 0.78),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initial,
          decoration: InputDecoration(
            prefixIcon:
                prefixIcon != null
                    ? Icon(prefixIcon, color: mutedText, size: 18)
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: cardBorder),
            ),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            hintText: hintText ?? label,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x66FF4D00)),
            ),
            hintStyle: TextStyle(
              color: mutedText.withValues(alpha: 0.58),
              fontSize: 14,
            ),
          ),
          maxLines: maxLines,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: darkText,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStatusDropdown() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _data.status,
          icon: const Padding(
            padding: EdgeInsets.only(left: 4.0),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: primaryColor,
            ),
          ),
          isDense: true,
          alignment: Alignment.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: primaryColor,
          ),
          items:
              statuses
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
          onChanged: (v) => setState(() => _data.status = v!),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: softText.withValues(alpha: 0.78),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x66FF4D00)),
            ),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          dropdownColor: Colors.white,
          iconEnabledColor: mutedText,
          style: const TextStyle(
            color: darkText,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          borderRadius: BorderRadius.circular(14),
          items:
              items
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(
                        t,
                        style: const TextStyle(
                          color: darkText,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
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

  Widget _buildMobileBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.94),
        border: const Border(top: BorderSide(color: cardBorder)),
        boxShadow: [
          BoxShadow(
            color: secondaryColor.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: _buildGradientButton(
                label: 'Kaydet',
                onPressed: _saveData,
                icon: Icons.cloud_done_outlined,
                expand: true,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGradientButton(
                label: 'Vitrini Aç',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => PreviewScreen(
                            storeData: _data,
                            previewGalleryItems: _galleryPreviewItems(),
                          ),
                    ),
                  );
                },
                icon: Icons.share_outlined,
                expand: true,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorGalleryItem {
  final String id;
  Uint8List? bytes;
  String imageUrl;
  String? fileName;
  String extension;
  String contentType;
  final TextEditingController titleController;
  final TextEditingController descriptionController;

  _EditorGalleryItem({
    required this.id,
    this.bytes,
    this.imageUrl = '',
    this.fileName,
    this.extension = 'jpg',
    this.contentType = 'image/jpeg',
    String title = '',
    String description = '',
  }) : titleController = TextEditingController(text: title),
       descriptionController = TextEditingController(text: description);

  factory _EditorGalleryItem.fromStoreItem(StoreGalleryItem item) {
    return _EditorGalleryItem(
      id:
          item.id.isEmpty
              ? DateTime.now().microsecondsSinceEpoch.toString()
              : item.id,
      imageUrl: item.imageUrl,
      title: item.title,
      description: item.description,
    );
  }

  String get title => titleController.text.trim();

  String get description => descriptionController.text.trim();

  bool get hasLocalBytes => bytes != null;

  bool get hasPreviewImage => hasLocalBytes || imageUrl.trim().isNotEmpty;

  void markUploaded(String uploadedUrl) {
    imageUrl = uploadedUrl;
    bytes = null;
  }

  void replaceImageFrom(_EditorGalleryItem replacement) {
    bytes = replacement.bytes;
    imageUrl = '';
    fileName = replacement.fileName;
    extension = replacement.extension;
    contentType = replacement.contentType;
  }

  StoreGalleryItem toStoreItem() {
    return StoreGalleryItem(
      id: id,
      imageUrl: imageUrl.trim(),
      title: title,
      description: description,
    );
  }

  VitrinGalleryPreviewItem toPreviewItem() {
    return VitrinGalleryPreviewItem(
      imageUrl: imageUrl,
      imageBytes: bytes,
      title: title,
      description: description,
    );
  }

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
  }
}

class _GalleryFilePickResult {
  const _GalleryFilePickResult._({this.item, this.failure});

  const _GalleryFilePickResult.success(_EditorGalleryItem item)
    : this._(item: item);

  const _GalleryFilePickResult.failure(GalleryImageValidationFailure? failure)
    : this._(failure: failure);

  final _EditorGalleryItem? item;
  final GalleryImageValidationFailure? failure;

  bool get isValid => item != null;
}

class _GalleryPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool compact;

  const _GalleryPill({
    required this.label,
    required this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: compact ? 10 : 13),
          SizedBox(width: compact ? 3 : 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 8.5 : 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorGridPainter extends CustomPainter {
  const _EditorGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color.fromRGBO(15, 23, 42, 0.055)
          ..strokeWidth = 0.5;

    for (double x = 0; x <= size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShelfHintChip extends StatelessWidget {
  final String label;

  const _ShelfHintChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _EditorScreenState.cardBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _EditorScreenState.softText.withValues(alpha: 0.9),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

enum _VitrinScoreTarget {
  storeName,
  whatsapp,
  description,
  social,
  address,
  marketplace,
  about,
  gallery,
}

class _VitrinScoreTask {
  final int points;
  final bool isComplete;
  final String suggestion;
  final _VitrinScoreTarget target;

  const _VitrinScoreTask({
    required this.points,
    required this.isComplete,
    required this.suggestion,
    required this.target,
  });
}

class _PublishChecklistItem {
  final bool isReady;
  final String readyText;
  final String missingText;

  const _PublishChecklistItem({
    required this.isReady,
    required this.readyText,
    required this.missingText,
  });
}
