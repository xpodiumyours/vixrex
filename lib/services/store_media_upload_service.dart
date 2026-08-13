import 'dart:typed_data';

import 'package:vixrex/models/editor_gallery_item.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/store_shelf_upload_service.dart';

/// [StoreMediaUploadService.yukle] sonucu.
class MediaUploadSonucu {
  const MediaUploadSonucu({
    required this.galleryItems,
    required this.editorGalleryItems,
    this.shelfImageUrl,
  });

  /// Kapak byte'tan yüklendiyse dolu; kapak yüklenmediyse `null` — çağıran
  /// bu durumda `storeData.coverImageUrl`'e DOKUNMAMALIDIR (orijinal
  /// davranış: hazır şablon/uzak URL kapak yalnız `shelfImageUrl`'i
  /// günceller, `coverImageUrl`'i değil — yalnız gerçek yükleme ikisini
  /// birden günceller).
  final String? shelfImageUrl;
  final List<StoreGalleryItem> galleryItems;
  final List<EditorGalleryItem> editorGalleryItems;
}

/// `StoreEditorController`'ın (`StoreMediaMixin` üzerinden) kapak ve galeri
/// görsellerini Supabase Storage'a yükleme orkestrasyonunu sahiplenir.
///
/// Yalnız YÜKLENECEK bir şey olduğunda çağrılmalı — "hiçbir şey
/// bekleşmiyor" kısayolu ve hazır şablon/uzak URL kapak durumu çağıranın
/// (mixin'in) sorumluluğunda kalıyor, çünkü ikisi de ağ isteği
/// gerektirmiyor ve mixin'in kendi state'ine (`_coverUrl` vb.) bakıyor.
///
/// Controller-state'e dokunmaz — yalnız [MediaUploadSonucu] döner
/// (`ProductCatalogSyncService` ile aynı desen).
///
/// 2026-08-13: `store_media_mixin.dart`'tan (Faz 4, controller parçalama)
/// birebir taşındı. Davranış kasıtlı olarak değiştirilmedi.
class StoreMediaUploadService {
  const StoreMediaUploadService();

  Future<MediaUploadSonucu> yukle({
    required String storeSlug,
    required Uint8List? coverBytes,
    required String? coverFileName,
    required List<EditorGalleryItem> editorGalleryItems,
    required StoreShelfUploadService uploadService,
  }) async {
    String? shelfImageUrl;
    if (coverBytes != null && coverFileName != null) {
      final ext = (coverFileName.split('.').lastOrNull ?? 'jpg').toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      shelfImageUrl = await uploadService.uploadShelfImage(
        coverBytes,
        storeSlug,
        fileExtension: ext,
        contentType: mime,
      );
    }

    final updatedGallery = <StoreGalleryItem>[];
    for (var i = 0; i < editorGalleryItems.length; i++) {
      final item = editorGalleryItems[i];
      if (item.isRemoved) continue;

      if (item.isFromBytes && item.bytes != null) {
        final ext = (item.extension ?? 'jpg').toLowerCase();
        final url = await uploadService.uploadGalleryImage(
          item.bytes!,
          storeSlug,
          fileExtension: ext,
        );
        updatedGallery.add(
          StoreGalleryItem(
            id: item.id,
            imageUrl: url,
            title: item.title ?? 'Galeri ${i + 1}',
          ),
        );
      } else if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
        updatedGallery.add(
          StoreGalleryItem(
            id: item.id,
            imageUrl: item.imageUrl!,
            title: item.title ?? 'Galeri ${i + 1}',
          ),
        );
      }
    }

    return MediaUploadSonucu(
      shelfImageUrl: shelfImageUrl,
      galleryItems: updatedGallery,
      editorGalleryItems:
          updatedGallery
              .map((i) => EditorGalleryItem.fromStoreItem(i))
              .toList(),
    );
  }
}
