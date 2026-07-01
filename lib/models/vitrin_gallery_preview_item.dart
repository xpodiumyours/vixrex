import 'dart:typed_data';
import 'package:vitrinx/models/store_data.dart';

class VitrinGalleryPreviewItem {
  final String imageUrl;
  final Uint8List? imageBytes;
  final String title;
  final String description;

  const VitrinGalleryPreviewItem({
    this.imageUrl = '',
    this.imageBytes,
    this.title = '',
    this.description = '',
  });

  factory VitrinGalleryPreviewItem.fromStoreItem(StoreGalleryItem item) {
    return VitrinGalleryPreviewItem(
      imageUrl: item.imageUrl,
      title: item.title,
      description: item.description,
    );
  }

  bool get hasImage => imageBytes != null || imageUrl.trim().isNotEmpty;
}
