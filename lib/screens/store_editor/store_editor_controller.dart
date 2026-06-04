import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:vitrinx/config/public_site_config.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/screens/landing_screen.dart';
import 'package:vitrinx/services/local_storage_keys.dart';
import 'package:vitrinx/services/store_publish_payload_builder.dart';
import 'package:vitrinx/services/store_publish_service.dart';
import 'package:vitrinx/services/store_publish_validator.dart';
import 'package:vitrinx/services/store_shelf_upload_service.dart';
import 'package:vitrinx/services/vitrin_view_service.dart';
import 'package:vitrinx/utils/gallery_image_file_validator.dart';
import 'package:vitrinx/widgets/vitrin_view.dart';
import 'editor_gallery_item.dart';

enum StoreScoreTarget {
  storeName,
  whatsapp,
  description,
  social,
  address,
  marketplace,
  about,
  gallery,
}

class StoreScoreTask {
  final int points;
  final bool isComplete;
  final String suggestion;
  final StoreScoreTarget target;

  const StoreScoreTask({
    required this.points,
    required this.isComplete,
    required this.suggestion,
    required this.target,
  });
}

class StorePublishChecklistItem {
  final bool isReady;
  final String readyText;
  final String missingText;

  const StorePublishChecklistItem({
    required this.isReady,
    required this.readyText,
    required this.missingText,
  });
}

class StoreEditorController extends ChangeNotifier {
  final String? initialStoreName;
  final StoreData data = StoreData(isEsnafMode: false, isStore: true);
  
  bool isLoading = true;
  bool isPublishing = false;
  bool isDeleting = false;
  bool isUploadingGallery = false;
  int selectedGalleryIndex = 0;
  String? existingVitrinToken;
  int todayViewCount = 0;
  bool isTodayViewCountLoading = false;
  final List<EditorGalleryItem> galleryItems = [];
  String? publishedLink;
  String? publishError;
  String? lastViewCountSlug;
  Timer? viewCountDebounce;
  StoreScoreTarget? highlightedScoreTarget;
  int scoreTargetHighlightToken = 0;

  // Geolocation & Consent fields
  double? latitude;
  double? longitude;
  double? locationAccuracyMeters;
  DateTime? locationConsentAt;
  String? locationSource;
  bool kvkkConsent = false;
  bool isLocating = false;
  String? locationStatusMessage;

  // Logo fields
  Uint8List? logoBytes;
  String? logoExtension;
  String? logoContentType;

  // Controllers
  final TextEditingController addressCtrl = TextEditingController();

  static const int _maxGalleryPhotos = 12;
  static const int _maxGalleryPhotoBytes = GalleryImageFileValidator.maxBytes;

  StoreEditorController({this.initialStoreName}) {
    if (initialStoreName != null && initialStoreName!.trim().isNotEmpty) {
      data.name = initialStoreName!.trim();
    }
  }

  void handleStoreNameChanged(String value) {
    data.name = value;
    _scheduleTodayViewCountRefresh();
    notifyListeners();
  }

  void _scheduleTodayViewCountRefresh() {
    viewCountDebounce?.cancel();
    viewCountDebounce = Timer(const Duration(milliseconds: 700), () {
      refreshTodayViewCount();
    });
  }

