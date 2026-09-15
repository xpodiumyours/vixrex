import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/services/product_batch_import_service.dart';
import 'package:vixrex/services/product_image_policy.dart';
import 'package:vixrex/utils/product_price_parser.dart';

/// XML feed dosyalarından ürün çıkarma servisi.
/// Farklı tedarikçi etiketlerini ortak Product CORE batch sözleşmesine eşler.
class XmlProductUploadService {
  const XmlProductUploadService();

  Future<XmlUploadResult> fetchAndSave({
    required String xmlUrl,
    required String storeId,
    required String editToken,
  }) async {
    try {
      final response = await http.get(Uri.parse(xmlUrl));
      if (response.statusCode != 200) {
        return XmlUploadResult.failure(
          'XML yüklenemedi: ${response.statusCode}',
        );
      }

      final xmlContent = String.fromCharCodes(response.bodyBytes);
      final parseResult = parse(xmlContent);
      if (!parseResult.isSuccess) {
        return XmlUploadResult.failure(parseResult.errorMessage!);
      }
      if (parseResult.products.isEmpty) {
        return XmlUploadResult.failure('XML dosyasında ürün bulunamadı.');
      }

      return saveToSupabase(
        products: parseResult.products,
        storeId: storeId,
        editToken: editToken,
      );
    } catch (e) {
      return XmlUploadResult.failure('İşlem hatası: $e');
    }
  }

  /// XML ürünlerini de Excel/CSV ile aynı ProductBatchImportService üzerinden
  /// yazar. Böylece external id -> barkod -> SKU upsert ve dört sayaç tek
  /// istemci sözleşmesinden geçer.
  Future<XmlUploadResult> saveToSupabase({
    required List<Product> products,
    required String storeId,
    required String editToken,
  }) async {
    final result = await ProductBatchImportService().save(
      products: products,
      storeId: storeId,
      editToken: editToken,
      defaultSourceType: 'xml_import',
    );

    if (!result.isSuccess) {
      return XmlUploadResult.failure(
        result.errorMessage ?? 'XML ürünleri kaydedilemedi.',
      );
    }

    return XmlUploadResult.success(
      total: result.total,
      inserted: result.inserted,
      updated: result.updated,
      unchanged: result.unchanged,
      errors: result.errors,
      errorDetails:
          result.errorDetails
              .map(
                (detail) => XmlUploadErrorDetail(
                  index: detail.index,
                  error: detail.error,
                ),
              )
              .toList(),
    );
  }

  XmlParseResult parse(String xmlContent) {
    try {
      final productElements = _extractProductElements(xmlContent);
      if (productElements.isEmpty) {
        return XmlParseResult.failure('XML dosyasında ürün bulunamadı.');
      }

      final products = <Product>[];
      final errors = <XmlParseError>[];
      for (var i = 0; i < productElements.length; i++) {
        final result = _elementToProduct(
          productElements[i],
          rowIndex: i + 1,
        );
        if (result.product != null) products.add(result.product!);
        if (result.error != null) errors.add(result.error!);
      }

      return XmlParseResult.success(products: products, errors: errors);
    } catch (e) {
      return XmlParseResult.failure('XML okuma hatası: $e');
    }
  }

  List<Map<String, String>> _extractProductElements(String xml) {
    final products = <Map<String, String>>[];
    const productTags = [
      'product',
      'urun',
      'item',
      'record',
      'entry',
      'ürün',
      'mahsul',
      'mal',
      'kalem',
      'stok',
    ];

    for (final tag in productTags) {
      final regex = RegExp(
        '<$tag[^>]*>(.*?)</$tag>',
        dotAll: true,
        caseSensitive: false,
      );
      final matches = regex.allMatches(xml);
      if (matches.isEmpty) continue;
      for (final match in matches) {
        final fields = _extractFields(match.group(1) ?? '');
        if (fields.isNotEmpty) products.add(fields);
      }
      break;
    }

    if (products.isEmpty) {
      final fields = _extractFields(xml);
      if (fields.isNotEmpty) products.add(fields);
    }
    return products;
  }

