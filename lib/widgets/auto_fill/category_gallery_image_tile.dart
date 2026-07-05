import 'package:flutter/material.dart';
import 'package:vitrinx/services/category_image_service.dart';
import 'package:vitrinx/theme/app_colors.dart';

/// Tek görsel kutucuğu — seçim durumu, loading, error state destekler
class CategoryGalleryImageTile extends StatelessWidget {
  final CategoryTemplateImage image;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryGalleryImageTile({
    super.key,
    required this.image,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 3,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                image.thumbnailUrl ?? image.imageUrl,
                fit: BoxFit.cover,
                cacheWidth: 300,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image),
                ),
              ),
              if (isSelected)
                Container(
                  color: AppColors.primary.withOpacity(0.3),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
