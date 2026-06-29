import 'package:flutter/material.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/theme/app_colors.dart';
import 'package:vitrinx/widgets/product/xrex_catalog_assistant_section.dart';

class ProductManagementSheet extends StatelessWidget {
  final List<Product> products;
  final Function(String message) showMessage;

  const ProductManagementSheet({
    super.key,
    required this.products,
    required this.showMessage,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ürün Yönetimi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Vitrininde sergilenecek ürünleri buradan yöneteceksin.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${products.length} Ürün',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            XrexCatalogAssistantSection(
              onActionTap: () => showMessage('X-rex katalog çıkarma özelliği bir sonraki aşamada aktif edilecek.'),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: products.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return _buildProductItem(product);
                      },
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                showMessage('Ürün ekleme özelliği bir sonraki pakette aktif edilecek.');
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Yeni Ürün Ekle',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(
            Icons.shopping_bag_outlined,
            color: AppColors.primary,
            size: 38,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Henüz ürün yok',
          style: TextStyle(
            color: AppColors.darkText,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'İlk ürün ekleme özelliği bir sonraki adımda aktif edilecek.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildProductItem(Product product) {
    final hasImage = product.imagePath != null && product.imagePath!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 52,
              height: 52,
              child: hasImage
                  ? Image.network(
                      product.imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildItemFallback(),
                    )
                  : _buildItemFallback(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      product.price.trim().isEmpty ? 'Fiyat yok' : product.price,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.category,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: AppColors.mutedText, size: 20),
                onPressed: () {
                  showMessage('Düzenleme özelliği bir sonraki pakette aktif edilecek.');
                },
                tooltip: 'Düzenle',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                onPressed: () {
                  showMessage('Silme özelliği bir sonraki pakette aktif edilecek.');
                },
                tooltip: 'Sil',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemFallback() {
    return Container(
      color: AppColors.surface,
      child: const Center(
        child: Icon(
          Icons.shopping_bag_outlined,
          color: AppColors.primary,
          size: 20,
        ),
      ),
    );
  }
}