  Map<String, String> _extractFields(String elementContent) {
    final fields = <String, String>{};
    final tagRegex = RegExp(r'<([^/>]+)>([^<]*)</\1>', caseSensitive: false);
    for (final match in tagRegex.allMatches(elementContent)) {
      final tagName = match.group(1)?.toLowerCase().trim() ?? '';
      final value = match.group(2)?.trim() ?? '';
      if (tagName.isNotEmpty && value.isNotEmpty) fields[tagName] = value;
    }
    return fields;
  }

  _XmlParseResult _elementToProduct(
    Map<String, String> fields, {
    required int rowIndex,
  }) {
    final name = _findField(fields, _nameAliases);
    if (name.isEmpty) {
      return _XmlParseResult(
        error: XmlParseError(
          row: rowIndex,
          message: 'Ürün adı bulunamadı, satır atlandı.',
        ),
      );
    }

    final price = _normalizePrice(_findField(fields, _priceAliases));
    final description = _findField(fields, _descAliases);
    final category = _findField(fields, _categoryAliases);
    final stockRaw = _findField(fields, _stockStatusAliases);
    final stockQuantityRaw = _findField(fields, _stockQuantityAliases);
    final stockQuantity = _normalizeStockQuantity(stockQuantityRaw);
    final stockStatus =
        (stockRaw.isNotEmpty || stockQuantity != null)
            ? _normalizeStockStatus(stockRaw, stockQuantity)
            : '';

    final imageUrls = _findImageUrls(fields);
    final imageError = ProductImagePolicy.validate(imageUrls);
    if (imageError != null) {
      return _XmlParseResult(
        error: XmlParseError(row: rowIndex, message: imageError),
      );
    }

    final externalId = _findField(fields, _externalIdAliases);
    final brand = _findField(fields, _brandAliases);
    final barcode = _findField(fields, _barcodeAliases);
    final sku = _findField(fields, _skuAliases);

    return _XmlParseResult(
      product: Product(
        id: 'xml_${const Uuid().v4()}',
        name: name,
        price: price,
        description: description,
        imagePath: imageUrls.isNotEmpty ? imageUrls.first : null,
        imageUrls: imageUrls,
        category: category,
        stockStatus: stockStatus,
        stockQuantity: stockQuantity,
        isVisible: true,
        source: 'xml_import',
        sourceMediaId: externalId.isNotEmpty ? externalId : null,
        brand: brand.isNotEmpty ? brand : null,
        barcode: barcode.isNotEmpty ? barcode : null,
        sku: sku.isNotEmpty ? sku : null,
      ),
    );
  }

  String _findField(Map<String, String> fields, Set<String> aliases) {
    final normalizedAliases = aliases.map(_normalizeTagName).toSet();
    for (final entry in fields.entries) {
      if (normalizedAliases.contains(_normalizeTagName(entry.key))) {
        return entry.value;
      }
    }
    return '';
  }

  List<String> _findImageUrls(Map<String, String> fields) {
    final urls = <String>[];
    final normalizedAliases = _imageUrlAliases.map(_normalizeTagName).toSet();
    final numberedImageField = RegExp(
      r'^(gorsel|image|foto|fotograf|resim|kapak|cover)(url)?\d+$',
    );

    for (final entry in fields.entries) {
      final normalizedKey = _normalizeTagName(entry.key);
      if (!normalizedAliases.contains(normalizedKey) &&
          !numberedImageField.hasMatch(normalizedKey)) {
        continue;
      }
      for (final raw in entry.value.split(RegExp(r'\s*\|\s*|\r?\n'))) {
        final trimmed = raw.trim();
        if (trimmed.isEmpty) continue;
        final url = trimmed.startsWith('//') ? 'https:$trimmed' : trimmed;
        if (!urls.contains(url)) urls.add(url);
      }
    }
    return urls;
  }

