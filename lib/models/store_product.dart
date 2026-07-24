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
  String description;
  String? imagePath;
  List<String> imageUrls;
  String categoryId;
  String category;
  String stockStatus; // 'Mevcut', 'Tükendi', 'Son birkaç adet'
  bool isVisible;
  String? slug;
  String? source;
  String? sourceMediaId;
  String? sourcePermalink;
  String? importedAt;
  String? brand;
  String? barcode;
  int? vatRate;
  List<ProductVariant> variants;

  Product({
    required this.id,
    this.name = '',
    this.price = '',
    this.description = '',
    this.imagePath,
    List<String>? imageUrls,
    this.categoryId = '',
    this.category = 'Tümü',
    this.stockStatus = 'Mevcut',
    this.isVisible = true,
    this.slug,
    this.source,
    this.sourceMediaId,
    this.sourcePermalink,
    this.importedAt,
    this.brand,
    this.barcode,
    this.vatRate,
    List<ProductVariant>? variants,
  })  : imageUrls = _normalizeImageUrls(imageUrls, imagePath),
        variants = variants ?? [];

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

    if (vatRate != null) json['vatRate'] = vatRate;
    if (variants.isNotEmpty) {
      json['variants'] = variants.map((v) => v.toJson()).toList();
    }

    return json;
  }

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: (json['id'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
    price: (json['price'] ?? '').toString(),
    description: (json['description'] ?? '').toString(),
    imagePath: (json['imagePath'] ?? json['image_path']) as String?,
    imageUrls:
        ((json['imageUrls'] ?? json['image_urls']) as List?)
            ?.map((item) => item.toString())
            .toList(),
    categoryId: (json['categoryId'] ?? json['category_id'] ?? '').toString(),
    category: (json['category'] ?? 'Tümü').toString(),
    stockStatus:
        (json['stockStatus'] ?? json['stock_status'] ?? StockStatus.available.label).toString(),
    isVisible: (json['isVisible'] ?? json['is_visible'] ?? true) as bool,
    slug:
        (json['slug'] ?? '').toString().trim().isEmpty
            ? null
            : json['slug'].toString(),
    source:
        (json['source'] ?? '').toString().trim().isEmpty
            ? null
            : json['source'].toString(),
    sourceMediaId:
        (json['sourceMediaId'] ?? json['source_media_id'] ?? '')
                .toString()
                .trim()
                .isEmpty
            ? null
            : (json['sourceMediaId'] ?? json['source_media_id']).toString(),
    sourcePermalink:
        (json['sourcePermalink'] ?? json['source_permalink'] ?? '')
                .toString()
                .trim()
                .isEmpty
            ? null
            : (json['sourcePermalink'] ?? json['source_permalink']).toString(),
    importedAt:
        (json['importedAt'] ?? json['imported_at'] ?? '')
                .toString()
                .trim()
                .isEmpty
            ? null
            : (json['importedAt'] ?? json['imported_at']).toString(),
    brand: (json['brand'] ?? '').toString().trim().isEmpty
        ? null
        : json['brand'].toString(),
    barcode: (json['barcode'] ?? '').toString().trim().isEmpty
        ? null
        : json['barcode'].toString(),
    vatRate: json['vat_rate'] != null
        ? int.tryParse(json['vat_rate'].toString())
        : json['vatRate'] != null
            ? int.tryParse(json['vatRate'].toString())
            : null,
    variants: (json['variants'] as List?)
        ?.map((item) => ProductVariant.fromJson(item as Map<String, dynamic>))
        .toList(),
  );

  Product copyWith({
    String? id,
    String? name,
    String? price,
    String? description,
    String? imagePath,
    List<String>? imageUrls,
    String? categoryId,
    String? category,
    String? stockStatus,
    bool? isVisible,
    String? slug,
    String? source,
    String? sourceMediaId,
    String? sourcePermalink,
    String? importedAt,
    String? brand,
    String? barcode,
    int? vatRate,
    List<ProductVariant>? variants,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      imageUrls: imageUrls ?? List.of(this.imageUrls),
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      stockStatus: stockStatus ?? this.stockStatus,
      isVisible: isVisible ?? this.isVisible,
      slug: slug ?? this.slug,
      source: source ?? this.source,
      sourceMediaId: sourceMediaId ?? this.sourceMediaId,
      sourcePermalink: sourcePermalink ?? this.sourcePermalink,
      importedAt: importedAt ?? this.importedAt,
      brand: brand ?? this.brand,
      barcode: barcode ?? this.barcode,
      vatRate: vatRate ?? this.vatRate,
      variants: variants ?? List.of(this.variants),
    );
  }
}

class ProductVariant {
  String? name;
  String? sku;
  String? price;
  int? stock;
  Map<String, String>? attributes;

  ProductVariant({
    this.name,
    this.sku,
    this.price,
    this.stock,
    this.attributes,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (name != null) json['name'] = name;
    if (sku != null) json['sku'] = sku;
    if (price != null) json['price'] = price;
    if (stock != null) json['stock'] = stock;
    if (attributes != null) json['attributes'] = attributes;
    return json;
  }

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
        name: json['name']?.toString(),
        sku: json['sku']?.toString(),
        price: json['price']?.toString(),
        stock: json['stock'] != null ? int.tryParse(json['stock'].toString()) : null,
        attributes: json['attributes'] != null
            ? Map<String, String>.from(json['attributes'] as Map)
            : null,
      );
}

class ProductCategory {
  String id;
  String name;
  int sortOrder;

  ProductCategory({
    required this.id,
    required this.name,
    this.sortOrder = 0,
  });

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
