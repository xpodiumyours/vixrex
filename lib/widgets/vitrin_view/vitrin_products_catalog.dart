import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vitrinx/config/app_router.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/services/store_publish_service.dart';
import 'package:vitrinx/theme/vitrin_theme_preset.dart';
import 'package:vitrinx/utils/whatsapp_link_helper.dart';
import 'package:vitrinx/widgets/vitrin_product_card.dart';

class VitrinProductsCatalog extends StatelessWidget {
  final StoreData storeData;
  final VitrinThemePreset preset;
  final bool isEmbedded;
  final bool publicMode;
  final Future<void> Function(BuildContext context, String? url)
  onOpenExternalUrl;

  const VitrinProductsCatalog({
    super.key,
    required this.storeData,
    required this.preset,
    required this.isEmbedded,
    required this.publicMode,
    required this.onOpenExternalUrl,
  });

  @override
  Widget build(BuildContext context) {
    return _VitrinProductsCatalogBody(
      storeData: storeData,
      preset: preset,
      isEmbedded: isEmbedded,
      publicMode: publicMode,
      onOpenExternalUrl: onOpenExternalUrl,
      onOpenProductDetail: _openProductDetail,
    );
  }

  void _openProductDetail(
    BuildContext context,
    Product product,
    int index,
  ) {
    final builder = const StorePublishPayloadBuilder();
    final explicit = product.slug?.trim() ?? '';
    final productSlug =
        explicit.isNotEmpty
            ? builder.generateSlug(explicit)
            : '${builder.generateSlug(product.name)}-${builder.generateSlug(product.id).replaceAll('magazaniz', '${index + 1}')}';
    AppRouter.navigateToPublicProduct(
      context,
      storeSlug: storeData.slug,
      productSlug: productSlug,
    );
  }
}

class _VitrinProductsCatalogBody extends StatefulWidget {
  final StoreData storeData;
  final VitrinThemePreset preset;
  final bool isEmbedded;
  final bool publicMode;
  final Future<void> Function(BuildContext context, String? url)
  onOpenExternalUrl;
  final void Function(BuildContext context, Product product, int index)
  onOpenProductDetail;

  const _VitrinProductsCatalogBody({
    required this.storeData,
    required this.preset,
    required this.isEmbedded,
    required this.publicMode,
    required this.onOpenExternalUrl,
    required this.onOpenProductDetail,
  });

  @override
  State<_VitrinProductsCatalogBody> createState() =>
      _VitrinProductsCatalogBodyState();
}

class _VitrinProductsCatalogBodyState extends State<_VitrinProductsCatalogBody> {
  static const int _pageSize = 12;

  String _selectedCategory = '';
  int _visibleLimit = _pageSize;

  @override
  Widget build(BuildContext context) {
    final preset = widget.preset;
    final isCompact = widget.isEmbedded;
    final allProducts =
        widget.storeData.products.where((product) => product.isVisible).toList();
    final categories = <String>[];

    for (final product in allProducts) {
      final label = product.category.trim();
      if (label.isNotEmpty &&
          !categories.any((item) => item.toLowerCase() == label.toLowerCase())) {
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
          color: preset.surface.withValues(alpha: preset.isDark ? 0.9 : 0.98),
          borderRadius: BorderRadius.circular(isCompact ? 16 : 22),
          border: Border.all(
            color: preset.border.withValues(alpha: preset.isDark ? 0.9 : 0.78),
            width: isCompact ? 1 : 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: preset.isDark ? 0.12 : 0.045,
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
                  color: preset.accent,
                  size: isCompact ? 18 : 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ÃœrÃ¼nler',
                    style: TextStyle(
                      color: preset.textPrimary,
                      fontSize: isCompact ? 14 : 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
            if (categories.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final label = isAll ? 'Hepsi' : categories[index - 1];
                    final isSelected =
                        isAll
                            ? _selectedCategory.isEmpty
                            : _selectedCategory.toLowerCase() ==
                                label.toLowerCase();

                    return ChoiceChip(
                      showCheckmark: false,
                      backgroundColor: preset.surfaceSoft,
                      selectedColor: preset.accent,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color:
                            isSelected ? preset.buttonText : preset.textPrimary,
                      ),
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = isAll ? '' : label;
                          _visibleLimit = _pageSize;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (allProducts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: preset.surfaceSoft.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: preset.border.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      color: preset.accent,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ÃœrÃ¼nler yakÄ±nda',
                      style: TextStyle(
                        color: preset.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MaÄŸaza sahibi henÃ¼z Ã¼rÃ¼n eklemedi.',
                      style: TextStyle(
                        color: preset.textSecondary,
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
                        return _buildProductCard(
                          context,
                          product,
                          allProducts.indexOf(product),
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
                                child: _buildProductCard(
                                  context,
                                  product,
                                  allProducts.indexOf(product),
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
                  onPressed: () {
                    setState(() {
                      _visibleLimit += _pageSize;
                    });
                  },
                  icon: const Icon(Icons.expand_more_rounded),
                  label: const Text('Daha fazla gÃ¶ster'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product, int index) {
    return VitrinProductCard(
      name: product.name,
      price: product.price,
      category: product.category,
      description: product.description,
      imagePath: product.primaryImageUrl,
      stockStatus: product.stockStatus,
      onTap:
          widget.publicMode
              ? () => widget.onOpenProductDetail(context, product, index)
              : null,
      onWhatsAppTap: () {
        if (!widget.publicMode) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "MÃ¼ÅŸteriler bu karta bastÄ±ÄŸÄ±nda '${product.name}' hakkÄ±nda WhatsApp'tan bilgi isteyebilir.",
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
          unawaited(widget.onOpenExternalUrl(context, url));
        }
      },
    );
  }
}
