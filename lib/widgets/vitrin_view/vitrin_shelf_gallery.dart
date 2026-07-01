import 'package:flutter/material.dart';
import 'package:vitrinx/theme/vitrin_theme_preset.dart';
import 'package:vitrinx/models/vitrin_gallery_preview_item.dart';
import 'package:vitrinx/widgets/vitrin_view/vitrin_gallery_image.dart';

class VitrinShelfGallery extends StatelessWidget {
  final VitrinThemePreset preset;
  final List<VitrinGalleryPreviewItem> galleryItems;
  final bool isEmbedded;

  const VitrinShelfGallery({
    super.key,
    required this.preset,
    required this.galleryItems,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = isEmbedded;
    final cardRadius = isCompact ? 16.0 : 26.0;
    var selectedIndex = 0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 14 : 24),
      child: StatefulBuilder(
        builder: (context, setGalleryState) {
          if (selectedIndex >= galleryItems.length) selectedIndex = 0;
          final selectedItem = galleryItems[selectedIndex];
          final selectedTitle = selectedItem.title.trim();
          final selectedDescription = selectedItem.description.trim();
          final shouldShowText =
              selectedTitle.isNotEmpty || selectedDescription.isNotEmpty;

          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(isCompact ? 10 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  preset.surface,
                  preset.surfaceSoft.withValues(
                    alpha: preset.isDark ? 0.38 : 0.5,
                  ),
                ],
              ),
              borderRadius: BorderRadius.circular(cardRadius),
              border: Border.all(
                color: preset.border.withValues(
                  alpha: preset.isDark ? 0.9 : 0.78,
                ),
                width: isCompact ? 1 : 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: preset.isDark ? 0.18 : 0.06,
                  ),
                  blurRadius: isCompact ? 14 : 28,
                  offset: Offset(0, isCompact ? 4 : 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: isCompact ? 28 : 36,
                      height: isCompact ? 28 : 36,
                      decoration: BoxDecoration(
                        color: preset.accent.withValues(
                          alpha: preset.isDark ? 0.2 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(
                          isCompact ? 11 : 13,
                        ),
                      ),
                      child: Icon(
                        Icons.photo_library_rounded,
                        color: preset.accent,
                        size: isCompact ? 16 : 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Galeri',
                            style: TextStyle(
                              color: preset.textPrimary,
                              fontSize: isCompact ? 13 : 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Fotoğraf albümü',
                            style: TextStyle(
                              color: preset.textSecondary.withValues(
                                alpha: 0.86,
                              ),
                              fontSize: isCompact ? 10 : 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: isCompact ? 188 : 280,
                  decoration: BoxDecoration(
                    color: preset.surfaceSoft,
                    borderRadius: BorderRadius.circular(
                      isCompact ? 12 : 18,
                    ),
                    border: Border.all(
                      color: preset.border.withValues(alpha: 0.6),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: VitrinGalleryImage(
                    item: selectedItem,
                    errorBuilder: (_, __, ___) => Container(
                      color: preset.surfaceSoft,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: preset.textSecondary,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                if (shouldShowText) ...[
                  const SizedBox(height: 12),
                  if (selectedTitle.isNotEmpty)
                    Text(
                      selectedTitle,
                      style: TextStyle(
                        color: preset.textPrimary,
                        fontSize: isCompact ? 13 : 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  if (selectedDescription.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      selectedDescription,
                      style: TextStyle(
                        color: preset.textSecondary.withValues(alpha: 0.9),
                        fontSize: isCompact ? 11 : 12,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
                if (galleryItems.length > 1) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: isCompact ? 42 : 56,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: List.generate(galleryItems.length, (index) {
                        final item = galleryItems[index];
                        final isSelected = selectedIndex == index;
                        return GestureDetector(
                          onTap: () =>
                              setGalleryState(() => selectedIndex = index),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Container(
                              width: isCompact ? 42 : 56,
                              height: isCompact ? 42 : 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  isCompact ? 9 : 12,
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? preset.accent
                                      : preset.border.withValues(
                                          alpha: 0.72,
                                        ),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  isCompact ? 9 : 12,
                                ),
                                child: VitrinGalleryImage(
                                  item: item,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: preset.surfaceSoft,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: preset.textSecondary,
                                      size: isCompact ? 16 : 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
