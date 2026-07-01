import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/theme/app_colors.dart';

// ─── Gallery item helper (moved from my_vitrin_screen) ────────────────────
class GalleryItem {
  String id;
  Uint8List? bytes;
  String imageUrl;
  String extension;
  String contentType;

  GalleryItem({
    required this.id,
    this.bytes,
    required this.imageUrl,
    this.extension = 'jpg',
    this.contentType = 'image/jpeg',
  });

  bool get hasLocalBytes => bytes != null;
  bool get hasUrl => imageUrl.trim().isNotEmpty;

  static GalleryItem fromStoreItem(StoreGalleryItem item) =>
      GalleryItem(id: item.id, imageUrl: item.imageUrl);

  StoreGalleryItem toStoreItem() => StoreGalleryItem(id: id, imageUrl: imageUrl);
}

// ─── Compact Gallery Row ──────────────────────────────────────────────────
class GalleryRowSection extends StatelessWidget {
  final List<GalleryItem> galleryItems;
  final int maxGalleryPhotos;
  final VoidCallback onPickGalleryPhotos;
  final void Function(int index) onRemoveGalleryItem;

  const GalleryRowSection({
    super.key,
    required this.galleryItems,
    required this.maxGalleryPhotos,
    required this.onPickGalleryPhotos,
    required this.onRemoveGalleryItem,
  });

  static const double _thumbSize = 68.0;
  static const Color _primaryColor = AppColors.primary;
  static const Color _mutedText = AppColors.mutedText;
  static const Color _inputBg = AppColors.inputBg;
  static const Color _cardBorder = AppColors.border;

  @override
  Widget build(BuildContext context) {
    final canAdd = galleryItems.length < maxGalleryPhotos;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canAdd)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: onPickGalleryPhotos,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: _thumbSize,
                height: _thumbSize,
                decoration: BoxDecoration(
                  color: _inputBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _cardBorder),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_photo_alternate_rounded,
                      color: _primaryColor,
                      size: 22,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      galleryItems.isEmpty ? 'Galeri' : '+',
                      style: const TextStyle(
                        color: _primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child:
              galleryItems.isEmpty
                  ? Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: Text(
                      'Galeri fotoğrafı ekleyebilirsin',
                      style: TextStyle(
                        color: _mutedText.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                  : SizedBox(
                    height: _thumbSize,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: galleryItems.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, index) {
                        final item = galleryItems[index];
                        Widget img;
                        if (item.hasLocalBytes) {
                          img = Image.memory(item.bytes!, fit: BoxFit.cover);
                        } else if (item.hasUrl) {
                          img = Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => const Icon(
                                  Icons.broken_image_rounded,
                                  color: _mutedText,
                                  size: 20,
                                ),
                          );
                        } else {
                          img = const Icon(
                            Icons.image_rounded,
                            color: _mutedText,
                            size: 20,
                          );
                        }

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: _thumbSize,
                              height: _thumbSize,
                              decoration: BoxDecoration(
                                color: _inputBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _cardBorder),
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
                                    color: _primaryColor,
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
                                onTap: () => onRemoveGalleryItem(index),
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
        if (galleryItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 24),
            child: Text(
              '${galleryItems.length}/$maxGalleryPhotos',
              style: const TextStyle(
                color: _mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}
