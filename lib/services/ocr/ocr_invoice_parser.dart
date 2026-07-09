import 'package:vixrex/models/ocr_line.dart';

/// Fatura/belge yapılandırılmış parsing servisi.
///
/// Fatura satırlarını yapılandırılmış olarak çıkarır:
/// 1. Header, Body, Footer ayrımı
/// 2. Sütun tespiti (ad, miktar, birim fiyat, toplam)
/// 3. Her satırı sütunlara ayırma
class OcrInvoiceParser {
  const OcrInvoiceParser();

  /// Fatura satırlarını yapılandırılmış olarak çıkar.
  List<InvoiceLineItem> parseInvoiceLines(List<OcrLine> lines) {
    // 1. Header, Body, Footer ayrımı
    final sections = _splitIntoSections(lines);

    // 2. Body içindeki ürün satırlarını tespit et
    final bodyLines = sections['body'] ?? [];

    // 3. Her satırı sütunlara ayır
    return _parseProductLines(bodyLines);
  }

  /// Satırları bölümlere ayır.
  Map<String, List<OcrLine>> _splitIntoSections(List<OcrLine> lines) {
    final sections = <String, List<OcrLine>>{
      'header': [],
      'body': [],
      'footer': [],
    };

    bool inBody = false;
    bool headerDone = false;

    for (final line in lines) {
      final lower = line.text.toLowerCase().trim();

      // Header anahtar kelimeleri
      if (!headerDone && _isHeaderLine(lower)) {
        sections['header']!.add(line);
        continue;
      }

      // Footer anahtar kelimeleri
      if (_isFooterLine(lower)) {
        sections['footer']!.add(line);
        inBody = false;
        continue;
      }

      // Separator → body başlangıcı/bitişi
      if (_isSeparatorLine(line.text)) {
        if (!inBody) {
          inBody = true;
          headerDone = true;
        } else {
          inBody = false;
        }
        continue;
      }

      // Body içindeyse
      if (inBody) {
        sections['body']!.add(line);
      } else if (sections['body']!.isEmpty && sections['header']!.isNotEmpty) {
        // Header henüz bitmediyse
        sections['header']!.add(line);
      }
    }

    return sections;
  }

  /// Header satırı mı kontrol et.
  bool _isHeaderLine(String lower) {
    const headerKeywords = [
      'tarih', 'saat', 'fiş no', 'sayfa', 'firma', 'mağaza',
      'adres', 'telefon', 'vergi', 'kasiyer', 'işlem', 'pos',
      'terminal', 'batch', 'referans', 'irsaliye', 'fatura',
    ];
    return headerKeywords.any((kw) => lower.contains(kw));
  }

  /// Footer satırı mı kontrol et.
  bool _isFooterLine(String lower) {
    const footerKeywords = [
      'toplam', 'ara toplam', 'genel toplam', 'mal bedeli',
      'net tutar', 'kdv', 'ötv', 'iskonto', 'teşekkür',
      'iyi günler', 'bizi tercih', 'müşteri memnuniyeti',
    ];
    return footerKeywords.any((kw) => lower.contains(kw));
  }

  /// Separator satırı mı kontrol et.
  bool _isSeparatorLine(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    if (RegExp(r'^[-=]{3,}$').hasMatch(trimmed)) return true;
    if (trimmed.length >= 3) {
      final firstChar = trimmed[0];
      if (trimmed.split('').every((c) => c == firstChar || c == ' ')) return true;
    }
    return false;
  }

  /// Body satırlarını InvoiceLineItem'lara dönüştür.
  List<InvoiceLineItem> _parseProductLines(List<OcrLine> bodyLines) {
    final items = <InvoiceLineItem>[];

    for (final line in bodyLines) {
      final item = _parseLine(line);
      if (item != null) items.add(item);
    }

    return items;
  }

  /// Tek bir satırı InvoiceLineItem'a dönüştür.
  InvoiceLineItem? _parseLine(OcrLine line) {
    final text = line.text.trim();
    if (text.length < 3) return null;

    // Fiyat pattern'leri
    final pricePattern = RegExp(r'([\d.,]+)\s*(?:₺|TL|TRY|tl|try)?');
    final prices = pricePattern.allMatches(text).toList();

    if (prices.isEmpty) return null;

    // Son fiyat → toplam olabilir, bir önceki → birim fiyat
    double? unitPrice;
    double? total;
    String name = text;

    if (prices.length >= 2) {
      // Son iki fiyatı al
      final lastMatch = prices.last;
      final secondLastMatch = prices[prices.length - 2];

      total = _parseAmount(lastMatch.group(1)!);
      unitPrice = _parseAmount(secondLastMatch.group(1)!);

      // İsim: İlk fiyat öncesindeki metin
      final firstPriceStart = text.indexOf(prices.first.group(0)!);
      name = text.substring(0, firstPriceStart).trim();
    } else if (prices.length == 1) {
      // Tek fiyat varsa birim fiyat olarak al
      unitPrice = _parseAmount(prices.first.group(1)!);

      // İsim: Fiyat öncesindeki metin
      final firstPriceStart = text.indexOf(prices.first.group(0)!);
      name = text.substring(0, firstPriceStart).trim();
    }

    // Miktarı tespit et
    final qtyMatch = RegExp(r'(\d+)\s*(?:adet|ad|pcs|kutu|paket|kg|lt|g)', caseSensitive: false).firstMatch(text);
    final quantity = qtyMatch != null ? int.tryParse(qtyMatch.group(1)!) ?? 1 : 1;

    // İsmi temizle
    name = _cleanName(name);
    if (name.length < 2) return null;

    return InvoiceLineItem(
      name: name,
      quantity: quantity,
      unitPrice: unitPrice,
      total: total,
      boundingBox: line.boundingBox,
    );
  }

  /// İsmi temizle.
  String _cleanName(String name) {
    var cleaned = name;
    cleaned = cleaned.replaceAll(RegExp(r'(?:₺|TL|TRY|tl|try|KR|KURUŞ)', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'\b\d{13}\b'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\b\d+\s*(ad|adet|dz|pcs|ADET)\b', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'\b[A-Z]{2,4}\d{4,6}\b'), '');
    cleaned = cleaned.trim();
    return cleaned;
  }

  /// Sayısal değeri parse et.
  double? _parseAmount(String raw) {
    var normalized = raw.replaceAll(' ', '');
    final lastComma = normalized.lastIndexOf(',');
    final lastDot = normalized.lastIndexOf('.');

    if (lastComma != -1 && lastDot != -1) {
      final decimalSep = lastComma > lastDot ? ',' : '.';
      final thousandsSep = decimalSep == ',' ? '.' : ',';
      normalized = normalized.replaceAll(thousandsSep, '');
      if (decimalSep == ',') normalized = normalized.replaceAll(',', '.');
    } else if (lastComma != -1) {
      normalized = normalized.replaceAll(',', '.');
    }

    return double.tryParse(normalized);
  }
}

/// Yapılandırılmış fatura satırı.
class InvoiceLineItem {
  final String name;
  final int quantity;
  final double? unitPrice;
  final double? total;
  final dynamic boundingBox;

  const InvoiceLineItem({
    required this.name,
    this.quantity = 1,
    this.unitPrice,
    this.total,
    this.boundingBox,
  });
}
