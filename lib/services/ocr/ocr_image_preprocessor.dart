import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// OCR için hızlı görsel ön işleme servisi.
class OcrImagePreprocessor {
  const OcrImagePreprocessor();

  /// Maksimum genişlik (piksel).
  static const int _maxWidth = 1600;

  /// OCR için görüntüyü optimize eder.
  Future<Uint8List> preprocess(Uint8List imageBytes) async {
    return compute(_preprocessSync, imageBytes);
  }

  /// Senkron ön işleme (isolate içinde çalışır).
  static Uint8List _preprocessSync(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    // 1. Görseli küçült (hız için)
    img.Image resized = image;
    if (image.width > _maxWidth) {
      final ratio = _maxWidth / image.width;
      final newHeight = (image.height * ratio).round();
      resized = img.copyResize(
        image,
        width: _maxWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );
    }

    // 2. Gri tonlamaya çevir
    final grayscale = img.grayscale(resized);

    // 3. Contrast enhancement (metin netliği için)
    final contrasted = img.adjustColor(grayscale, contrast: 1.3);

    // 4. Hafif sharpening (kenar netliği için)
    final sharpened = img.convolution(
      contrasted,
      filter: [
         0, -1,  0,
        -1,  5, -1,
         0, -1,  0,
      ],
    );

    // JPEG kalitesi 90 (kalite + hız dengesi)
    return Uint8List.fromList(img.encodeJpg(sharpened, quality: 90));
  }

  /// Global threshold: Tek sabit eşik değeri ile siyah/beyaz ayrımı.
  /// Adaptive threshold'dan çok daha hızlı (100x+).
  /// Ortalama parlaklığı hesapla, onu eşik olarak kullan.
  static img.Image _globalThreshold(img.Image grayscale) {
    final width = grayscale.width;
    final height = grayscale.height;
    final result = img.Image(width: width, height: height);

    // Ortalama parlaklığı hesapla (örneklem ile — hızlı)
    double totalBrightness = 0;
    int sampleCount = 0;
    final step = max(1, (width * height) ~/ 10000); // 10000 piksel örnekle

    for (int y = 0; y < height; y += step) {
      for (int x = 0; x < width; x += step) {
        totalBrightness += grayscale.getPixel(x, y).r.toDouble();
        sampleCount++;
      }
    }
    final meanBrightness = totalBrightness / sampleCount;

    // Eşik: Ortalamanın %60'ı (karanlık metinler için ideal)
    final threshold = meanBrightness * 0.6;

    // Tüm pikselleri ayrıştır
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = grayscale.getPixel(x, y).r.toDouble();
        if (pixel < threshold) {
          result.setPixel(x, y, img.ColorRgb8(0, 0, 0));       // Siyah (metin)
        } else {
          result.setPixel(x, y, img.ColorRgb8(255, 255, 255)); // Beyaz (arka plan)
        }
      }
    }

    return result;
  }

  /// 3x3 Median filtre: Gürültü temizleme (çok hızlı).
  static img.Image _medianFilter(img.Image binary) {
    final width = binary.width;
    final height = binary.height;
    final result = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final neighbors = <int>[];

        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            final nx = x + dx;
            final ny = y + dy;
            if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
              neighbors.add(binary.getPixel(nx, ny).r.toInt());
            }
          }
        }

        neighbors.sort();
        final median = neighbors[neighbors.length ~/ 2];

        if (median < 128) {
          result.setPixel(x, y, img.ColorRgb8(0, 0, 0));
        } else {
          result.setPixel(x, y, img.ColorRgb8(255, 255, 255));
        }
      }
    }

    return result;
  }

  /// Fiyat etiketleri için renk filtresi.
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

        final isYellow = r > 180 && g > 180 && b < 100;
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
