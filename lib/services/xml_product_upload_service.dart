import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/services/product_image_policy.dart';
import 'package:vixrex/utils/product_price_parser.dart';

/// XML feed dosyalarından ürün çıkarma servisi.
/// Farklı tedarikçi etiketlerini ortak Product CORE alanlarına eşler.
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

  /// XML ürünlerini mevcut batch Product CORE sözleşmesi üzerinden kaydeder.
  Future<XmlUploadResult> saveToSupabase({
    required List<Product> products,
    required String storeId,
    required String editToken,
  }) async {
    try {
      final productsJson =
          products
              .map(
                (p) => {
                  'name': p.name,
                  'slug': p.slug ?? '',
                  'description': p.description,
                  'price_text': p.price,
                  'image_urls': p.imageUrls,
                  'category_name': p.category,
                  'stock_status': p.stockStatus,
                  'source_type': 'xml_import',
                  'isVisible': p.isVisible,
                  if (p.stockQuantity != null)
                    'stock_quantity': p.stockQuantity,
                  if (p.brand != null) 'brand': p.brand,
                  if (p.barcode != null) 'barcode': p.barcode,
                  if (p.sku != null) 'sku': p.sku,
                },
              )
              .toList();

      final result = await Supabase.instance.client.rpc(
        'batch_create_products',
        params: {
          'p_store_id': storeId,
          'p_edit_token': editToken,
          'p_products': productsJson,
        },
      );

      if (result is Map<String, dynamic> && result['success'] == true) {
        return XmlUploadResult.success(
          total: result['total'] ?? 0,
          inserted: result['inserted'] ?? 0,
          errors: result['errors'] ?? 0,
        );
      }

      return XmlUploadResult.failure('Kaydetme hatası: $result');
    } catch (e) {
      return XmlUploadResult.failure('Supabase hatası: $e');
    }
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
      if (tagName.isNotEmpty && value.isNotEmpty) {
        fields[tagName] = value;
      }
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
    final stockRaw = _findField(fields, _stockAliases);
    final stockQuantityRaw = _findField(fields, _stockQuantityAliases);
    final stockQuantity = _normalizeStockQuantity(
      stockQuantityRaw.isNotEmpty ? stockQuantityRaw : stockRaw,
    );
    final stockStatus = _normalizeStockStatus(stockRaw, stockQuantity);
    final imageUrls = _findImageUrls(fields);
    final imageError = ProductImagePolicy.validate(imageUrls);
    if (imageError != null) {
      return _XmlParseResult(
        error: XmlParseError(row: rowIndex, message: imageError),
      );
    }

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
        category: category.isNotEmpty ? category : 'Genel',
        stockStatus: stockStatus,
        stockQuantity: stockQuantity,
        isVisible: true,
        source: 'xml_import',
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
        if ((url.startsWith('http://') || url.startsWith('https://')) &&
            !urls.contains(url)) {
          urls.add(url);
        }
        if (urls.length >= ProductImagePolicy.maxImages) return urls;
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
    'urunadi',
    'urunad',
    'urun',
    'adi',
    'ad',
    'name',
    'urunname',
    'baslik',
    'title',
    'product',
    'productname',
    'isim',
    'adi ',
    'urunadii',
    'urun adi',
    'urun adı',
    'mahsul',
    'mal',
    'kalem',
    'stokadi',
    'stokname',
    'urununadi',
    'urunun adi',
    'urunun adı',
  };

  static const _priceAliases = {
    'fiyat',
    'price',
    'fiyatitl',
    'satisfiyati',
    'satis',
    'tutar',
    'amount',
    'saleprice',
    'alisfiyati',
    'listprice',
    'fiyat ',
    'fiyatidr',
    'fiyatı',
    'satis fiyati',
    'satis fiyatı',
    'fiyat bilgisi',
    'fiyatinfo',
  };

  static const _descAliases = {
    'aciklama',
    'description',
    'detay',
    'detail',
    'not',
    'note',
    'ozet',
    'summary',
    'aciklama ',
    'urunaciklama',
    'urun aciklamasi',
    'urun açıklaması',
    'aciklama bilgisi',
  };

  static const _categoryAliases = {
    'kategori',
    'category',
    'kat',
    'grup',
    'group',
    'turu',
    'type',
    'kategoriadi',
    'kategori adi',
    'kategori adı',
    'kategoriismi',
    'kategori ismi',
  };

  static const _stockAliases = {
    'stok',
    'stock',
    'stokdurumu',
    'stockstatus',
    'stokdurum',
    'stok bilgisi',
  };

  static const _stockQuantityAliases = {
    'stok',
    'stock',
    'stokmiktari',
    'stok miktarı',
    'stokadedi',
    'stok adedi',
    'adet',
    'quantity',
    'miktar',
  };

  static const _imageUrlAliases = {
    'gorselurl',
    'gorsel',
    'imageurl',
    'image',
    'foto',
    'fotoğraf',
    'resim',
    'kapak',
    'cover',
    'gorsel ',
    'fotourl',
    'foto url',
    'resimurl',
    'gorseladresi',
    'görsel',
    'img',
    'src',
  };

  static const _brandAliases = {
    'brand',
    'marka',
    'markaadi',
    'marka adi',
    'marka adı',
    'uretici',
    'manufacturer',
  };

  static const _barcodeAliases = {
    'barkod',
    'barcode',
    'gtin',
    'ean',
    'upc',
  };

  static const _skuAliases = {
    'sku',
    'stokkodu',
    'stok kodu',
    'kod',
    'productcode',
    'urunkodu',
    'urun kodu',
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

class XmlUploadResult {
  final bool isSuccess;
  final String? errorMessage;
  final int total;
  final int inserted;
  final int errors;

  const XmlUploadResult._({
    required this.isSuccess,
    this.errorMessage,
    this.total = 0,
    this.inserted = 0,
    this.errors = 0,
  });

  factory XmlUploadResult.success({
    required int total,
    required int inserted,
    required int errors,
  }) => XmlUploadResult._(
    isSuccess: true,
    total: total,
    inserted: inserted,
    errors: errors,
  );

  factory XmlUploadResult.failure(String message) =>
      XmlUploadResult._(isSuccess: false, errorMessage: message);
}
