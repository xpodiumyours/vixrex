import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// OCR için gelişmiş görsel ön işleme servisi.
class OcrImagePreprocessor {
  const OcrImagePreprocessor();

  /// Maksimum genişlik (piksel).
  static const int _maxWidth = 2400;

  /// OCR için görüntüyü optimize eder.
  Future<Uint8List> preprocess(Uint8List imageBytes) async {
    return compute(_preprocessSync, imageBytes);
  }

  /// Senkron ön işleme (isolate içinde çalışır).
  static Uint8List _preprocessSync(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    // 1. Görseli küçült (büyük fotoğraflar için)
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

    // 3. Adaptive threshold (ikili ayrıştırma) — EN KRİTİK ADIM
    final thresholded = _adaptiveThreshold(grayscale);

    // 4. Gürültü temizleme (küçük lekeleri sil)
    final denoised = _removeNoise(thresholded);

    // 5. Hafif keskinlik
    final sharpened = img.convolution(
      denoised,
      filter: [
         0, -1,  0,
        -1,  5, -1,
         0, -1,  0,
      ],
    );

    // JPEG kalitesi 95 (daha iyi OCR için)
    return Uint8List.fromList(img.encodeJpg(sharpened, quality: 95));
  }

  /// Adaptive threshold: Her piksel için çevresindeki ortalamaya göre
  /// siyah/beyaz ayrımı yapar. Sabit eşik değerinden çok daha iyidir.
  static img.Image _adaptiveThreshold(img.Image grayscale) {
    final width = grayscale.width;
    final height = grayscale.height;
    final result = img.Image(width: width, height: height);

    // Pencere boyutu (adaptive threshold için)
    final blockSize = 15;
    final c = 10; // Eşik offset'i (ne kadar karanlık olacak)

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Pencere sınırları
        final x0 = max(0, x - blockSize ~/ 2);
        final y0 = max(0, y - blockSize ~/ 2);
        final x1 = min(width - 1, x + blockSize ~/ 2);
        final y1 = min(height - 1, y + blockSize ~/ 2);

        // Pencere内的 ortalama
        double sum = 0;
        int count = 0;
        for (int wy = y0; wy <= y1; wy++) {
          for (int wx = x0; wx <= x1; wx++) {
            sum += grayscale.getPixel(wx, wy).r.toDouble();
            count++;
          }
        }
        final mean = sum / count;

        // Piksel ortalamadan karanlıksa → siyah, değilse → beyaz
        final pixel = grayscale.getPixel(x, y).r.toDouble();
        if (pixel < mean - c) {
          result.setPixel(x, y, img.ColorRgb8(0, 0, 0));       // Siyah (metin)
        } else {
          result.setPixel(x, y, img.ColorRgb8(255, 255, 255)); // Beyaz (arka plan)
        }
      }
    }

    return result;
  }

  /// Gürültü temizleme: 3x3 piksel alanında 5'ten az siyah piksel varsa
  /// o pikseli beyaz yap (küçük lekeleri sil).
  static img.Image _removeNoise(img.Image binary) {
    final width = binary.width;
    final height = binary.height;
    final result = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final centerPixel = binary.getPixel(x, y).r.toInt();

        // Siyah piksel mi?
        if (centerPixel < 128) {
          // 3x3 penceredeki siyah piksel sayısını say
          int blackCount = 0;
          for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
              final nx = x + dx;
              final ny = y + dy;
              if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
                if (binary.getPixel(nx, ny).r.toInt() < 128) {
                  blackCount++;
                }
              }
            }
          }

          // 3x3 alanda 3'ten az siyah piksel varsa → gürültü, beyaz yap
          if (blackCount < 3) {
            result.setPixel(x, y, img.ColorRgb8(255, 255, 255));
          } else {
            result.setPixel(x, y, img.ColorRgb8(0, 0, 0));
          }
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
