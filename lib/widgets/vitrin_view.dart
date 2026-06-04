import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/theme/vitrin_theme_preset.dart';
import 'package:vitrinx/widgets/status_chip.dart';

class VitrinGalleryPreviewItem {
  final String imageUrl;
  final Uint8List? imageBytes;
  final String title;
  final String description;

  const VitrinGalleryPreviewItem({
    this.imageUrl = '',
    this.imageBytes,
    this.title = '',
    this.description = '',
  });

  factory VitrinGalleryPreviewItem.fromStoreItem(StoreGalleryItem item) {
    return VitrinGalleryPreviewItem(
      imageUrl: item.imageUrl,
      title: item.title,
      description: item.description,
    );
  }

  bool get hasImage => imageBytes != null || imageUrl.trim().isNotEmpty;
}

class VitrinView extends StatelessWidget {
  final StoreData storeData;
  final bool isEmbedded;
  final bool publicMode;
  final bool compactEmbeddedHeader;
  final List<VitrinGalleryPreviewItem>? previewGalleryItems;

  /// Public vitrinde sayfanın tamamını tarayacak olan URL.
  /// Doluysa [publicMode] == true iken gerçek QR kod kartı gösterilir.
  final String? publicLink;

  const VitrinView({
    super.key,
    required this.storeData,
    this.isEmbedded = false,
    this.publicMode = false,
    this.compactEmbeddedHeader = false,
    this.previewGalleryItems,
    this.publicLink,
  });

  @override
  Widget build(BuildContext context) {
    final preset = vitrinThemePresetFor(storeData.theme);
    final themeData = _getThemeData(preset);
    final radius = isEmbedded ? 24.0 : 40.0;
    final galleryItems = _effectiveGalleryItems();
    final hasGalleryMedia = galleryItems.isNotEmpty;
    final children = <Widget>[
      _buildModernHeader(context, preset, radius, galleryItems),
      SizedBox(height: isEmbedded ? 14 : 24),
      _buildStoreIdentityBlock(preset),
      SizedBox(height: isEmbedded ? 16 : 28),
      if (_hasVisibleActions()) ...[
        _buildPremiumActionButtons(radius),
        SizedBox(height: isEmbedded ? 16 : 30),
      ],
      if (publicMode && _aboutText().isNotEmpty) ...[
        _buildAboutCard(preset),
        SizedBox(height: isEmbedded ? 16 : 30),
      ] else if (!publicMode) ...[
        _buildProfessionalBio(preset),
        SizedBox(height: isEmbedded ? 16 : 48),
      ],
      if (hasGalleryMedia) ...[
        _buildShelfImageCard(preset, galleryItems),
        SizedBox(height: isEmbedded ? 16 : 30),
      ],
      if (storeData.isStore && storeData.products.isNotEmpty) ...[
        _buildProductsCatalogBlock(preset, radius),
        SizedBox(height: isEmbedded ? 16 : 30),
      ],
      _buildModernLinkHub(preset, radius),
      SizedBox(
        height:
            isEmbedded
                ? 18
                : publicMode
                ? 24
                : 64,
      ),
      if (!publicMode) ...[
        _buildPremiumIdentityCard(context, preset, radius),
        SizedBox(height: isEmbedded ? 18 : 64),
      ],
      if (publicMode && (publicLink?.isNotEmpty ?? false)) ...[
        _buildPublicQrCard(publicLink!, preset),
        const SizedBox(height: 24),
      ],
      _buildModernFooter(preset),
      SizedBox(
        height:
            isEmbedded
                ? 36
                : publicMode
                ? 48
                : 120,
      ),
    ];

    final content =
        isEmbedded
            ? ListView(
              padding: EdgeInsets.zero,
              physics: const ClampingScrollPhysics(),
              children: children,
            )
            : publicMode
            ? Column(children: children)
            : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(children: children),
            );

