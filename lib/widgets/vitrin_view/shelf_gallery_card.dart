import 'package:flutter/material.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/theme/vitrin_theme_preset.dart';
import 'package:vitrinx/utils/whatsapp_link_helper.dart';
import 'package:vitrinx/widgets/vitrin_view/vitrin_gallery_preview_item.dart';

class ShelfGalleryCard extends StatefulWidget {
  const ShelfGalleryCard({
    required this.preset,
    required this.galleryItems,
    required this.isEmbedded,
    required this.publicMode,
    required this.storeData,
    required this.onExternalUrl,
  });

  final VitrinThemePreset preset;
  final List<VitrinGalleryPreviewItem> galleryItems;
  final bool isEmbedded;
  final bool publicMode;
  final StoreData storeData;
  final Future<void> Function(BuildContext, String?) onExternalUrl;

  @override
  State<ShelfGalleryCard> createState() => _ShelfGalleryCardState();
}

class _ShelfGalleryCardState extends State<ShelfGalleryCard> {
  int _selectedIndex = 0;

  static Widget _buildGalleryImage(
    VitrinGalleryPreviewItem item, {
    BoxFit fit = BoxFit.cover,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) {
    final imageBytes = item.imageBytes;
    if (imageBytes != null) {
      return Image.memory(
        imageBytes,
        width: double.infinity,
        height: double.infinity,
        fit: fit,
        filterQuality: FilterQuality.medium,
      );
    }
    return Image.network(
      item.imageUrl.trim(),
      width: double.infinity,
      height: double.infinity,
      fit: fit,
      filterQuality: FilterQuality.medium,
      errorBuilder: errorBuilder,
    );
  }

  Widget _buildWhatsAppButton(
    BuildContext context,
    VitrinGalleryPreviewItem item,
    bool isCompact,
  ) {
    final preset = widget.preset;
    final title =
        item.title.trim().isNotEmpty ? item.title.trim() : 'Vitrin Görseli';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: preset.accent.withValues(alpha: preset.isDark ? 0.14 : 0.10),
        borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
        border: Border.all(
          color: preset.accent.withValues(alpha: isDark ? 0.35 : 0.22),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!widget.publicMode) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Müşteriler bu butona bastığında WhatsApp'tan '$title' hakkında bilgi sorabilir.",
                  ),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
              return;
            }
            final url = WhatsAppLinkHelper.buildInquiryUrl(
              number: widget.storeData.whatsapp,
              storeName: widget.storeData.name,
              itemTitle: title,
            );
            if (url != null) {
              widget.onExternalUrl(context, url);
            }
          },
          borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: isCompact ? 10 : 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: preset.accent,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  isCompact
                      ? 'Görseldeki Ürünü Sor'
                      : "Fotoğraftaki Ürünü WhatsApp'tan Sor",
                  style: TextStyle(
                    color: preset.accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preset = widget.preset;
    final galleryItems = widget.galleryItems;
    final isCompact = widget.isEmbedded;
    final cardRadius = isCompact ? 16.0 : 26.0;

    if (_selectedIndex >= galleryItems.length) _selectedIndex = 0;
    final selectedItem = galleryItems[_selectedIndex];
    final selectedTitle = selectedItem.title.trim();
    final selectedDescription = selectedItem.description.trim();
    final shouldShowText =
        selectedTitle.isNotEmpty || selectedDescription.isNotEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 14 : 24),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isCompact ? 10 : 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              preset.surface,
              preset.surfaceSoft.withValues(alpha: preset.isDark ? 0.38 : 0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(
            color: preset.border.withValues(alpha: preset.isDark ? 0.9 : 0.78),
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
                    borderRadius: BorderRadius.circular(isCompact ? 11 : 13),
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
                        'Vitrin galerisi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: preset.textPrimary,
                          fontSize: isCompact ? 11 : 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      Text(
                        '${_selectedIndex + 1} / ${galleryItems.length} seçili',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: preset.textSecondary,
                          fontSize: isCompact ? 9 : 11,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 8 : 10,
                    vertical: isCompact ? 5 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: preset.accent.withValues(
                      alpha: preset.isDark ? 0.18 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: preset.accent.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    '${galleryItems.length} fotoğraf',
                    style: TextStyle(
                      color: preset.accent,
                      fontSize: isCompact ? 9 : 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 10 : 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(isCompact ? 12 : 20),
              child: AspectRatio(
                aspectRatio: isCompact
                    ? 16 / 9
                    : widget.publicMode
                        ? 16 / 9
                        : 16 / 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildGalleryImage(
                      selectedItem,
                      errorBuilder: (_, __, ___) => Container(
                        color: preset.surfaceSoft,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: preset.textSecondary,
                          size: isCompact ? 26 : 32,
                        ),
                      ),
                    ),
                    Positioned(
                      left: isCompact ? 8 : 12,
                      top: isCompact ? 8 : 12,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 8 : 10,
                          vertical: isCompact ? 5 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.48),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          _selectedIndex == 0
                              ? 'Kapak'
                              : '${_selectedIndex + 1}. fotoğraf',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isCompact ? 9 : 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (shouldShowText) ...[
              SizedBox(height: isCompact ? 10 : 12),
              if (selectedTitle.isNotEmpty)
                Text(
                  selectedTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: preset.textPrimary,
                    fontSize: isCompact ? 12 : 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                    height: 1.2,
                  ),
                ),
              if (selectedDescription.isNotEmpty) ...[
                SizedBox(height: isCompact ? 4 : 6),
                Text(
                  selectedDescription,
                  maxLines: isCompact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: preset.textSecondary,
                    fontSize: isCompact ? 10 : 12,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ],
            ],
            if (WhatsAppLinkHelper.isValidTurkeyMobile(
              widget.storeData.whatsapp,
            )) ...[
              SizedBox(height: isCompact ? 12 : 16),
              _buildWhatsAppButton(context, selectedItem, isCompact),
            ],
            if (galleryItems.length > 1) ...[
              SizedBox(height: isCompact ? 10 : 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(galleryItems.length, (index) {
                    final item = galleryItems[index];
                    final isSelected = _selectedIndex == index;
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index == galleryItems.length - 1 ? 0 : 8,
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: isCompact ? 48 : 58,
                          height: isCompact ? 48 : 58,
                          padding: EdgeInsets.all(isSelected ? 2 : 0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              isCompact ? 12 : 15,
                            ),
                            border: Border.all(
                              color: isSelected
                                  ? preset.accent
                                  : preset.border.withValues(alpha: 0.72),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              isCompact ? 9 : 12,
                            ),
                            child: _buildGalleryImage(
                              item,
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
      ),
    );
  }
}
