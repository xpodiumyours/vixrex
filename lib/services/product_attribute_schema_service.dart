import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ProductAttributeDefinition {
  const ProductAttributeDefinition({
    required this.key,
    required this.label,
    required this.valueType,
    required this.requirement,
    required this.storage,
    required this.display,
    this.options = const [],
    this.variantEligible = false,
  });

  final String key;
  final String label;
  final String valueType;
  final String requirement;
  final String storage;
  final List<String> display;
  final List<String> options;
  final bool variantEligible;

  factory ProductAttributeDefinition.fromJson(Map<String, dynamic> json) {
    return ProductAttributeDefinition(
      key: (json['key'] ?? '').toString().trim(),
      label: (json['label'] ?? '').toString().trim(),
      valueType: (json['valueType'] ?? 'text').toString().trim(),
      requirement: (json['requirement'] ?? 'optional').toString().trim(),
      storage: (json['storage'] ?? 'metadata.attributes').toString().trim(),
      display:
          (json['display'] as List? ?? const [])
              .map((value) => value.toString().trim())
              .where((value) => value.isNotEmpty)
              .toList(),
      options:
          (json['options'] as List? ?? const [])
              .map((value) => value.toString().trim())
              .where((value) => value.isNotEmpty)
              .toList(),
      variantEligible: json['variantEligible'] == true,
    );
  }
}

class ProductAttributeTemplate {
  const ProductAttributeTemplate({
    required this.key,
    required this.label,
    required this.itemKind,
    required this.attributes,
  });

  final String key;
  final String label;
  final String itemKind;
  final List<ProductAttributeDefinition> attributes;

  bool get isService => itemKind == 'service';

  factory ProductAttributeTemplate.fromJson(Map<String, dynamic> json) {
    return ProductAttributeTemplate(
      key: (json['key'] ?? '').toString().trim(),
      label: (json['label'] ?? '').toString().trim(),
      itemKind: json['itemKind'] == 'service' ? 'service' : 'physical',
      attributes:
          (json['attributes'] as List? ?? const [])
              .whereType<Map>()
              .map(
                (item) => ProductAttributeDefinition.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .where((item) => item.key.isNotEmpty)
              .toList(),
    );
  }
}

class ProductAttributeSchema {
  const ProductAttributeSchema({
    required this.version,
    required this.commonPhysicalAttributes,
    required this.commonServiceAttributes,
    required this.templates,
  });

  final int version;
  final List<ProductAttributeDefinition> commonPhysicalAttributes;
  final List<ProductAttributeDefinition> commonServiceAttributes;
  final List<ProductAttributeTemplate> templates;

  ProductAttributeTemplate? templateByKeyOrNull(String? key) {
    final normalized = (key ?? '').trim();
    final lookupKey = normalized.isEmpty ? 'generic' : normalized;
    for (final template in templates) {
      if (template.key == lookupKey) return template;
    }
    return null;
  }

  ProductAttributeTemplate templateByKey(String? key) {
    return templateByKeyOrNull(key) ??
        templates.firstWhere(
          (template) => template.key == 'generic',
          orElse:
              () => const ProductAttributeTemplate(
                key: 'generic',
                label: 'Genel ürün',
                itemKind: 'physical',
                attributes: [],
              ),
        );
  }

  List<ProductAttributeDefinition> attributesForTemplate(String? key) {
    final template = templateByKey(key);
    final common =
        template.isService ? commonServiceAttributes : commonPhysicalAttributes;
    return [...common, ...template.attributes];
  }

  factory ProductAttributeSchema.fromJson(Map<String, dynamic> json) {
    List<ProductAttributeDefinition> parseDefinitions(Object? raw) {
      return (raw as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => ProductAttributeDefinition.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((item) => item.key.isNotEmpty)
          .toList();
    }

    return ProductAttributeSchema(
      version: json['version'] is num ? (json['version'] as num).toInt() : 1,
      commonPhysicalAttributes: parseDefinitions(
        json['commonPhysicalAttributes'],
      ),
      commonServiceAttributes: parseDefinitions(
        json['commonServiceAttributes'],
      ),
      templates:
          (json['templates'] as List? ?? const [])
              .whereType<Map>()
              .map(
                (item) => ProductAttributeTemplate.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .where((item) => item.key.isNotEmpty)
              .toList(),
    );
  }
}

class ProductAttributeSchemaService {
  const ProductAttributeSchemaService();

  /// Yalnızca testler için: şema yüklemeden sabit bir şema döndürür.
  static ProductAttributeSchema? debugSchemaOverride;

  static Future<ProductAttributeSchema>? _cached;

  Future<ProductAttributeSchema> load() {
    final override = debugSchemaOverride;
    if (override != null) {
      return SynchronousFuture<ProductAttributeSchema>(override);
    }
    return _cached ??= _load();
  }

  Future<ProductAttributeSchema> _load() async {
    final source = await rootBundle.loadString(
      'shared/product_attribute_schema.json',
    );
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Ürün alan şeması geçersiz.');
    }
    return ProductAttributeSchema.fromJson(Map<String, dynamic>.from(decoded));
  }
}
