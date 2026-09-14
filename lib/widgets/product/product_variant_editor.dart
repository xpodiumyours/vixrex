import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:vixrex/models/product_rich_data.dart';
import 'package:vixrex/services/product_attribute_schema_service.dart';
import 'package:vixrex/services/product_image_policy.dart';
import 'package:vixrex/theme/app_colors.dart';

class ProductVariantImageChoice {
  const ProductVariantImageChoice({
    required this.reference,
    this.url,
    this.bytes,
  });

  final String reference;
  final String? url;
  final Uint8List? bytes;
}

Future<List<ProductVariantData>> sanitizeProductVariantsForTemplate(
  String templateKey,
  List<ProductVariantData> variants, {
  Set<String>? availableImageUrls,
}) async {
  final schema = await const ProductAttributeSchemaService().load();
  final template = schema.templateByKey(templateKey);
  if (template.isService) return const [];

  final allowedKeys =
      schema
          .attributesForTemplate(template.key)
          .where((definition) => definition.variantEligible)
          .map((definition) => definition.key)
          .toSet();

  List<String> cleanImages(ProductVariantData variant) {
    final seen = <String>{};
    return variant.imageUrls
        .map((url) => url.trim())
        .where(
          (url) =>
              url.isNotEmpty &&
              seen.add(url) &&
              (availableImageUrls == null || availableImageUrls.contains(url)),
        )
        .take(ProductImagePolicy.maxImages)
        .toList();
  }

  // Generic/bilinmeyen fiziksel şemada Vixrex varyant anlamı tahmin etmez.
  // Mevcut/import edilmiş seçenekleri korur; verilen galeri varsa görselleri ona sınırlar.
  if (allowedKeys.isEmpty) {
    return variants
        .map(
          (variant) => ProductVariantData(
            id: variant.id,
            options: variant.options,
            sku: variant.sku,
            barcode: variant.barcode,
            priceAmount: variant.priceAmount,
            stockQuantity: variant.stockQuantity,
            stockStatus: variant.stockStatus,
            imageUrls: cleanImages(variant),
          ),
        )
        .toList();
  }

  final result = <ProductVariantData>[];
  for (final variant in variants) {
    final options = <String, String>{};
    for (final entry in variant.options.entries) {
      final key = entry.key.trim();
      final value = entry.value.trim();
      if (allowedKeys.contains(key) && value.isNotEmpty) {
        options[key] = value;
      }
    }
    if (options.isEmpty) continue;
    result.add(
      ProductVariantData(
        id: variant.id,
        options: options,
        sku: variant.sku,
        barcode: variant.barcode,
        priceAmount: variant.priceAmount,
        stockQuantity: variant.stockQuantity,
        stockStatus: variant.stockStatus,
        imageUrls: cleanImages(variant),
      ),
    );
  }
  return result;
}

class ProductVariantEditor extends StatefulWidget {
  const ProductVariantEditor({
    super.key,
    required this.templateKey,
    required this.variants,
    required this.onChanged,
    this.imageChoices = const [],
    this.enabled = true,
  });

  final String templateKey;
  final List<ProductVariantData> variants;
  final ValueChanged<List<ProductVariantData>> onChanged;
  final List<ProductVariantImageChoice> imageChoices;
  final bool enabled;

  @override
  State<ProductVariantEditor> createState() => _ProductVariantEditorState();
}

