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
  static const int maxPreferredBytes = 2 * 1024 * 1024;

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

    final sourceType = _sourceType(fileExtension, contentType);
    if (sourceType == _ImageSourceType.webp) {
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
          sourceType == _ImageSourceType.png
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
            sourceType == _ImageSourceType.png
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
          quality: 72,
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
        extension: sourceType == _ImageSourceType.png ? 'png' : 'jpg',
        contentType:
            sourceType == _ImageSourceType.png ? 'image/png' : 'image/jpeg',
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

  _ImageSourceType _sourceType(String extension, String contentType) {
    final normalizedExtension = extension.trim().toLowerCase().replaceAll(
      '.',
      '',
    );
    final normalizedContentType = contentType.trim().toLowerCase();

    if (normalizedExtension == 'png' || normalizedContentType == 'image/png') {
      return _ImageSourceType.png;
    }
    if (normalizedExtension == 'webp' ||
        normalizedContentType == 'image/webp') {
      return _ImageSourceType.webp;
    }
    return _ImageSourceType.jpeg;
  }
}

enum _ImageSourceType { jpeg, png, webp }
