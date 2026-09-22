import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:vixrex/models/ocr_line.dart';
import 'package:vixrex/models/ocr_text_result.dart';
import 'package:vixrex/models/ocr_token.dart';

/// OCR ile metin ayrıştırma servisi.
///
/// Ek yetenekler:
/// - Receipt layout tanımı: HEADER → ITEMS → FOOTER → TOTAL
/// - Separator line detection (------, ====)
class OcrTextParser {
  const OcrTextParser();

  // ─── ANA METOT ──────────────────────────────────────────────────

  Future<OcrTextResult> parseFromImage(
    List<int> imageBytes, {
    String scanMode = 'receipt',
  }) async {
    // Web'de sahte/sentetik OCR sonucu üretmek gerçek belge akışını
    // olduğundan başarılı gösteriyordu. Gerçek web OCR bağlanana kadar
    // uydurma ürün üretmek yerine boş sonuç dön.
    if (kIsWeb) {
      return OcrTextResult.empty();
    }

    final tempFile = await _saveTempFile(imageBytes);
    if (tempFile == null) return OcrTextResult.empty();

    try {
      final inputImage = InputImage.fromFilePath(tempFile.path);
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );

      try {
        final recognizedText = await textRecognizer.processImage(inputImage);
        final lines = <OcrLine>[];
        final tokens = <OcrToken>[];

        for (
          var blockIndex = 0;
          blockIndex < recognizedText.blocks.length;
          blockIndex++
        ) {
          final block = recognizedText.blocks[blockIndex];
          for (var lineIndex = 0; lineIndex < block.lines.length; lineIndex++) {
            final line = block.lines[lineIndex];
            final text = line.text.trim();
            if (text.isEmpty) continue;

            lines.add(
              OcrLine(
                text: text,
                boundingBox: line.boundingBox,
                blockIndex: blockIndex,
                lineIndex: lineIndex,
              ),
            );

            for (
              var elementIndex = 0;
              elementIndex < line.elements.length;
              elementIndex++
            ) {
              final element = line.elements[elementIndex];
              final elementText = element.text.trim();
              if (elementText.isEmpty) continue;
              tokens.add(
                OcrToken(
                  text: elementText,
                  boundingBox: element.boundingBox,
                  blockIndex: blockIndex,
                  lineIndex: lineIndex,
                  elementIndex: elementIndex,
                ),
              );
            }
          }
        }

        return OcrTextResult(
          rawText: recognizedText.text.trim(),
          lines: lines,
          tokens: tokens,
        );
      } finally {
        await textRecognizer.close();
      }
    } finally {
      try {
        await tempFile.delete();
      } catch (e) {
        if (kDebugMode) debugPrint('OCR temp file delete error: $e');
      }
    }
  }

  /// Invoice layout analysis: HEADER → ITEMS → TAX → TOTAL
  InvoiceLayout analyzeInvoiceLayout(List<OcrLine> lines) {
    final sections = <String, List<OcrLine>>{
      'header': [],
      'items': [],
      'tax': [],
      'total': [],
    };

    bool inItems = false;
    bool inTax = false;

    for (final line in lines) {
      final lower = line.text.toLowerCase();
      final isSeparator = _isSeparatorLine(line.text);

      if (isSeparator) {
        inItems = !inItems;
        inTax = false;
        continue;
      }

      // Tax section detection
      if (lower.contains('kdv') ||
          lower.contains('vergi') ||
          lower.contains('vergi dairesi') ||
          lower.contains('tax') ||
          lower.contains('kdv %)') ||
          lower.contains('kdv %')) {
        inTax = true;
        inItems = false;
        sections['tax']!.add(line);
        continue;
      }

      if (inTax) {
        sections['tax']!.add(line);
        continue;
      }

      // Separator handling for items/total toggle
      if (lower.contains('toplam') ||
          lower.contains('genel toplam') ||
          lower.contains('ara toplam') ||
          lower.contains('mal bedeli') ||
          lower.contains('net tutar') ||
          lower.contains('kdv') ||
          lower.contains('kdv %')) {
        inItems = false;
        inTax = false;
        sections['total']!.add(line);
        continue;
      }

      if (inItems) {
        sections['items']!.add(line);
      } else if (sections['items']!.isEmpty) {
        sections['header']!.add(line);
      } else {
        sections['footer']!.add(line);
      }
    }

    final columnBounds = _detectInvoiceColumnBounds(sections['items']!);

    return InvoiceLayout(sections: sections, columnBounds: columnBounds);
  }

  Map<String, double> _detectInvoiceColumnBounds(List<OcrLine> items) {
    if (items.isEmpty) return {};
    final bounds = <String, double>{};
    final leftEdges = items.map((l) => l.centerX).toList()..sort();
    final rightEdges = items.map((l) => l.boundingBox.right).toList()..sort();
    bounds['left'] = leftEdges.isNotEmpty ? leftEdges.first : 0;
    bounds['right'] = rightEdges.isNotEmpty ? rightEdges.last : 300;
    bounds['width'] = bounds['right']! - bounds['left']!;
    bounds['priceColumnStart'] = bounds['left']! + bounds['width']! * 0.7;
    return bounds;
  }

  // ─── YARDIMCI METOTLAR ──────────────────────────────────────────

  // ─── LAYOUT TANIMA ─────────────────────────────────────────────

  ReceiptLayout analyzeLayout(List<OcrLine> lines) {
    final sections = <String, List<OcrLine>>{
      'header': [],
      'items': [],
      'footer': [],
      'total': [],
    };

    bool inItems = false;

    for (final line in lines) {
      final lower = line.text.toLowerCase();
      final isSeparator = _isSeparatorLine(line.text);

      if (isSeparator) {
        inItems = !inItems;
        continue;
      }

      if (lower.contains('toplam') ||
          lower.contains('genel toplam') ||
          lower.contains('ara toplam') ||
          lower.contains('mal bedeli') ||
          lower.contains('net tutar') ||
          lower.contains('kdv')) {
        sections['total']!.add(line);
        continue;
      }

      if (inItems) {
        sections['items']!.add(line);
      } else if (sections['items']!.isEmpty) {
        sections['header']!.add(line);
      } else {
        sections['footer']!.add(line);
      }
    }

    final columnBounds = _detectColumnBounds(sections['items']!);

    return ReceiptLayout(sections: sections, columnBounds: columnBounds);
  }

  bool _isSeparatorLine(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    if (RegExp(r'^[-=]{3,}$').hasMatch(trimmed)) return true;
    if (trimmed.length >= 3) {
      final firstChar = trimmed[0];
      if (trimmed.split('').every((c) => c == firstChar || c == ' ')) {
        return true;
      }
    }
    return false;
  }

  Map<String, double> _detectColumnBounds(List<OcrLine> items) {
    if (items.isEmpty) return {};
    final bounds = <String, double>{};
    final leftEdges = items.map((l) => l.centerX).toList()..sort();
    final rightEdges = items.map((l) => l.boundingBox.right).toList()..sort();
    bounds['left'] = leftEdges.isNotEmpty ? leftEdges.first : 0;
    bounds['right'] = rightEdges.isNotEmpty ? rightEdges.last : 300;
    bounds['width'] = bounds['right']! - bounds['left']!;
    bounds['priceColumnStart'] = bounds['left']! + bounds['width']! * 0.7;
    return bounds;
  }

  // ─── YARDIMCI METOTLAR ──────────────────────────────────────────

  List<String> extractProductCandidates(String rawText) {
    final lines =
        rawText.split('\n').where((l) => l.trim().isNotEmpty).toList();
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
      'kargo',
      'teslimat',
      'kupon',
      'puan',
      'yorum',
      'bedava',
      'indirim',
      'sepet',
      'taksit',
      'kampanya',
      'hakkımızda',
      'iletişim',
      'fiş no',
      'fiş tarihi',
      'mağaza',
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

class ReceiptLayout {
  final Map<String, List<OcrLine>> sections;
  final Map<String, double> columnBounds;

  const ReceiptLayout({required this.sections, required this.columnBounds});

  List<OcrLine> get header => sections['header'] ?? [];
  List<OcrLine> get items => sections['items'] ?? [];
  List<OcrLine> get footer => sections['footer'] ?? [];
  List<OcrLine> get total => sections['total'] ?? [];
}

/// Invoice layout analysis result.
class InvoiceLayout {
  final Map<String, List<OcrLine>> sections;
  final Map<String, double> columnBounds;

  const InvoiceLayout({required this.sections, required this.columnBounds});

  List<OcrLine> get header => sections['header'] ?? [];
  List<OcrLine> get items => sections['items'] ?? [];
  List<OcrLine> get tax => sections['tax'] ?? [];
  List<OcrLine> get total => sections['total'] ?? [];
}
