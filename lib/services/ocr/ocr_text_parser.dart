import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:vixrex/models/ocr_line.dart';
import 'package:vixrex/models/ocr_text_result.dart';

/// OCR ile metin ayrıştırma servisi.
class OcrTextParser {
  const OcrTextParser();

  /// Görüntüden metin oku.
  Future<OcrTextResult> parseFromImage(List<int> imageBytes) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'OCR özelliği sadece mobil uygulamalarda çalışır. '
        'Lütfen Android veya iOS uygulamasını kullanın.',
      );
    }

    // Geçici dosyaya kaydet
    final tempFile = await _saveTempFile(imageBytes);
    if (tempFile == null) return OcrTextResult.empty();

    try {
      final inputImage = InputImage.fromFilePath(tempFile.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

      try {
        final recognizedText = await textRecognizer.processImage(inputImage);
        final lines = <OcrLine>[];

        for (var blockIndex = 0; blockIndex < recognizedText.blocks.length; blockIndex++) {
          final block = recognizedText.blocks[blockIndex];
          for (var lineIndex = 0; lineIndex < block.lines.length; lineIndex++) {
            final line = block.lines[lineIndex];
            final text = line.text.trim();
            if (text.isEmpty) continue;

            lines.add(OcrLine(
              text: text,
              boundingBox: line.boundingBox,
              blockIndex: blockIndex,
              lineIndex: lineIndex,
            ));
          }
        }

        return OcrTextResult(
          rawText: recognizedText.text.trim(),
          lines: lines,
        );
      } finally {
        await textRecognizer.close();
      }
    } finally {
      // Geçici dosyayı temizle
      try {
        await tempFile.delete();
      } catch (e) {
        if (kDebugMode) debugPrint('OCR temp file delete error: $e');
      }
    }
  }

  /// Ham metinden ürün adaylarını çıkar.
  List<String> extractProductCandidates(String rawText) {
    final lines = rawText.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final candidates = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.length < 3) continue;
      if (RegExp(r'^\d+[.,]\d{2}').hasMatch(trimmed)) continue;
      if (_isNoiseLine(trimmed)) continue;

      candidates.add(trimmed);
    }

    return candidates;
  }

  bool _isNoiseLine(String text) {
    final lower = text.toLowerCase();
    const noiseKeywords = [
      'kargo', 'teslimat', 'kupon', 'puan', 'yorum',
      'bedava', 'indirim', 'sepet', 'stok', 'kdv',
      'taksit', 'kampanya', 'hakkımızda', 'iletişim',
    ];
    return noiseKeywords.any((kw) => lower.contains(kw));
  }

  Future<File?> _saveTempFile(List<int> bytes) async {
    try {
      final dir = await Directory.systemTemp.createTemp();
      final file = File('${dir.path}/ocr_temp.jpg');
      await file.writeAsBytes(bytes);
      return file;
    } catch (_) {
      return null;
    }
  }
}
