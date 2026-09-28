import 'ocr_line.dart';
import 'ocr_token.dart';

/// OCR metin ayrıştırma sonucu.
class OcrTextResult {
  final String rawText;
  final List<OcrLine> lines;
  final List<OcrToken> tokens;
  final DateTime parsedAt;

  OcrTextResult({
    required this.rawText,
    required this.lines,
    this.tokens = const [],
    DateTime? parsedAt,
  }) : parsedAt = parsedAt ?? DateTime.now();

  OcrTextResult.empty()
    : rawText = '',
      lines = const [],
      tokens = const [],
      parsedAt = DateTime.now();

  bool get isEmpty => rawText.isEmpty && lines.isEmpty && tokens.isEmpty;
  bool get isNotEmpty => !isEmpty;

  int get lineCount => lines.length;
  int get tokenCount => tokens.length;

  /// Fiyat içeren satırları bul.
  List<OcrLine> get priceLines =>
      lines.where((l) => RegExp(r'\d+[.,]\d{2}').hasMatch(l.text)).toList();

  /// Fiyat içermeyen satırları bul (ürün adı adayları).
  List<OcrLine> get textLines =>
      lines.where((l) => !RegExp(r'\d+[.,]\d{2}').hasMatch(l.text)).toList();
}
