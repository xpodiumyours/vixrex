import 'dart:ui';

/// OCR motorunun tek kelime/parça düzeyindeki çıktısı.
///
/// Fatura tablolarında yalnız satır metni yetmez: barkod, beden, adet ve
/// fiyatın hangi sütunda olduğu da gerekir. Bu model o konumu korur.
class OcrToken {
  final String text;
  final Rect boundingBox;
  final int blockIndex;
  final int lineIndex;
  final int elementIndex;

  const OcrToken({
    required this.text,
    required this.boundingBox,
    required this.blockIndex,
    required this.lineIndex,
    required this.elementIndex,
  });

  double get centerX => boundingBox.center.dx;
  double get centerY => boundingBox.center.dy;
  double get width => boundingBox.width;
  double get height => boundingBox.height;
}
