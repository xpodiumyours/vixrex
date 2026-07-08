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
        return _buildProductCard(product, index);
      },
    );
  }

  Widget _buildProductCard(DetectedProduct product, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: product.isApproved
              ? AppColors.success
              : AppColors.border,
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
                      product.formattedPrice,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: product.price != null
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
              ],
            ),
          ),
          // Aksiyon butonları
          IconButton(
            icon: Icon(
              product.isApproved
                  ? Icons.check_circle
                  : Icons.check_circle_outline,
              color: product.isApproved ? AppColors.success : AppColors.mutedText,
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

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.85) return AppColors.success;
    if (confidence >= 0.60) return const Color(0xFFF59E0B); // Amber/warning
    return AppColors.error;
  }
}
