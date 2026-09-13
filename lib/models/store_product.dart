enum StockStatus {
  available('Mevcut'),
  soldOut('Tükendi'),
  lowStock('Son birkaç adet');

  final String label;
  const StockStatus(this.label);

  static StockStatus fromString(String value) {
    for (final status in values) {
      if (status.label == value) return status;
    }
    return StockStatus.available;
  }
}

class Product {
  String id;
  String name;
  String price;
  double? priceAmount;
  String description;
  String? imagePath;
  List<String> imageUrls;
  String categoryId;
  String category;
  String stockStatus; // 'Mevcut', 'Tükendi', 'Son birkaç adet'
  int? stockQuantity;
  bool isVisible;
  String? slug;
  String? source;
  String? sourceMediaId;
  String? sourcePermalink;
  String? importedAt;
  String? brand;
  String? barcode;
  String? sku;
  int? vatRate;
  List<Map<String, dynamic>> variants;
  Map<String, dynamic> metadata;
  double? oldPriceAmount;
  String? badgeTag;
  String? fulfillmentLocation;

  Product({
    required this.id,
    this.name = '',
    this.price = '',
    this.priceAmount,
    this.description = '',
    this.imagePath,
    List<String>? imageUrls,
    this.categoryId = '',
    this.category = 'Tümü',
    this.stockStatus = 'Mevcut',
    this.stockQuantity,
    this.isVisible = true,
    this.slug,
    this.source,
    this.sourceMediaId,
    this.sourcePermalink,
    this.importedAt,
    this.brand,
    this.barcode,
    this.sku,
    this.vatRate,
    List<Map<String, dynamic>>? variants,
    Map<String, dynamic>? metadata,
    this.oldPriceAmount,
    this.badgeTag,
    this.fulfillmentLocation,
  }) : imageUrls = _normalizeImageUrls(imageUrls, imagePath),
       variants =
           variants
               ?.map((item) => Map<String, dynamic>.from(item))
               .toList() ??
           <Map<String, dynamic>>[],
       metadata = Map<String, dynamic>.from(metadata ?? const {});

  static List<String> _normalizeImageUrls(
    List<String>? imageUrls,
    String? legacyImagePath,
  ) {
    final values = <String>[
      ...?imageUrls,
      if (legacyImagePath != null) legacyImagePath,
    ];
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .take(4)
        .toList();
  }

  List<String> get displayImageUrls =>
      _normalizeImageUrls(imageUrls, imagePath);

