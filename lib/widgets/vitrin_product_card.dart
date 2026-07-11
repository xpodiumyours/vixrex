import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';

class VitrinProductCard extends StatelessWidget {
  final String name;
  final String price;
  final String category;
  final String description;
  final String? imagePath;
  final String stockStatus;
  final VoidCallback? onTap;
  final VoidCallback? onWhatsAppTap;

  /// Görsel oranı (genişlik / yükseklik). Katalog kart yüksekliği buna göre hesaplanır.
  static const double imageAspectRatio = 1.15;

  /// Görsel altı metin bloğu için yaklaşık yükseklik (padding dahil).
  static const double textBlockHeight = 118;

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

  static double cardHeightForWidth(double width) {
    return (width / imageAspectRatio) + textBlockHeight;
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.trim().isNotEmpty;
    final trimmedDesc = description.trim();

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: imageAspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    Image.network(
                      imagePath!.trim(),
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              _buildImagePlaceholder(),
                    )
                  else
                    _buildImagePlaceholder(),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.surface.withValues(alpha: 0.75),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
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
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          category.trim().isEmpty
                              ? 'GENEL'
                              : category.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: AppColors.secondary,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      if (stockStatus != 'Mevcut')
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            stockStatus.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                  const SizedBox(height: 4),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText,
                      height: 1.2,
                    ),
                  ),
                  if (trimmedDesc.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      trimmedDesc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedText,
                        height: 1.25,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          price.trim().isEmpty ? '—' : price,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: onWhatsAppTap,
                        borderRadius: BorderRadius.circular(99),
                        child: Container(
                          padding: const EdgeInsets.all(6),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_outlined,
              size: 28,
              color: AppColors.primary.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 4),
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
