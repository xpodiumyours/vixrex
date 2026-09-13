import 'package:flutter/material.dart';
import 'package:vixrex/models/product_rich_data.dart';
import 'package:vixrex/services/product_attribute_schema_service.dart';
import 'package:vixrex/theme/app_colors.dart';

class ProductRichEditorValue {
  const ProductRichEditorValue({
    required this.metadata,
    this.brand,
    this.barcode,
    this.stockQuantity,
  });

  final String? brand;
  final String? barcode;
  final int? stockQuantity;
  final ProductRichMetadata metadata;
}

class ProductRichFieldsEditor extends StatefulWidget {
  const ProductRichFieldsEditor({
    super.key,
    required this.templateKey,
    required this.value,
    required this.onChanged,
    this.variantCount = 0,
    this.enabled = true,
  });

  final String templateKey;
  final ProductRichEditorValue value;
  final ValueChanged<ProductRichEditorValue> onChanged;
  final int variantCount;
  final bool enabled;

  @override
  State<ProductRichFieldsEditor> createState() => _ProductRichFieldsEditorState();
}

class _ProductRichFieldsEditorState extends State<ProductRichFieldsEditor> {
  late final Future<ProductAttributeSchema> _schemaFuture =
      const ProductAttributeSchemaService().load();

  static const _optionLabels = <String, String>{
    'new': 'Yeni',
    'used': 'Kullanılmış',
    'refurbished': 'Yenilenmiş',
    'fixed': 'Sabit fiyat',
    'starting_from': 'Başlangıç fiyatı',
    'ask': 'Fiyat sor',
    'business': 'İşletmede',
    'customer': 'Müşterinin adresinde',
    'remote': 'Uzaktan',
  };

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProductAttributeSchema>(
      future: _schemaFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(minHeight: 2),
          );
        }
        final schema = snapshot.data;
        if (schema == null) {
          return const SizedBox.shrink();
        }
        final template = schema.templateByKey(widget.templateKey);
        final definitions = schema.attributesForTemplate(template.key);
        return _buildFields(schema, template, definitions);
      },
    );
  }

  Widget _buildFields(
    ProductAttributeSchema schema,
    ProductAttributeTemplate template,
    List<ProductAttributeDefinition> definitions,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppColors.radius16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ürün detayları',
            style: TextStyle(
              color: AppColors.darkText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${template.label} için ilgili bilgiler gösteriliyor. Bilmediğiniz alanı boş bırakabilirsiniz; Vixrex değer uydurmaz.',
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          if (!template.isService) ...[
            const SizedBox(height: 14),
            TextFormField(
              key: ValueKey('stock-${template.key}'),
              initialValue: widget.value.stockQuantity?.toString() ?? '',
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stok adedi'),
              onChanged: (raw) {
                final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
                _emit(
                  stockQuantity: cleaned.isEmpty ? null : int.tryParse(cleaned),
                  setStockQuantity: true,
                );
              },
            ),
          ],
          ...definitions.map(
            (definition) => Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildDefinition(schema, template, definition),
            ),
          ),
          if (widget.variantCount > 0) ...[
            const SizedBox(height: 14),
            Text(
              'Bu üründe ${widget.variantCount} kayıtlı varyant var. Mevcut varyantlar korunur; varyant düzenleme ayrı adımda açılacak.',
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefinition(
    ProductAttributeSchema schema,
    ProductAttributeTemplate template,
    ProductAttributeDefinition definition,
  ) {
    final current = _displayValue(_readValue(widget.value, definition));
    final label =
        definition.requirement == 'recommended'
            ? '${definition.label} · önerilen'
            : definition.label;

    if (definition.valueType == 'boolean') {
      return DropdownButtonFormField<String>(
        key: ValueKey('${template.key}-${definition.key}'),
        value: current.isEmpty ? null : current,
        decoration: InputDecoration(labelText: label),
        items: const [
          DropdownMenuItem(value: 'true', child: Text('Evet')),
          DropdownMenuItem(value: 'false', child: Text('Hayır')),
        ],
        onChanged:
            widget.enabled
                ? (value) => _writeDefinition(
                  schema,
                  template,
                  definition,
                  value,
                )
                : null,
      );
    }

    if (definition.options.isNotEmpty) {
      return DropdownButtonFormField<String>(
        key: ValueKey('${template.key}-${definition.key}'),
        value: current.isEmpty ? null : current,
        decoration: InputDecoration(labelText: label),
        items:
            definition.options
                .map(
                  (option) => DropdownMenuItem(
                    value: option,
                    child: Text(_optionLabels[option] ?? option),
                  ),
                )
                .toList(),
        onChanged:
            widget.enabled
                ? (value) => _writeDefinition(
                  schema,
                  template,
                  definition,
                  value,
                )
                : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: ValueKey('${template.key}-${definition.key}'),
          initialValue: current,
          enabled: widget.enabled,
          keyboardType:
              definition.valueType == 'number'
                  ? TextInputType.number
                  : TextInputType.text,
          decoration: InputDecoration(
            labelText: label,
            hintText:
                definition.valueType == 'multi'
                    ? 'Virgülle ayırın'
                    : null,
          ),
          onChanged:
              (raw) => _writeDefinition(
                schema,
                template,
                definition,
                raw,
              ),
        ),
        if (definition.variantEligible)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Bu özellik varyant oluşturmak için kullanılabilir.',
              style: TextStyle(color: AppColors.mutedText, fontSize: 10),
            ),
          ),
      ],
    );
  }

  Object? _readValue(
    ProductRichEditorValue value,
    ProductAttributeDefinition definition,
  ) {
    if (definition.storage == 'core.brand') return value.brand;
    if (definition.storage == 'core.barcode') return value.barcode;
    final metadata = value.metadata;
    if (definition.storage == 'metadata.identifiers.sku') return metadata.sku;
    if (definition.storage == 'metadata.identifiers.mpn') return metadata.mpn;
    if (definition.storage == 'metadata.service.serviceType') {
      return metadata.service?.serviceType;
    }
    if (definition.storage == 'metadata.service.priceMode') {
      return metadata.service?.priceMode;
    }
    if (definition.storage == 'metadata.service.durationMinutes') {
      return metadata.service?.durationMinutes;
    }
    if (definition.storage == 'metadata.service.serviceLocation') {
      return metadata.service?.serviceLocation;
    }
    if (definition.storage == 'metadata.service.appointmentRequired') {
      return metadata.service?.appointmentRequired;
    }
    if (definition.storage == 'metadata.service.included') {
      return metadata.service?.included;
    }
    for (final attribute in metadata.attributes) {
      if (attribute.key == definition.key) return attribute.value;
    }
    return null;
  }

  String _displayValue(Object? value) {
    if (value == null) return '';
    if (value is bool) return value ? 'true' : 'false';
    if (value is List) return value.map((item) => item.toString()).join(', ');
    return value.toString();
  }

  void _writeDefinition(
    ProductAttributeSchema schema,
    ProductAttributeTemplate template,
    ProductAttributeDefinition definition,
    String? raw,
  ) {
    if (!widget.enabled) return;
    if (definition.storage == 'core.brand') {
      _emit(brand: _clean(raw), setBrand: true);
      return;
    }
    if (definition.storage == 'core.barcode') {
      _emit(barcode: _clean(raw), setBarcode: true);
      return;
    }

    final base = _metadataForTemplate(schema, template);
    final parsed = _parseValue(definition, raw);
    ProductRichMetadata next;

    if (definition.storage == 'metadata.identifiers.sku') {
      next = _copyMetadata(base, sku: parsed as String?, setSku: true);
    } else if (definition.storage == 'metadata.identifiers.mpn') {
      next = _copyMetadata(base, mpn: parsed as String?, setMpn: true);
    } else if (definition.storage.startsWith('metadata.service.')) {
      next = _withServiceValue(base, definition, parsed);
    } else {
      final attributes = base.attributes
          .where((item) => item.key != definition.key)
          .toList();
      if (_hasValue(parsed)) {
        attributes.add(
          ProductAttributeValue(
            key: definition.key,
            label: definition.label,
            value: parsed!,
          ),
        );
      }
      next = _copyMetadata(base, attributes: attributes);
    }
    _emit(metadata: next);
  }

  ProductRichMetadata _metadataForTemplate(
    ProductAttributeSchema schema,
    ProductAttributeTemplate template,
  ) {
    final allowed =
        schema.attributesForTemplate(template.key).map((item) => item.key).toSet();
    final current = widget.value.metadata;
    return ProductRichMetadata(
      schemaVersion: schema.version,
      itemKind: template.itemKind,
      templateKey: template.key,
      sku: current.sku,
      mpn: current.mpn,
      attributes:
          current.attributes.where((item) => allowed.contains(item.key)).toList(),
      service: template.isService ? current.service : null,
    );
  }

  Object? _parseValue(ProductAttributeDefinition definition, String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    if (definition.valueType == 'number') {
      final parsed = int.tryParse(value);
      return parsed != null && parsed >= 0 ? parsed : null;
    }
    if (definition.valueType == 'boolean') {
      if (value == 'true') return true;
      if (value == 'false') return false;
      return null;
    }
    if (definition.valueType == 'multi') {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return value;
  }

  ProductRichMetadata _withServiceValue(
    ProductRichMetadata metadata,
    ProductAttributeDefinition definition,
    Object? value,
  ) {
    final current = metadata.service ?? const ProductServiceMetadata();
    var serviceType = current.serviceType;
    var priceMode = current.priceMode;
    var durationMinutes = current.durationMinutes;
    var serviceLocation = current.serviceLocation;
    var appointmentRequired = current.appointmentRequired;
    var included = current.included;

    switch (definition.storage) {
      case 'metadata.service.serviceType':
        serviceType = value as String?;
        break;
      case 'metadata.service.priceMode':
        priceMode = value as String?;
        break;
      case 'metadata.service.durationMinutes':
        durationMinutes = value as int?;
        break;
      case 'metadata.service.serviceLocation':
        serviceLocation = value as String?;
        break;
      case 'metadata.service.appointmentRequired':
        appointmentRequired = value as bool?;
        break;
      case 'metadata.service.included':
        included = value is List<String> ? value : const [];
        break;
    }

    return _copyMetadata(
      metadata,
      service: ProductServiceMetadata(
        serviceType: serviceType,
        priceMode: priceMode,
        durationMinutes: durationMinutes,
        serviceLocation: serviceLocation,
        appointmentRequired: appointmentRequired,
        included: included,
      ),
      setService: true,
    );
  }

  ProductRichMetadata _copyMetadata(
    ProductRichMetadata source, {
    String? sku,
    bool setSku = false,
    String? mpn,
    bool setMpn = false,
    List<ProductAttributeValue>? attributes,
    ProductServiceMetadata? service,
    bool setService = false,
  }) {
    return ProductRichMetadata(
      schemaVersion: source.schemaVersion,
      itemKind: source.itemKind,
      templateKey: source.templateKey,
      sku: setSku ? sku : source.sku,
      mpn: setMpn ? mpn : source.mpn,
      attributes: attributes ?? source.attributes,
      service: setService ? service : source.service,
    );
  }

  bool _hasValue(Object? value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is List) return value.isNotEmpty;
    return true;
  }

  String? _clean(String? value) {
    final clean = value?.trim() ?? '';
    return clean.isEmpty ? null : clean;
  }

  void _emit({
    String? brand,
    bool setBrand = false,
    String? barcode,
    bool setBarcode = false,
    int? stockQuantity,
    bool setStockQuantity = false,
    ProductRichMetadata? metadata,
  }) {
    widget.onChanged(
      ProductRichEditorValue(
        brand: setBrand ? brand : widget.value.brand,
        barcode: setBarcode ? barcode : widget.value.barcode,
        stockQuantity:
            setStockQuantity ? stockQuantity : widget.value.stockQuantity,
        metadata: metadata ?? widget.value.metadata,
      ),
    );
  }
}
