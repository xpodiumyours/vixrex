import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/image_optimization_service.dart';

void main() {
  const service = ImageOptimizationService();

  group('ImageOptimizationService content signature security', () {
    test('WebP diye beyan edilen rastgele bytes reddedilir', () async {
      final bytes = Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6, 7, 8]);

      await expectLater(
        service.optimize(
          bytes,
          fileExtension: 'webp',
          contentType: 'image/webp',
        ),
        throwsA(
          isA<ImageOptimizationException>().having(
            (error) => error.message,
            'message',
            contains('formatı doğrulanamadı'),
          ),
        ),
      );
    });

    test('JPEG içeriği WebP diye beyan edilirse mismatch reddedilir', () async {
      // Decode aşamasına ulaşması gerekmiyor; gerçek format magic-byte ile
      // JPEG olarak tanınır ve caller beyanıyla uyuşmadığı için reddedilir.
      final bytes = Uint8List.fromList(<int>[
        0xff,
        0xd8,
        0xff,
        0x00,
        0x01,
        0x02,
      ]);

      await expectLater(
        service.optimize(
          bytes,
          fileExtension: 'webp',
          contentType: 'image/webp',
        ),
        throwsA(
          isA<ImageOptimizationException>().having(
            (error) => error.message,
            'message',
            contains('dosya içeriğiyle uyuşmuyor'),
          ),
        ),
      );
    });

    test('uzantı ile MIME kendi arasında çelişirse reddedilir', () async {
      // Gerçek PNG signature. Caller uzantıyı PNG, MIME'ı JPEG ilan ediyor.
      final bytes = Uint8List.fromList(<int>[
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
        0x00,
      ]);

      await expectLater(
        service.optimize(
          bytes,
          fileExtension: 'png',
          contentType: 'image/jpeg',
        ),
        throwsA(
          isA<ImageOptimizationException>().having(
            (error) => error.message,
            'message',
            contains('uzantısı ile içerik türü uyuşmuyor'),
          ),
        ),
      );
    });

    test(
      'yalnız RIFF WEBP başlığı taklit edilmiş bozuk payload reddedilir',
      () async {
        // Magic-byte kontrolünü geçer; gerçek codec decode kontrolünde düşmelidir.
        final bytes = Uint8List.fromList(<int>[
          0x52,
          0x49,
          0x46,
          0x46, // RIFF
          0x04,
          0x00,
          0x00,
          0x00, // sahte size
          0x57,
          0x45,
          0x42,
          0x50, // WEBP
        ]);

        await expectLater(
          service.optimize(
            bytes,
            fileExtension: 'webp',
            contentType: 'image/webp',
          ),
          throwsA(
            isA<ImageOptimizationException>().having(
              (error) => error.message,
              'message',
              contains('WebP fotoğraf doğrulanamadı'),
            ),
          ),
        );
      },
    );
  });
}
