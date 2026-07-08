import 'dart:ui';

/// OCR ile okunan tek bir metin satırı.
class OcrLine {
  final String text;
  final Rect boundingBox;
  final int blockIndex;
  final int lineIndex;

  const OcrLine({
    required this.text,
    required this.boundingBox,
    required this.blockIndex,
    required this.lineIndex,
  });

  double get centerX => boundingBox.center.dx;
  double get centerY => boundingBox.center.dy;
  double get width => boundingBox.width;
  double get height => boundingBox.height;

  bool get isEmpty => text.trim().isEmpty;
  bool get isNotEmpty => text.trim().isNotEmpty;

  /// Bu satırın başka bir satırla yatay eksende kesişip kesişmediğini kontrol et.
  bool overlapsHorizontally(OcrLine other, {double threshold = 0.3}) {
    final overlapLeft = boundingBox.left.clamp(
      other.boundingBox.left,
      other.boundingBox.right,
    );
    final overlapRight = boundingBox.right.clamp(
      other.boundingBox.left,
      other.boundingBox.right,
    );
    final overlapWidth = overlapRight - overlapLeft;
    final minWidth = width < other.width ? width : other.width;
    if (minWidth <= 0) return false;
    return overlapWidth / minWidth >= threshold;
  }

  /// Bu satırın başka bir satırla dikey eksende ne kadar yakın olduğunu hesapla.
  double verticalDistanceTo(OcrLine other) {
    return (centerY - other.centerY).abs();
  }
}
