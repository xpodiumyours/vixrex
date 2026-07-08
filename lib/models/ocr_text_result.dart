import 'ocr_line.dart';

/// OCR metin ayrıştırma sonucu.
class OcrTextResult {
  final String rawText;
  final List<OcrLine> lines;
  final DateTime parsedAt;

  OcrTextResult({
    required this.rawText,
    required this.lines,
    DateTime? parsedAt,
  }) : parsedAt = parsedAt ?? DateTime.now();

  OcrTextResult.empty()
      : rawText = '',
        lines = const [],
        parsedAt = DateTime.now();

  bool get isEmpty => rawText.isEmpty && lines.isEmpty;
  bool get isNotEmpty => !isEmpty;

  int get lineCount => lines.length;

  /// Fiyat içeren satırları bul.
  List<OcrLine> get priceLines =>
      lines.where((l) => RegExp(r'\d+[.,]\d{2}').hasMatch(l.text)).toList();

  /// Fiyat içermeyen satırları bul (ürün adı adayları).
  List<OcrLine> get textLines =>
      lines.where((l) => !RegExp(r'\d+[.,]\d{2}').hasMatch(l.text)).toList();
}
