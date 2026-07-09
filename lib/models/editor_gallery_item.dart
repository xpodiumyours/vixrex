import 'dart:typed_data';
import 'package:vixrex/models/store_data.dart';

/// Editör içinde kullanılan galeri öğesi modeli.
/// Hem yerel (yeni eklenen) hem de sunucudaki görselleri yönetir.
class EditorGalleryItem {
  final String id;
  final String? imageUrl;
  final Uint8List? bytes;
  final String? extension;
  final String? contentType;
  final String? title;
  final String? description;
  final bool isRemoved;

  const EditorGalleryItem({
    required this.id,
    this.imageUrl,
    this.bytes,
    this.extension,
    this.contentType,
    this.title,
    this.description,
    this.isRemoved = false,
  });

  bool get isFromUrl => imageUrl != null && imageUrl!.isNotEmpty;
  bool get isFromBytes => bytes != null;

  factory EditorGalleryItem.fromStoreItem(StoreGalleryItem item) {
    return EditorGalleryItem(
      id: item.id,
      imageUrl: item.imageUrl,
      title: item.title,
      description: item.description,
    );
  }

  factory EditorGalleryItem.fromUrl(String url, {String? id}) {
    return EditorGalleryItem(
      id: id ?? 'url_${DateTime.now().millisecondsSinceEpoch}',
      imageUrl: url,
    );
  }

  factory EditorGalleryItem.fromBytes(
    Uint8List bytes, {
    String? id,
    String? extension,
    String? contentType,
  }) {
    return EditorGalleryItem(
      id: id ?? 'bytes_${DateTime.now().millisecondsSinceEpoch}',
      bytes: bytes,
      extension: extension,
      contentType: contentType,
    );
  }

  EditorGalleryItem markRemoved() {
    return EditorGalleryItem(
      id: id,
      imageUrl: imageUrl,
      bytes: bytes,
      extension: extension,
      contentType: contentType,
      title: title,
      description: description,
      isRemoved: true,
    );
  }

  EditorGalleryItem copyWith({
    String? title,
    String? description,
    bool? isRemoved,
  }) {
    return EditorGalleryItem(
      id: id,
      imageUrl: imageUrl,
      bytes: bytes,
      extension: extension,
      contentType: contentType,
      title: title ?? this.title,
      description: description ?? this.description,
      isRemoved: isRemoved ?? this.isRemoved,
    );
  }
}
