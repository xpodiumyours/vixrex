import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../editor_gallery_item.dart';
import '../store_editor_controller.dart';
import 'editor_ui_components.dart';

class StoreGallerySection extends StatefulWidget {
  final StoreEditorController controller;
  final Map<StoreScoreTarget, GlobalKey> scoreTargetKeys;

  const StoreGallerySection({
    super.key,
    required this.controller,
    required this.scoreTargetKeys,
  });

  @override
  State<StoreGallerySection> createState() => _StoreGallerySectionState();
}

class _StoreGallerySectionState extends State<StoreGallerySection> {
  static const Color primaryColor = Color(0xFFFF4D00);
  static const Color secondaryColor = Color(0xFFB200FF);
  static const Color cardBorder = Color.fromRGBO(15, 23, 42, 0.10);
  static const Color darkText = Color(0xFF111827);
  static const Color mutedText = Color(0xFF64748B);
  static const Color inputBg = Color(0xFFF1F5F9);
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, secondaryColor],
  );

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final data = controller.data;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return EditCard(
          title: 'Mağaza Görünümü',
          children: [
            ScoreTargetAnchor(
              target: StoreScoreTarget.gallery,
              controller: controller,
              scoreTargetKeys: widget.scoreTargetKeys,
              child: _buildGalleryStudio(),
            ),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.image,
                    withData: true,
                  );
                  if (result != null && result.files.isNotEmpty) {
                    final file = result.files.first;
                    if (file.bytes != null) {
                      controller.setLogoBytes(
                        file.bytes!,
                        file.extension ?? 'jpg',
                        file.extension == 'png' ? 'image/png' : 'image/jpeg',
                      );
                    }
                  }
                },
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor.withAlpha((0.16 * 255).round()), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.05 * 255).round()),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: controller.logoBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(45),
                              child: Image.memory(controller.logoBytes!, fit: BoxFit.cover),
                            )
                          : (data.logoUrl != null && data.logoUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(45),
                                  child: Image.network(data.logoUrl!, fit: BoxFit.cover),
                                )
                              : const Icon(Icons.storefront_rounded, color: mutedText, size: 36)),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (data.logoUrl != null || controller.logoBytes != null) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: controller.removeLogo,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Logoyu Kaldır'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildGalleryStudio() {
    final controller = widget.controller;
    final selectedItem = controller.galleryItems.isEmpty
        ? null
        : controller.galleryItems[controller.selectedGalleryIndex];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: secondaryColor.withAlpha((0.08 * 255).round()),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: ctaGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withAlpha((0.22 * 255).round()),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Galeri Stüdyosu',
                      style: TextStyle(
                        color: darkText,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Kapak, fotoğraflar ve kısa açıklamalar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.86 * 255).round()),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cardBorder),
                ),
                child: Text(
                  '${controller.galleryItems.length} / 12',
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (controller.galleryItems.isEmpty)
            _buildGalleryEmptyState()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 620;
                if (!isWide) {
                  return Column(
                    children: [
                      _buildGalleryMainStage(selectedItem!),
                      const SizedBox(height: 14),
                      _buildGalleryGrid(),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildGalleryMainStage(selectedItem!)),
                    const SizedBox(width: 16),
                    SizedBox(width: 230, child: _buildGalleryGrid()),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildGalleryEmptyState() {
    return InkWell(
      onTap: () => widget.controller.pickGalleryPhotos(context),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((0.72 * 255).round()),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: ctaGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withAlpha((0.22 * 255).round()),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_photo_alternate_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'İlk fotoğrafı ekle',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: darkText,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Mağazanı, ürünlerini veya rafını gösteren güçlü görseller seç. İlk fotoğraf kapak olur.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            const Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                _ShelfHintChip(label: 'Kapak fotoğrafı'),
                _ShelfHintChip(label: 'Ürün alanı'),
                _ShelfHintChip(label: 'Mağaza atmosferi'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryMainStage(EditorGalleryItem item) {
    final controller = widget.controller;
    final isCover = controller.selectedGalleryIndex == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildEditorGalleryImage(item),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha((0.08 * 255).round()),
                        Colors.black.withAlpha((0.05 * 255).round()),
                        Colors.black.withAlpha((0.48 * 255).round()),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: _GalleryPill(
                    label: isCover ? 'Kapak' : '${controller.selectedGalleryIndex + 1}. fotoğraf',
                    icon: isCover ? Icons.star_rounded : Icons.image_rounded,
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      if (!isCover)
                        _buildGalleryToolbarButton(
                          label: 'Kapak yap',
                          icon: Icons.star_rounded,
                          onPressed: () => controller.makeGalleryCover(controller.selectedGalleryIndex),
                        ),
                      _buildGalleryToolbarButton(
                        label: 'Değiştir',
                        icon: Icons.swap_horiz_rounded,
                        onPressed: () => controller.replaceGalleryPhoto(context, controller.selectedGalleryIndex),
                      ),
                      _buildGalleryToolbarButton(
                        label: 'Sil',
                        icon: Icons.close_rounded,
                        onPressed: () => controller.removeGalleryPhoto(controller.selectedGalleryIndex),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildGalleryMetaFields(item),
      ],
    );
  }

  Widget _buildGalleryMetaFields(EditorGalleryItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCompactGalleryTextField(
          label: 'Kısa başlık',
          controller: item.titleController,
          hintText: 'Örn: Yeni sezon rafı',
          maxLength: 40,
        ),
        const SizedBox(height: 10),
        _buildCompactGalleryTextField(
          label: 'Açıklama',
          controller: item.descriptionController,
          hintText: 'Örn: El yapımı ürünlerin yer aldığı ana bölüm.',
          maxLength: 120,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildCompactGalleryTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required int maxLength,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          onChanged: (_) {
            setState(() {});
          },
          decoration: InputDecoration(
            counterText: '',
            hintText: hintText,
            filled: true,
            fillColor: Colors.white.withAlpha((0.86 * 255).round()),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Color(0x66FF4D00)),
            ),
            hintStyle: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: const TextStyle(
            color: darkText,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryGrid() {
    final controller = widget.controller;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 420 ? 3 : 2;
        const gap = 9.0;
        final tileWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
        final children = <Widget>[
          ...List.generate(
            controller.galleryItems.length,
            (index) => SizedBox(
              width: tileWidth,
              child: _buildGalleryThumbnailTile(index),
            ),
          ),
          if (controller.galleryItems.length < 12)
            SizedBox(width: tileWidth, child: _buildGalleryAddTile()),
        ];

        return Wrap(spacing: gap, runSpacing: gap, children: children);
      },
    );
  }

  Widget _buildGalleryThumbnailTile(int index) {
    final controller = widget.controller;
    final item = controller.galleryItems[index];
    final isSelected = controller.selectedGalleryIndex == index;

    return InkWell(
      onTap: () => controller.selectGalleryItem(index),
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.all(isSelected ? 2 : 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? primaryColor : cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withAlpha((0.18 * 255).round()),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ]
              : null,
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(isSelected ? 12 : 15),
                child: _buildEditorGalleryImage(item),
              ),
              Positioned(
                left: 6,
                top: 6,
                child: _GalleryPill(
                  label: index == 0 ? 'Kapak' : '${index + 1}',
                  icon: index == 0 ? Icons.star_rounded : Icons.image_rounded,
                  compact: true,
                ),
              ),
              Positioned(
                right: 5,
                top: 5,
                child: GestureDetector(
                  onTap: () => controller.removeGalleryPhoto(index),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.92 * 255).round()),
                      shape: BoxShape.circle,
                      border: Border.all(color: cardBorder),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: darkText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryAddTile() {
    return InkWell(
      onTap: () => widget.controller.pickGalleryPhotos(context),
      borderRadius: BorderRadius.circular(15),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((0.78 * 255).round()),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: cardBorder),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_rounded, color: primaryColor),
              SizedBox(height: 6),
              Text(
                'Ekle',
                style: TextStyle(
                  color: darkText,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryToolbarButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white.withAlpha((0.92 * 255).round()),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: darkText),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: darkText,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditorGalleryImage(EditorGalleryItem item) {
    final bytes = item.bytes;
    if (bytes != null) {
      return Image.memory(
        bytes,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }

    return Image.network(
      item.imageUrl.trim(),
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildShelfImageError(),
    );
  }

  Widget _buildShelfImageError() {
    return Container(
      color: inputBg,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, color: mutedText, size: 28),
          SizedBox(height: 8),
          Text(
            'Fotoğraf önizlenemedi',
            style: TextStyle(
              color: Color(0xFF334155),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool compact;

  const _GalleryPill({
    required this.label,
    required this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((0.54 * 255).round()),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha((0.18 * 255).round())),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: compact ? 10 : 13),
          SizedBox(width: compact ? 3 : 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 8.5 : 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShelfHintChip extends StatelessWidget {
  final String label;

  const _ShelfHintChip({required this.label});

  @override
  Widget build(BuildContext context) {
    const cardBorder = Color.fromRGBO(15, 23, 42, 0.10);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cardBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF334155),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