    return Theme(
      data: themeData,
      child:
          publicMode
              ? Material(color: preset.background, child: content)
              : isEmbedded
              ? Material(
                color: preset.background,
                child: SizedBox.expand(child: content),
              )
              : Scaffold(
                backgroundColor: preset.background,
                extendBodyBehindAppBar: true,
                body: content,
              ),
    );
  }

  ThemeData _getThemeData(VitrinThemePreset preset) {
    return ThemeData(
      useMaterial3: true,
      brightness: preset.isDark ? Brightness.dark : Brightness.light,
      primaryColor: preset.accent,
      scaffoldBackgroundColor: preset.background,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: preset.accent,
        brightness: preset.isDark ? Brightness.dark : Brightness.light,
      ).copyWith(
        primary: preset.accent,
        onPrimary: preset.buttonText,
        surface: preset.surface,
        onSurface: preset.textPrimary,
        outline: preset.border,
      ),
      textTheme: ThemeData(
        brightness: preset.isDark ? Brightness.dark : Brightness.light,
      ).textTheme.apply(
        bodyColor: preset.textPrimary,
        displayColor: preset.textPrimary,
      ),
    );
  }

  List<VitrinGalleryPreviewItem> _effectiveGalleryItems() {
    final previewItems =
        previewGalleryItems?.where((item) => item.hasImage).take(12).toList();
    if (previewItems != null && previewItems.isNotEmpty) return previewItems;

    return storeData.displayGalleryItems
        .map(VitrinGalleryPreviewItem.fromStoreItem)
        .toList();
  }

  Widget _buildGalleryImage(
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

  Widget _buildModernHeader(
    BuildContext context,
    VitrinThemePreset preset,
    double radius,
    List<VitrinGalleryPreviewItem> galleryItems,
  ) {
    final heroItem = galleryItems.isEmpty ? null : galleryItems.first;
    final hasHeroImage = heroItem != null;
    final heroHeight =
        isEmbedded
            ? (compactEmbeddedHeader ? 178.0 : 230.0)
            : publicMode
            ? 360.0
            : 380.0;
    final monogramRadius =
        isEmbedded
            ? (compactEmbeddedHeader ? 25.0 : 34.0)
            : publicMode
            ? 54.0
            : 58.0;

    return Container(
      width: double.infinity,
      height: heroHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius:
            publicMode && !isEmbedded
                ? const BorderRadius.only(
                  bottomLeft: Radius.circular(34),
                  bottomRight: Radius.circular(34),
                )
                : BorderRadius.circular(radius),
        border: Border.all(
          color: preset.border.withValues(alpha: 0.55),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: preset.isDark ? 0.28 : 0.08),
            blurRadius: publicMode ? 34 : 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (heroItem != null)
            _buildGalleryImage(
              heroItem,
              errorBuilder:
                  (_, __, ___) => Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildHeaderFallbackSurface(preset),
                      Center(child: _buildVxMonogram(preset, monogramRadius)),
                    ],
                  ),
            )
          else
            _buildHeaderFallbackSurface(preset),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors:
                    hasHeroImage
                        ? [
                          Colors.black.withValues(alpha: 0.24),
                          Colors.black.withValues(alpha: 0.36),
                          Colors.black.withValues(alpha: 0.70),
                        ]
                        : [
                          Colors.transparent,
                          preset.background.withValues(
                            alpha: preset.isDark ? 0.12 : 0.18,
                          ),
                          preset.background.withValues(
                            alpha: preset.isDark ? 0.34 : 0.58,
                          ),
                        ],
              ),
            ),
          ),
          if (!hasHeroImage)
            Center(child: _buildVxMonogram(preset, monogramRadius)),
          Positioned(
            top: isEmbedded ? 12 : 20,
            right: isEmbedded ? 12 : 20,
            child: _buildShareButton(context, preset),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreIdentityBlock(VitrinThemePreset preset) {
    final storeName = storeData.name.trim();
    final businessType = storeData.businessType.trim();
    final status = storeData.status.trim();
    final titleText =
        storeName.isNotEmpty
            ? storeName
            : (publicMode ? 'Vitrin' : 'Dijital Vitrin');
    final shouldShowBusinessType = !publicMode || businessType.isNotEmpty;
    final shouldShowStatus = !publicMode || status.isNotEmpty;
    final titleSize =
        isEmbedded
            ? (compactEmbeddedHeader ? 18.0 : 21.0)
            : publicMode
            ? 30.0
            : 34.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isEmbedded ? 18 : 28),
      child: Column(
        children: [
          Text(
            titleText,
            maxLines: (publicMode || isEmbedded) ? 2 : null,
            overflow: (publicMode || isEmbedded) ? TextOverflow.ellipsis : null,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w900,
              color: preset.textPrimary,
              letterSpacing: 0,
              height: 1.08,
            ),
          ),
          if (shouldShowBusinessType || shouldShowStatus) ...[
            SizedBox(height: isEmbedded ? 10 : 14),
            Wrap(
              spacing: isEmbedded ? 8 : 10,
              runSpacing: isEmbedded ? 8 : 10,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (shouldShowBusinessType)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isEmbedded ? 12 : 15,
                      vertical: isEmbedded ? 6 : 7,
                    ),
                    decoration: BoxDecoration(
                      color: preset.accent.withValues(
                        alpha: preset.isDark ? 0.16 : 0.11,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: preset.accent.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      (businessType.isEmpty ? 'Vitrin' : businessType)
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: isEmbedded ? 9 : 10,
                        color: preset.accent,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                if (shouldShowStatus) StatusChip(status: status),
              ],
            ),
          ],
          if (!publicMode && storeData.description.trim().isNotEmpty) ...[
            SizedBox(height: isEmbedded ? 10 : 16),
            Text(
              storeData.description.trim(),
              textAlign: TextAlign.center,
              maxLines: isEmbedded ? 2 : null,
              overflow: isEmbedded ? TextOverflow.ellipsis : null,
              style: TextStyle(
                fontSize: isEmbedded ? 12 : 14,
                color: preset.textSecondary,
                fontWeight: FontWeight.w600,
                height: isEmbedded ? 1.3 : 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderFallbackSurface(VitrinThemePreset preset) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            preset.accent.withValues(alpha: preset.isDark ? 0.2 : 0.16),
            preset.surfaceSoft.withValues(alpha: preset.isDark ? 0.42 : 0.88),
            preset.background.withValues(alpha: preset.isDark ? 0.96 : 0.98),
          ],
          stops: const [0, 0.48, 1],
        ),
      ),
    );
  }

  Widget _buildVxMonogram(VitrinThemePreset preset, double avatarRadius) {
    final monogramColor = preset.isDark ? preset.textPrimary : preset.accent;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            preset.accent.withValues(alpha: preset.isDark ? 0.24 : 0.14),
            preset.surface.withValues(alpha: preset.isDark ? 0.9 : 0.96),
            preset.surfaceSoft.withValues(alpha: preset.isDark ? 0.74 : 0.9),
          ],
        ),
        border: Border.all(
          color: preset.accent.withValues(alpha: preset.isDark ? 0.3 : 0.2),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Text(
          'VX',
          style: TextStyle(
            color: monogramColor,
            fontSize: avatarRadius * 0.62,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            height: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumActionButtons(double radius) {
    final isCompact = isEmbedded;
    final actions = _buildVisibleActions(radius, isCompact);
    final horizontalPadding = isCompact ? 18.0 : 24.0;
    final spacing = isCompact ? 8.0 : 12.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth =
              constraints.hasBoundedWidth ? constraints.maxWidth : 360.0;
          final itemWidth =
              actions.length == 1
                  ? availableWidth
                  : (availableWidth - spacing) / 2;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            alignment: WrapAlignment.center,
            children:
                actions
                    .map(
                      (action) => SizedBox(
                        width: itemWidth.clamp(112.0, availableWidth),
                        child: action,
                      ),
                    )
                    .toList(),
          );
        },
      ),
    );
  }

  bool _hasVisibleActions() {
    if (!publicMode) return true;

    return storeData.whatsapp.trim().isNotEmpty ||
        storeData.instagram.trim().isNotEmpty ||
        storeData.website.trim().isNotEmpty ||
        storeData.address.trim().isNotEmpty;
  }

  List<Widget> _buildVisibleActions(double radius, bool isCompact) {
    if (!publicMode) {
      return [
        _ActionIconBtn(
          label: 'WhatsApp',
          icon: Icons.chat_bubble_rounded,
          color: const Color(0xFF25D366),
          radius: radius,
          compact: isCompact,
        ),
        _ActionIconBtn(
          label: 'Instagram',
          icon: Icons.camera_rounded,
          color: const Color(0xFFE1306C),
          radius: radius,
          compact: isCompact,
        ),
        if (storeData.website.isNotEmpty)
          _ActionIconBtn(
            label: 'Web',
            icon: Icons.language_rounded,
            color: Colors.blue.shade600,
            radius: radius,
            compact: isCompact,
          ),
        _ActionIconBtn(
          label: 'Adres',
          icon: Icons.location_on_rounded,
          color: Colors.red.shade500,
          radius: radius,
          compact: isCompact,
        ),
      ];
    }

    return [
      if (storeData.whatsapp.trim().isNotEmpty)
        _ActionIconBtn(
          label: 'WhatsApp',
          icon: Icons.chat_bubble_rounded,
          color: const Color(0xFF25D366),
          radius: radius,
          compact: isCompact,
          emphasis: true,
          onTap: () => _openExternalUrl(_buildWhatsAppUrl(storeData.whatsapp)),
        ),
      if (storeData.instagram.trim().isNotEmpty)
        _ActionIconBtn(
          label: 'Instagram',
          icon: Icons.camera_rounded,
          color: const Color(0xFFE1306C),
          radius: radius,
          compact: isCompact,
          onTap:
              () => _openExternalUrl(_buildInstagramUrl(storeData.instagram)),
        ),
      if (storeData.website.trim().isNotEmpty)
        _ActionIconBtn(
          label: 'Web',
          icon: Icons.language_rounded,
          color: Colors.blue.shade600,
          radius: radius,
          compact: isCompact,
          onTap:
              () => _openExternalUrl(_normalizeExternalUrl(storeData.website)),
        ),
      if (storeData.address.trim().isNotEmpty)
        _ActionIconBtn(
          label: 'Adres',
          icon: Icons.location_on_rounded,
          color: Colors.red.shade500,
          radius: radius,
          compact: isCompact,
          onTap: () => _openExternalUrl(_buildMapsUrl(storeData.address)),
        ),
    ];
  }

  Widget _buildProductsCatalogBlock(VitrinThemePreset preset, double radius) {
    final isCompact = isEmbedded;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 18 : 24),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isCompact ? 16 : 22),
        decoration: BoxDecoration(
          color: preset.surface.withValues(alpha: preset.isDark ? 0.9 : 0.98),
          borderRadius: BorderRadius.circular(isCompact ? 16 : 24),
          border: Border.all(
            color: preset.border.withValues(alpha: preset.isDark ? 0.9 : 0.78),
            width: isCompact ? 1 : 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: preset.isDark ? 0.12 : 0.045,
              ),
              blurRadius: isCompact ? 12 : 24,
              offset: Offset(0, isCompact ? 3 : 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shopping_bag_rounded,
                  color: preset.accent,
                  size: isCompact ? 18 : 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ürün Kataloğu',
                  style: TextStyle(
                    color: preset.textPrimary,
                    fontSize: isCompact ? 14 : 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: storeData.products.length,
              separatorBuilder: (context, index) => Divider(
                color: preset.border.withValues(alpha: 0.5),
                height: 24,
              ),
              itemBuilder: (context, index) {
                final product = storeData.products[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.imagePath != null && product.imagePath!.trim().isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          product.imagePath!.trim(),
                          width: isCompact ? 60 : 70,
                          height: isCompact ? 60 : 70,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            width: isCompact ? 60 : 70,
                            height: isCompact ? 60 : 70,
                            color: preset.border.withValues(alpha: 0.3),
                            child: Icon(Icons.shopping_bag_outlined, color: preset.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: TextStyle(
                                    color: preset.textPrimary,
                                    fontSize: isCompact ? 13 : 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildProductStockBadge(product.stockStatus, preset),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (product.category.isNotEmpty && product.category != 'Tümü' && product.category != 'Genel') ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: preset.accent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    product.category,
                                    style: TextStyle(
                                      color: preset.accent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                product.price.trim().isEmpty ? 'Fiyat Belirtilmemiş' : product.price,
                                style: TextStyle(
                                  color: preset.textPrimary,
                                  fontSize: isCompact ? 12 : 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          if (product.description.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              product.description,
                              style: TextStyle(
                                color: preset.textSecondary,
                                fontSize: isCompact ? 11 : 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductStockBadge(String status, VitrinThemePreset preset) {
    Color color;
    String text = status;
    if (status == 'Son birkaç adet') {
      color = Colors.orange;
    } else if (status == 'Tükendi') {
      color = Colors.red;
    } else {
      color = Colors.green;
      text = 'Mevcut';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildShelfImageCard(
    VitrinThemePreset preset,
    List<VitrinGalleryPreviewItem> galleryItems,
  ) {
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
                            '${selectedIndex + 1} / ${galleryItems.length} seçili',
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
                    aspectRatio:
                        isCompact
                            ? 16 / 9
                            : publicMode
                            ? 16 / 9
                            : 16 / 10,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildGalleryImage(
                          selectedItem,
                          errorBuilder:
                              (_, __, ___) => Container(
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
                              selectedIndex == 0
                                  ? 'Kapak'
                                  : '${selectedIndex + 1}. fotoğraf',
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
                if (storeData.whatsapp.trim().isNotEmpty) ...[
                  SizedBox(height: isCompact ? 12 : 16),
                  _buildShelfWhatsAppButton(context, preset, selectedItem, isCompact),
                ],
                if (galleryItems.length > 1) ...[
                  SizedBox(height: isCompact ? 10 : 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(galleryItems.length, (index) {
                        final item = galleryItems[index];
                        final isSelected = selectedIndex == index;
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index == galleryItems.length - 1 ? 0 : 8,
                          ),
                          child: GestureDetector(
                            onTap:
                                () => setGalleryState(
                                  () => selectedIndex = index,
                                ),
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
                                  color:
                                      isSelected
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
                                child: _buildGalleryImage(
                                  item,
                                  errorBuilder:
                                      (_, __, ___) => Container(
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

  Widget _buildAboutCard(VitrinThemePreset preset) {
    final isCompact = isEmbedded;
    final aboutText = _aboutText();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 18 : 24),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isCompact ? 16 : 22),
        decoration: BoxDecoration(
          color: preset.surface.withValues(alpha: preset.isDark ? 0.9 : 0.98),
          borderRadius: BorderRadius.circular(isCompact ? 16 : 24),
          border: Border.all(
            color: preset.border.withValues(alpha: preset.isDark ? 0.9 : 0.78),
            width: isCompact ? 1 : 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: preset.isDark ? 0.12 : 0.045,
              ),
              blurRadius: isCompact ? 12 : 24,
              offset: Offset(0, isCompact ? 3 : 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hakkımızda',
              style: TextStyle(
                color: preset.textPrimary,
                fontSize: isCompact ? 14 : 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              aboutText,
              style: TextStyle(
                color: preset.textSecondary,
                fontSize: isCompact ? 12 : 13,
                fontWeight: FontWeight.w500,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _aboutText() {
    final corporateBio = storeData.corporateBio.trim();
    if (corporateBio.isNotEmpty) return corporateBio;
    return storeData.description.trim();
  }

  Widget _buildProfessionalBio(VitrinThemePreset preset) {
    final isCompact = isEmbedded;
    final bioText =
        storeData.corporateBio.trim().isNotEmpty
            ? storeData.corporateBio.trim()
            : storeData.description.trim().isNotEmpty
            ? storeData.description.trim()
            : 'Tüm bilgileriniz, linkleriniz ve iletişim kanallarınız tek yerde.';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 28 : 40),
      child: Column(
        children: [
          Icon(
            Icons.format_quote_rounded,
            color: preset.accent.withValues(alpha: preset.isDark ? 0.28 : 0.18),
            size: isCompact ? 38 : 54,
          ),
          SizedBox(height: isCompact ? 4 : 8),
          Text(
            bioText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isCompact ? 13 : 16,
              height: isCompact ? 1.55 : 1.8,
              color: preset.textSecondary,
              fontStyle: FontStyle.italic,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernLinkHub(VitrinThemePreset preset, double radius) {
    final isCompact = isEmbedded;
    final visibleMarketplaceLinks =
        publicMode
            ? storeData.marketplaceLinks
                .where(
                  (link) =>
                      link.platform.trim().isNotEmpty &&
                      link.url.trim().isNotEmpty,
                )
                .toList()
            : storeData.marketplaceLinks;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 18 : 24),
      child: Column(
        children: [
          ...visibleMarketplaceLinks.map(
            (link) => _ModernLinkItem(
              icon: _getPlatformIcon(link.platform),
              title: link.platform,
              subtitle: link.url.isEmpty ? 'Mağazamızı ziyaret edin' : link.url,
              color: _getPlatformColor(link.platform),
              radius: radius,
              compact: isCompact,
              preset: preset,
              onTap:
                  publicMode
                      ? () => _openExternalUrl(_normalizeExternalUrl(link.url))
                      : null,
            ),
          ),

          if (!publicMode && storeData.marketplaceLinks.isEmpty)
            _ModernLinkItem(
              icon: Icons.auto_stories_rounded,
              title: 'Dijital Katalog',
              subtitle: 'Geniş ürün ve hizmet yelpazesi',
              color: Colors.blueGrey,
              radius: radius,
              compact: isCompact,
              preset: preset,
            ),

          if (!publicMode) ...[
            _ModernLinkItem(
              icon: Icons.verified_rounded,
              title: 'Referanslarımız',
              subtitle: 'Güçlü çözüm ortaklıklarımız',
              color: Colors.indigo.shade400,
              radius: radius,
              compact: isCompact,
              preset: preset,
            ),
            _ModernLinkItem(
              icon: Icons.qr_code_rounded,
              title: 'vCard Kaydet',
              subtitle: 'Hızlı iletişim için rehbere ekle',
              color: Colors.teal.shade500,
              radius: radius,
              compact: isCompact,
              preset: preset,
            ),
          ],

          if (publicMode && _hasVCardData())
            Builder(
              builder:
                  (ctx) => _ModernLinkItem(
                    icon: Icons.contact_page_rounded,
                    title: 'vCard Kaydet',
                    subtitle: 'İletişim bilgilerini hızlıca kopyala',
                    color: Colors.teal.shade500,
                    radius: radius,
                    compact: isCompact,
                    preset: preset,
                    onTap: () => _copyVCardToClipboard(ctx),
                  ),
            ),

          if (publicMode && storeData.referencesLink.trim().isNotEmpty)
            _ModernLinkItem(
              icon: Icons.verified_rounded,
              title: 'Referanslarımız',
              subtitle: 'Müşteri yorumları ve referanslarımız',
              color: Colors.indigo.shade400,
              radius: radius,
              compact: isCompact,
              preset: preset,
              onTap:
                  () => _openExternalUrl(
                    _normalizeExternalUrl(storeData.referencesLink.trim()),
                  ),
            ),
        ],
      ),
    );
  }

  /// vCard kartını göstermek için yeterli veri var mı?
  bool _hasVCardData() {
    if (storeData.name.trim().isEmpty) return false;
    return storeData.whatsapp.trim().isNotEmpty ||
        storeData.instagram.trim().isNotEmpty ||
        storeData.website.trim().isNotEmpty ||
        storeData.address.trim().isNotEmpty;
  }

  /// Boş alanları atlayarak iletişim metnini oluşturur.
  String _buildVCardContactText() {
    final lines = <String>[
      'Mağaza: ${storeData.name.trim()}',
      if (storeData.whatsapp.trim().isNotEmpty)
        'WhatsApp: ${storeData.whatsapp.trim()}',
      if (storeData.instagram.trim().isNotEmpty)
        'Instagram: ${storeData.instagram.trim()}',
      if (storeData.website.trim().isNotEmpty)
        'Web: ${storeData.website.trim()}',
      if (storeData.address.trim().isNotEmpty)
        'Adres: ${storeData.address.trim()}',
    ];
    return lines.join('\n');
  }

  /// İletişim bilgilerini panoya kopyalar ve SnackBar gösterir.
  Future<void> _copyVCardToClipboard(BuildContext context) async {
    final text = _buildVCardContactText();
    await Clipboard.setData(ClipboardData(text: text));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'İletişim bilgileri kopyalandı.',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform) {
      case 'Trendyol':
        return Icons.shopping_bag_rounded;
      case 'Hepsiburada':
        return Icons.shopping_cart_rounded;
      case 'N11':
        return Icons.store_rounded;
      case 'Amazon':
        return Icons.cloud_done_rounded;
      case 'Shopier':
        return Icons.sell_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  Color _getPlatformColor(String platform) {
    switch (platform) {
      case 'Trendyol':
        return const Color(0xFFF27A1A);
      case 'Hepsiburada':
        return const Color(0xFFFF6000);
      case 'N11':
        return const Color(0xFFE11D48);
      case 'Amazon':
        return const Color(0xFF232F3E);
      case 'Shopier':
        return const Color(0xFFDB2777);
      default:
        return const Color(0xFF4B5563);
    }
  }

  Widget _buildPremiumIdentityCard(
    BuildContext context,
    VitrinThemePreset preset,
    double radius,
  ) {
    final isCompact = isEmbedded;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 18 : 24),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isCompact ? 18 : 28),
        decoration: BoxDecoration(
          color: preset.qrBackground,
          borderRadius: BorderRadius.circular(isCompact ? 20 : radius),
          border: Border.all(
            color: preset.qrForeground.withValues(alpha: 0.14),
            width: isCompact ? 1.5 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: isCompact ? 24 : 40,
              offset: Offset(0, isCompact ? 8 : 15),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isCompact ? 10 : 14),
                  decoration: BoxDecoration(
                    color: preset.qrForeground.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
                  ),
                  child: Icon(
                    Icons.qr_code_2_rounded,
                    size: isCompact ? 34 : 54,
                    color: preset.qrForeground,
                  ),
                ),
                SizedBox(width: isCompact ? 14 : 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeData.name.isEmpty
                            ? 'VitrinX Kart'
                            : storeData.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: isCompact ? 16 : 20,
                          color: preset.qrForeground,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(height: isCompact ? 4 : 6),
                      Text(
                        'TÜM BİLGİLERİM TEK QR İLE BURADA',
                        style: TextStyle(
                          fontSize: isCompact ? 8 : 10,
                          color: preset.qrForeground.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w900,
                          letterSpacing: isCompact ? 0.8 : 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 18 : 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.share_rounded, size: isCompact ? 16 : 20),
                label: Text(
                  'PROFİLİ PAYLAŞ',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: isCompact ? 11 : 13,
                    letterSpacing: isCompact ? 1 : 1.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: preset.accent,
                  foregroundColor: preset.buttonText,
                  padding: EdgeInsets.symmetric(vertical: isCompact ? 12 : 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublicQrCard(String url, VitrinThemePreset preset) {
    final isCompact = isEmbedded;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 18 : 24),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 18 : 22,
          vertical: isCompact ? 18 : 22,
        ),
        decoration: BoxDecoration(
          color: preset.qrBackground,
          borderRadius: BorderRadius.circular(isCompact ? 18 : 24),
          border: Border.all(
            color: preset.qrForeground.withValues(alpha: 0.12),
            width: isCompact ? 1 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.055),
              blurRadius: isCompact ? 18 : 28,
              offset: Offset(0, isCompact ? 5 : 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Vitrin QR kodu',
              style: TextStyle(
                color: preset.qrForeground,
                fontSize: isCompact ? 14 : 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            SizedBox(height: isCompact ? 4 : 6),
            Text(
              'Müşteriler bu kodu okutarak vitrininize ulaşabilir.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: preset.qrForeground.withValues(alpha: 0.62),
                fontSize: isCompact ? 11 : 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            SizedBox(height: isCompact ? 14 : 18),
            Container(
              padding: EdgeInsets.all(isCompact ? 10 : 12),
              decoration: BoxDecoration(
                color: preset.qrBackground,
                borderRadius: BorderRadius.circular(isCompact ? 16 : 18),
                border: Border.all(
                  color: preset.qrForeground.withValues(alpha: 0.1),
                ),
              ),
              child: QrImageView(
                data: url,
                version: QrVersions.auto,
                size: isCompact ? 132 : 156,
                backgroundColor: preset.qrBackground,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: preset.qrForeground,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: preset.qrForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernFooter(VitrinThemePreset preset) {
    return Column(
      children: [
        Text(
          publicMode
              ? 'Bu vitrin VitrinX ile oluşturuldu'
              : 'vitrinx.app/${storeData.name.toLowerCase().replaceAll(' ', '-')}',
          style: TextStyle(
            fontSize: publicMode ? 12 : 14,
            fontWeight: publicMode ? FontWeight.w700 : FontWeight.w800,
            color: preset.textSecondary.withValues(
              alpha: preset.isDark ? 0.86 : 0.78,
            ),
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: publicMode ? 26 : 48),
        Container(
          height: 1,
          width: publicMode ? 34 : 50,
          color: preset.border.withValues(alpha: publicMode ? 0.7 : 1),
        ),
        SizedBox(height: publicMode ? 18 : 24),
        if (!publicMode)
          Text(
            'BU BİR VITRINX DİJİTAL KİMLİĞİDİR',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: preset.textSecondary.withValues(alpha: 0.72),
              letterSpacing: 4,
            ),
          ),
      ],
    );
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    try {
      final didLaunch = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!didLaunch) {
        debugPrint('External link could not be opened: $url');
      }
    } catch (error) {
      debugPrint('External link open error: $error');
    }
  }

  String _normalizeExternalUrl(String value) {
    final text = value.trim();
    if (text.startsWith('http://') || text.startsWith('https://')) {
      return text;
    }

    return 'https://$text';
  }

  String _buildInstagramUrl(String value) {
    final text = value.trim();
    if (text.contains('instagram.com')) return _normalizeExternalUrl(text);

    final username = text.replaceFirst('@', '').replaceAll('/', '').trim();
    return 'https://instagram.com/$username';
  }

  String _buildWhatsAppUrl(String value) {
    var number = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (number.startsWith('0') && number.length == 11) {
      number = '90${number.substring(1)}';
    } else if (number.startsWith('5') && number.length == 10) {
      number = '90$number';
    }

    return 'https://wa.me/$number';
  }

  String _buildMapsUrl(String address) {
    if (storeData.latitude != null && storeData.longitude != null) {
      return Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': '${storeData.latitude},${storeData.longitude}',
      }).toString();
    }
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': address.trim(),
    }).toString();
  }

  Widget _buildShareButton(BuildContext context, VitrinThemePreset preset) {
    final slug = storeData.name.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '-');
    final shareUrl = publicLink ?? 'https://vitrinx.app/v/$slug';

    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: shareUrl));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Vitrin bağlantısı panoya kopyalandı!'),
                      ],
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: preset.accent,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.all(isEmbedded ? 8.0 : 12.0),
                child: Icon(
                  Icons.share_rounded,
                  color: Colors.white,
                  size: isEmbedded ? 16 : 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShelfWhatsAppButton(
    BuildContext context,
    VitrinThemePreset preset,
    VitrinGalleryPreviewItem item,
    bool isCompact,
  ) {
    final title = item.title.trim().isNotEmpty
        ? item.title.trim()
        : 'Vitrin Görseli';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0x1A25D366),
        borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
        border: Border.all(
          color: const Color(0xFF25D366).withValues(alpha: isDark ? 0.35 : 0.22),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!publicMode) {
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
            final url = _buildWhatsAppInquiryUrl(
              storeData.whatsapp,
              storeData.name,
              title,
            );
            _openExternalUrl(url);
          },
          borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: isCompact ? 10 : 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF25D366),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  isCompact ? 'Görseldeki Ürünü Sor' : 'Fotoğraftaki Ürünü WhatsApp\'tan Sor',
                  style: const TextStyle(
                    color: Color(0xFF25D366),
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

  String _buildWhatsAppInquiryUrl(
    String numberValue,
    String storeName,
    String itemTitle,
  ) {
    var number = numberValue.replaceAll(RegExp(r'[^0-9]'), '');
    if (number.startsWith('0') && number.length == 11) {
      number = '90${number.substring(1)}';
    } else if (number.startsWith('5') && number.length == 10) {
      number = '90$number';
    }

    final message =
        "Merhaba! $storeName vitrininizdeki '$itemTitle' görseli hakkında bilgi alabilir miyim?";
    final encodedMessage = Uri.encodeComponent(message);
    return 'https://wa.me/$number?text=$encodedMessage';
  }
}

class _ActionIconBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double radius;
  final bool compact;
  final bool emphasis;
  final VoidCallback? onTap;

  const _ActionIconBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.radius,
    this.compact = false,
    this.emphasis = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final buttonRadius = compact ? 12.0 : 16.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        emphasis ? color : color.withValues(alpha: isDark ? 0.18 : 0.09);
    final foregroundColor = emphasis ? Colors.white : color;
    final borderColor =
        emphasis
            ? color.withValues(alpha: isDark ? 0.38 : 0.22)
            : color.withValues(alpha: isDark ? 0.22 : 0.12);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(buttonRadius),
        border: Border.all(color: borderColor),
        boxShadow:
            emphasis
                ? [
                  BoxShadow(
                    color: color.withValues(alpha: isDark ? 0.22 : 0.18),
                    blurRadius: compact ? 14 : 22,
                    offset: Offset(0, compact ? 5 : 8),
                  ),
                ]
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(buttonRadius),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 20,
              vertical: compact ? 9 : 14,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(icon, size: compact ? 15 : 20, color: foregroundColor),
                SizedBox(width: compact ? 7 : 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: compact ? 11 : 13,
                    fontWeight: FontWeight.w800,
                    color: foregroundColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernLinkItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final double radius;
  final bool compact;
  final VitrinThemePreset preset;
  final VoidCallback? onTap;

  const _ModernLinkItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.radius,
    required this.preset,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        preset.isDark && color.computeLuminance() < 0.35
            ? preset.accent
            : color;

    return Container(
      margin: EdgeInsets.only(bottom: compact ? 10 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            preset.surface,
            preset.surfaceSoft.withValues(alpha: preset.isDark ? 0.36 : 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(compact ? 16 : 24),
        border: Border.all(
          color: preset.border.withValues(alpha: preset.isDark ? 0.9 : 0.78),
          width: compact ? 1 : 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: preset.isDark ? 0.14 : 0.045),
            blurRadius: compact ? 12 : 24,
            offset: Offset(0, compact ? 3 : 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(compact ? 16 : 24),
          child: Padding(
            padding: EdgeInsets.all(compact ? 13 : 20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(compact ? 9 : 13),
                  decoration: BoxDecoration(
                    color: effectiveColor.withValues(
                      alpha: preset.isDark ? 0.2 : 0.11,
                    ),
                    borderRadius: BorderRadius.circular(compact ? 11 : 16),
                    border: Border.all(
                      color: effectiveColor.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: effectiveColor,
                    size: compact ? 18 : 22,
                  ),
                ),
                SizedBox(width: compact ? 12 : 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: compact ? 14 : 16,
                          color: preset.textPrimary,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(height: compact ? 2 : 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: preset.textSecondary,
                          fontSize: compact ? 10.5 : 12,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: compact ? 24 : 30,
                  height: compact ? 24 : 30,
                  decoration: BoxDecoration(
                    color: preset.surfaceSoft.withValues(
                      alpha: preset.isDark ? 0.38 : 0.72,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: preset.border.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: preset.textSecondary.withValues(alpha: 0.75),
                    size: compact ? 10 : 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