  String _normalizeTagName(String value) {
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
        lower.contains('low') ||
        lower.contains('hurry')) {
      return StockStatus.lowStock.label;
    }
    return StockStatus.available.label;
  }

  int? _normalizeStockQuantity(String raw) {
    final trimmed = raw.trim();
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) return null;
    return int.tryParse(trimmed);
  }

  static const _nameAliases = {
    'urunadi', 'urunad', 'urun', 'adi', 'ad', 'name', 'urunname',
    'baslik', 'title', 'product', 'productname', 'isim', 'mahsul', 'mal',
    'kalem', 'stokadi', 'stokname', 'urununadi',
  };
  static const _priceAliases = {
    'fiyat', 'price', 'fiyatitl', 'satisfiyati', 'satis', 'tutar', 'amount',
    'saleprice', 'alisfiyati', 'listprice', 'fiyatidr', 'fiyati', 'fiyatinfo',
  };
  static const _descAliases = {
    'aciklama', 'description', 'detay', 'detail', 'not', 'note', 'ozet',
    'summary', 'urunaciklama', 'urunaciklamasi',
  };
  static const _categoryAliases = {
    'kategori', 'category', 'kat', 'grup', 'group', 'turu', 'type',
    'kategoriadi', 'kategoriismi',
  };
  static const _stockStatusAliases = {
    'stokdurumu', 'stockstatus', 'stokdurum', 'availability',
  };
  static const _stockQuantityAliases = {
    'stok', 'stock', 'stokmiktari', 'stockquantity', 'stokadedi', 'adet',
    'quantity', 'miktar',
  };
  static const _externalIdAliases = {
    'externalproductid', 'externalid', 'productid', 'urunid', 'itemid',
    'recordid', 'id',
  };
  static const _imageUrlAliases = {
    'gorselurl', 'gorsel', 'imageurl', 'image', 'foto', 'fotograf', 'resim',
    'kapak', 'cover', 'fotourl', 'resimurl', 'gorseladresi', 'img', 'src',
  };
  static const _brandAliases = {
    'brand', 'marka', 'markaadi', 'uretici', 'manufacturer',
  };
  static const _barcodeAliases = {
    'barkod', 'barcode', 'gtin', 'ean', 'ean13', 'upc',
  };
  static const _skuAliases = {
    'sku', 'stokkodu', 'kod', 'code', 'productcode', 'urunkodu',
  };
}

class XmlParseResult {
  final bool isSuccess;
  final String? errorMessage;
  final List<Product> products;
  final List<XmlParseError> errors;

  const XmlParseResult._({
    required this.isSuccess,
    this.errorMessage,
    this.products = const [],
    this.errors = const [],
  });

  factory XmlParseResult.success({
    required List<Product> products,
    required List<XmlParseError> errors,
  }) => XmlParseResult._(isSuccess: true, products: products, errors: errors);

  factory XmlParseResult.failure(String message) =>
      XmlParseResult._(isSuccess: false, errorMessage: message);

  int get validCount => products.length;
  int get errorCount => errors.length;
}

class XmlParseError {
  final int row;
  final String message;

  const XmlParseError({required this.row, required this.message});

  @override
  String toString() => 'Satır $row: $message';
}

class _XmlParseResult {
  final Product? product;
  final XmlParseError? error;

  const _XmlParseResult({this.product, this.error});
}

class XmlUploadErrorDetail {
  final int index;
  final String error;

  const XmlUploadErrorDetail({required this.index, required this.error});
}

class XmlUploadResult {
  final bool isSuccess;
  final String? errorMessage;
  final int total;
  final int inserted;
  final int updated;
  final int unchanged;
  final int errors;
  final List<XmlUploadErrorDetail> errorDetails;

  const XmlUploadResult._({
    required this.isSuccess,
    this.errorMessage,
    this.total = 0,
    this.inserted = 0,
    this.updated = 0,
    this.unchanged = 0,
    this.errors = 0,
    this.errorDetails = const [],
  });

  factory XmlUploadResult.success({
    required int total,
    required int inserted,
    required int updated,
    required int unchanged,
    required int errors,
    List<XmlUploadErrorDetail> errorDetails = const [],
  }) => XmlUploadResult._(
    isSuccess: true,
    total: total,
    inserted: inserted,
    updated: updated,
    unchanged: unchanged,
    errors: errors,
    errorDetails: errorDetails,
  );

  factory XmlUploadResult.failure(String message) =>
      XmlUploadResult._(isSuccess: false, errorMessage: message);

  int get changed => inserted + updated;
}
