import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/theme/vitrin_theme_preset.dart';
import 'package:vitrinx/utils/whatsapp_link_helper.dart';
import 'package:vitrinx/widgets/vitrin_product_card.dart';

class ProductCatalogBlock extends StatefulWidget {
  const ProductCatalogBlock({
    required this.preset,
    required this.radius,
    required this.storeData,
    required this.publicMode,
    required this.isEmbedded,
    required this.onExternalUrl,
    required this.onProductDetail,
  });

  final VitrinThemePreset preset;
  final double radius;
  final StoreData storeData;
  final bool publicMode;
  final bool isEmbedded;
  final Future<void> Function(BuildContext, String?) onExternalUrl;
  final void Function(BuildContext, Product, int) onProductDetail;

  @override
  State<ProductCatalogBlock> createState() => _ProductCatalogBlockState();
}

class _ProductCatalogBlockState extends State<ProductCatalogBlock> {
  String _selectedCategory = '';
  int _visibleLimit = 12;

  void _onProductWhatsAppTap(BuildContext context, Product product) {
    if (!widget.publicMode) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Müşteriler bu karta bastığında '${product.name}' hakkında WhatsApp'tan bilgi isteyebilir.",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final url = WhatsAppLinkHelper.buildInquiryUrl(
      number: widget.storeData.whatsapp,
      storeName: widget.storeData.name,
      itemTitle: product.name,
    );
    if (url != null) {
      unawaited(widget.onExternalUrl(context, url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = widget.isEmbedded;
    final allProducts =
        widget.storeData.products
            .where((product) => product.isVisible)
            .toList();

    final categories = <String>[];
    for (final product in allProducts) {
      final label = product.category.trim();
      if (label.isNotEmpty &&
          !categories.any(
            (item) => item.toLowerCase() == label.toLowerCase(),
          )) {
        categories.add(label);
      }
    }
    final filteredProducts =
        _selectedCategory.isEmpty
            ? allProducts
            : allProducts
                .where(
                  (product) =>
                      product.category.trim().toLowerCase() ==
                      _selectedCategory.toLowerCase(),
                )
                .toList();
    final visibleProducts = filteredProducts.take(_visibleLimit).toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 18 : 24),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isCompact ? 14 : 18),
        decoration: BoxDecoration(
          color: widget.preset.surface.withValues(
            alpha: widget.preset.isDark ? 0.9 : 0.98,
          ),
          borderRadius: BorderRadius.circular(isCompact ? 16 : 22),
          border: Border.all(
            color: widget.preset.border.withValues(
              alpha: widget.preset.isDark ? 0.9 : 0.78,
            ),
            width: isCompact ? 1 : 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: widget.preset.isDark ? 0.12 : 0.045,
              ),
              blurRadius: isCompact ? 12 : 24,
              offset: Offset(0, isCompact ? 3 : 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shopping_bag_rounded,
                  color: widget.preset.accent,
                  size: isCompact ? 18 : 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ürünler',
                    style: TextStyle(
                      color: widget.preset.textPrimary,
                      fontSize: isCompact ? 14 : 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (filteredProducts.length > visibleProducts.length)
                  Text(
                    '+${filteredProducts.length - visibleProducts.length}',
                    style: TextStyle(
                      color: widget.preset.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (categories.length > 1) ...[
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ChoiceChip(
                      label: const Text('Tümü'),
                      selected: _selectedCategory.isEmpty,
                      onSelected:
                          (_) => setState(() {
                            _selectedCategory = '';
                            _visibleLimit = 12;
                          }),
                    ),
                    const SizedBox(width: 8),
                    ...categories.map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: _selectedCategory == category,
                          onSelected:
                              (_) => setState(() {
                                _selectedCategory = category;
                                _visibleLimit = 12;
                              }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (allProducts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: widget.preset.surfaceSoft.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.preset.border.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      color: widget.preset.accent,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ürünler yakında',
                      style: TextStyle(
                        color: widget.preset.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mağaza sahibi henüz ürün eklemedi.',
                      style: TextStyle(
                        color: widget.preset.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 620;
                  if (!isWide) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: visibleProducts.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.64,
                          ),
                      itemBuilder: (context, index) {
                        final product = visibleProducts[index];
                        return VitrinProductCard(
                          name: product.name,
                          price: product.price,
                          category: product.category,
                          description: product.description,
                          imagePath: product.primaryImageUrl,
                          stockStatus: product.stockStatus,
                          onTap:
                              widget.publicMode
                                  ? () => widget.onProductDetail(
                                    context,
                                    product,
                                    allProducts.indexOf(product),
                                  )
                                  : null,
                          onWhatsAppTap:
                              () => _onProductWhatsAppTap(context, product),
                        );
                      },
                    );
                  }

                  final columns = constraints.maxWidth >= 1000 ? 4 : 3;
                  final cardWidth =
                      (constraints.maxWidth - (12 * (columns - 1))) / columns;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children:
                        visibleProducts
                            .map(
                              (product) => SizedBox(
                                width: cardWidth,
                                height: 250,
                                child: VitrinProductCard(
                                  name: product.name,
                                  price: product.price,
                                  category: product.category,
                                  description: product.description,
                                  imagePath: product.primaryImageUrl,
                                  stockStatus: product.stockStatus,
                                  onTap:
                                      widget.publicMode
                                          ? () => widget.onProductDetail(
                                            context,
                                            product,
                                            allProducts.indexOf(product),
                                          )
                                          : null,
                                  onWhatsAppTap:
                                      () => _onProductWhatsAppTap(
                                        context,
                                        product,
                                      ),
                                ),
                              ),
                            )
                            .toList(),
                  );
                },
              ),
            if (filteredProducts.length > visibleProducts.length) ...[
              const SizedBox(height: 14),
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _visibleLimit += 12),
                  icon: const Icon(Icons.expand_more_rounded),
                  label: const Text('Daha fazla göster'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ShelfGalleryCard — extracted StatefulWidget for the gallery shelf card
// ---------------------------------------------------------------------------
