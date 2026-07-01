import 'package:flutter/material.dart';
import 'package:vitrinx/services/store_local_storage_service.dart';
import 'package:vitrinx/theme/app_colors.dart';

class PublishedSummarySection extends StatelessWidget {
  final PublishedVitrinInfo publishedInfo;
  final String? coverUrl;
  final VoidCallback? onOpenExplore;

  const PublishedSummarySection({
    super.key,
    required this.publishedInfo,
    required this.coverUrl,
    required this.onOpenExplore,
  });

  static const Color _primaryColor = AppColors.primary;
  static const Color _darkText = AppColors.darkText;
  static const Color _cardBorder = AppColors.border;

  @override
  Widget build(BuildContext context) {
    final cover = coverUrl?.trim() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child:
                cover.isNotEmpty
                    ? Image.network(
                      cover,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _coverPlaceholder(),
                    )
                    : _coverPlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 14,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Keşfet\'te yayında',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onOpenExplore,
                      icon: const Icon(Icons.travel_explore_rounded, size: 18),
                      color: _primaryColor,
                      tooltip: 'Keşfet\'te Gör',
                      style: IconButton.styleFrom(
                        backgroundColor: _primaryColor.withValues(alpha: 0.12),
                        minimumSize: const Size(36, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  publishedInfo.name.trim().isNotEmpty
                      ? publishedInfo.name
                      : 'Vitrinim',
                  style: const TextStyle(
                    color: _darkText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  publishedInfo.publicLink,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceSoft, AppColors.bgEditor],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.storefront_rounded,
          color: _primaryColor,
          size: 38,
        ),
      ),
    );
  }
}
