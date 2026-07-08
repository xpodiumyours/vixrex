import 'ocr_line.dart';

/// OCR analiz sonucu.
class OcrResult {
  final String rawText;
  final List<OcrLine> lines;

  const OcrResult({
    required this.rawText,
    required this.lines,
  });

  const OcrResult.empty()
      : rawText = '',
        lines = const [];

  bool get isEmpty => rawText.isEmpty && lines.isEmpty;
  bool get isNotEmpty => !isEmpty;

  int get lineCount => lines.length;

  List<String> get uniqueTexts =>
      lines.map((l) => l.text).toSet().toList();
}
