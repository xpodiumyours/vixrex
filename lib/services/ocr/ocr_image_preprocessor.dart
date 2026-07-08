import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// OCR için görsel ön işleme servisi.
class OcrImagePreprocessor {
  const OcrImagePreprocessor();

  /// Görüntüyü OCR için optimize eder.
  Future<Uint8List> preprocess(Uint8List imageBytes) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    // 1. Gri tonlamaya çevir (gürültüyü azaltır)
    final grayscale = img.grayscale(image);

    // 2. Kontrastı artır (metinleri netleştirir)
    final contrasted = img.adjustColor(grayscale, contrast: 1.8);

    // 3. Keskinlik ekle (OCR doğruluğunu artırır)
    final sharpened = img.convolution(
      contrasted,
      filter: [
         0, -1,  0,
        -1,  5, -1,
         0, -1,  0,
      ],
    );

    // 4. Hafif blur (pürüzleri yumuşatır)
    final blurred = img.gaussianBlur(sharpened, radius: 1);

    return Uint8List.fromList(img.encodeJpg(blurred));
  }

  /// Fiyat etiketleri için renk filtresi uygular.
  Uint8List filterPriceTagColors(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    final result = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        // Sarı etiket algılama (r > 180, g > 180, b < 100)
        final isYellow = r > 180 && g > 180 && b < 100;
        // Kırmızı etiket algılama (r > 180, g < 100, b < 100)
        final isRed = r > 180 && g < 100 && b < 100;

        if (isYellow || isRed) {
          result.setPixel(x, y, img.ColorRgb8(255, 255, 255));
        } else {
          final gray = (r * 0.299 + g * 0.587 + b * 0.114).toInt();
          final darkened = (gray * 0.5).clamp(0, 255).toInt();
          result.setPixel(x, y, img.ColorRgb8(darkened, darkened, darkened));
        }
      }
    }

    return Uint8List.fromList(img.encodeJpg(result));
  }
}
