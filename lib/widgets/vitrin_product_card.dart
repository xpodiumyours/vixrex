import 'package:flutter/material.dart';
import 'package:vitrinx/theme/app_colors.dart';

class VitrinProductCard extends StatelessWidget {
  final String name;
  final String price;
  final String category;
  final String description;
  final String? imagePath;
  final String stockStatus;
  final VoidCallback? onTap;
  final VoidCallback? onWhatsAppTap;

  const VitrinProductCard({
    super.key,
    required this.name,
    required this.price,
    required this.category,
    required this.description,
    this.imagePath,
    this.stockStatus = 'Mevcut',
    this.onTap,
    this.onWhatsAppTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radius24),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.2,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasImage)
                  Image.network(
                    imagePath!,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) =>
                            _buildImagePlaceholder(),
                  )
                else
                  _buildImagePlaceholder(),

                // Bottom gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.surface.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // Siber Onay/Aktif Göstergesi (Sağ Alt Köşe)
                Positioned(
                  bottom: AppColors.spacing12,
                  right: AppColors.spacing12,
                  child: Container(
                    width: AppColors.spacing20,
                    height: AppColors.spacing20,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.black,
                        size: 12,
                        weight: 900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppColors.spacing12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          category.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: AppColors.secondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      if (stockStatus != 'Mevcut')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppColors.spacing8,
                            vertical: AppColors.spacing4,
                          ),
                          decoration: BoxDecoration(
                            color: (stockStatus == 'Tükendi'
                                    ? AppColors.error
                                    : AppColors.primary)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(
                              AppColors.spacing4,
                            ),
                            border: Border.all(
                              color:
                                  stockStatus == 'Tükendi'
                                      ? AppColors.error
                                      : AppColors.primary,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            stockStatus.toUpperCase(),
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color:
                                  stockStatus == 'Tükendi'
                                      ? AppColors.error
                                      : AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppColors.spacing8),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: AppColors.spacing4),
                  Expanded(
                    child: Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedText,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppColors.spacing8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      InkWell(
                        onTap: onWhatsAppTap,
                        borderRadius: BorderRadius.circular(99),
                        child: Container(
                          padding: const EdgeInsets.all(AppColors.spacing8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
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
            Icon(
              Icons.image_outlined,
              size: 34,
              color: AppColors.primary.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 6),
            Text(
              'Görsel yok',
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
