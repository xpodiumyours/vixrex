import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';
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
    if (lowerName.endsWith('.xml')) {
      return _parseXml(bytes);
    }
    return BulkParseResult.failure('Desteklenmeyen dosya formatı. .xlsx, .csv veya .xml kullanın.');
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

  // ─── XML PARSE ─────────────────────────────────────────────────

  BulkParseResult _parseXml(Uint8List bytes) {
    try {
      final content = utf8.decode(bytes, allowMalformed: true);
      final document = XmlDocument.parse(content);

      // Farklı XML kök elementlerini destekle
      final root = document.rootElement;
      final productElements = _findProductElements(root);

      if (productElements.isEmpty) {
        return BulkParseResult.failure(
          'XML dosyasında ürün bulunamadı. '
          'Beklenen yapı: <products>, <catalog>, <items> veya <urunler> kök elemanı.',
        );
      }

      final products = <Product>[];
      final errors = <BulkParseError>[];
      var rowIndex = 0;

      for (final element in productElements) {
        rowIndex++;
        final result = _xmlElementToProduct(element, rowIndex);
        if (result.product != null) {
          products.add(result.product!);
        }
        if (result.error != null) {
          errors.add(result.error!);
        }
      }

      return BulkParseResult.success(products: products, errors: errors);
    } catch (e) {
      return BulkParseResult.failure('XML okuma hatası: $e');
    }
  }

  /// XML kök elementinden ürün elementlerini bulur.
  List<XmlElement> _findProductElements(XmlElement root) {
    final possibleChildren = ['product', 'item', 'urun', 'entry', 'record'];

    // Kök elemanın kendisi ürün listesi olabilir
    for (final childName in possibleChildren) {
      if (root.name.local.toLowerCase() == childName) {
        return [root];
      }
    }

    // Çocuk elemanları ara
    for (final childName in possibleChildren) {
      final elements = root.findAllElements(childName);
      if (elements.isNotEmpty) {
        return elements.toList();
      }
    }

    // RSS yapısı kontrolü (Google Merchant Center)
    final channel = root.findElements('channel');
    if (channel.isNotEmpty) {
      final items = channel.first.findAllElements('item');
      if (items.isNotEmpty) {
        return items.toList();
      }
    }

    return [];
  }

  /// XML elementini Product'a çevirir.
  _RowParseResult _xmlElementToProduct(XmlElement element, int rowIndex) {
    // İsim alanı için farklı XML alan isimlerini dene
    final name = _xmlChildText(element, [
      'name', 'title', 'urunadi', 'urun_adi', 'productName',
      'product_name', 'baslik', 'adi', 'ad',
    ]);

    if (name.isEmpty) {
      return _RowParseResult(
        error: BulkParseError(row: rowIndex, message: 'Ürün adı boş, satır atlandı.'),
      );
    }

    // Fiyat
    final priceRaw = _xmlChildText(element, [
      'price', 'fiyat', 'satisfiyati', 'satis_fiyati', 'salePrice',
      'sale_price', 'amount', 'tutar', 'listPrice', 'list_price',
    ]);
    final price = _normalizePrice(priceRaw);

    // Açıklama
    final description = _xmlChildText(element, [
      'description', 'aciklama', 'detay', 'detail', 'ozet', 'summary',
      'shortDescription', 'short_description', 'longDescription', 'long_description',
    ]);

    // Kategori
    final category = _xmlChildText(element, [
      'category', 'kategori', 'categoryName', 'category_name', 'grup',
      'group', 'turu', 'type', 'productType', 'product_type',
    ]);

    // Barkod/SKU
    final barcode = _xmlChildText(element, [
      'barcode', 'barkod', 'sku', 'kod', 'code', 'productId',
      'product_id', 'externalId', 'external_id', 'id',
    ]);

    // Stok
    final stockRaw = _xmlChildText(element, [
      'stock', 'stok', 'stockQuantity', 'stock_quantity', 'stokAdet',
      'stok_adet', 'quantity', 'miktar', 'stokDurumu', 'stockStatus',
    ]);
    final stockStatus = _normalizeStockStatus(stockRaw);

    // Görseller
    final imageUrls = _xmlChildTexts(element, [
      'image', 'image_url', 'imageUrl', 'gorsel', 'gorselUrl', 'gorsel_url',
      'photo', 'foto', 'resim', 'picture', 'thumbnail', 'thumb',
      'mainImage', 'main_image', 'coverImage', 'cover_image',
    ]);

    // Marka
    final brand = _xmlChildText(element, [
      'brand', 'marka', 'brandName', 'brand_name', 'manufacturer', 'uretici',
    ]);

    // KDV oranı
    final vatRaw = _xmlChildText(element, [
      'vat', 'kdv', 'vatRate', 'vat_rate', 'taxRate', 'tax_rate', 'vergi',
    ]);
    final vatRate = int.tryParse(vatRaw.replaceAll(RegExp(r'[^0-9]'), ''));

    // Varyantlar
    final variants = _parseVariants(element);

    final product = Product(
      id: 'xml_${const Uuid().v4()}',
      name: name,
      price: price,
      description: description,
      imagePath: imageUrls.isNotEmpty ? imageUrls.first : null,
      imageUrls: imageUrls,
      category: category.isNotEmpty ? category : 'Genel',
      stockStatus: stockStatus,
      isVisible: true,
      source: 'xml_import',
      slug: barcode.isNotEmpty ? barcode : null,
      brand: brand.isNotEmpty ? brand : null,
      barcode: barcode.isNotEmpty ? barcode : null,
      vatRate: vatRate,
      variants: variants,
    );

    return _RowParseResult(product: product);
  }

  /// XML'den varyantları parse eder.
  List<ProductVariant> _parseVariants(XmlElement element) {
    final variants = <ProductVariant>[];

    // Farklı varyant XML yapılarını dene
    final variantElements = [
      ...element.findAllElements('variant'),
      ...element.findAllElements('varyant'),
      ...element.findAllElements('variation'),
      ...element.findAllElements('size'),
      ...element.findAllElements('beden'),
    ];

    for (final variantEl in variantElements) {
      final variantName = _xmlChildText(variantEl, [
        'name', 'adi', 'beden', 'size', 'color', 'renk',
      ]);
      final variantSku = _xmlChildText(variantEl, [
        'sku', 'barkod', 'stockCode', 'stok_kodu', 'code',
      ]);
      final variantPrice = _xmlChildText(variantEl, [
        'price', 'fiyat', 'satisFiyati',
      ]);
      final variantStockRaw = _xmlChildText(variantEl, [
        'stock', 'stok', 'quantity', 'miktar',
      ]);
      final variantStock = int.tryParse(variantStockRaw.replaceAll(RegExp(r'[^0-9]'), ''));

      if (variantName.isNotEmpty || variantSku.isNotEmpty) {
        variants.add(ProductVariant(
          name: variantName.isNotEmpty ? variantName : null,
          sku: variantSku.isNotEmpty ? variantSku : null,
          price: variantPrice.isNotEmpty ? _normalizePrice(variantPrice) : null,
          stock: variantStock,
        ));
      }
    }

    return variants;
  }

  /// XML elementinden tek bir child text'i okur.
  String _xmlChildText(XmlElement element, List<String> names) {
    for (final name in names) {
      // Doğrudan çocuk
      final child = element.findElements(name);
      if (child.isNotEmpty) {
        final text = child.first.innerText.trim();
        if (text.isNotEmpty) return text;
      }

      // Alt elemanlarda ara (nested XML)
      final nested = element.findAllElements(name);
      if (nested.isNotEmpty) {
        final text = nested.first.innerText.trim();
        if (text.isNotEmpty) return text;
      }
    }
    return '';
  }

  /// XML elementinden birden fazla child text'i okur (görseller için).
  List<String> _xmlChildTexts(XmlElement element, List<String> names) {
    final urls = <String>[];
    for (final name in names) {
      final children = element.findElements(name);
      for (final child in children) {
        final text = child.innerText.trim();
        if (text.isNotEmpty && _isImageUrl(text)) {
          urls.add(text);
        }
      }

      // Alt elemanlarda da ara
      final nested = element.findAllElements(name);
      for (final item in nested) {
        final text = item.innerText.trim();
        if (text.isNotEmpty && _isImageUrl(text)) {
          urls.add(text);
        }
      }
    }
    return urls.toSet().take(4).toList();
  }

  /// String'in görsel URL'si olup olmadığını kontrol eder.
  bool _isImageUrl(String text) {
    final lower = text.toLowerCase();
    return lower.startsWith('http') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
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
