import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:vixrex/config/app_constants.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/models/editor_gallery_item.dart';
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
  bool get hasCover => _coverBytes != null || (_coverUrl != null && _coverUrl!.isNotEmpty);

  List<EditorGalleryItem> get editorGalleryItems => _editorGalleryItems;
  List<EditorGalleryItem> get galleryItems => _editorGalleryItems;
  int get maxGalleryPhotos => _maxGalleryPhotos;

  List<EditorGalleryItem> get activeGalleryItems =>
      _editorGalleryItems.where((item) => !item.isRemoved).toList();

  // --- Methods ---
  void setCoverBytes(Uint8List bytes, String fileName, [String? ext, String? contentType]) {
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

  /// Görselleri (Kapak ve Galeri) Supabase Storage'a yükler.
  Future<void> uploadMedia({
    required StoreData storeData,
    required StoreShelfUploadService uploadService,
    required StorePublishService publishService,
  }) async {
    final hasPendingCover = _coverBytes != null && _coverFileName != null;
    final hasPendingGallery = _editorGalleryItems.any((item) => !item.isRemoved && item.isFromBytes && item.bytes != null);

    if (!hasPendingCover && !hasPendingGallery) {
      storeData.galleryItems = _editorGalleryItems.where((item) => !item.isRemoved).map((item) {
        return StoreGalleryItem(
          id: item.id,
          imageUrl: item.imageUrl ?? '',
          title: item.title ?? '',
        );
      }).toList();
      return;
    }

    final storeSlug = storeData.slug.isNotEmpty
        ? storeData.slug
        : publishService.payloadBuilder.generateSlug(storeData.name);

    // 1. Kapak Yükleme
    if (hasPendingCover) {
      final ext = (_coverFileName!.split('.').lastOrNull ?? 'jpg').toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      final url = await uploadService.uploadShelfImage(_coverBytes!, storeSlug, fileExtension: ext, contentType: mime);
      storeData.shelfImageUrl = url;
      storeData.coverImageUrl = url;
      _coverUrl = url;
      _coverBytes = null;
    }

    // 2. Galeri Yükleme
    final updatedGallery = <StoreGalleryItem>[];
    for (var i = 0; i < _editorGalleryItems.length; i++) {
      final item = _editorGalleryItems[i];
      if (item.isRemoved) continue;

      if (item.isFromBytes && item.bytes != null) {
        final ext = (item.extension ?? 'jpg').toLowerCase();
        final url = await uploadService.uploadGalleryImage(item.bytes!, storeSlug, fileExtension: ext);
        updatedGallery.add(StoreGalleryItem(
          id: item.id,
          imageUrl: url,
          title: item.title ?? 'Galeri ${i + 1}',
        ));
      } else if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
        updatedGallery.add(StoreGalleryItem(
          id: item.id,
          imageUrl: item.imageUrl!,
          title: item.title ?? 'Galeri ${i + 1}',
        ));
      }
    }
    storeData.galleryItems = updatedGallery;
    _editorGalleryItems = updatedGallery.map((i) => EditorGalleryItem.fromStoreItem(i)).toList();
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
