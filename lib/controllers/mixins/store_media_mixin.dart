import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:vixrex/config/app_constants.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/models/editor_gallery_item.dart';
import 'package:vixrex/services/store_media_upload_service.dart';
import 'package:vixrex/services/store_shelf_upload_service.dart';
import 'package:vixrex/services/store_publish_service.dart';

/// Görsel ve Galeri işlemlerini yöneten Mixin.
/// Web ve Mobil uyumluluğu için Uint8List (bytes) kullanımını standartlaştırır.
mixin StoreMediaMixin on ChangeNotifier {
  // --- States ---
  Uint8List? _coverBytes;
  String? _coverFileName;
  String? _coverUrl;
  List<EditorGalleryItem> _editorGalleryItems = [];
  final int _maxGalleryPhotos = AppConstants.maxGalleryPhotos;

  // --- Getters ---
  Uint8List? get coverBytes => _coverBytes;
  String? get coverFileName => _coverFileName;
  String? get coverUrl => _coverUrl;
  bool get hasCover =>
      _coverBytes != null || (_coverUrl != null && _coverUrl!.isNotEmpty);

  List<EditorGalleryItem> get editorGalleryItems => _editorGalleryItems;
  List<EditorGalleryItem> get galleryItems => _editorGalleryItems;
  int get maxGalleryPhotos => _maxGalleryPhotos;

  List<EditorGalleryItem> get activeGalleryItems =>
      _editorGalleryItems.where((item) => !item.isRemoved).toList();

  // --- Methods ---
  void setCoverBytes(
    Uint8List bytes,
    String fileName, [
    String? ext,
    String? contentType,
  ]) {
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

  void updateGalleryItemTitle(int index, String title) {
    if (index < 0 || index >= _editorGalleryItems.length) return;
    final item = _editorGalleryItems[index];
    if (item.isRemoved) return;
    _editorGalleryItems[index] = item.copyWith(title: title.trim());
    notifyListeners();
  }

  /// Görselleri (Kapak ve Galeri) Supabase Storage'a yükler.
  ///
  /// Gerçek yükleme işi `StoreMediaUploadService`'te (Faz 4, controller
  /// parçalama, birebir taşındı); burada yalnız "bekleyen bir şey var mı"
  /// kısayolu, hazır şablon/uzak URL kapak durumu ve sonucun mixin/
  /// `storeData` state'ine uygulanması kalıyor.
  Future<void> uploadMedia({
    required StoreData storeData,
    required StoreShelfUploadService uploadService,
    required StorePublishService publishService,
    StoreMediaUploadService mediaUploadService =
        const StoreMediaUploadService(),
  }) async {
    final hasPendingCover = _coverBytes != null && _coverFileName != null;
    final hasPendingGallery = _editorGalleryItems.any(
      (item) => !item.isRemoved && item.isFromBytes && item.bytes != null,
    );

    // Hazır şablon / uzak URL kapak: byte yüklemesi yoksa StoreData'ya yaz
    if (!hasPendingCover) {
      final remoteCover = (_coverUrl ?? '').trim();
      if (remoteCover.isNotEmpty) {
        storeData.shelfImageUrl = remoteCover;
      }
    }

    if (!hasPendingCover && !hasPendingGallery) {
      storeData.galleryItems =
          _editorGalleryItems.where((item) => !item.isRemoved).map((item) {
            return StoreGalleryItem(
              id: item.id,
              imageUrl: item.imageUrl ?? '',
              title: item.title ?? '',
            );
          }).toList();
      return;
    }

    final storeSlug =
        storeData.slug.isNotEmpty
            ? storeData.slug
            : publishService.payloadBuilder.generateSlug(storeData.name);

    final sonuc = await mediaUploadService.yukle(
      storeSlug: storeSlug,
      coverBytes: hasPendingCover ? _coverBytes : null,
      coverFileName: hasPendingCover ? _coverFileName : null,
      editorGalleryItems: _editorGalleryItems,
      uploadService: uploadService,
    );

    if (sonuc.shelfImageUrl != null) {
      storeData.shelfImageUrl = sonuc.shelfImageUrl!;
      storeData.coverImageUrl = sonuc.shelfImageUrl!;
      _coverUrl = sonuc.shelfImageUrl;
      _coverBytes = null;
    }

    storeData.galleryItems = sonuc.galleryItems;
    _editorGalleryItems = sonuc.editorGalleryItems;
    notifyListeners();
  }

  /// Mixin state'ini temizler (yeni dükkan oluştururken kullanılır).
  void resetMedia() {
    _coverBytes = null;
    _coverFileName = null;
    _coverUrl = null;
    _editorGalleryItems = [];
    notifyListeners();
  }
}
