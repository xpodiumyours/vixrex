import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/models/store_product.dart';

/// XML feed dosyalarından ürün çıkarma servisi.
/// Herhangi bir XML formatını otomatik olarak parse eder.
class XmlProductUploadService {
  const XmlProductUploadService();

  /// XML URL'inden ürünleri çekip Supabase'e kaydeder.
  Future<XmlUploadResult> fetchAndSave({
    required String xmlUrl,
    required String storeId,
    required String editToken,
  }) async {
    try {
      // 1. XML'i indir
      final response = await http.get(Uri.parse(xmlUrl));
      if (response.statusCode != 200) {
        return XmlUploadResult.failure(
          'XML yüklenemedi: ${response.statusCode}',
        );
      }

      final xmlContent = String.fromCharCodes(response.bodyBytes);

      // 2. Parse et
      final parseResult = parse(xmlContent);
      if (!parseResult.isSuccess) {
        return XmlUploadResult.failure(parseResult.errorMessage!);
      }

      if (parseResult.products.isEmpty) {
        return XmlUploadResult.failure('XML dosyasında ürün bulunamadı.');
      }

      // 3. Supabase'e kaydet
      final saveResult = await saveToSupabase(
        products: parseResult.products,
        storeId: storeId,
        editToken: editToken,
      );

      return saveResult;
    } catch (e) {
      return XmlUploadResult.failure('İşlem hatası: $e');
    }
  }

