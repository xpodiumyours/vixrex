import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import 'package:vixrex/models/store_product.dart';

/// Excel (.xlsx) ve CSV dosyalarından toplu ürün çıkarma servisi.
class BulkProductUploadService {
  const BulkProductUploadService();

  /// Dosya içeriğinden ürün listesi oluşturur.
  BulkParseResult parse(Uint8List bytes, {required String fileName}) {
    // Maksimum dosya boyutu kontrolü (5 MB)
    const maxBytes = 5 * 1024 * 1024;
    if (bytes.length > maxBytes) {
      return BulkParseResult.failure(
        'Dosya çok büyük (${(bytes.length / 1024 / 1024).toStringAsFixed(1)} MB). '
        'Maksimum 5 MB olmalıdır.',
      );
    }

    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.csv')) {
      return _parseCsv(bytes);
    }
    if (lowerName.endsWith('.xlsx') || lowerName.endsWith('.xls')) {
      return _parseExcel(bytes);
    }
    return BulkParseResult.failure('Desteklenmeyen dosya formatı. .xlsx veya .csv kullanın.');
  }

  // ─── CSV PARSE ──────────────────────────────────────────────────

  BulkParseResult _parseCsv(Uint8List bytes) {
    try {
      final content = utf8.decode(bytes, allowMalformed: true);
      final lines = content.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
      if (lines.length < 2) {
        return BulkParseResult.failure('CSV dosyasında en az 2 satır olmalı (başlık + veri).');
      }

      final header = _parseCsvLine(lines[0]);
      final columnMap = _mapColumns(header);
      if (columnMap['name'] == null) {
        return BulkParseResult.failure('CSV dosyasında "Ürün Adı" veya "Name" başlığı bulunamadı.');
      }

      final products = <Product>[];
      final errors = <BulkParseError>[];

      for (var i = 1; i < lines.length; i++) {
        final values = _parseCsvLine(lines[i]);
        final result = _rowToProduct(values, columnMap, rowIndex: i + 1);
        if (result.product != null) {
          products.add(result.product!);
        }
        if (result.error != null) {
          errors.add(result.error!);
        }
      }

      return BulkParseResult.success(products: products, errors: errors);
    } catch (e) {
      return BulkParseResult.failure('CSV okuma hatası: $e');
    }
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString().trim());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString().trim());
    return result;
  }

  // ─── EXCEL PARSE ───────────────────────────────────────────────

  BulkParseResult _parseExcel(Uint8List bytes) {
    try {
      final excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) {
        return BulkParseResult.failure('Excel dosyasında sayfa bulunamadı.');
      }

      final table = excel.tables.values.first;
      if (table.rows.length < 2) {
        return BulkParseResult.failure('Excel dosyasında en az 2 satır olmalı (başlık + veri).');
      }

      final header = table.rows.first
          .map((cell) => cell?.value?.toString() ?? '')
          .toList();
      final columnMap = _mapColumns(header);
      if (columnMap['name'] == null) {
        return BulkParseResult.failure('Excel dosyasında "Ürün Adı" veya "Name" başlığı bulunamadı.');
      }

      final products = <Product>[];
      final errors = <BulkParseError>[];

      for (var row = 1; row < table.rows.length; row++) {
        final values = table.rows[row]
            .map((cell) => cell?.value?.toString() ?? '')
            .toList();
        final result = _rowToProduct(values, columnMap, rowIndex: row + 1);
        if (result.product != null) {
          products.add(result.product!);
        }
        if (result.error != null) {
          errors.add(result.error!);
        }
      }

      return BulkParseResult.success(products: products, errors: errors);
    } catch (e) {
      return BulkParseResult.failure('Excel okuma hatası: $e');
    }
  }

  // ─── ORTAK YARDIMCILAR ─────────────────────────────────────────

  /// Başlık satırından sütun eşlemeleri oluşturur.
  Map<String, int> _mapColumns(List<String> headers) {
    final map = <String, int>{};
    for (var i = 0; i < headers.length; i++) {
      final normalized = _normalizeHeader(headers[i]);
      if (_nameAliases.contains(normalized)) map['name'] ??= i;
      if (_priceAliases.contains(normalized)) map['price'] ??= i;
      if (_descAliases.contains(normalized)) map['description'] ??= i;
      if (_categoryAliases.contains(normalized)) map['category'] ??= i;
      if (_stockAliases.contains(normalized)) map['stockStatus'] ??= i;
      if (_barcodeAliases.contains(normalized)) map['barcode'] ??= i;
      if (_imageUrlAliases.contains(normalized)) map['imageUrl'] ??= i;
    }
    return map;
  }

  String _normalizeHeader(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[üû]'), 'u')
        .replaceAll(RegExp(r'[öo]'), 'o')
        .replaceAll(RegExp(r'[çc]'), 'c')
        .replaceAll(RegExp(r'[şs]'), 's')
        .replaceAll(RegExp(r'[ğg]'), 'g')
        .replaceAll(RegExp(r'[iiî]'), 'i')
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  static const _nameAliases = {'urunadi', 'urunad', 'urun', 'adi', 'ad', 'name', 'urunname', 'baslik', 'title', 'product', 'productname', 'urunadii', 'urunadi '};
  static const _priceAliases = {'fiyat', 'price', 'fiyatitl', 'satisfiyati', 'satis', 'tutar', 'amount', 'saleprice', 'fiyat '};
  static const _descAliases = {'aciklama', 'description', 'detay', 'detail', 'not', 'note', 'ozet', 'summary', 'aciklama '};
  static const _categoryAliases = {'kategori', 'category', 'kat', 'grup', 'group', 'turu', 'type', 'kategori '};
  static const _stockAliases = {'stok', 'stock', 'stokdurumu', 'stockstatus', 'stokdurum', 'stok '};
  static const _barcodeAliases = {'barkod', 'barcode', 'sku', 'kod', 'code', 'barkod '};
  static const _imageUrlAliases = {'gorselurl', 'gorsel', 'imageurl', 'image', 'foto', 'fotoğraf', 'resim', 'kapak', 'cover', 'gorselurl ',};

  /// Satırı Product'a çevirir.
  _RowParseResult _rowToProduct(List<String> values, Map<String, int> columnMap, {required int rowIndex}) {
    final nameIndex = columnMap['name']!;
    final name = _cellValue(values, nameIndex);

    if (name.isEmpty) {
      return _RowParseResult(error: BulkParseError(row: rowIndex, message: 'Ürün adı boş, satır atlandı.'));
    }

    final priceRaw = _cellValue(values, columnMap['price'] ?? -1);
    final price = _normalizePrice(priceRaw);

    final description = _cellValue(values, columnMap['description'] ?? -1);
    final category = _cellValue(values, columnMap['category'] ?? -1);
    final stockRaw = _cellValue(values, columnMap['stockStatus'] ?? -1);
    final stockStatus = _normalizeStockStatus(stockRaw);

    final imageUrlRaw = _cellValue(values, columnMap['imageUrl'] ?? -1);
    final imageUrl = imageUrlRaw.trim();
    final imageUrls = imageUrl.isNotEmpty ? [imageUrl] : <String>[];

    final product = Product(
      id: 'bulk_${const Uuid().v4()}',
      name: name,
      price: price,
      description: description,
      imagePath: imageUrl.isNotEmpty ? imageUrl : null,
      imageUrls: imageUrls,
      category: category.isNotEmpty ? category : 'Genel',
      stockStatus: stockStatus,
      isVisible: true,
      source: 'bulk_import',
    );

    return _RowParseResult(product: product);
  }

  String _cellValue(List<String> values, int index) {
    if (index < 0 || index >= values.length) return '';
    return values[index].trim();
  }

  /// Fiyat string'ini normalize eder: "125,50 TL" → "125.50"
  String _normalizePrice(String raw) {
    if (raw.isEmpty) return '';
    var normalized = raw
        .replaceAll(RegExp(r'\b(TL|TRY|₺|tl|try)\b'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (normalized.isEmpty) return '';

    // Virgül ve nokta ayracını ayırt et
    final lastComma = normalized.lastIndexOf(',');
    final lastDot = normalized.lastIndexOf('.');

    if (lastComma != -1 && lastDot != -1) {
      // İkisi de varsa: sonuncu ondalık ayracı
      final decimalSep = lastComma > lastDot ? ',' : '.';
      final thousandsSep = decimalSep == ',' ? '.' : ',';
      normalized = normalized.replaceAll(thousandsSep, '');
      if (decimalSep == ',') {
        normalized = normalized.replaceAll(',', '.');
      }
    } else if (lastComma != -1) {
      // Sadece virgül var
      final parts = normalized.split(',');
      if (parts.length == 2 && parts.last.length <= 2) {
        normalized = normalized.replaceAll(',', '.');
      } else {
        normalized = normalized.replaceAll(',', '');
      }
    }

    final number = num.tryParse(normalized);
    if (number == null) return raw.trim();
    return number % 1 == 0 ? number.toInt().toString() : number.toStringAsFixed(2);
  }

  /// Stok durumunu normalize eder.
  String _normalizeStockStatus(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('tükendi') || lower.contains('yok') || lower.contains('0')) {
      return StockStatus.soldOut.label;
    }
    if (lower.contains('son') || lower.contains('az') || lower.contains('limit')) {
      return StockStatus.lowStock.label;
    }
    return StockStatus.available.label;
  }

  /// Örnek CSV şablonu üretir.
  Uint8List generateTemplateCsv() {
    final buffer = StringBuffer();
    buffer.writeln('Ürün Adı,Fiyat,Açıklama,Kategori,Stok Durumu,Görsel URL');
    buffer.writeln('Örnek Ürün 1,125.50,Günlük kullanım için uygun,Genel,Mevcut,');
    buffer.writeln('Örnek Ürün 2,"1,250.00",Özel tasarım elbise,Elbise,Mevcut,https://ornek.com/gorsel.jpg');
    buffer.writeln('Örnek Ürün 3,,Kampanyalı fiyat,Genel,Tükendi,');
    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }
}

// ─── SONUÇ MODELLERİ ────────────────────────────────────────────

class BulkParseResult {
  final bool isSuccess;
  final String? errorMessage;
  final List<Product> products;
  final List<BulkParseError> errors;

  const BulkParseResult._({
    required this.isSuccess,
    this.errorMessage,
    this.products = const [],
    this.errors = const [],
  });

  factory BulkParseResult.success({
    required List<Product> products,
    required List<BulkParseError> errors,
  }) => BulkParseResult._(isSuccess: true, products: products, errors: errors);

  factory BulkParseResult.failure(String message) =>
      BulkParseResult._(isSuccess: false, errorMessage: message);

  int get validCount => products.length;
  int get errorCount => errors.length;
}

class BulkParseError {
  final int row;
  final String message;

  const BulkParseError({required this.row, required this.message});

  @override
  String toString() => 'Satır $row: $message';
}

class _RowParseResult {
  final Product? product;
  final BulkParseError? error;

  const _RowParseResult({this.product, this.error});
}
