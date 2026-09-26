from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]

def source(path):
    return subprocess.check_output(['git', 'show', 'work/product-live-ready-20260914:' + path], cwd=root).decode('utf-8')

def section(text, start, end):
    return text[text.index(start):text.index(end, text.index(start))]

def replace(text, old, new):
    assert old in text, old[:100]
    return text.replace(old, new)

path = 'lib/services/bulk_product_upload_service.dart'
p = root / path
t = p.read_text(encoding='utf-8')
s = source(path)
t = replace(t, "import 'package:vixrex/models/store_product.dart';", "import 'package:vixrex/models/store_product.dart';\nimport 'package:vixrex/models/product_rich_data.dart';\nimport 'package:vixrex/services/product_image_policy.dart';")
old = section(t, '  Map<String, int> _mapColumns', '  String _normalizeHeader')
new = section(s, '  Map<String, int> _mapColumns', '  String _normalizeHeader')
t = replace(t, old, new)
t = replace(t, "RegExp(r'[iiî]')", "RegExp(r'[ıiî]')")
t = replace(t, '  static const _nameAliases', section(s, '  static final _numberedImageHeader', '  static const _nameAliases') + '  static const _nameAliases')
old = section(t, '  static const _barcodeAliases', '  static const _imageUrlAliases')
new = section(s, '  static const _stockQuantityAliases', '  static const _imageUrlAliases')
new = new.replace("{'barkod', 'barcode', 'gtin', 'ean', 'upc'}", "{'barkod', 'barcode', 'gtin', 'ean', 'upc', 'kod'}")
t = replace(t, old, new)
t = replace(t, "'fotoğraf',", "'fotograf',")
old = section(t, '  _RowParseResult _rowToProduct', '  String _cellValue')
new = section(s, '  _RowParseResult _rowToProduct', '  String _cellValue').replace('imagePath: imageUrls.first,', 'imagePath: imageUrls.isEmpty ? null : imageUrls.first,')
t = replace(t, old, new)
old = section(t, '  String _normalizeStockStatus', '  /// Örnek CSV')
new = section(s, '  String _normalizeStockStatus', '  /// Örnek CSV')
t = replace(t, old, new)
t = replace(t, section(t, '  Uint8List generateTemplateCsv()', '\n}\n'), section(s, '  Uint8List generateTemplateCsv()', '\n}\n'))
p.write_text(t, encoding='utf-8')

path = 'lib/services/xml_product_upload_service.dart'
p = root / path
t = p.read_text(encoding='utf-8')
s = source(path)
t = replace(t, "import 'package:uuid/uuid.dart';", "import 'dart:convert';\nimport 'package:uuid/uuid.dart';\nimport 'package:vixrex/services/product_image_policy.dart';")
t = replace(t, 'String.fromCharCodes(response.bodyBytes)', 'utf8.decode(response.bodyBytes)')
t = replace(t, "'image_urls': p.imageUrls.isNotEmpty ? p.imageUrls : [''],", "'image_urls': p.imageUrls,\n                  'category_name': p.category,\n                  'stock_status': p.stockStatus,\n                  'stock_quantity': p.stockQuantity,\n                  'barcode': p.barcode,")
t = replace(t, '    final stockStatus = _normalizeStockStatus(stockRaw);', "    final quantityRaw = _findField(fields, _stockQuantityAliases);\n    final stockQuantity = _normalizeStockQuantity(quantityRaw.isEmpty ? stockRaw : quantityRaw);\n    final stockStatus = stockQuantity == 0 ? StockStatus.soldOut.label : _normalizeStockStatus(stockRaw);")
t = replace(t, '    final sku = _findField(fields, _skuAliases);', '    final sku = _findField(fields, _skuAliases);\n    final barcode = _findField(fields, _barcodeAliases);')
t = replace(t, '      stockStatus: stockStatus,', '      stockStatus: stockStatus,\n      stockQuantity: stockQuantity,\n      barcode: barcode.isEmpty ? null : barcode,')
t = replace(t, section(t, '  String _findField', '  /// Görsel URL'), section(s, '  String _findField', '  List<String> _findImageUrls'))
old = section(t, '  List<String> _findImageUrls', '  /// Tag adını')
new = section(s, '  List<String> _findImageUrls', '  String _normalizeTagName')
new = new.replace('if (urls.length >= ProductImagePolicy.maxImages) break;', '')
new = new.replace('    return urls;', '    return urls; // Maksimum 4 görsel')
t = replace(t, old, new)
t = replace(t, '    final imageUrls = _findImageUrls(fields);', "    final imageUrls = _findImageUrls(fields);\n    final imageError = ProductImagePolicy.validate(imageUrls);\n    if (imageError != null) {\n      return _XmlParseResult(error: XmlParseError(row: rowIndex, message: imageError));\n    }")
t = replace(t, "RegExp(r'[iiî]')", "RegExp(r'[ıiî]')")
t = replace(t, '  static const _nameAliases', section(s, '  int? _normalizeStockQuantity', '  static const _nameAliases') + "  static const _stockQuantityAliases = {'stokadedi', 'stokmiktari', 'stockquantity', 'quantity', 'adet'};\n  static const _barcodeAliases = {'barkod', 'barcode', 'gtin', 'ean', 'upc'};\n\n  static const _nameAliases")
p.write_text(t, encoding='utf-8')

p = root / 'lib/controllers/bulk_product_upload_controller.dart'
t = p.read_text(encoding='utf-8')
s = source('lib/controllers/bulk_product_upload_controller.dart')
t = replace(t, section(t, '  Future<bool> saveProducts', '  // ─── Sıfırlama'), section(s, '  Future<bool> saveProducts', '  // ─── Sıfırlama'))
p.write_text(t, encoding='utf-8')
p = root / 'lib/screens/bulk_product_upload_screen.dart'
t = p.read_text(encoding='utf-8').replace('typedef OnBulkProductsSaved = Future<void>', 'typedef OnBulkProductsSaved = Future<bool>')
p.write_text(t, encoding='utf-8')
p = root / 'lib/widgets/product/product_management_sheet.dart'
t = p.read_text(encoding='utf-8')
t = replace(t, '          setState(() => _products = previousProducts);\n        }\n      },', '          setState(() => _products = previousProducts);\n        }\n        return saved;\n      },')
p.write_text(t, encoding='utf-8')
