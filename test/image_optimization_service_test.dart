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

  test('WebP görselini yeniden kodlamadan korur', () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);

    final result = await service.optimize(
      bytes,
      fileExtension: 'webp',
      contentType: 'image/webp',
    );

    expect(result.bytes, bytes);
    expect(result.extension, 'webp');
    expect(result.contentType, 'image/webp');
  });
}