class _ProductVariantEditorState extends State<ProductVariantEditor> {
  late final Future<ProductAttributeSchema> _schemaFuture =
      const ProductAttributeSchemaService().load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProductAttributeSchema>(
      future: _schemaFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final schema = snapshot.data;
        if (schema == null) return const SizedBox.shrink();
        final template = schema.templateByKey(widget.templateKey);
        if (template.isService) return const SizedBox.shrink();

        final definitions =
            schema
                .attributesForTemplate(template.key)
                .where((definition) => definition.variantEligible)
                .toList();
        if (definitions.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(AppColors.radius16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Varyantlar',
                          style: TextStyle(
                            color: AppColors.darkText,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Renk, beden, RAM veya depolama gibi seçenekleri gerçek stok ve fiyatla bağlayın.',
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: widget.enabled ? _addVariant : null,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Varyant ekle'),
                  ),
                ],
              ),
              if (widget.variants.isEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Varyant yok. Tek seçenekli ürünlerde eklemeniz gerekmez.',
                  style: TextStyle(color: AppColors.mutedText, fontSize: 11),
                ),
              ] else ...[
                const SizedBox(height: 12),
                ...List.generate(
                  widget.variants.length,
                  (index) => Padding(
                    padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
                    child: _buildVariant(index, definitions),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildVariant(
    int index,
    List<ProductAttributeDefinition> definitions,
  ) {
    final variant = widget.variants[index];
    return Container(
      key: ValueKey('variant-card-${variant.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radius14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Varyant ${index + 1}',
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Varyantı sil',
                visualDensity: VisualDensity.compact,
                onPressed: widget.enabled ? () => _removeVariant(index) : null,
                icon: const Icon(Icons.delete_outline_rounded, size: 19),
              ),
            ],
          ),
          ...definitions.map(
            (definition) => Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextFormField(
                key: ValueKey('variant-${variant.id}-${definition.key}'),
                initialValue: variant.options[definition.key] ?? '',
                enabled: widget.enabled,
                decoration: InputDecoration(labelText: definition.label),
                onChanged: (raw) => _updateOption(index, definition.key, raw),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            key: ValueKey('variant-${variant.id}-sku'),
            initialValue: variant.sku ?? '',
            enabled: widget.enabled,
            decoration: const InputDecoration(labelText: 'Varyant SKU'),
            onChanged:
                (raw) => _updateVariant(index, sku: _clean(raw), setSku: true),
          ),
          const SizedBox(height: 10),
          TextFormField(
            key: ValueKey('variant-${variant.id}-barcode'),
            initialValue: variant.barcode ?? '',
            enabled: widget.enabled,
            decoration: const InputDecoration(labelText: 'Varyant barkodu'),
            onChanged:
                (raw) => _updateVariant(
                  index,
                  barcode: _clean(raw),
                  setBarcode: true,
                ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('variant-${variant.id}-price'),
                  initialValue: variant.priceAmount?.toString() ?? '',
                  enabled: widget.enabled,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Varyant fiyatı',
                    hintText: 'Boşsa ana fiyat',
                  ),
                  onChanged:
                      (raw) => _updateVariant(
                        index,
                        priceAmount: _parseAmount(raw),
                        setPriceAmount: true,
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  key: ValueKey('variant-${variant.id}-stock'),
                  initialValue: variant.stockQuantity?.toString() ?? '',
                  enabled: widget.enabled,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stok adedi'),
                  onChanged: (raw) {
                    final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
                    _updateVariant(
                      index,
                      stockQuantity:
                          cleaned.isEmpty ? null : int.tryParse(cleaned),
                      setStockQuantity: true,
                    );
                  },
                ),
              ),
            ],
          ),
          if (widget.imageChoices.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Varyant fotoğrafları',
              style: TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Bu varyant seçilince önce seçtiğiniz ürün fotoğrafları gösterilir.',
              style: TextStyle(color: AppColors.mutedText, fontSize: 10),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 58,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.imageChoices.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, imageIndex) {
                  final choice = widget.imageChoices[imageIndex];
                  final selected = variant.imageUrls.contains(choice.reference);
                  return InkWell(
                    key: ValueKey(
                      'variant-${variant.id}-image-${choice.reference}',
                    ),
                    onTap:
                        widget.enabled
                            ? () => _toggleVariantImage(index, choice.reference)
                            : null,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              selected ? AppColors.primary : AppColors.border,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildImageChoice(choice),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageChoice(ProductVariantImageChoice choice) {
    final bytes = choice.bytes;
    if (bytes != null) {
      return Image.memory(bytes, fit: BoxFit.cover);
    }
    final url = choice.url?.trim() ?? '';
    if (url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) => const Center(
              child: Icon(Icons.broken_image_outlined, size: 18),
            ),
      );
    }
    return const Center(child: Icon(Icons.image_outlined, size: 18));
  }

  void _addVariant() {
    if (!widget.enabled) return;
    final id = 'variant-${DateTime.now().microsecondsSinceEpoch}';
    widget.onChanged([
      ...widget.variants,
      ProductVariantData(id: id, options: const {}),
    ]);
  }

  void _removeVariant(int index) {
    final next = List<ProductVariantData>.of(widget.variants)..removeAt(index);
    widget.onChanged(next);
  }

  void _updateOption(int index, String key, String raw) {
    final variant = widget.variants[index];
    final options = Map<String, String>.of(variant.options);
    final value = raw.trim();
    if (value.isEmpty) {
      options.remove(key);
    } else {
      options[key] = value;
    }
    _replace(index, _copyVariant(variant, options: options));
  }

  void _toggleVariantImage(int index, String reference) {
    final variant = widget.variants[index];
    final images = List<String>.of(variant.imageUrls);
    if (images.contains(reference)) {
      images.remove(reference);
    } else if (images.length < ProductImagePolicy.maxImages) {
      images.add(reference);
    }
    _replace(
      index,
      _copyVariant(variant, imageUrls: images, setImageUrls: true),
    );
  }

  void _updateVariant(
    int index, {
    String? sku,
    bool setSku = false,
    String? barcode,
    bool setBarcode = false,
    double? priceAmount,
    bool setPriceAmount = false,
    int? stockQuantity,
    bool setStockQuantity = false,
  }) {
    final variant = widget.variants[index];
    _replace(
      index,
      _copyVariant(
        variant,
        sku: sku,
        setSku: setSku,
        barcode: barcode,
        setBarcode: setBarcode,
        priceAmount: priceAmount,
        setPriceAmount: setPriceAmount,
        stockQuantity: stockQuantity,
        setStockQuantity: setStockQuantity,
      ),
    );
  }

  void _replace(int index, ProductVariantData variant) {
    final next = List<ProductVariantData>.of(widget.variants);
    next[index] = variant;
    widget.onChanged(next);
  }

  ProductVariantData _copyVariant(
    ProductVariantData source, {
    Map<String, String>? options,
    String? sku,
    bool setSku = false,
    String? barcode,
    bool setBarcode = false,
    double? priceAmount,
    bool setPriceAmount = false,
    int? stockQuantity,
    bool setStockQuantity = false,
    List<String>? imageUrls,
    bool setImageUrls = false,
  }) {
    return ProductVariantData(
      id: source.id,
      options: options ?? source.options,
      sku: setSku ? sku : source.sku,
      barcode: setBarcode ? barcode : source.barcode,
      priceAmount: setPriceAmount ? priceAmount : source.priceAmount,
      stockQuantity: setStockQuantity ? stockQuantity : source.stockQuantity,
      stockStatus: source.stockStatus,
      imageUrls: setImageUrls ? imageUrls ?? const [] : source.imageUrls,
    );
  }

  double? _parseAmount(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    final value = double.tryParse(normalized);
    return value != null && value >= 0 ? value : null;
  }

  String? _clean(String raw) {
    final value = raw.trim();
    return value.isEmpty ? null : value;
  }
}