  Future<void> loadSavedData(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedJson = prefs.getString(LocalStorageKeys.storeData);
      final token = prefs.getString(LocalStorageKeys.storeEditToken);

      existingVitrinToken = token;

      if (savedJson != null) {
        final Map<String, dynamic> jsonData = jsonDecode(savedJson);
        final loadedData = StoreData.fromJson(jsonData);
        
        data.name = (initialStoreName != null && initialStoreName!.trim().isNotEmpty)
            ? initialStoreName!.trim()
            : loadedData.name;
        data.businessType = loadedData.businessType;
        data.kategori = loadedData.kategori.isEmpty ? 'Diğer' : loadedData.kategori;
        data.description = loadedData.description;
        data.whatsapp = loadedData.whatsapp;
        data.instagram = loadedData.instagram;
        data.website = loadedData.website;
        data.address = loadedData.address;
        data.theme = loadedData.theme;
        data.status = loadedData.status;
        data.isEsnafMode = loadedData.isEsnafMode;
        data.isStore = loadedData.isStore;
        data.corporateBio = loadedData.corporateBio;
        data.referencesLink = loadedData.referencesLink;
        data.shelfImageUrl = loadedData.shelfImageUrl;
        data.galleryItems = loadedData.galleryItems;
        data.marketplaceLinks = loadedData.marketplaceLinks;
        data.products = loadedData.products;
        data.logoUrl = loadedData.logoUrl;

        latitude = loadedData.latitude;
        longitude = loadedData.longitude;
        locationAccuracyMeters = loadedData.locationAccuracyMeters;
        locationConsentAt = loadedData.locationConsentAt;
        locationSource = loadedData.locationSource;
        kvkkConsent = loadedData.latitude != null && loadedData.longitude != null;

        addressCtrl.text = loadedData.address;
        _replaceEditorGalleryItems(loadedData.displayGalleryItems);
      } else {
        if (initialStoreName != null && initialStoreName!.trim().isNotEmpty) {
          data.name = initialStoreName!.trim();
        }
        data.kategori = 'Diğer';
        addressCtrl.text = data.address;
      }
      isLoading = false;
      notifyListeners();
      unawaited(refreshTodayViewCount(force: true));
    } catch (e) {
      debugPrint('Data load error: $e');
      isLoading = false;
      notifyListeners();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mağaza verileri yüklenemedi, varsayılan değerler kullanılıyor.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      });
    }
  }

  Future<void> saveData(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (logoBytes != null) {
        final slug = generateStoreSlug(data.name);
        final logoUrl = await const StoreShelfUploadService().uploadShelfImage(
          logoBytes!,
          '$slug/logo',
          fileExtension: logoExtension ?? 'jpg',
          contentType: logoContentType ?? 'image/jpeg',
        );
        data.logoUrl = logoUrl;
        logoBytes = null;
      }

      data.address = addressCtrl.text.trim();
      data.latitude = latitude;
      data.longitude = longitude;
      data.locationAccuracyMeters = locationAccuracyMeters;
      data.locationConsentAt = locationConsentAt;
      data.locationSource = locationSource;
      data.isStore = true;

      final String jsonData = jsonEncode(data.toJson());
      await prefs.setString(LocalStorageKeys.storeData, jsonData);
      
      notifyListeners();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.cloud_done_outlined, color: Colors.white),
              SizedBox(width: 12),
              Text('Mağaza başarıyla kaydedildi'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFFF4D00),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
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

  Future<void> getCurrentLocation() async {
    isLocating = true;
    locationStatusMessage = null;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationStatusMessage = 'Konum servisleri devre dışı. Lütfen cihazınızda konumu açın.';
        isLocating = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          locationStatusMessage = 'Konum izni reddedildi. Konum almak için izin vermelisiniz.';
          isLocating = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        locationStatusMessage = 'Konum izinleri kalıcı olarak reddedildi. Tarayıcı ayarlarından izin verin.';
        isLocating = false;
        notifyListeners();
        return;
      }

      LocationSettings locationSettings;
      if (kIsWeb) {
        locationSettings = WebSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 8),
          maximumAge: Duration.zero,
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 8),
        );
      }

      Position? bestPosition;
      final positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      );

      final completer = Completer<Position?>();
      StreamSubscription<Position>? subscription;

      subscription = positionStream.listen(
        (pos) {
          if (bestPosition == null || pos.accuracy < bestPosition!.accuracy) {
            bestPosition = pos;
          }
          if (pos.accuracy <= 20) {
            completer.complete(pos);
          }
        },
        onError: (err) {
          if (!completer.isCompleted) {
            completer.completeError(err);
          }
        },
      );

      Future.delayed(const Duration(seconds: 4), () {
        if (!completer.isCompleted) {
          completer.complete(bestPosition);
        }
      });

      Position? position;
      try {
        position = await completer.future.timeout(const Duration(seconds: 8));
      } finally {
        await subscription.cancel();
      }

      position ??= await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      latitude = position.latitude;
      longitude = position.longitude;
      locationAccuracyMeters = position.accuracy;
      locationConsentAt = DateTime.now();
      locationSource = 'geolocator';

      final accuracyStr = position.accuracy.toStringAsFixed(0);
      if (position.accuracy > 100) {
        locationStatusMessage = 'Konum alındı. Hata payı: yaklaşık $accuracyStr m. Hata payı yüksek. Daha iyi sonuç için açık alanda tekrar deneyebilirsiniz.';
      } else {
        locationStatusMessage = 'Konum alındı. Hata payı: yaklaşık $accuracyStr m.';
      }

      isLocating = false;

      if (addressCtrl.text.trim().isEmpty) {
        addressCtrl.text = 'Koordinatlarla işaretlenen konum';
        data.address = 'Koordinatlarla işaretlenen konum';
      }
      notifyListeners();
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('timeout') || errorStr.contains('time out')) {
        locationStatusMessage = 'Konum alınamadı. Lütfen tekrar deneyin veya adresi elle yazın.';
      } else {
        locationStatusMessage = 'Konum alınırken hata oluştu: $e';
      }
      isLocating = false;
      notifyListeners();
    }
  }

  Future<void> publishStore(BuildContext context) async {
    if (isPublishing) return;

    data.address = addressCtrl.text.trim();
    data.latitude = latitude;
    data.longitude = longitude;
    data.locationAccuracyMeters = locationAccuracyMeters;
    data.locationConsentAt = locationConsentAt;
    data.locationSource = locationSource;

    final validationMessage = const StorePublishValidator().validateStore(data);
    if (validationMessage != null) {
      publishedLink = null;
      publishError = validationMessage;
      notifyListeners();
      
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

    if (data.products.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ürün eklemek mağazanızı güçlendirir!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    }

    isPublishing = true;
    isUploadingGallery = galleryItems.any((item) => item.hasLocalBytes);
    publishedLink = null;
    publishError = null;
    notifyListeners();

    var failedUploadCount = 0;

    try {
      if (galleryItems.any((item) => item.hasLocalBytes)) {
        failedUploadCount = await _uploadPendingGalleryImages();
        isUploadingGallery = false;
        notifyListeners();
        if (failedUploadCount > 0) {
          throw StorePublishException(
            '$failedUploadCount fotoğraf yüklenemedi. Mağaza yayınlanmadı. Lütfen tekrar deneyin veya sorunlu fotoğrafı kaldırın.',
          );
        }
      }

      if (logoBytes != null) {
        final slug = generateStoreSlug(data.name);
        final logoUrl = await const StoreShelfUploadService().uploadShelfImage(
          logoBytes!,
          '$slug/logo',
          fileExtension: logoExtension ?? 'jpg',
          contentType: logoContentType ?? 'image/jpeg',
        );
        data.logoUrl = logoUrl;
        logoBytes = null;
      }

      _syncPublishedGalleryData();

      final editToken = await _loadOrCreateEditToken();
      final publishResult = await const StorePublishService().publishStore(
        data,
        editToken: editToken,
      );
      
      final publicLink = _buildFullPublicLink(publishResult.publicPath);

      final publishSnackMessage = publishResult.wasUpdated
          ? 'Mağazanız güncellendi.'
          : 'Mağaza linkiniz hazırlandı.';
          
      publishedLink = publicLink;
      existingVitrinToken = editToken;
      notifyListeners();
      
      unawaited(refreshTodayViewCount(force: true));

      if (!context.mounted) return;
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
      final userMessage = error is StorePublishException
          ? error.message
          : 'Mağaza bağlantısı hazırlanamadı. Supabase ayarlarını veya izinleri kontrol edin.';
          
      publishError = userMessage;
      notifyListeners();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userMessage),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      isPublishing = false;
      isUploadingGallery = false;
      notifyListeners();
    }
  }

  Future<void> copyPublishedLink(BuildContext context, String message) async {
    final link = publishedLink;
    if (link == null || link.trim().isEmpty) return;

    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> deleteVitrin(BuildContext context) async {
    if (isDeleting) return;
    isDeleting = true;
    notifyListeners();

    try {
      final token = existingVitrinToken;
      if (token != null && token.isNotEmpty) {
        final client = Supabase.instance.client;
        debugPrint('[Editor] Vitrin siliniyor, token: $token');
        await client.from('stores').delete().eq('edit_token', token);
        debugPrint('[Editor] Vitrin veritabanından silindi ✓');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(LocalStorageKeys.storeEditToken);
      await prefs.remove(LocalStorageKeys.storeData);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mağazanız başarıyla silindi.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF10B981),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LandingScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('[Editor] Silme hatası: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mağaza silinirken bir hata oluştu: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      isDeleting = false;
      notifyListeners();
    }
  }

  Future<String> _loadOrCreateEditToken() async {
    final prefs = await SharedPreferences.getInstance();
    final String key = LocalStorageKeys.storeEditToken;
    final savedToken = prefs.getString(key);
    if (savedToken != null && savedToken.trim().isNotEmpty) {
      return savedToken;
    }

    final token = _generateEditToken();
    await prefs.setString(key, token);
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

  Future<void> refreshTodayViewCount({bool force = false}) async {
    final slug = generateStoreSlug(data.name);

    if (data.name.trim().isEmpty) {
      todayViewCount = 0;
      isTodayViewCountLoading = false;
      lastViewCountSlug = null;
      notifyListeners();
      return;
    }

    if (!force && lastViewCountSlug == slug) return;

    isTodayViewCountLoading = true;
    lastViewCountSlug = slug;
    notifyListeners();

    try {
      final editToken = await _loadOrCreateEditToken();
      final count = await const VitrinViewService().fetchTodayViewCount(
        slug: slug,
        editToken: editToken,
      );

      if (generateStoreSlug(data.name) != slug) return;

      todayViewCount = count;
      isTodayViewCountLoading = false;
      notifyListeners();
    } catch (error) {
      debugPrint('Today view count refresh error: $error');
      if (generateStoreSlug(data.name) != slug) return;

      todayViewCount = 0;
      isTodayViewCountLoading = false;
      notifyListeners();
    }
  }

  String generateStoreSlug(String name) {
    return const StorePublishPayloadBuilder().generateSlug(name);
  }

  void _replaceEditorGalleryItems(List<StoreGalleryItem> items) {
    for (final item in galleryItems) {
      item.dispose();
    }

    galleryItems
      ..clear()
      ..addAll(
        items
            .where((item) => item.imageUrl.trim().isNotEmpty)
            .take(_maxGalleryPhotos)
            .map(EditorGalleryItem.fromStoreItem),
      );
    selectedGalleryIndex = 0;
  }

  void _syncPublishedGalleryData() {
    final publishedItems = galleryItems
        .where((item) => item.imageUrl.trim().isNotEmpty)
        .take(_maxGalleryPhotos)
        .map((item) => item.toStoreItem())
        .toList();

    data.galleryItems = publishedItems;
    data.shelfImageUrl = publishedItems.isEmpty ? '' : publishedItems.first.imageUrl.trim();
  }

  List<VitrinGalleryPreviewItem> galleryPreviewItems() {
    return galleryItems
        .where((item) => item.hasPreviewImage)
        .take(_maxGalleryPhotos)
        .map((item) => item.toPreviewItem())
        .toList();
  }

  String galleryPreviewKey() {
    return galleryItems
        .map(
          (item) => '${item.id}_${item.imageUrl}_${item.hasLocalBytes}_${item.title}_${item.description}',
        )
        .join('|');
  }

  Future<int> _uploadPendingGalleryImages() async {
    var failedUploadCount = 0;
    final uploadService = const StoreShelfUploadService();
    final slug = generateStoreSlug(data.name);

    for (final item in galleryItems) {
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

  Future<void> pickGalleryPhotos(BuildContext context) async {
    final remainingSlots = _maxGalleryPhotos - galleryItems.length;
    if (remainingSlots <= 0) {
      _showInfoSnackBar(context, 'En fazla $_maxGalleryPhotos fotoğraf ekleyebilirsiniz.');
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: true,
    );

    if (!context.mounted) return;
    if (result == null || result.files.isEmpty) return;

    var rejectedCount = 0;
    GalleryImageValidationFailure? firstFailure;
    final newItems = <EditorGalleryItem>[];
    final selectedFiles = result.files.take(remainingSlots).toList();

    for (final file in selectedFiles) {
      final res = _editorGalleryItemFromFile(file);
      if (!res.isValid) {
        rejectedCount += 1;
        firstFailure ??= res.failure;
        continue;
      }
      newItems.add(res.item!);
    }

    if (result.files.length > remainingSlots) {
      rejectedCount += result.files.length - remainingSlots;
    }

    if (newItems.isEmpty) {
      _showInfoSnackBar(
        context,
        rejectedCount > 0 ? _galleryImageFailureMessage(firstFailure) : 'Fotoğraf eklenmedi.',
      );
      return;
    }

    final firstNewIndex = galleryItems.length;
    galleryItems.addAll(newItems);
    selectedGalleryIndex = firstNewIndex;
    _syncPublishedGalleryData();
    notifyListeners();

    if (rejectedCount > 0) {
      _showInfoSnackBar(
        context,
        '$rejectedCount fotoğraf eklenemedi. Sınır: $_maxGalleryPhotos fotoğraf, dosya başı ${_maxGalleryPhotoBytes ~/ (1024 * 1024)} MB.',
      );
    }
  }

  Future<void> replaceGalleryPhoto(BuildContext context, int index) async {
    if (index < 0 || index >= galleryItems.length) return;

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
      withData: true,
    );

    if (!context.mounted) return;
    if (result == null || result.files.isEmpty) return;

    final replacement = _editorGalleryItemFromFile(result.files.single);
    if (!replacement.isValid) {
      _showInfoSnackBar(context, _galleryImageFailureMessage(replacement.failure));
      return;
    }

    galleryItems[index].replaceImageFrom(replacement.item!);
    replacement.item!.dispose();
    _syncPublishedGalleryData();
    notifyListeners();
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
      EditorGalleryItem(
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

  void removeGalleryPhoto(int index) {
    if (index < 0 || index >= galleryItems.length) return;

    final removedItem = galleryItems.removeAt(index);
    removedItem.dispose();
    _normalizeGallerySelection();
    _syncPublishedGalleryData();
    notifyListeners();
  }

  void makeGalleryCover(int index) {
    if (index <= 0 || index >= galleryItems.length) return;

    final item = galleryItems.removeAt(index);
    galleryItems.insert(0, item);
    selectedGalleryIndex = 0;
    _syncPublishedGalleryData();
    notifyListeners();
  }

  void selectGalleryItem(int index) {
    if (index < 0 || index >= galleryItems.length) return;
    selectedGalleryIndex = index;
    notifyListeners();
  }

  void _normalizeGallerySelection() {
    if (galleryItems.isEmpty) {
      selectedGalleryIndex = 0;
      return;
    }

    if (selectedGalleryIndex >= galleryItems.length) {
      selectedGalleryIndex = galleryItems.length - 1;
    }
  }

  String _galleryImageFailureMessage(GalleryImageValidationFailure? failure) {
    if (failure == GalleryImageValidationFailure.unreadable) {
      return 'Fotoğraf tarayıcı tarafından okunamadı. Lütfen galeriden tekrar seçin.';
    }
    return 'Seçilen fotoğraflar eklenemedi. JPG, PNG veya WEBP ve en fazla ${_maxGalleryPhotoBytes ~/ (1024 * 1024)} MB olmalı.';
  }

  void _showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _buildFullPublicLink(String path) {
    return PublicSiteConfig.buildPublicLink(path);
  }

  void showPremiumVisibilityInfo(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SEO anahtar kelime ve blog fikirleri premium özellik olarak hazırlanıyor.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Points & Profile checklist targets
  bool hasCompleteMarketplaceLink() {
    return data.marketplaceLinks.any((link) => link.platform.trim().isNotEmpty && link.url.trim().isNotEmpty);
  }

  bool hasSupportingVitrinContent() {
    final hasLogo = (data.logoUrl?.trim().isNotEmpty ?? false) || logoBytes != null;
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

  List<StoreScoreTask> scoreTasks() {
    final descriptionLength = data.description.trim().length;
    return [
      StoreScoreTask(
        points: 20,
        isComplete: data.name.trim().isNotEmpty,
        suggestion: 'Mağaza adını ekle',
        target: StoreScoreTarget.storeName,
      ),
      StoreScoreTask(
        points: 15,
        isComplete: data.whatsapp.trim().isNotEmpty,
        suggestion: 'WhatsApp numarası ekle',
        target: StoreScoreTarget.whatsapp,
      ),
      StoreScoreTask(
        points: 15,
        isComplete: descriptionLength >= 10,
        suggestion: descriptionLength == 0
            ? 'Kısa açıklama yaz'
            : 'Kısa açıklamayı güçlendir $descriptionLength/10',
        target: StoreScoreTarget.description,
      ),
      StoreScoreTask(
        points: 10,
        isComplete: data.instagram.trim().isNotEmpty || data.website.trim().isNotEmpty,
        suggestion: 'Instagram veya web sitesi ekle',
        target: StoreScoreTarget.social,
      ),
      StoreScoreTask(
        points: 10,
        isComplete: data.address.trim().isNotEmpty,
        suggestion: 'Adres bilgisini ekle',
        target: StoreScoreTarget.address,
      ),
      StoreScoreTask(
        points: 15,
        isComplete: hasCompleteMarketplaceLink(),
        suggestion: 'En az 1 pazaryeri linki ekle',
        target: StoreScoreTarget.marketplace,
      ),
      StoreScoreTask(
        points: 15,
        isComplete: hasSupportingVitrinContent(),
        suggestion: 'Logo, ürün veya hakkımızda bilgisi ekle',
        target: StoreScoreTarget.about,
      ),
    ];
  }

  List<StoreScoreTask> scoreActionTasks() {
    final tasks = scoreTasks().where((task) => !task.isComplete).toList();
    final hasGalleryPhoto = galleryItems.isNotEmpty || data.displayGalleryItems.isNotEmpty;
    if (!hasGalleryPhoto) {
      tasks.add(
        const StoreScoreTask(
          points: 0,
          isComplete: false,
          suggestion: 'Galeri fotoğrafı ekle',
          target: StoreScoreTarget.gallery,
        ),
      );
    }
    return tasks;
  }

  int calculateScore() {
    var sum = 0;
    for (final task in scoreTasks()) {
      if (task.isComplete) sum += task.points;
    }
    return sum.clamp(0, 100);
  }

  bool isScoreTargetComplete(StoreScoreTarget target) {
    if (target == StoreScoreTarget.gallery) {
      return galleryItems.isNotEmpty || data.displayGalleryItems.isNotEmpty;
    }
    for (final task in scoreTasks()) {
      if (task.target == target) return task.isComplete;
    }
    return false;
  }

  List<StorePublishChecklistItem> publishChecklist() {
    return [
      StorePublishChecklistItem(
        isReady: data.name.trim().isNotEmpty,
        readyText: 'Mağaza adı girildi.',
        missingText: 'Mağaza adı eksik.',
      ),
      StorePublishChecklistItem(
        isReady: data.whatsapp.trim().isNotEmpty,
        readyText: 'WhatsApp numarası girildi.',
        missingText: 'WhatsApp numarası eksik.',
      ),
      StorePublishChecklistItem(
        isReady: data.description.trim().isNotEmpty,
        readyText: 'Mağaza açıklaması girildi.',
        missingText: 'Mağaza açıklaması eksik.',
      ),
      StorePublishChecklistItem(
        isReady: addressCtrl.text.trim().isNotEmpty,
        readyText: 'Açık adres girildi.',
        missingText: 'Açık adres eksik.',
      ),
      StorePublishChecklistItem(
        isReady: data.kategori.trim().isNotEmpty,
        readyText: 'İşletme kategorisi seçildi.',
        missingText: 'İşletme kategorisi seçilmedi.',
      ),
    ];
  }

  void addProduct(Product product, BuildContext context) {
    data.products.add(product);
    notifyListeners();
    unawaited(saveData(context));
  }

  void updateProduct(int index, Product product, BuildContext context) {
    if (index >= 0 && index < data.products.length) {
      data.products[index] = product;
      notifyListeners();
      unawaited(saveData(context));
    }
  }

  void removeProduct(int index, BuildContext context) {
    if (index >= 0 && index < data.products.length) {
      data.products.removeAt(index);
      notifyListeners();
      unawaited(saveData(context));
    }
  }

  void setKvkkConsent(bool value) {
    kvkkConsent = value;
    notifyListeners();
  }

  void setLogoBytes(Uint8List bytes, String extension, String contentType) {
    logoBytes = bytes;
    logoExtension = extension;
    logoContentType = contentType;
    notifyListeners();
  }

  void removeLogo() {
    data.logoUrl = null;
    logoBytes = null;
    logoExtension = null;
    logoContentType = null;
    notifyListeners();
  }

  void triggerHighlightScoreTarget(StoreScoreTarget target) {
    highlightedScoreTarget = target;
    scoreTargetHighlightToken += 1;
    notifyListeners();
  }

  void clearHighlightScoreTarget() {
    highlightedScoreTarget = null;
    notifyListeners();
  }

  @override
  void dispose() {
    viewCountDebounce?.cancel();
    addressCtrl.dispose();
    for (final item in galleryItems) {
      item.dispose();
    }
    super.dispose();
  }
}

class _GalleryFilePickResult {
  const _GalleryFilePickResult._({this.item, this.failure});

  const _GalleryFilePickResult.success(EditorGalleryItem item) : this._(item: item);

  const _GalleryFilePickResult.failure(GalleryImageValidationFailure? failure) : this._(failure: failure);

  final EditorGalleryItem? item;
  final GalleryImageValidationFailure? failure;

  bool get isValid => item != null;
}
