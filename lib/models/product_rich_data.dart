class ProductAttributeValue {
  final String key;
  final String? label;
  final Object value;
  final String? unit;
  final String? section;

  const ProductAttributeValue({
    required this.key,
    required this.value,
    this.label,
    this.unit,
    this.section,
  });

  factory ProductAttributeValue.fromJson(Map<String, dynamic> json) {
    return ProductAttributeValue(
      key: (json['key'] ?? '').toString().trim(),
      label: _cleanString(json['label']),
      value: _normalizeAttributeValue(json['value']),
      unit: _cleanString(json['unit']),
      section: _cleanString(json['section']),
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    if (label != null) 'label': label,
    'value': value,
    if (unit != null) 'unit': unit,
    if (section != null) 'section': section,
  };
}

class ProductServiceMetadata {
  final String? serviceType;
  final String? priceMode;
  final int? durationMinutes;
  final String? serviceLocation;
  final bool? appointmentRequired;
  final List<String> included;

  const ProductServiceMetadata({
    this.serviceType,
    this.priceMode,
    this.durationMinutes,
    this.serviceLocation,
    this.appointmentRequired,
    this.included = const [],
  });

  factory ProductServiceMetadata.fromJson(Map<String, dynamic> json) {
    final duration = json['durationMinutes'];
    final parsedDuration = duration is num ? duration.toInt() : null;
    return ProductServiceMetadata(
      serviceType: _cleanString(json['serviceType']),
      priceMode: _allowedValue(json['priceMode'], const {
        'fixed',
        'starting_from',
        'ask',
      }),
      durationMinutes:
          parsedDuration != null && parsedDuration >= 0 ? parsedDuration : null,
      serviceLocation: _allowedValue(json['serviceLocation'], const {
        'business',
        'customer',
        'remote',
      }),
      appointmentRequired:
          json['appointmentRequired'] is bool
              ? json['appointmentRequired'] as bool
              : null,
      included: _cleanStringList(json['included']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (serviceType != null) 'serviceType': serviceType,
    if (priceMode != null) 'priceMode': priceMode,
    if (durationMinutes != null) 'durationMinutes': durationMinutes,
    if (serviceLocation != null) 'serviceLocation': serviceLocation,
    if (appointmentRequired != null)
      'appointmentRequired': appointmentRequired,
    if (included.isNotEmpty) 'included': included,
  };
}

class ProductRichMetadata {
  final int schemaVersion;
  final String itemKind;
  final String? templateKey;
  final String? sku;
  final String? mpn;
  final List<ProductAttributeValue> attributes;
  final ProductServiceMetadata? service;

  const ProductRichMetadata({
    this.schemaVersion = 1,
    this.itemKind = 'physical',
    this.templateKey,
    this.sku,
    this.mpn,
    this.attributes = const [],
    this.service,
  });

  bool get isService => itemKind == 'service';

  factory ProductRichMetadata.fromJson(Object? raw) {
    if (raw is! Map) return const ProductRichMetadata();
    final json = Map<String, dynamic>.from(raw);
    final identifiersRaw = json['identifiers'];
    final identifiers =
        identifiersRaw is Map
            ? Map<String, dynamic>.from(identifiersRaw)
            : const <String, dynamic>{};
    final rawAttributes = json['attributes'];
    final attributes = <ProductAttributeValue>[];
    if (rawAttributes is List) {
      for (final item in rawAttributes.take(100)) {
        if (item is! Map) continue;
        final normalized = ProductAttributeValue.fromJson(
          Map<String, dynamic>.from(item),
        );
        if (normalized.key.isEmpty) continue;
        attributes.add(normalized);
      }
    }
    final rawService = json['service'];
    return ProductRichMetadata(
      schemaVersion:
          json['schemaVersion'] is num
              ? (json['schemaVersion'] as num).toInt()
              : 1,
      itemKind: json['itemKind'] == 'service' ? 'service' : 'physical',
      templateKey: _cleanString(json['templateKey']),
      sku: _cleanString(identifiers['sku']),
      mpn: _cleanString(identifiers['mpn']),
      attributes: attributes,
      service:
          rawService is Map
              ? ProductServiceMetadata.fromJson(
                Map<String, dynamic>.from(rawService),
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'itemKind': itemKind,
    if (templateKey != null) 'templateKey': templateKey,
    if (sku != null || mpn != null)
      'identifiers': {
        if (sku != null) 'sku': sku,
        if (mpn != null) 'mpn': mpn,
      },
    if (attributes.isNotEmpty)
      'attributes': attributes.map((item) => item.toJson()).toList(),
    if (service != null) 'service': service!.toJson(),
  };
}

class ProductVariantData {
  final String id;
  final Map<String, String> options;
  final String? sku;
  final String? barcode;
  final double? priceAmount;
  final int? stockQuantity;
  final String? stockStatus;
  final List<String> imageUrls;

  const ProductVariantData({
    required this.id,
    required this.options,
    this.sku,
    this.barcode,
    this.priceAmount,
    this.stockQuantity,
    this.stockStatus,
    this.imageUrls = const [],
  });

  factory ProductVariantData.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final options = <String, String>{};
    if (rawOptions is Map) {
      for (final entry in rawOptions.entries) {
        final key = entry.key.toString().trim();
        final value = entry.value?.toString().trim() ?? '';
        if (key.isNotEmpty && value.isNotEmpty) options[key] = value;
      }
    }
    final price = json['priceAmount'];
    final stock = json['stockQuantity'];
    return ProductVariantData(
      id: (json['id'] ?? '').toString().trim(),
      options: options,
      sku: _cleanString(json['sku']),
      barcode: _cleanString(json['barcode']),
      priceAmount:
          price is num && price >= 0 ? price.toDouble() : null,
      stockQuantity:
          stock is num && stock >= 0 ? stock.toInt() : null,
      stockStatus: _cleanString(json['stockStatus']),
      imageUrls: _cleanStringList(json['imageUrls']).take(11).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'options': options,
    if (sku != null) 'sku': sku,
    if (barcode != null) 'barcode': barcode,
    if (priceAmount != null) 'priceAmount': priceAmount,
    if (stockQuantity != null) 'stockQuantity': stockQuantity,
    if (stockStatus != null) 'stockStatus': stockStatus,
    if (imageUrls.isNotEmpty) 'imageUrls': imageUrls,
  };
}

List<ProductVariantData> parseProductVariants(Object? raw) {
  if (raw is! List) return const [];
  final variants = <ProductVariantData>[];
  for (final item in raw.take(100)) {
    if (item is! Map) continue;
    final variant = ProductVariantData.fromJson(Map<String, dynamic>.from(item));
    if (variant.id.isEmpty || variant.options.isEmpty) continue;
    variants.add(variant);
  }
  return variants;
}

String? _cleanString(Object? value) {
  if (value is! String) return null;
  final clean = value.trim();
  return clean.isEmpty ? null : clean;
}

String? _allowedValue(Object? value, Set<String> allowed) {
  final clean = _cleanString(value);
  return clean != null && allowed.contains(clean) ? clean : null;
}

List<String> _cleanStringList(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .take(50)
      .toList();
}

Object _normalizeAttributeValue(Object? value) {
  if (value is bool || value is num) return value!;
  if (value is List) return _cleanStringList(value);
  return value?.toString().trim() ?? '';
}
