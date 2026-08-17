import 'package:flutter/material.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/theme/app_colors.dart';

typedef OnPickFile = VoidCallback;
typedef OnEditProduct = Future<void> Function(int index, Product product);
typedef OnRemoveProduct = void Function(int index);

class BulkUploadReviewView extends StatelessWidget {
  final List<Product> products;
  final int errorCount;
  final OnPickFile onPickFile;
  final OnEditProduct onEditProduct;
  final OnRemoveProduct onRemoveProduct;

  const BulkUploadReviewView({
    super.key,
    required this.products,
    required this.errorCount,
    required this.onPickFile,
    required this.onEditProduct,
    required this.onRemoveProduct,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ReviewStats(products: products, onPickFile: onPickFile),
        const SizedBox(height: 10),
        if (errorCount > 0) ...[
          _ErrorsBanner(errorCount: errorCount),
          const SizedBox(height: 10),
        ],
        Expanded(
          child: ListView.separated(
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder:
                (context, index) => _ProductReviewItem(
                  index: index,
                  product: products[index],
                  onEdit: onEditProduct,
                  onRemove: onRemoveProduct,
                ),
          ),
        ),
      ],
    );
  }
}

class _ReviewStats extends StatelessWidget {
  final List<dynamic> products;
  final OnPickFile onPickFile;

  const _ReviewStats({required this.products, required this.onPickFile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _StatItem(value: '${products.length}', label: 'Toplam'),
          const Spacer(),
          TextButton.icon(
            onPressed: onPickFile,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Yeni Dosya', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}

class _ErrorsBanner extends StatelessWidget {
  final int errorCount;

  const _ErrorsBanner({required this.errorCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.error,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$errorCount satırda hata bulundu. Bu satırlar atlandı.',
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductReviewItem extends StatelessWidget {
  final int index;
  final Product product;
  final OnEditProduct onEdit;
  final OnRemoveProduct onRemove;

  const _ProductReviewItem({
    required this.index,
    required this.product,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                p.primaryImageUrl != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        p.primaryImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _productIcon(),
                      ),
                    )
                    : _productIcon(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      p.price.isEmpty ? 'Fiyat yok' : '${p.price} ₺',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color:
                            p.price.isEmpty
                                ? AppColors.mutedText
                                : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      p.category,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => onEdit(index, p),
            icon: const Icon(Icons.edit_rounded, size: 18),
            color: AppColors.mutedText,
            tooltip: 'Düzenle',
          ),
          IconButton(
            onPressed: () => onRemove(index),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: AppColors.error,
            tooltip: 'Kaldır',
          ),
        ],
      ),
    );
  }

  Widget _productIcon() {
    return const Center(
      child: Icon(
        Icons.shopping_bag_outlined,
        color: AppColors.primary,
        size: 22,
      ),
    );
  }
}
