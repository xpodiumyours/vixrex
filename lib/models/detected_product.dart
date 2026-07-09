/// OCR ile tespit edilen ürün.
class DetectedProduct {
  final String id;
  String name;
  String brand;
  String category;
  String? description;
  double? price;
  double? oldPrice;
  int quantity;
  double confidence;
  String source;
  bool isApproved;
  String? databaseEntryId;

  DetectedProduct({
    required this.id,
    required this.name,
    this.brand = '',
    this.category = 'Genel',
    this.description,
    this.price,
    this.oldPrice,
    this.quantity = 1,
    this.confidence = 0.0,
    this.source = 'ocr',
    this.isApproved = false,
    this.databaseEntryId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'category': category,
    'description': description,
    'price': price,
    'oldPrice': oldPrice,
    'quantity': quantity,
    'confidence': confidence,
    'source': source,
    'isApproved': isApproved,
    'databaseEntryId': databaseEntryId,
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
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      source: json['source'] as String? ?? 'ocr',
      isApproved: json['isApproved'] as bool? ?? false,
      databaseEntryId: json['databaseEntryId'] as String?,
    );
  }

  /// Ürünün güvenilirlik seviyesi.
  String get confidenceLevel {
    if (confidence >= 0.85) return 'Yüksek';
    if (confidence >= 0.60) return 'Orta';
    return 'Düşük';
  }

  /// Ürünün fiyat formatı.
  String get formattedPrice {
    if (price == null) return 'Fiyat Yok';
    return '${price!.toStringAsFixed(2)} ₺';
  }
}
