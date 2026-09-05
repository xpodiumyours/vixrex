import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';

class OptimizedImage {
  const OptimizedImage({
    required this.bytes,
    required this.extension,
    required this.contentType,
  });

  final Uint8List bytes;
  final String extension;
  final String contentType;
}

class ImageTargetSize {
  const ImageTargetSize({required this.width, required this.height});

  final int width;
  final int height;
}

class ImageOptimizationException implements Exception {
  const ImageOptimizationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ImageOptimizationService {
  const ImageOptimizationService();

  static const int maxLongEdge = 1600;
  static const int fallbackLongEdge = 1200;
  static const int maxPreferredBytes = 1 * 1024 * 1024;

  Future<OptimizedImage> optimize(
    Uint8List bytes, {
    required String fileExtension,
    required String contentType,
  }) async {
    if (bytes.isEmpty) {
      throw const ImageOptimizationException(
        'Fotoğraf okunamadı. Lütfen farklı bir dosya seçin.',
      );
    }

    // Dosya uzantısı / MIME caller beyanıdır; güvenlik sınırı değildir.
    // Gerçek format magic-byte üzerinden belirlenir. Beyan edilen tanınmış
    // format gerçek içerikle uyuşmuyorsa dosya reddedilir.
    final actualType = _detectSourceType(bytes);
    if (actualType == null) {
      throw const ImageOptimizationException(
        'Fotoğraf formatı doğrulanamadı. JPG, PNG veya WebP kullanın.',
      );
    }

    final declaredType = _declaredSourceType(fileExtension, contentType);
    if (declaredType != null && declaredType != actualType) {
      throw const ImageOptimizationException(
        'Fotoğraf formatı dosya içeriğiyle uyuşmuyor.',
      );
    }

    if (actualType == _ImageSourceType.webp) {
      // Eski yol WebP için yalnız uzantı/MIME'a güvenip ham bytes döndürüyordu.
      // En azından gerçek codec ile decode + ölçü okuma zorunlu: yalnız RIFF/
      // WEBP başlığı taklit edilmiş bozuk payload Storage'a gitmez.
      try {
        await _readDimensions(bytes);
      } catch (_) {
        throw const ImageOptimizationException(
          'WebP fotoğraf doğrulanamadı. Farklı bir dosya seçin.',
        );
      }
      return OptimizedImage(
        bytes: bytes,
        extension: 'webp',
        contentType: 'image/webp',
      );
    }

    try {
      final dimensions = await _readDimensions(bytes);
      final target = targetSizeForDimensions(
        dimensions.width,
        dimensions.height,
      );
      final format =
          actualType == _ImageSourceType.png
              ? CompressFormat.png
              : CompressFormat.jpeg;

      var optimized = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: target.width,
        minHeight: target.height,
        quality: 82,
        format: format,
        keepExif: false,
      );

      if (optimized.isEmpty) {
        throw const ImageOptimizationException(
          'Fotoğraf optimize edilemedi. Lütfen farklı bir dosya seçin.',
        );
      }

      if (optimized.length > maxPreferredBytes) {
        final retryTarget =
            actualType == _ImageSourceType.png
                ? targetSizeForDimensions(
                  dimensions.width,
                  dimensions.height,
                  maxEdge: fallbackLongEdge,
                )
                : target;
        optimized = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: retryTarget.width,
          minHeight: retryTarget.height,
          quality: 65,
          format: format,
          keepExif: false,
        );
      }

      if (optimized.isEmpty) {
        throw const ImageOptimizationException(
          'Fotoğraf optimize edilemedi. Lütfen farklı bir dosya seçin.',
        );
      }

      return OptimizedImage(
        bytes: optimized,
        extension: actualType == _ImageSourceType.png ? 'png' : 'jpg',
        contentType:
            actualType == _ImageSourceType.png ? 'image/png' : 'image/jpeg',
      );
    } on ImageOptimizationException {
      rethrow;
    } catch (_) {
      throw const ImageOptimizationException(
        'Fotoğraf işlenemedi. JPG, PNG veya WebP formatında tekrar deneyin.',
      );
    }
  }

  ImageTargetSize targetSizeForDimensions(
    int width,
    int height, {
    int maxEdge = maxLongEdge,
  }) {
    if (width <= 0 || height <= 0) {
      throw const ImageOptimizationException('Fotoğraf ölçüleri okunamadı.');
    }
    if (width <= maxEdge && height <= maxEdge) {
      return ImageTargetSize(width: width, height: height);
    }

    final scale = maxEdge / (width > height ? width : height);
    return ImageTargetSize(
      width: (width * scale).round().clamp(1, maxEdge),
      height: (height * scale).round().clamp(1, maxEdge),
    );
  }

  Future<ImageTargetSize> _readDimensions(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      try {
        return ImageTargetSize(
          width: frame.image.width,
          height: frame.image.height,
        );
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  _ImageSourceType? _detectSourceType(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return _ImageSourceType.jpeg;
    }

    const pngSignature = <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
    if (bytes.length >= pngSignature.length) {
      var png = true;
      for (var i = 0; i < pngSignature.length; i++) {
        if (bytes[i] != pngSignature[i]) {
          png = false;
          break;
        }
      }
      if (png) return _ImageSourceType.png;
    }

    // WebP container: RIFF <size:4 bytes> WEBP
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return _ImageSourceType.webp;
    }

    return null;
  }

  _ImageSourceType? _declaredSourceType(String extension, String contentType) {
    final normalizedExtension = extension.trim().toLowerCase().replaceAll(
      '.',
      '',
    );
    final normalizedContentType = contentType.trim().toLowerCase();

    final extensionType = switch (normalizedExtension) {
      'jpg' || 'jpeg' => _ImageSourceType.jpeg,
      'png' => _ImageSourceType.png,
      'webp' => _ImageSourceType.webp,
      _ => null,
    };
    final contentTypeValue = switch (normalizedContentType) {
      'image/jpeg' || 'image/jpg' => _ImageSourceType.jpeg,
      'image/png' => _ImageSourceType.png,
      'image/webp' => _ImageSourceType.webp,
      _ => null,
    };

    if (extensionType != null &&
        contentTypeValue != null &&
        extensionType != contentTypeValue) {
      throw const ImageOptimizationException(
        'Fotoğraf uzantısı ile içerik türü uyuşmuyor.',
      );
    }
    return extensionType ?? contentTypeValue;
  }
}

enum _ImageSourceType { jpeg, png, webp }
