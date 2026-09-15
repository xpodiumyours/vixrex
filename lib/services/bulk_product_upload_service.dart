import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/services/product_image_policy.dart';
import 'package:vixrex/utils/product_price_parser.dart';

/// Excel (.xlsx) ve CSV dosyalarından Product CORE uyumlu ürünler çıkarır.
class BulkProductUploadService {
  const BulkProductUploadService();

  BulkParseResult parse(Uint8List bytes, {required String fileName}) {
    const maxBytes = 5 * 1024 * 1024;
    if (bytes.length > maxBytes) {
      return BulkParseResult.failure(
        'Dosya çok büyük (${(bytes.length / 1024 / 1024).toStringAsFixed(1)} MB). Maksimum 5 MB olmalıdır.',
      );
    }

    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.csv')) return _parseCsv(bytes);
    if (lowerName.endsWith('.xlsx') || lowerName.endsWith('.xls')) {
      return _parseExcel(bytes);
    }
    return BulkParseResult.failure(
      'Desteklenmeyen dosya formatı. .xlsx veya .csv kullanın.',
    );
  }

  BulkParseResult _parseCsv(Uint8List bytes) {
    try {
      final content = utf8.decode(bytes, allowMalformed: true);
      final lines =
          content
              .split(RegExp(r'\r?\n'))
              .where((line) => line.trim().isNotEmpty)
              .toList();
      if (lines.length < 2) {
        return BulkParseResult.failure(
          'CSV dosyasında en az 2 satır olmalı (başlık + veri).',
        );
      }

      final columnMap = _mapColumns(_parseCsvLine(lines.first));
      if (columnMap['name'] == null) {
        return BulkParseResult.failure(
          'CSV dosyasında "Ürün Adı" veya "Name" başlığı bulunamadı.',
        );
      }

      final products = <Product>[];
      final errors = <BulkParseError>[];
      for (var index = 1; index < lines.length; index++) {
        final result = _rowToProduct(
          _parseCsvLine(lines[index]),
          columnMap,
          rowIndex: index + 1,
        );
        if (result.product != null) products.add(result.product!);
        if (result.error != null) errors.add(result.error!);
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

  BulkParseResult _parseExcel(Uint8List bytes) {
    try {
      final excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) {
        return BulkParseResult.failure('Excel dosyasında sayfa bulunamadı.');
      }
      final table = excel.tables.values.first;
      if (table.rows.length < 2) {
        return BulkParseResult.failure(
          'Excel dosyasında en az 2 satır olmalı (başlık + veri).',
        );
      }

      final headers =
          table.rows.first
              .map((cell) => cell?.value?.toString() ?? '')
              .toList();
      final columnMap = _mapColumns(headers);
      if (columnMap['name'] == null) {
        return BulkParseResult.failure(
          'Excel dosyasında "Ürün Adı" veya "Name" başlığı bulunamadı.',
        );
      }

      final products = <Product>[];
      final errors = <BulkParseError>[];
      for (var row = 1; row < table.rows.length; row++) {
        final values =
            table.rows[row]
                .map((cell) => cell?.value?.toString() ?? '')
                .toList();
        final result = _rowToProduct(values, columnMap, rowIndex: row + 1);
        if (result.product != null) products.add(result.product!);
        if (result.error != null) errors.add(result.error!);
      }
      return BulkParseResult.success(products: products, errors: errors);
    } catch (e) {
      return BulkParseResult.failure('Excel okuma hatası: $e');
    }
  }

  Map<String, int> _mapColumns(List<String> headers) {
    final map = <String, int>{};
    for (var i = 0; i < headers.length; i++) {
      final normalized = _normalizeHeader(headers[i]);
      if (_nameAliases.contains(normalized)) map['name'] ??= i;
      if (_externalIdAliases.contains(normalized)) map['externalId'] ??= i;
      if (_priceAliases.contains(normalized)) map['price'] ??= i;
      if (_descAliases.contains(normalized)) map['description'] ??= i;
      if (_categoryAliases.contains(normalized)) map['category'] ??= i;
      if (_stockStatusAliases.contains(normalized)) map['stockStatus'] ??= i;
      if (_stockQuantityAliases.contains(normalized)) {
        map['stockQuantity'] ??= i;
      }
      if (_brandAliases.contains(normalized)) map['brand'] ??= i;
      if (_barcodeAliases.contains(normalized)) map['barcode'] ??= i;
      if (_skuAliases.contains(normalized)) map['sku'] ??= i;
      if (_imageUrlAliases.contains(normalized)) map['image1'] ??= i;

      final numberedImage = _numberedImageHeader.firstMatch(normalized);
      if (numberedImage != null) {
        final number = int.tryParse(numberedImage.group(3) ?? '');
        if (number != null && number > 0) map['image$number'] ??= i;
      }
    }
    return map;
  }

  _RowParseResult _rowToProduct(
    List<String> values,
    Map<String, int> columnMap, {
    required int rowIndex,
  }) {
    final name = _cellValue(values, columnMap['name']!);
    if (name.isEmpty) {
      return _RowParseResult(
        error: BulkParseError(
          row: rowIndex,
          message: 'Ürün adı boş, satır atlandı.',
        ),
      );
    }

    final imageUrls = _collectImageUrls(values, columnMap);
    final imageError = ProductImagePolicy.validate(imageUrls);
    if (imageError != null) {
      return _RowParseResult(
        error: BulkParseError(row: rowIndex, message: imageError),
      );
    }

    final stockRaw = _cellValue(values, columnMap['stockStatus'] ?? -1);
    final stockQuantityRaw = _cellValue(
      values,
      columnMap['stockQuantity'] ?? -1,
    );
    final stockQuantity = _normalizeStockQuantity(stockQuantityRaw);
    final stockStatus =
        (stockRaw.isNotEmpty || stockQuantity != null)
            ? _normalizeStockStatus(stockRaw, stockQuantity)
            : '';
    final sku = _cellValue(values, columnMap['sku'] ?? -1);
    final barcode = _cellValue(values, columnMap['barcode'] ?? -1);
    final externalId = _cellValue(values, columnMap['externalId'] ?? -1);
    final brand = _cellValue(values, columnMap['brand'] ?? -1);
    final category = _cellValue(values, columnMap['category'] ?? -1);

    return _RowParseResult(
      product: Product(
        id: 'bulk_${const Uuid().v4()}',
        name: name,
        price: _normalizePrice(
          _cellValue(values, columnMap['price'] ?? -1),
        ),
        description: _cellValue(values, columnMap['description'] ?? -1),
        imagePath: imageUrls.isNotEmpty ? imageUrls.first : null,
        imageUrls: imageUrls,
        category: category,
        stockStatus: stockStatus,
        stockQuantity: stockQuantity,
        isVisible: true,
        source: 'bulk_import',
        sourceMediaId: externalId.isNotEmpty ? externalId : null,
        brand: brand.isNotEmpty ? brand : null,
        barcode: barcode.isNotEmpty ? barcode : null,
        sku: sku.isNotEmpty ? sku : null,
      ),
    );
  }

  List<String> _collectImageUrls(
    List<String> values,
    Map<String, int> columnMap,
  ) {
    final imageEntries =
        columnMap.entries.where((entry) => entry.key.startsWith('image')).toList()
          ..sort((left, right) {
            final leftIndex = int.tryParse(left.key.substring(5)) ?? 0;
            final rightIndex = int.tryParse(right.key.substring(5)) ?? 0;
            return leftIndex.compareTo(rightIndex);
          });

    final urls = <String>[];
    for (final entry in imageEntries) {
      final cell = _cellValue(values, entry.value);
      if (cell.isEmpty) continue;
      for (final raw in cell.split(RegExp(r'\s*\|\s*|\r?\n'))) {
        final trimmed = raw.trim();
        if (trimmed.isEmpty) continue;
        final url = trimmed.startsWith('//') ? 'https:$trimmed' : trimmed;
        if (!urls.contains(url)) urls.add(url);
      }
    }
    return urls;
  }

  String _cellValue(List<String> values, int index) {
    if (index < 0 || index >= values.length) return '';
    return values[index].trim();
  }

  String _normalizeHeader(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[üû]'), 'u')
        .replaceAll(RegExp(r'[öo]'), 'o')
        .replaceAll(RegExp(r'[çc]'), 'c')
        .replaceAll(RegExp(r'[şs]'), 's')
        .replaceAll(RegExp(r'[ğg]'), 'g')
        .replaceAll(RegExp(r'[ıiî]'), 'i')
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  String _normalizePrice(String raw) {
    if (raw.trim().isEmpty) return '';
    final amount = parseProductPriceAmount(raw);
    if (amount == null) return raw.trim();
    return amount % 1 == 0
        ? amount.toInt().toString()
        : amount.toStringAsFixed(2);
  }

  String _normalizeStockStatus(String raw, int? stockQuantity) {
    if (stockQuantity == 0) return StockStatus.soldOut.label;
    final lower = raw.toLowerCase().trim();
    if (lower == '0' ||
        lower.contains('tükendi') ||
        lower.contains('yok') ||
        lower.contains('out of stock') ||
        lower.contains('sold out')) {
      return StockStatus.soldOut.label;
    }
    if (lower.contains('son') ||
        lower.contains('az') ||
        lower.contains('limit') ||
        lower.contains('low')) {
      return StockStatus.lowStock.label;
    }
    return StockStatus.available.label;
  }

  int? _normalizeStockQuantity(String raw) {
    final trimmed = raw.trim();
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) return null;
    return int.tryParse(trimmed);
  }

  /// Örnek CSV şablonu. Harici Ürün ID, barkod ve SKU ayrı kimlik alanlarıdır.
  Uint8List generateTemplateCsv() {
    final buffer = StringBuffer();
    buffer.writeln(
      'Harici Ürün ID,Ürün Adı,Fiyat,Açıklama,Kategori,Stok Durumu,Stok Adedi,Marka,Barkod,SKU,Görsel URL 1,Görsel URL 2,Görsel URL 3',
    );
    buffer.writeln(
      'TED-1001,Örnek Ürün 1,125.50,Günlük kullanım için uygun,Genel,Mevcut,12,Örnek Marka,8690000000005,ORNEK-1,https://ornek.com/urun1-a.jpg,https://ornek.com/urun1-b.jpg,https://ornek.com/urun1-c.jpg',
    );
    buffer.writeln(
      'TED-1002,Örnek Ürün 2,"1,250.00",Özel tasarım elbise,Elbise,Mevcut,4,Örnek Marka,,ELBISE-2,https://ornek.com/urun2-a.jpg,https://ornek.com/urun2-b.jpg,https://ornek.com/urun2-c.jpg',
    );
    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  static final _numberedImageHeader = RegExp(
    r'^(gorsel|image|foto|fotograf|resim|kapak|cover)(url)?(\d+)$',
  );

  static const _nameAliases = {
    'urunadi', 'urunad', 'urun', 'adi', 'ad', 'name', 'urunname', 'baslik',
    'title', 'product', 'productname', 'urunadii',
  };
  static const _externalIdAliases = {
    'hariciurunid', 'externalproductid', 'externalid', 'productid', 'urunid',
    'itemid', 'recordid',
  };
  static const _priceAliases = {
    'fiyat', 'price', 'fiyatitl', 'satisfiyati', 'satis', 'tutar', 'amount',
    'saleprice',
  };
  static const _descAliases = {
    'aciklama', 'description', 'detay', 'detail', 'not', 'note', 'ozet',
    'summary',
  };
  static const _categoryAliases = {
    'kategori', 'category', 'kat', 'grup', 'group', 'turu', 'type',
  };
  static const _stockStatusAliases = {
    'stokdurumu', 'stockstatus', 'stokdurum', 'availability',
  };
  static const _stockQuantityAliases = {
    'stok', 'stock', 'stokadedi', 'stokmiktari', 'stockquantity', 'quantity',
    'adet', 'miktar',
  };
  static const _brandAliases = {'marka', 'brand', 'uretici', 'manufacturer'};
  static const _barcodeAliases = {
    'barkod', 'barcode', 'gtin', 'ean', 'ean13', 'upc',
  };
  static const _skuAliases = {
    'sku', 'stokkodu', 'urunkodu', 'productcode', 'code',
  };
  static const _imageUrlAliases = {
    'gorselurl', 'gorsel', 'imageurl', 'image', 'foto', 'fotograf', 'resim',
    'kapak', 'cover',
  };
}

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
