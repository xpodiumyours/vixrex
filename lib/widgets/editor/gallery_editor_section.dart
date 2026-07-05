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
  final ValueChanged<int> onRemovePhoto;

  const GalleryEditorSection({
    super.key,
    required this.galleryItems,
    this.maxGalleryPhotos = 12,
    required this.onPickPhotos,
    required this.onRemovePhoto,
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add button
            if (canAdd)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: onPickPhotos,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_photo_alternate_rounded,
                          color: primaryColor,
                          size: 22,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          galleryItems.isEmpty ? 'Galeri' : '+',
                          style: const TextStyle(
                            color: primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Thumbnails or empty state explanation
            Expanded(
              child: galleryItems.isEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 22),
                          child: Text(
                            'Vitrin galerisi için en fazla $maxGalleryPhotos fotoğraf ekleyin.',
                            style: TextStyle(
                              color: mutedText.withOpacity(0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
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
            ),
            // Count badge
            if (galleryItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 24),
                child: Text(
                  '${galleryItems.length}/$maxGalleryPhotos',
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
