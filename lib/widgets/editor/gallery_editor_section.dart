import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/editor/common_form_fields.dart';

class GalleryItem {
  String id;
  Uint8List? bytes;
  String imageUrl;
  String extension;
  String contentType;
  String title;
  bool isRemoved;

  GalleryItem({
    required this.id,
    this.bytes,
    required this.imageUrl,
    this.extension = 'jpg',
    this.contentType = 'image/jpeg',
    this.title = '',
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
  final void Function(int index, String title)? onTitleChanged;
  final TextEditingController galleryActionLabelController;
  final TextEditingController galleryActionHrefController;
  final ValueChanged<String> onGalleryActionLabelChanged;
  final ValueChanged<String> onGalleryActionHrefChanged;

  const GalleryEditorSection({
    super.key,
    required this.galleryItems,
    this.maxGalleryPhotos = 12,
    required this.onPickPhotos,
    required this.onRemovePhoto,
    this.onTitleChanged,
    required this.galleryActionLabelController,
    required this.galleryActionHrefController,
    required this.onGalleryActionLabelChanged,
    required this.onGalleryActionHrefChanged,
  });

  static const Color primaryColor = AppColors.primary;
  static const Color mutedText = AppColors.mutedText;
  static const Color cardBorder = AppColors.cardBorderDark;
  static const Color inputBg = AppColors.inputBg;

  Future<void> _editTitle(
    BuildContext context,
    int index,
    GalleryItem item,
  ) async {
    if (onTitleChanged == null) return;
    final controller = TextEditingController(text: item.title);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Görsel etiketi',
            style: TextStyle(
              color: AppColors.darkText,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 40,
            style: const TextStyle(color: AppColors.darkText),
            decoration: const InputDecoration(
              hintText: 'Örn: Yeni sezon seçkisi',
              counterText: '',
            ),
            onSubmitted: (value) => Navigator.of(ctx).pop(value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result == null) return;
    onTitleChanged!(index, result);
  }

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
        const SizedBox(height: 4),
        Text(
          'Görsele dokunarak etiket ekleyebilirsin.',
          style: TextStyle(
            color: mutedText.withOpacity(0.75),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        EditorTextField(
          label: 'Galeri Buton Metni',
          controller: galleryActionLabelController,
          hint: 'Örn: Kataloğu Gör',
          icon: Icons.smart_button_outlined,
          maxLength: 40,
          onChanged: onGalleryActionLabelChanged,
        ),
        const SizedBox(height: 12),
        EditorTextField(
          label: 'Galeri Buton Bağlantısı',
          controller: galleryActionHrefController,
          hint: 'https://... veya #sayfa-icı',
          icon: Icons.link_rounded,
          keyboardType: TextInputType.url,
          onChanged: onGalleryActionHrefChanged,
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Expanded(
              child:
                  galleryItems.isEmpty
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
                              img = Image.memory(
                                item.bytes!,
                                fit: BoxFit.cover,
                              );
                            } else if (item.hasUrl) {
                              img = Image.network(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => const Icon(
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

                            final hasTitle = item.title.trim().isNotEmpty;

                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                GestureDetector(
                                  onTap: () => _editTitle(context, index, item),
                                  child: Container(
                                    width: thumbSize,
                                    height: thumbSize,
                                    decoration: BoxDecoration(
                                      color: inputBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color:
                                            hasTitle
                                                ? primaryColor.withOpacity(0.55)
                                                : cardBorder,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: img,
                                  ),
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
                                if (hasTitle && index != 0)
                                  Positioned(
                                    bottom: 3,
                                    left: 3,
                                    right: 3,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
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
