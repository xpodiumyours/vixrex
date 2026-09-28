/// OCR ile tespit edilen ürün.
class DetectedProduct {
  final String id;
  String name;
  String brand;
  String category;
  String? description;

  /// Müşteriye gösterilecek satış fiyatı. Faturadaki alış fiyatı buraya yazılmaz.
  double? price;
  double? oldPrice;

  /// Eski fiş/raf akışları için korunur. Fatura akışında gerçek okunan miktar
  /// [documentQuantity] alanında ayrıca tutulur; okunamadıysa null kalır.
  int quantity;
  int? documentQuantity;

  double confidence;
  String source;
  bool isApproved;
  String? databaseEntryId;

  /// Faturadan görülen ürün kimliği ve varyant bilgileri.
  String? barcode;
  String? sku;
  String? variant;
  String? size;

  /// Yalnız çalışma belleğinde tutulur. Ürün kartının satış fiyatına
  /// otomatik çevrilmez ve Product CORE'a özel alan olarak yazılmaz.
  double? purchaseUnitPrice;
  double? lineTotal;

  /// İnsan kontrolü gerektiren somut doğrulama sorunları.
  List<String> issues;

  DetectedProduct({
    required this.id,
    required this.name,
    this.brand = '',
    this.category = 'Genel',
    this.description,
    this.price,
    this.oldPrice,
    this.quantity = 1,
    this.documentQuantity,
    this.confidence = 0.0,
    this.source = 'ocr',
    this.isApproved = false,
    this.databaseEntryId,
    this.barcode,
    this.sku,
    this.variant,
    this.size,
    this.purchaseUnitPrice,
    this.lineTotal,
    List<String>? issues,
  }) : issues = issues ?? <String>[];

  bool get isInvoiceSource => source == 'ocr_invoice';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'category': category,
    'description': description,
    'price': price,
    'oldPrice': oldPrice,
    'quantity': quantity,
    'documentQuantity': documentQuantity,
    'confidence': confidence,
    'source': source,
    'isApproved': isApproved,
    'databaseEntryId': databaseEntryId,
    'barcode': barcode,
    'sku': sku,
    'variant': variant,
    'size': size,
    'purchaseUnitPrice': purchaseUnitPrice,
    'lineTotal': lineTotal,
    'issues': issues,
  };

  factory DetectedProduct.fromJson(Map<String, dynamic> json) {
    return DetectedProduct(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      category: json['category'] as String? ?? 'Genel',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      oldPrice: (json['oldPrice'] as num?)?.toDouble(),
      quantity: json['quantity'] as int? ?? 1,
      documentQuantity: (json['documentQuantity'] as num?)?.toInt(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      source: json['source'] as String? ?? 'ocr',
      isApproved: json['isApproved'] as bool? ?? false,
      databaseEntryId: json['databaseEntryId'] as String?,
      barcode: json['barcode'] as String?,
      sku: json['sku'] as String?,
      variant: json['variant'] as String?,
      size: json['size'] as String?,
      purchaseUnitPrice: (json['purchaseUnitPrice'] as num?)?.toDouble(),
      lineTotal: (json['lineTotal'] as num?)?.toDouble(),
      issues:
          (json['issues'] as List?)
              ?.map((value) => value.toString())
              .toList() ??
          <String>[],
    );
  }

  /// Ürünün güvenilirlik seviyesi.
  String get confidenceLevel {
    if (confidence >= 0.85) return 'Yüksek';
    if (confidence >= 0.60) return 'Orta';
    return 'Düşük';
  }

  /// Ürünün satış fiyatı formatı.
  String get formattedPrice {
    if (price == null) return 'Fiyat Yok';
    return '${price!.toStringAsFixed(2)} ₺';
  }
}