  /// Ürünleri Supabase'e toplu olarak kaydeder.
  Future<XmlUploadResult> saveToSupabase({
    required List<Product> products,
    required String storeId,
    required String editToken,
  }) async {
    try {
      // Ürünleri JSON formatına çevir
      final productsJson =
          products
              .map(
                (p) => {
                  'name': p.name,
                  'slug': p.slug ?? '',
                  'description': p.description,
                  'price_text': p.price,
                  'image_urls': p.imageUrls.isNotEmpty ? p.imageUrls : [''],
                  'source_type': 'xml_import',
                  'isVisible': p.isVisible,
                  if (p.brand != null) 'brand': p.brand,
                  if (p.sku != null) 'sku': p.sku,
                },
              )
              .toList();

      // Batch RPC'yi çağır
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

  /// XML string'inden ürün listesi oluşturur.
  XmlParseResult parse(String xmlContent) {
    try {
      // XML elementlerini çıkar
      final productElements = _extractProductElements(xmlContent);

      if (productElements.isEmpty) {
        return XmlParseResult.failure('XML dosyasında ürün bulunamadı.');
      }

      final products = <Product>[];
      final errors = <XmlParseError>[];

      for (var i = 0; i < productElements.length; i++) {
        final element = productElements[i];
        final result = _elementToProduct(element, rowIndex: i + 1);

        if (result.product != null) {
          products.add(result.product!);
        }
        if (result.error != null) {
          errors.add(result.error!);
        }
      }

      return XmlParseResult.success(products: products, errors: errors);
    } catch (e) {
      return XmlParseResult.failure('XML okuma hatası: $e');
    }
  }

  /// XML içeriğinden ürün elementlerini çıkarır.
  List<Map<String, String>> _extractProductElements(String xml) {
    final products = <Map<String, String>>[];

    // Ürün elementlerini bul (farklı etiket isimlerini destekler)
    final productTags = [
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
      if (matches.isNotEmpty) {
        for (final match in matches) {
          final elementContent = match.group(1) ?? '';
          final fields = _extractFields(elementContent);
          if (fields.isNotEmpty) {
            products.add(fields);
          }
        }
        break; // İlk eşleşen tag'ı kullan
      }
    }

    // Hiç eşleşme yoksa, tüm XML'i bir element olarak işle
    if (products.isEmpty) {
      final fields = _extractFields(xml);
      if (fields.isNotEmpty) {
        products.add(fields);
      }
    }

    return products;
  }

  /// Bir element içinden alan değerlerini çıkarır.
  Map<String, String> _extractFields(String elementContent) {
    final fields = <String, String>{};

    // Tüm XML tag'lerini eşle
    final tagRegex = RegExp(r'<([^/>]+)>([^<]*)</\1>', caseSensitive: false);
    final matches = tagRegex.allMatches(elementContent);

    for (final match in matches) {
      final tagName = match.group(1)?.toLowerCase().trim() ?? '';
      final value = match.group(2)?.trim() ?? '';

      if (tagName.isNotEmpty && value.isNotEmpty) {
        fields[tagName] = value;
      }
    }

    return fields;
  }

  /// Element'i Product'a çevirir.
  _XmlParseResult _elementToProduct(
    Map<String, String> fields, {
    required int rowIndex,
  }) {
    // Ürün adını bul
    final name = _findField(fields, _nameAliases);

    if (name.isEmpty) {
      return _XmlParseResult(
        error: XmlParseError(
          row: rowIndex,
          message: 'Ürün adı bulunamadı, satır atlandı.',
        ),
      );
    }

    // Diğer alanları bul
    final priceRaw = _findField(fields, _priceAliases);
    final price = _normalizePrice(priceRaw);

    final description = _findField(fields, _descAliases);
    final category = _findField(fields, _categoryAliases);
    final stockRaw = _findField(fields, _stockAliases);
    final stockStatus = _normalizeStockStatus(stockRaw);

    // Görsel URL'lerini bul (birden fazla olabilir)
    final imageUrls = _findImageUrls(fields);

    // Marka ve SKU
    final brand = _findField(fields, _brandAliases);
    final sku = _findField(fields, _skuAliases);

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
      brand: brand.isNotEmpty ? brand : null,
      sku: sku.isNotEmpty ? sku : null,
    );

    return _XmlParseResult(product: product);
  }

  /// Alan eşleme tablosunda değeri bulur.
  String _findField(Map<String, String> fields, Set<String> aliases) {
    for (final alias in aliases) {
      for (final entry in fields.entries) {
        if (_normalizeTagName(entry.key) == alias) {
          return entry.value;
        }
      }
    }
    return '';
  }

  /// Görsel URL'lerini bulur.
  List<String> _findImageUrls(Map<String, String> fields) {
    final urls = <String>[];

    for (final alias in _imageUrlAliases) {
      for (final entry in fields.entries) {
        if (_normalizeTagName(entry.key) == alias) {
          final url = entry.value.trim();
          if (url.isNotEmpty &&
              (url.startsWith('http') || url.startsWith('//'))) {
            urls.add(url);
          }
        }
      }
    }

    return urls.take(4).toList(); // Maksimum 4 görsel
  }

  /// Tag adını normalize eder.
  String _normalizeTagName(String value) {
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

  /// Fiyat string'ini normalize eder.
  String _normalizePrice(String raw) {
    if (raw.isEmpty) return '';
    var normalized =
        raw
            .replaceAll(RegExp(r'\b(TL|TRY|₺|tl|try)\b'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

    if (normalized.isEmpty) return '';

    final lastComma = normalized.lastIndexOf(',');
    final lastDot = normalized.lastIndexOf('.');

    if (lastComma != -1 && lastDot != -1) {
      final decimalSep = lastComma > lastDot ? ',' : '.';
      final thousandsSep = decimalSep == ',' ? '.' : ',';
      normalized = normalized.replaceAll(thousandsSep, '');
      if (decimalSep == ',') {
        normalized = normalized.replaceAll(',', '.');
      }
    } else if (lastComma != -1) {
      final parts = normalized.split(',');
      if (parts.length == 2 && parts.last.length <= 2) {
        normalized = normalized.replaceAll(',', '.');
      } else {
        normalized = normalized.replaceAll(',', '');
      }
    }

    final number = num.tryParse(normalized);
    if (number == null) return raw.trim();
    return number % 1 == 0
        ? number.toInt().toString()
        : number.toStringAsFixed(2);
  }

  /// Stok durumunu normalize eder.
  String _normalizeStockStatus(String raw) {
    final lower = raw.toLowerCase();
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

  // ─── ALIAS TABLOLARI ─────────────────────────────────────────

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
    'stok ',
    'stokmiktari',
    'stok miktarı',
    'adet',
    'quantity',
    'miktar',
    'stok bilgisi',
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
    'gorsel1',
    'gorsel2',
    'gorsel3',
    'image1',
    'image2',
    'foto1',
    'foto2',
    'resim1',
    'resim2',
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

  static const _skuAliases = {
    'sku',
    'stokkodu',
    'stok kodu',
    'barkod',
    'kod',
    'productcode',
    'urunkodu',
    'urun kodu',
  };
}

// ─── SONUÇ MODELLERİ ────────────────────────────────────────────

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

// ─── YÜKLEME SONUÇ MODELLERİ ────────────────────────────────────

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
