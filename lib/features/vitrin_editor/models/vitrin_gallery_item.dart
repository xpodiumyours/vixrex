import 'dart:typed_data';
import 'package:vitrinx/models/store_data.dart';

/// Local UI model for gallery items in the vitrin editor.
/// Used only by the editor screen; distinct from [EditorGalleryItem] in the
/// controller which also stores per-image title/description text controllers.
class VitrinGalleryItem {
  String id;
  Uint8List? bytes;
  String imageUrl;
  String extension;
  String contentType;

  VitrinGalleryItem({
    required this.id,
    this.bytes,
    required this.imageUrl,
    this.extension = 'jpg',
    this.contentType = 'image/jpeg',
  });

  bool get hasLocalBytes => bytes != null;
  bool get hasUrl => imageUrl.trim().isNotEmpty;

  static VitrinGalleryItem fromStoreItem(StoreGalleryItem item) =>
      VitrinGalleryItem(id: item.id, imageUrl: item.imageUrl);

  StoreGalleryItem toStoreItem() =>
      StoreGalleryItem(id: id, imageUrl: imageUrl);
}
