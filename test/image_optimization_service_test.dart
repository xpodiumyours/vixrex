import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/image_optimization_service.dart';

void main() {
  const service = ImageOptimizationService();

  group('ImageOptimizationService.targetSizeForDimensions', () {
    test('küçük görselin ölçülerini korur', () {
      final target = service.targetSizeForDimensions(1200, 800);

      expect(target.width, 1200);
      expect(target.height, 800);
    });

    test('yatay görselin uzun kenarını 1600 piksele indirir', () {
      final target = service.targetSizeForDimensions(4000, 2000);

      expect(target.width, 1600);
      expect(target.height, 800);
    });

    test('dikey görselin uzun kenarını 1600 piksele indirir', () {
      final target = service.targetSizeForDimensions(1500, 3000);

      expect(target.width, 800);
      expect(target.height, 1600);
    });

    test('geçersiz ölçüde açıklayıcı hata verir', () {
      expect(
        () => service.targetSizeForDimensions(0, 100),
        throwsA(isA<ImageOptimizationException>()),
      );
    });
  });

  group('ImageOptimizationService içerik doğrulaması', () {
    test('rastgele byte WebP beyanıyla geçemez', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);

      await expectLater(
        service.optimize(
          bytes,
          fileExtension: 'webp',
          contentType: 'image/webp',
        ),
        throwsA(isA<ImageOptimizationException>()),
      );
    });

    test(
      'yalnız RIFF/WEBP başlığı taklit edilmiş bozuk payload geçemez',
      () async {
        final bytes = Uint8List.fromList([
          0x52,
          0x49,
          0x46,
          0x46,
          0x00,
          0x00,
          0x00,
          0x00,
          0x57,
          0x45,
          0x42,
          0x50,
          0x00,
          0x00,
          0x00,
          0x00,
        ]);

        await expectLater(
          service.optimize(
            bytes,
            fileExtension: 'webp',
            contentType: 'image/webp',
          ),
          throwsA(isA<ImageOptimizationException>()),
        );
      },
    );

    test('JPEG içeriği WebP diye beyan edilirse reddedilir', () async {
      final jpegLike = Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10]);

      await expectLater(
        service.optimize(
          jpegLike,
          fileExtension: 'webp',
          contentType: 'image/webp',
        ),
        throwsA(isA<ImageOptimizationException>()),
      );
    });

    test('uzantı ile MIME birbiriyle çelişirse reddedilir', () async {
      final realWebp = Uint8List.fromList(
        base64Decode('UklGRhwAAABXRUJQVlA4TA8AAAAvAAAAAAcQ/Y/+ByKi/wEA'),
      );

      await expectLater(
        service.optimize(
          realWebp,
          fileExtension: 'webp',
          contentType: 'image/png',
        ),
        throwsA(isA<ImageOptimizationException>()),
      );
    });

    test('gerçek decode edilebilir WebP güvenli pass-through olur', () async {
      // Pillow ile üretilmiş 1x1 lossless WebP fixture.
      final realWebp = Uint8List.fromList(
        base64Decode('UklGRhwAAABXRUJQVlA4TA8AAAAvAAAAAAcQ/Y/+ByKi/wEA'),
      );

      final result = await service.optimize(
        realWebp,
        fileExtension: 'webp',
        contentType: 'image/webp',
      );

      expect(result.bytes, realWebp);
      expect(result.extension, 'webp');
      expect(result.contentType, 'image/webp');
    });
  });
}
