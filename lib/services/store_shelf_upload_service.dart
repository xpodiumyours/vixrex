import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class StoreShelfUploadService {
  const StoreShelfUploadService();

  static const String _bucketName = 'shelf-images';

  Future<String> uploadShelfImage(
    Uint8List bytes,
    String slug, {
    String fileExtension = 'jpg',
    String contentType = 'image/jpeg',
  }) async {
    final safeSlug = _safeSlug(slug);
    final safeExtension = _safeExtension(fileExtension);
    final path =
        '$safeSlug/${DateTime.now().millisecondsSinceEpoch}.$safeExtension';

    try {
      final bucket = Supabase.instance.client.storage.from(_bucketName);
      await bucket.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: contentType, upsert: false),
      );
      return bucket.getPublicUrl(path);
    } catch (error) {
      throw Exception('Raf fotoğrafı yüklenemedi: $error');
    }
  }

  String _safeSlug(String slug) {
    final cleaned = slug.trim().replaceAll(RegExp(r'^/+|/+$'), '');
    return cleaned.isEmpty ? 'magazaniz' : cleaned;
  }

  String _safeExtension(String extension) {
    final cleaned = extension.trim().toLowerCase().replaceAll('.', '');
    if (cleaned == 'jpeg') return 'jpg';
    if (cleaned == 'jpg' || cleaned == 'png' || cleaned == 'webp') {
      return cleaned;
    }
    return 'jpg';
  }
}
