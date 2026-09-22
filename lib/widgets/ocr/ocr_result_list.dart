import 'package:flutter/material.dart';
import 'package:vixrex/models/detected_product.dart';
import 'package:vixrex/theme/app_colors.dart';

/// OCR sonuç listesi widget'ı.
class OcrResultList extends StatelessWidget {
  final List<DetectedProduct> products;
  final Function(int index) onApprove;
  final Function(int index) onReject;
  final Function(int index)? onEdit;

  const OcrResultList({
    super.key,
    required this.products,
    required this.onApprove,
    required this.onReject,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(
        child: Text(
          'Ürün bulunamadı',
          style: TextStyle(color: AppColors.mutedText),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Dismissible(
          key: Key(product.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => onReject(index),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppColors.radius12),
            ),
            child: const Icon(Icons.delete, color: AppColors.error),
          ),
          child: _buildProductCard(product, index),
        );
      },
    );
  }

  Widget _buildProductCard(DetectedProduct product, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radius12),
        border: Border.all(
          color: product.isApproved ? AppColors.success : AppColors.border,
          width: product.isApproved ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Ürün bilgileri
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                    if (product.brand.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.brand,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      product.category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      product.isInvoiceSource && product.price == null
                          ? 'Satış fiyatı girilmedi'
                          : product.formattedPrice,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color:
                            product.price != null
                                ? AppColors.success
                                : AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      product.confidenceLevel,
                      style: TextStyle(
                        fontSize: 10,
                        color: _getConfidenceColor(product.confidence),
                      ),
                    ),
                  ],
                ),
                if (product.isInvoiceSource) ...[
                  const SizedBox(height: 6),
                  Text(
                    _invoiceSummary(product),
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: AppColors.mutedText,
                    ),
                  ),
                  if (product.issues.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _issueSummary(product.issues),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          // Aksiyon butonları
          IconButton(
            icon: Icon(
              product.isApproved
                  ? Icons.check_circle
                  : Icons.check_circle_outline,
              color:
                  product.isApproved ? AppColors.success : AppColors.mutedText,
            ),
            onPressed: () {
              if (product.isApproved) {
                onReject(index);
              } else {
                onApprove(index);
              }
            },
          ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () => onEdit!(index),
            ),
        ],
      ),
    );
  }

  String _invoiceSummary(DetectedProduct product) {
    final parts = <String>[];
    final sku = product.sku?.trim();
    final barcode = product.barcode?.trim();
    final variant = product.variant?.trim();
    final size = product.size?.trim();

    if (sku != null && sku.isNotEmpty) parts.add('Model: $sku');
    if (barcode != null && barcode.isNotEmpty) parts.add('Barkod: $barcode');
    if (variant != null && variant.isNotEmpty) parts.add('Varyant: $variant');
    if (size != null && size.isNotEmpty) parts.add('Beden: $size');
    if (product.documentQuantity != null) {
      parts.add('Adet: ${product.documentQuantity}');
    }
    if (product.purchaseUnitPrice != null) {
      parts.add('Alış: ${product.purchaseUnitPrice!.toStringAsFixed(2)} TL');
    }
    if (product.lineTotal != null) {
      parts.add('Tutar: ${product.lineTotal!.toStringAsFixed(2)} TL');
    }
    return parts.join(' · ');
  }

  String _issueSummary(List<String> issues) {
    final labels = <String>[];
    for (final issue in issues) {
      switch (issue) {
        case 'INVALID_BARCODE_CHECK_DIGIT':
          labels.add('Barkod doğrulanamadı');
          break;
        case 'QUANTITY_MISSING':
          labels.add('Adet okunamadı');
          break;
        case 'PURCHASE_PRICE_MISSING':
          labels.add('Alış fiyatı okunamadı');
          break;
        case 'LINE_TOTAL_MISSING':
          labels.add('Satır toplamı okunamadı');
          break;
        case 'ARITHMETIC_MISMATCH':
          labels.add('Adet × alış fiyatı toplamla uyuşmuyor');
          break;
        default:
          labels.add('Kontrol gerekli');
          break;
      }
    }
    return labels.toSet().join(' · ');
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.85) return AppColors.success;
    if (confidence >= 0.60) return const Color(0xFFF59E0B); // Amber/warning
    return AppColors.error;
  }
}
