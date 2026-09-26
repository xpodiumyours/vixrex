import 'detected_product.dart';
import 'invoice_product_draft.dart';

/// OCR analizinin tam sonucu.
class OcrCatalogResult {
  final String rawText;
  final List<DetectedProduct> products;
  final List<InvoiceProductDraft> invoiceDrafts;
  final double confidence;
  final DateTime analyzedAt;

  OcrCatalogResult({
    required this.rawText,
    required this.products,
    this.invoiceDrafts = const [],
    required this.confidence,
    DateTime? analyzedAt,
  }) : analyzedAt = analyzedAt ?? DateTime.now();

  OcrCatalogResult.empty()
    : rawText = '',
      products = const [],
      invoiceDrafts = const [],
      confidence = 0.0,
      analyzedAt = DateTime.now();

  bool get isEmpty => products.isEmpty;
  bool get isNotEmpty => !isEmpty;

  int get productCount => products.length;

  List<DetectedProduct> get approvedProducts =>
      products.where((p) => p.isApproved).toList();

  List<DetectedProduct> get unapprovedProducts =>
      products.where((p) => !p.isApproved).toList();

  /// Kategorilere göre grupla.
  Map<String, List<DetectedProduct>> get productsByCategory {
    final map = <String, List<DetectedProduct>>{};
    for (final product in products) {
      map.putIfAbsent(product.category, () => []).add(product);
    }
    return map;
  }

  /// Toplam tutarı hesapla.
  double get totalAmount {
    double total = 0;
    for (final product in products) {
      if (product.price != null) {
        total += product.price! * product.quantity;
      }
    }
    return total;
  }
}
