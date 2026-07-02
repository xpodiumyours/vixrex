import 'package:flutter/material.dart';
import 'package:vitrinx/services/store_local_storage_service.dart';
import 'package:vitrinx/theme/app_colors.dart';

class PublishedSummaryCard extends StatelessWidget {
  final PublishedVitrinInfo info;
  final String coverUrl;
  final VoidCallback? onOpenExplore;

  const PublishedSummaryCard({
    super.key,
    required this.info,
    required this.coverUrl,
    this.onOpenExplore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorderDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(14),
                  image: coverUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(coverUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: coverUrl.isEmpty
                    ? const Icon(Icons.storefront_rounded,
                        color: AppColors.mutedText, size: 28)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.name,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info.slug,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      info.publicLink,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (onOpenExplore != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onOpenExplore,
              icon: const Icon(Icons.travel_explore_rounded, size: 16),
              label: const Text(
                'Keşfet\'te Gör',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
