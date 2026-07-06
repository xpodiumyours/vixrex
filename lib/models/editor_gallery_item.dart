import 'dart:typed_data';
import 'package:vixrex/models/store_data.dart';

class EditorGalleryItem {
  final String id;
  final Uint8List? bytes;
  final String? imageUrl;
  final String? extension;
  final String? contentType;
  final int? originalWidth;
  final int? originalHeight;
  final bool isRemoved;

  const EditorGalleryItem._({
    required this.id,
    this.bytes,
    this.imageUrl,
    this.extension,
    this.contentType,
    this.originalWidth,
    this.originalHeight,
    this.isRemoved = false,
  });

  factory EditorGalleryItem.fromBytes({
    required String id,
    required Uint8List bytes,
    required String extension,
    required String contentType,
    int? originalWidth,
    int? originalHeight,
  }) {
    return EditorGalleryItem._(
      id: id,
      bytes: bytes,
      extension: extension,
      contentType: contentType,
      originalWidth: originalWidth,
      originalHeight: originalHeight,
    );
  }

  factory EditorGalleryItem.fromUrl(String url, {String? id}) {
    return EditorGalleryItem._(
      id: id ?? url,
      imageUrl: url,
    );
  }

  factory EditorGalleryItem.fromStoreItem(StoreGalleryItem item) {
    return EditorGalleryItem._(
      id: item.id,
      imageUrl: item.imageUrl,
    );
  }

  EditorGalleryItem markRemoved() {
    return EditorGalleryItem._(
      id: id,
      bytes: bytes,
      imageUrl: imageUrl,
      extension: extension,
      contentType: contentType,
      originalWidth: originalWidth,
      originalHeight: originalHeight,
      isRemoved: true,
    );
  }

  bool get isFromUrl => imageUrl != null && imageUrl!.isNotEmpty;
  bool get isFromBytes => bytes != null;
  bool get isEmpty => !isFromUrl && !isFromBytes;
}