  String? get primaryImageUrl =>
      displayImageUrls.isEmpty ? null : displayImageUrls.first;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'imagePath': primaryImageUrl,
      'imageUrls': displayImageUrls,
      'categoryId': categoryId,
      'category': category,
      'stockStatus': stockStatus,
      'isVisible': isVisible,
    };

    void putOptional(String key, String? value) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        json[key] = trimmed;
      }
    }

    putOptional('slug', slug);
    putOptional('source', source);
    putOptional('sourceMediaId', sourceMediaId);
    putOptional('sourcePermalink', sourcePermalink);
    putOptional('importedAt', importedAt);
    putOptional('brand', brand);
    putOptional('barcode', barcode);
    putOptional('sku', sku);
    putOptional('badgeTag', badgeTag);
    putOptional('fulfillmentLocation', fulfillmentLocation);
    if (priceAmount != null) json['priceAmount'] = priceAmount;
    if (stockQuantity != null) json['stockQuantity'] = stockQuantity;
    if (vatRate != null) json['vatRate'] = vatRate;
    if (variants.isNotEmpty) {
      json['variants'] = variants.map((item) => Map<String, dynamic>.from(item)).toList();
    }
    if (metadata.isNotEmpty) {
      json['metadata'] = Map<String, dynamic>.from(metadata);
    }
    if (oldPriceAmount != null) {
      json['oldPriceAmount'] = oldPriceAmount;
    }

    return json;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final metadataRaw = json['metadata'];
    final metadata =
        metadataRaw is Map
            ? Map<String, dynamic>.from(metadataRaw)
            : <String, dynamic>{};
    final identifiersRaw = metadata['identifiers'];
    final identifiers =
        identifiersRaw is Map
            ? Map<String, dynamic>.from(identifiersRaw)
            : <String, dynamic>{};
    final variantsRaw = json['variants'];
    final variants =
        variantsRaw is List
            ? variantsRaw
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
            : <Map<String, dynamic>>[];

    int? parseIntValue(dynamic value) {
      if (value is int) return value;
      return value == null ? null : int.tryParse(value.toString());
    }

    double? parseDoubleValue(dynamic value) {
      if (value is num) return value.toDouble();
      return value == null ? null : double.tryParse(value.toString());
    }

    String? optionalText(dynamic value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    }

    return Product(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      price: (json['price'] ?? json['price_text'] ?? '').toString(),
      priceAmount: parseDoubleValue(json['priceAmount'] ?? json['price_amount']),
      description: (json['description'] ?? '').toString(),
      imagePath: (json['imagePath'] ?? json['image_path']) as String?,
      imageUrls:
          ((json['imageUrls'] ?? json['image_urls']) as List?)
              ?.map((item) => item.toString())
              .toList(),
      categoryId: (json['categoryId'] ?? json['category_id'] ?? '').toString(),
      category: (json['category'] ?? 'Tümü').toString(),
      stockStatus:
          (json['stockStatus'] ??
                  json['stock_status'] ??
                  StockStatus.available.label)
              .toString(),
      stockQuantity: parseIntValue(
        json['stockQuantity'] ?? json['stock_quantity'],
      ),
      isVisible: (json['isVisible'] ?? json['is_visible'] ?? true) as bool,
      brand: optionalText(json['brand']),
      barcode: optionalText(json['barcode']),
      sku: optionalText(json['sku'] ?? identifiers['sku']),
      vatRate: parseIntValue(json['vatRate'] ?? json['vat_rate']),
      variants: variants,
      metadata: metadata,
      oldPriceAmount: parseDoubleValue(
        json['oldPriceAmount'] ?? json['old_price_amount'],
      ),
      badgeTag: optionalText(json['badgeTag'] ?? json['badge_tag']),
      fulfillmentLocation: optionalText(
        json['fulfillmentLocation'] ?? json['fulfillment_region'],
      ),
      slug: optionalText(json['slug']),
      source: optionalText(json['source']),
      sourceMediaId: optionalText(
        json['sourceMediaId'] ?? json['source_media_id'],
      ),
      sourcePermalink: optionalText(
        json['sourcePermalink'] ?? json['source_permalink'],
      ),
      importedAt: optionalText(json['importedAt'] ?? json['imported_at']),
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? price,
    double? priceAmount,
    String? description,
    String? imagePath,
    List<String>? imageUrls,
    String? categoryId,
    String? category,
    String? stockStatus,
    int? stockQuantity,
    bool? isVisible,
    String? slug,
    String? source,
    String? sourceMediaId,
    String? sourcePermalink,
    String? importedAt,
    String? brand,
    String? barcode,
    String? sku,
    int? vatRate,
    List<Map<String, dynamic>>? variants,
    Map<String, dynamic>? metadata,
    double? oldPriceAmount,
    String? badgeTag,
    String? fulfillmentLocation,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      priceAmount: priceAmount ?? this.priceAmount,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      imageUrls: imageUrls ?? List.of(this.imageUrls),
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      stockStatus: stockStatus ?? this.stockStatus,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isVisible: isVisible ?? this.isVisible,
      slug: slug ?? this.slug,
      source: source ?? this.source,
      sourceMediaId: sourceMediaId ?? this.sourceMediaId,
      sourcePermalink: sourcePermalink ?? this.sourcePermalink,
      importedAt: importedAt ?? this.importedAt,
      brand: brand ?? this.brand,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      vatRate: vatRate ?? this.vatRate,
      variants: variants ?? this.variants,
      metadata: metadata ?? this.metadata,
      oldPriceAmount: oldPriceAmount ?? this.oldPriceAmount,
      badgeTag: badgeTag ?? this.badgeTag,
      fulfillmentLocation: fulfillmentLocation ?? this.fulfillmentLocation,
    );
  }
}

class ProductCategory {
  String id;
  String name;
  int sortOrder;

  ProductCategory({required this.id, required this.name, this.sortOrder = 0});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sortOrder': sortOrder,
  };

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      sortOrder: (json['sortOrder'] ?? json['sort_order'] ?? 0) as int,
    );
  }
}

class MarketplaceLink {
  String id;
  String platform;
  String url;
  String subtitle;

  MarketplaceLink({
    required this.id,
    this.platform = 'Trendyol',
    this.url = '',
    this.subtitle = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'platform': platform,
    'url': url,
    'subtitle': subtitle,
  };

  factory MarketplaceLink.fromJson(Map<String, dynamic> json) =>
      MarketplaceLink(
        id: json['id'] ?? '',
        platform: json['platform'] ?? 'Trendyol',
        url: json['url'] ?? '',
        subtitle: (json['subtitle'] ?? '').toString(),
      );
}
