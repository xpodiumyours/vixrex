import 'package:flutter/material.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/theme/app_colors.dart';

class VitrinStoreCard extends StatelessWidget {
  final StoreData store;
  final bool isExample;
  final bool isFavorited;
  final bool isOwnStore;
  final VoidCallback? onTap;
  final VoidCallback onFavoritePressed;
  final VoidCallback onWhatsAppPressed;

  // Theme Colors from AppColors
  static const Color primaryColor = AppColors.primary;
  static const Color cardBorder = AppColors.border;
  static const Color darkText = AppColors.darkText;
  static const Color mutedText = AppColors.mutedText;

  const VitrinStoreCard({
    super.key,
    required this.store,
    required this.isExample,
    required this.isFavorited,
    required this.isOwnStore,
    this.onTap,
    required this.onFavoritePressed,
    required this.onWhatsAppPressed,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = store.shelfImageUrl.isNotEmpty;
    final status = store.status.trim();
    final isOpen = status.isEmpty || status.toLowerCase() == 'açık';
    final location =
        store.districtName.trim().isNotEmpty
            ? store.districtName.trim()
            : store.provinceName.trim().isNotEmpty
            ? store.provinceName.trim()
            : store.address.trim().isNotEmpty
            ? store.address.trim()
            : 'Konum belirtilmedi';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOwnStore ? primaryColor.withValues(alpha: 0.8) : cardBorder,
          width: isOwnStore ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          if (isOwnStore)
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.15),
              blurRadius: 12,
              spreadRadius: 1,
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isExample ? null : onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      Image.network(
                        store.shelfImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                _buildImagePlaceholder(),
                      )
                    else
                      _buildImagePlaceholder(),

                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.surface.withValues(alpha: 0.85),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),

                    if (isExample)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: _buildImageBadge('Örnek'),
                      ),

                    if (isOwnStore)
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: _buildImageBadge(
                          'Senin vitrinin',
                          highlighted: true,
                        ),
                      ),

                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.border,
                            width: 1.2,
                          ),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            isFavorited
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 20,
                            color:
                                isFavorited
                                    ? Colors.redAccent
                                    : AppColors.mutedText,
                          ),
                          onPressed: onFavoritePressed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 9, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              store.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: AppColors.darkText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color:
                                  isOpen ? AppColors.success : AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOpen ? 'Açık' : 'Kapalı',
                            style: TextStyle(
                              color:
                                  isOpen ? AppColors.success : AppColors.error,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        store.kategori.trim().isEmpty
                            ? 'Dijital vitrin'
                            : store.kategori.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF25D366,
                              ).withValues(alpha: 0.13),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(
                                  0xFF25D366,
                                ).withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.chat_bubble_rounded,
                                color: Color(0xFF25D366),
                                size: 18,
                              ),
                              onPressed: onWhatsAppPressed,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageBadge(String label, {bool highlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color:
            highlighted
                ? AppColors.primary
                : AppColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              highlighted
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: highlighted ? AppColors.bgEditor : AppColors.darkText,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surfaceSoft, AppColors.bgEditor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.storefront_outlined,
              color: AppColors.primary,
              size: 34,
            ),
            const SizedBox(height: 6),
            Text(
              'Kapak görseli bekleniyor',
              style: TextStyle(
                color: AppColors.mutedText.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
