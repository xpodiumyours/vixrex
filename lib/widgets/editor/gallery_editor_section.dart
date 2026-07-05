import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:vitrinx/theme/app_colors.dart';

class GalleryItem {
  String id;
  Uint8List? bytes;
  String imageUrl;
  String extension;
  String contentType;
  bool isRemoved;

  GalleryItem({
    required this.id,
    this.bytes,
    required this.imageUrl,
    this.extension = 'jpg',
    this.contentType = 'image/jpeg',
    this.isRemoved = false,
  });

  bool get hasLocalBytes => bytes != null;
  bool get hasUrl => imageUrl.trim().isNotEmpty;
}

class GalleryEditorSection extends StatelessWidget {
  final List<GalleryItem> galleryItems;
  final int maxGalleryPhotos;
  final VoidCallback onPickPhotos;
  final VoidCallback onCameraTap;
  final ValueChanged<int> onRemovePhoto;
  final VoidCallback? onAutoFillTap;

  const GalleryEditorSection({
    super.key,
    required this.galleryItems,
    this.maxGalleryPhotos = 12,
    required this.onPickPhotos,
    required this.onCameraTap,
    required this.onRemovePhoto,
    this.onAutoFillTap,
  });

  static const Color primaryColor = AppColors.primary;
  static const Color mutedText = AppColors.mutedText;
  static const Color cardBorder = AppColors.cardBorderDark;
  static const Color inputBg = AppColors.inputBg;

  @override
  Widget build(BuildContext context) {
    const double thumbSize = 64;
    final canAdd = galleryItems.length < maxGalleryPhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vitrin Galerisi',
          style: TextStyle(
            color: AppColors.softText,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        if (canAdd) ...[
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  onPressed: onPickPhotos,
                  icon: Icons.add_photo_alternate_rounded,
                  label: 'Fotoğraf Yükle',
                  isPrimary: false,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildActionButton(
                  onPressed: onCameraTap,
                  icon: Icons.photo_camera_rounded,
                  label: 'Fotoğraf Çek',
                  isPrimary: false,
                ),
              ),
              if (onAutoFillTap != null) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: _buildActionButton(
                    onPressed: onAutoFillTap!,
                    icon: Icons.auto_awesome_rounded,
                    label: 'Hazır Şablonlar',
                    isPrimary: true,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
        ],
        // Thumbnails
        if (galleryItems.isNotEmpty) ...[
          SizedBox(
            height: thumbSize,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: galleryItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, index) {
                final item = galleryItems[index];
                if (item.isRemoved) {
                  return const SizedBox.shrink();
                }
                Widget img;
                if (item.hasLocalBytes) {
                  img = Image.memory(item.bytes!, fit: BoxFit.cover);
                } else if (item.hasUrl) {
                  img = Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_rounded,
                      color: mutedText,
                      size: 20,
                    ),
                  );
                } else {
                  img = const Icon(
                    Icons.image_rounded,
                    color: mutedText,
                    size: 20,
                  );
                }

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: thumbSize,
                      height: thumbSize,
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cardBorder),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: img,
                    ),
                    if (index == 0)
                      Positioned(
                        bottom: 3,
                        left: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Kapak',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: GestureDetector(
                        onTap: () => onRemovePhoto(index),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
        // Explanation
        Text(
          'Vitrin galerisi için en fazla $maxGalleryPhotos fotoğraf ekleyin.${galleryItems.isNotEmpty ? ' (${galleryItems.length}/$maxGalleryPhotos)' : ''}',
          style: TextStyle(
            color: mutedText.withOpacity(0.7),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    if (isPrimary) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.black),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkText,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
