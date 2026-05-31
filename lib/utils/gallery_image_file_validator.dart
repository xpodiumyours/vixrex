import 'dart:typed_data';

class GalleryImageFileInfo {
  const GalleryImageFileInfo({
    required this.extension,
    required this.contentType,
  });

  final String extension;
  final String contentType;
}

class GalleryImageValidationResult {
  const GalleryImageValidationResult._({this.fileInfo, this.failure});

  const GalleryImageValidationResult.valid(GalleryImageFileInfo fileInfo)
    : this._(fileInfo: fileInfo);

  const GalleryImageValidationResult.invalid(
    GalleryImageValidationFailure failure,
  ) : this._(failure: failure);

  final GalleryImageFileInfo? fileInfo;
  final GalleryImageValidationFailure? failure;

  bool get isValid => fileInfo != null;
}

enum GalleryImageValidationFailure { tooLarge, unreadable, unsupportedType }

class GalleryImageFileValidator {
  const GalleryImageFileValidator._();

  static const int maxMegabytes = 15;
  static const int maxBytes = maxMegabytes * 1024 * 1024;

  static GalleryImageValidationResult validate({
    required Uint8List? bytes,
    required int reportedSize,
  }) {
    final effectiveSize = _effectiveSize(bytes, reportedSize);
    if (effectiveSize > maxBytes) {
      return const GalleryImageValidationResult.invalid(
        GalleryImageValidationFailure.tooLarge,
      );
    }

    if (bytes == null || bytes.isEmpty) {
      return const GalleryImageValidationResult.invalid(
        GalleryImageValidationFailure.unreadable,
      );
    }

    final fileInfo = _detectFileInfo(bytes);
    if (fileInfo == null) {
      return const GalleryImageValidationResult.invalid(
        GalleryImageValidationFailure.unsupportedType,
      );
    }

    return GalleryImageValidationResult.valid(fileInfo);
  }

  static int _effectiveSize(Uint8List? bytes, int reportedSize) {
    final byteLength = bytes?.length ?? 0;
    if (reportedSize <= 0) return byteLength;
    return reportedSize > byteLength ? reportedSize : byteLength;
  }

  static GalleryImageFileInfo? _detectFileInfo(Uint8List bytes) {
    if (_isJpeg(bytes)) {
      return const GalleryImageFileInfo(
        extension: 'jpg',
        contentType: 'image/jpeg',
      );
    }

    if (_isPng(bytes)) {
      return const GalleryImageFileInfo(
        extension: 'png',
        contentType: 'image/png',
      );
    }

    if (_isWebp(bytes)) {
      return const GalleryImageFileInfo(
        extension: 'webp',
        contentType: 'image/webp',
      );
    }

    return null;
  }

  static bool _isJpeg(Uint8List bytes) {
    return bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8;
  }

  static bool _isPng(Uint8List bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
  }

  static bool _isWebp(Uint8List bytes) {
    return bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50;
  }
}
