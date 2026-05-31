import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/utils/gallery_image_file_validator.dart';

void main() {
  group('GalleryImageFileValidator', () {
    test('JPEG görseli byte imzasından kabul eder', () {
      final result = GalleryImageFileValidator.validate(
        bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]),
        reportedSize: 4,
      );

      expect(result.isValid, isTrue);
      expect(result.fileInfo?.extension, 'jpg');
      expect(result.fileInfo?.contentType, 'image/jpeg');
    });

    test('PNG görseli byte imzasından kabul eder', () {
      final result = GalleryImageFileValidator.validate(
        bytes: Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A]),
        reportedSize: 6,
      );

      expect(result.isValid, isTrue);
      expect(result.fileInfo?.extension, 'png');
      expect(result.fileInfo?.contentType, 'image/png');
    });

    test('WEBP görseli byte imzasından kabul eder', () {
      final result = GalleryImageFileValidator.validate(
        bytes: Uint8List.fromList([
          0x52,
          0x49,
          0x46,
          0x46,
          0x01,
          0x00,
          0x00,
          0x00,
          0x57,
          0x45,
          0x42,
          0x50,
        ]),
        reportedSize: 12,
      );

      expect(result.isValid, isTrue);
      expect(result.fileInfo?.extension, 'webp');
      expect(result.fileInfo?.contentType, 'image/webp');
    });

    test('uzantı bilgisi olmasa da geçerli byte imzasını kabul eder', () {
      final result = GalleryImageFileValidator.validate(
        bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF]),
        reportedSize: 0,
      );

      expect(result.isValid, isTrue);
      expect(result.fileInfo?.extension, 'jpg');
    });

    test('15 MB üstü dosyayı reddeder', () {
      final result = GalleryImageFileValidator.validate(
        bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF]),
        reportedSize: GalleryImageFileValidator.maxBytes + 1,
      );

      expect(result.isValid, isFalse);
      expect(result.failure, GalleryImageValidationFailure.tooLarge);
    });

    test('geçersiz byte tipini reddeder', () {
      final result = GalleryImageFileValidator.validate(
        bytes: Uint8List.fromList([0x00, 0x01, 0x02, 0x03]),
        reportedSize: 4,
      );

      expect(result.isValid, isFalse);
      expect(result.failure, GalleryImageValidationFailure.unsupportedType);
    });

    test('okunamayan dosyayı reddeder', () {
      final result = GalleryImageFileValidator.validate(
        bytes: null,
        reportedSize: 4,
      );

      expect(result.isValid, isFalse);
      expect(result.failure, GalleryImageValidationFailure.unreadable);
    });
  });
}
