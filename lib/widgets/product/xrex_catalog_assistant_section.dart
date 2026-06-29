import 'package:flutter/material.dart';
import 'package:vitrinx/theme/app_colors.dart';

class XrexCatalogAssistantSection extends StatelessWidget {
  final VoidCallback onActionTap;

  const XrexCatalogAssistantSection({
    super.key,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'X-rex ile katalog oluştur',
                      style: TextStyle(
                        color: AppColors.darkText,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Fotoğraf, fatura veya Instagram ürünlerinden otomatik ürün kataloğu hazırlamaya yardımcı olacak.',
                      style: TextStyle(
                        color: AppColors.mutedText.withValues(alpha: 0.85),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildActionTile(
                  icon: Icons.image_search_rounded,
                  title: 'Fotoğraftan çıkar',
                  desc: 'Fotoğraftan ad/kategori çıkar',
                ),
                const SizedBox(width: 10),
                _buildActionTile(
                  icon: Icons.document_scanner_rounded,
                  title: 'Faturadan çıkar',
                  desc: 'Faturadan ürünleri algıla',
                ),
                const SizedBox(width: 10),
                _buildActionTile(
                  icon: Icons.smart_toy_rounded,
                  title: 'X-rex önerileri',
                  desc: 'Ürün başlıklarını iyileştir',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return InkWell(
      onTap: onActionTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 146,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.darkText,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              desc,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 8,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
