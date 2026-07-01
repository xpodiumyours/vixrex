import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vitrinx/config/business_category_config.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/theme/app_colors.dart';
import 'package:vitrinx/theme/vitrin_theme_preset.dart';
import 'package:vitrinx/utils/whatsapp_link_helper.dart';
import 'package:vitrinx/widgets/status_chip.dart';
import 'package:vitrinx/services/seo_helper.dart';
import 'package:vitrinx/models/vitrin_gallery_preview_item.dart';
import 'package:vitrinx/widgets/vitrin_view/vitrin_desktop_layout.dart';
import 'package:vitrinx/widgets/vitrin_view/vitrin_mobile_layout.dart';
import 'package:vitrinx/widgets/vitrin_view/vitrin_booking_cta.dart';
import 'package:vitrinx/widgets/vitrin_view/vitrin_qr.dart';
import 'package:vitrinx/widgets/vitrin_view/vitrin_footer.dart';
import 'package:vitrinx/widgets/vitrin_view/vitrin_products_catalog.dart';
import 'package:vitrinx/widgets/vitrin_view/vitrin_shelf_gallery.dart';
import 'package:vitrinx/widgets/vitrin_view/vitrin_profile_tools.dart';
import 'package:vitrinx/widgets/vitrin_view/vitrin_premium_identity_card.dart';
import 'package:vitrinx/widgets/vitrin_view/vitrin_links_hub.dart';

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
    if (publicMode) {
      injectStoreJsonLd(storeData, publicUrl: publicLink);
    }
    final preset = vitrinThemePresetFor(storeData.theme);
    final themeData = _getThemeData(preset);
    final radius = isEmbedded ? AppColors.radius24 : AppColors.radius40;
    final galleryItems = _effectiveGalleryItems();
    final content =
        publicMode && !isEmbedded
            ? LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 860;
                return isDesktop
                    ? _buildPublicDesktopLayout(
                      context,
                      preset,
                      radius,
                      galleryItems,
                    )
                    : VitrinMobileLayout(
                        hero: _buildPublicProfileHero(
                          context,
                          preset,
                          radius,
                          galleryItems,
                          desktop: false,
                        ),
                        bookingCTA: VitrinBookingCTA(
                          storeData: storeData,
                          preset: preset,
                          isEmbedded: isEmbedded,
                          publicMode: publicMode,
                        ),
                        productsCatalog: VitrinProductsCatalog(
                          storeData: storeData,
                          preset: preset,
                          isEmbedded: isEmbedded,
                          publicMode: publicMode,
                          onOpenExternalUrl: _openExternalUrl,
                        ),
                        profileTools: VitrinProfileTools(
                          storeData: storeData,
                          preset: preset,
                          isEmbedded: isEmbedded,
                          publicLink: publicLink,
                          hasVCardData: _hasVCardData(),
                          onDownloadVCard: _downloadVCard,
                          onShareVitrin: _shareVitrin,
                          onOpenExternalUrl: _openExternalUrl,
                          onNormalizeExternalUrl: _normalizeExternalUrl,
                        ),
                        aboutCard: _buildAboutCard(preset),
                        linkHub: VitrinLinksHub(
                          storeData: storeData,
                          preset: preset,
                          isEmbedded: isEmbedded,
                          publicMode: publicMode,
                          onGetPlatformIcon: _getPlatformIcon,
                          onOpenExternalUrl: _openExternalUrl,
                          onNormalizeExternalUrl: _normalizeExternalUrl,
                        ),
                        shelfImageCard: VitrinShelfGallery(preset: preset, galleryItems: galleryItems, isEmbedded: isEmbedded),
                        qrCard: publicLink != null
                            ? VitrinQrCard(
                              url: publicLink!,
                              preset: preset,
                              isEmbedded: isEmbedded,
                            )
                            : const SizedBox(),
                        footer: VitrinFooter(
                          storeData: storeData,
                          preset: preset,
                          publicMode: publicMode,
                        ),
                        isBookingEnabled: storeData.bookingSettings?.isEnabled == true,
                        isStore: storeData.isStore,
                        hasAboutText: _aboutText().isNotEmpty,
                        hasMarketplaceLinks: storeData.marketplaceLinks.any(
                          (link) => link.url.trim().isNotEmpty,
                        ),
                        hasGalleryMedia: galleryItems.isNotEmpty,
                        hasQrCard: publicLink?.isNotEmpty ?? false,
                      );
              },
            )
            : _buildDefaultScrollableContent(
              context,
              preset,
              radius,
              galleryItems,
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

  Widget _buildDefaultScrollableContent(
    BuildContext context,
    VitrinThemePreset preset,
    double radius,
    List<VitrinGalleryPreviewItem> galleryItems,
  ) {
    final hasGalleryMedia = galleryItems.isNotEmpty;
    final hasBio = !publicMode;
    final hasAbout = publicMode && _aboutText().isNotEmpty;

    Widget bioOrAbout;
    if (hasBio) {
      bioOrAbout = Column(
        children: [
          _buildProfessionalBio(preset),
          SizedBox(height: isEmbedded ? 16 : 48),
        ],
      );
    } else if (hasAbout) {
      bioOrAbout = Column(
        children: [
          _buildAboutCard(preset),
          SizedBox(height: isEmbedded ? 16 : 30),
        ],
      );
    } else {
      bioOrAbout = const SizedBox();
    }

    return VitrinDefaultLayout(
      header: _buildModernHeader(context, preset, radius, galleryItems),
      identityBlock: _buildStoreIdentityBlock(preset),
      bookingCTA: VitrinBookingCTA(
        storeData: storeData,
        preset: preset,
        isEmbedded: isEmbedded,
        publicMode: publicMode,
      ),
      premiumActionButtons: _buildPremiumActionButtons(context, preset, radius),
      bioOrAbout: bioOrAbout,
      shelfImageCard: VitrinShelfGallery(preset: preset, galleryItems: galleryItems, isEmbedded: isEmbedded),
      productsCatalog: VitrinProductsCatalog(
        storeData: storeData,
        preset: preset,
        isEmbedded: isEmbedded,
        publicMode: publicMode,
        onOpenExternalUrl: _openExternalUrl,
      ),
      profileTools: VitrinProfileTools(
        storeData: storeData,
        preset: preset,
        isEmbedded: isEmbedded,
        publicLink: publicLink,
        hasVCardData: _hasVCardData(),
        onDownloadVCard: _downloadVCard,
        onShareVitrin: _shareVitrin,
        onOpenExternalUrl: _openExternalUrl,
        onNormalizeExternalUrl: _normalizeExternalUrl,
      ),
      linkHub: VitrinLinksHub(
        storeData: storeData,
        preset: preset,
        isEmbedded: isEmbedded,
        publicMode: publicMode,
        onGetPlatformIcon: _getPlatformIcon,
        onOpenExternalUrl: _openExternalUrl,
        onNormalizeExternalUrl: _normalizeExternalUrl,
      ),
      premiumIdentityCard: VitrinPremiumIdentityCard(
        storeData: storeData,
        preset: preset,
        radius: radius,
        isEmbedded: isEmbedded,
        onSharePressed: publicLink != null ? () => _shareVitrin(context, publicLink!, preset) : null,
      ),
      qrCard: publicLink != null ? VitrinQrCard(url: publicLink!, preset: preset, isEmbedded: isEmbedded) : const SizedBox(),
      footer: VitrinFooter(storeData: storeData, preset: preset, publicMode: publicMode),
      isEmbedded: isEmbedded,
      isBookingEnabled: storeData.bookingSettings?.isEnabled == true,
      hasVisibleActions: _hasVisibleActions(),
      hasGalleryMedia: hasGalleryMedia,
      isStore: storeData.isStore,
      publicMode: publicMode,
      hasQrCard: publicMode && (publicLink?.isNotEmpty ?? false),
      showPremiumIdentityCard: !publicMode,
    );
  }

  Widget _buildPublicDesktopLayout(
    BuildContext context,
    VitrinThemePreset preset,
    double radius,
    List<VitrinGalleryPreviewItem> galleryItems,
  ) {
    final hasGalleryMedia = galleryItems.isNotEmpty;
    final hasSideLinks = storeData.marketplaceLinks.any(
      (link) => link.url.trim().isNotEmpty,
    );

    return VitrinDesktopLayout(
      hero: _buildPublicProfileHero(
        context,
        preset,
        radius,
        galleryItems,
        desktop: true,
      ),
      bookingCTA: VitrinBookingCTA(
        storeData: storeData,
        preset: preset,
        isEmbedded: isEmbedded,
        publicMode: publicMode,
      ),
      productsCatalog: VitrinProductsCatalog(
        storeData: storeData,
        preset: preset,
        isEmbedded: isEmbedded,
        publicMode: publicMode,
        onOpenExternalUrl: _openExternalUrl,
      ),
      aboutCard: _buildAboutCard(preset),
      profileTools: VitrinProfileTools(
        storeData: storeData,
        preset: preset,
        isEmbedded: isEmbedded,
        publicLink: publicLink,
        hasVCardData: _hasVCardData(),
        onDownloadVCard: _downloadVCard,
        onShareVitrin: _shareVitrin,
        onOpenExternalUrl: _openExternalUrl,
        onNormalizeExternalUrl: _normalizeExternalUrl,
      ),
      qrCard: publicLink != null ? VitrinQrCard(url: publicLink!, preset: preset, isEmbedded: isEmbedded) : const SizedBox(),
      linkHub: VitrinLinksHub(
        storeData: storeData,
        preset: preset,
        isEmbedded: isEmbedded,
        publicMode: publicMode,
        onGetPlatformIcon: _getPlatformIcon,
        onOpenExternalUrl: _openExternalUrl,
        onNormalizeExternalUrl: _normalizeExternalUrl,
      ),
      shelfImageCard: VitrinShelfGallery(preset: preset, galleryItems: galleryItems, isEmbedded: isEmbedded),
      footer: VitrinFooter(storeData: storeData, preset: preset, publicMode: publicMode),
      hasSideLinks: hasSideLinks,
      hasGalleryMedia: hasGalleryMedia,
      isBookingEnabled: storeData.bookingSettings?.isEnabled == true,
      isStore: storeData.isStore,
      hasAboutText: _aboutText().isNotEmpty,
      hasQrCard: publicLink?.isNotEmpty ?? false,
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

  Widget _buildPublicProfileHero(
    BuildContext context,
    VitrinThemePreset preset,
    double radius,
    List<VitrinGalleryPreviewItem> galleryItems, {
    required bool desktop,
  }) {
    final heroItem = galleryItems.isEmpty ? null : galleryItems.first;
    final heroHeight = desktop ? 376.0 : 168.0;
    final avatarSize = desktop ? 116.0 : 92.0;
    final actions = _buildVisibleActions(
      context,
      radius,
      true,
      actionColor: preset.accent,
    );
    final description = _publicHeroDescription();

    final cover = Stack(
      fit: StackFit.expand,
      children: [
        if (heroItem != null)
          _buildGalleryImage(
            heroItem,
            errorBuilder: (_, __, ___) => _buildHeaderFallbackSurface(preset),
          )
        else
          _buildHeaderFallbackSurface(preset),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: desktop ? Alignment.centerLeft : Alignment.topCenter,
              end: desktop ? Alignment.centerRight : Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: desktop ? 0.62 : 0.10),
                Colors.black.withValues(alpha: desktop ? 0.34 : 0.24),
                preset.background.withValues(alpha: desktop ? 0.72 : 0.66),
              ],
            ),
          ),
        ),
      ],
    );

    if (desktop) {
      return Container(
        height: heroHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: preset.border.withValues(alpha: 0.72),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 34,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            cover,
            Positioned(
              top: 22,
              right: 22,
              child: _buildShareButton(context, preset),
            ),
            Positioned(
              left: 38,
              right: 38,
              bottom: 34,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildPublicAvatar(preset, avatarSize),
                  const SizedBox(width: 22),
                  Expanded(
                    child: _buildPublicHeroText(
                      preset,
                      description,
                      desktop: true,
                    ),
                  ),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(width: 28),
                    SizedBox(
                      width: 360,
                      child: _buildPublicHeroActionGrid(actions),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: preset.background,
        border: Border(
          bottom: BorderSide(
            color: preset.border.withValues(alpha: 0.58),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: double.infinity,
                height: heroHeight,
                child: cover,
              ),
              Positioned(
                top: 14,
                right: 16,
                child: _buildShareButton(context, preset),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: -avatarSize / 2,
                child: Center(child: _buildPublicAvatar(preset, avatarSize)),
              ),
            ],
          ),
          SizedBox(height: avatarSize / 2 + 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: _buildPublicHeroText(preset, description, desktop: false),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: _buildPublicHeroActionGrid(actions),
            ),
          ],
          const SizedBox(height: 22),
        ],
      ),
    );
  }

  Widget _buildPublicHeroText(
    VitrinThemePreset preset,
    String description, {
    required bool desktop,
  }) {
    final storeName = storeData.name.trim();
    final businessType = storeData.businessType.trim();
    final status = storeData.status.trim();
    final titleText = storeName.isEmpty ? 'Dijital Vitrin' : storeName;

    return Column(
      crossAxisAlignment:
          desktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          titleText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: desktop ? TextAlign.start : TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: desktop ? 34 : 31,
            fontWeight: FontWeight.w900,
            height: 1.04,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: desktop ? WrapAlignment.start : WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (businessType.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: Text(
                  businessType.toUpperCase(),
                  style: TextStyle(
                    color: preset.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            if (status.isNotEmpty) StatusChip(status: status),
          ],
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 13),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: desktop ? 520 : 350),
            child: Text(
              description,
              maxLines: desktop ? 3 : 2,
              overflow: TextOverflow.ellipsis,
              textAlign: desktop ? TextAlign.start : TextAlign.center,
              style: TextStyle(
                color: preset.textSecondary,
                fontSize: desktop ? 14 : 13,
                fontWeight: FontWeight.w600,
                height: 1.45,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPublicHeroActionGrid(List<Widget> actions) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.hasBoundedWidth ? constraints.maxWidth : 340.0;
        final spacing = availableWidth < 340 ? 9.0 : 12.0;
        final itemWidth =
            actions.length == 1
                ? availableWidth
                : (availableWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              actions
                  .map(
                    (action) => SizedBox(
                      width: itemWidth.clamp(132.0, availableWidth).toDouble(),
                      child: action,
                    ),
                  )
                  .toList(),
        );
      },
    );
  }

  Widget _buildPublicAvatar(VitrinThemePreset preset, double size) {
    final logoUrl = storeData.logoUrl?.trim() ?? '';

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size > 100 ? 4 : 3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: preset.background,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.86),
          width: size > 100 ? 2.6 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child:
            logoUrl.isNotEmpty
                ? Image.network(
                  logoUrl,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (_, __, ___) => _buildAvatarFallback(preset, size),
                )
                : _buildAvatarFallback(preset, size),
      ),
    );
  }

  Widget _buildAvatarFallback(VitrinThemePreset preset, double size) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            preset.surfaceSoft.withValues(alpha: 0.96),
            preset.surface.withValues(alpha: 0.96),
            preset.background,
          ],
        ),
      ),
      child: Center(
        child: Text(
          _storeInitials(),
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.32,
            fontWeight: FontWeight.w900,
            height: 1,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }

  String _storeInitials() {
    final words =
        storeData.name
            .trim()
            .split(RegExp(r'\s+'))
            .where((word) => word.isNotEmpty)
            .toList();
    if (words.isEmpty) return 'VX';
    if (words.length == 1) {
      final initials =
          words.first.runes.take(2).map(String.fromCharCode).join();
      return initials.toUpperCase();
    }
    return words
        .take(2)
        .map((word) => String.fromCharCode(word.runes.first))
        .join()
        .toUpperCase();
  }

  String _publicHeroDescription() {
    final description = storeData.description.trim();
    if (description.isNotEmpty) return description;

    final bio = storeData.corporateBio.trim();
    if (bio.isNotEmpty) return bio;

    if (storeData.products.isNotEmpty) {
      return 'Ürünleri, iletişim kanalları ve konumu tek dijital vitrinde.';
    }
    return '';
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
    final workingHours = storeData.workingHours.trim();
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
          // Çalışma saatleri — sadece doluysa göster
          if (workingHours.isNotEmpty) ...[
            SizedBox(height: isEmbedded ? 8 : 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: isEmbedded ? 12 : 15,
                  color: preset.textSecondary,
                ),
                SizedBox(width: isEmbedded ? 4 : 5),
                Flexible(
                  child: Text(
                    workingHours,
                    textAlign: TextAlign.center,
                    maxLines: isEmbedded ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isEmbedded ? 11 : 13,
                      color: preset.textSecondary,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
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

  Widget _buildPremiumActionButtons(
    BuildContext context,
    VitrinThemePreset preset,
    double radius,
  ) {
    final isCompact = isEmbedded;
    final actions = _buildVisibleActions(
      context,
      radius,
      isCompact,
      actionColor: preset.accent,
    );
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
                        width:
                            itemWidth.clamp(112.0, availableWidth).toDouble(),
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

    return WhatsAppLinkHelper.isValidTurkeyMobile(storeData.whatsapp) ||
        storeData.instagram.trim().isNotEmpty ||
        _publicWebsiteActionUrl().isNotEmpty ||
        storeData.googleBusinessLink.trim().isNotEmpty ||
        storeData.address.trim().isNotEmpty ||
        (storeData.latitude != null && storeData.longitude != null);
  }

  String _publicWebsiteActionUrl() {
    final generatedLink = publicLink?.trim() ?? '';
    final normalizedGeneratedLink = _normalizeExternalUrl(generatedLink);
    if (publicMode && normalizedGeneratedLink.isNotEmpty) {
      return normalizedGeneratedLink;
    }
    return _normalizeExternalUrl(storeData.website);
  }

  List<Widget> _buildVisibleActions(
    BuildContext context,
    double radius,
    bool isCompact, {
    Color? actionColor,
  }) {
    final config = BusinessCategoryConfig.fromCategoryLabel(storeData.kategori);
    final ctaLabel = config.ctaLabel;
    final profileActionColor = actionColor ?? AppColors.primary;

    if (!publicMode) {
      return [
        _ActionIconBtn(
          label: ctaLabel,
          icon: Icons.chat_bubble_rounded,
          color: profileActionColor,
          compact: isCompact,
          onTap: () {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Müşteriler bu butona bastığında WhatsApp'tan '$ctaLabel' talebi gönderir.",
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        _ActionIconBtn(
          label: 'Instagram',
          icon: Icons.camera_rounded,
          color: profileActionColor,
          compact: isCompact,
          onTap: () {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Müşteriler bu butona bastığında Instagram profilinize yönlendirilir.",
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        if (storeData.website.isNotEmpty)
          _ActionIconBtn(
            label: 'Web',
            icon: Icons.language_rounded,
            color: profileActionColor,
            compact: isCompact,
            onTap: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Müşteriler bu butona bastığında web sitenize yönlendirilir.",
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        _ActionIconBtn(
          label: 'Yol Tarifi',
          icon: Icons.location_on_rounded,
          color: profileActionColor,
          compact: isCompact,
          onTap: () {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Müşteriler bu butona bastığında Google Haritalar'dan yol tarifi alır.",
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        if (storeData.googleBusinessLink.isNotEmpty)
          _ActionIconBtn(
            label: 'Yorum Yap',
            icon: Icons.star_rate_rounded,
            color: profileActionColor,
            compact: isCompact,
            onTap: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Müşteriler bu butona bastığında Google yorum sayfanıza yönlendirilir.",
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
      ];
    }

    return [
      if (WhatsAppLinkHelper.isValidTurkeyMobile(storeData.whatsapp))
        _ActionIconBtn(
          label: ctaLabel,
          icon: Icons.chat_bubble_rounded,
          color: profileActionColor,
          compact: isCompact,
          emphasis: true,
          onTap: () {
            final url = WhatsAppLinkHelper.buildCategoryGeneralUrl(
              number: storeData.whatsapp,
              storeName: storeData.name,
              categoryId: config.id,
            );
            if (url != null) {
              _openExternalUrl(context, url);
            }
          },
        ),
      if (storeData.instagram.trim().isNotEmpty)
        _ActionIconBtn(
          label: 'Instagram',
          icon: Icons.camera_rounded,
          color: profileActionColor,
          compact: isCompact,
          onTap:
              () => _openExternalUrl(
                context,
                _buildInstagramUrl(storeData.instagram),
              ),
        ),
      if (_publicWebsiteActionUrl().isNotEmpty)
        _ActionIconBtn(
          label: 'Web Sitesi',
          icon: Icons.language_rounded,
          color: profileActionColor,
          compact: isCompact,
          onTap: () => _openExternalUrl(context, _publicWebsiteActionUrl()),
        ),
      if (storeData.googleBusinessLink.trim().isNotEmpty)
        _ActionIconBtn(
          label: 'Google\'da Yorum Yap',
          icon: Icons.star_rate_rounded,
          color: profileActionColor,
          compact: isCompact,
          onTap:
              () => _openExternalUrl(
                context,
                _normalizeExternalUrl(storeData.googleBusinessLink),
              ),
        ),
      if (storeData.address.trim().isNotEmpty ||
          (storeData.latitude != null && storeData.longitude != null))
        _ActionIconBtn(
          label: 'Yol Tarifi',
          icon: Icons.location_on_rounded,
          color: profileActionColor,
          compact: isCompact,
          onTap:
              () => _openExternalUrl(context, _buildMapsUrl(storeData.address)),
        ),
    ];
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

  /// vCard kartını göstermek için yeterli veri var mı?
  bool _hasVCardData() {
    if (storeData.name.trim().isEmpty) return false;
    return WhatsAppLinkHelper.isValidTurkeyMobile(storeData.whatsapp) ||
        storeData.instagram.trim().isNotEmpty ||
        storeData.website.trim().isNotEmpty ||
        storeData.address.trim().isNotEmpty;
  }

  /// Boş alanları atlayarak iletişim metnini oluşturur.
  String _buildVCardContactText() {
    final lines = <String>[
      'Mağaza: ${storeData.name.trim()}',
      if (WhatsAppLinkHelper.isValidTurkeyMobile(storeData.whatsapp))
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

  /// vCard (.vcf) dosya içeriğini standart formatta oluşturur.
  String _buildVCardFileContent() {
    final name = storeData.name.trim();
    final phone = WhatsAppLinkHelper.normalizeTurkeyMobile(storeData.whatsapp);
    final address = storeData.address.trim();
    final website = storeData.website.trim();
    final bio =
        storeData.corporateBio.trim().isNotEmpty
            ? storeData.corporateBio.trim()
            : storeData.description.trim();

    final card = StringBuffer();
    card.writeln('BEGIN:VCARD');
    card.writeln('VERSION:3.0');
    card.writeln('FN:$name');
    card.writeln('ORG:$name');
    if (phone != null) {
      card.writeln('TEL;TYPE=CELL,VOICE:+$phone');
    }
    if (website.isNotEmpty) {
      card.writeln('URL;TYPE=WORK:$website');
    }
    if (address.isNotEmpty) {
      final escapedAddress = address
          .replaceAll(',', '\\,')
          .replaceAll('\n', ' ');
      card.writeln('ADR;TYPE=WORK:;;$escapedAddress;;;;');
    }
    if (bio.isNotEmpty) {
      card.writeln('NOTE:$bio');
    }
    card.writeln('END:VCARD');
    return card.toString();
  }

  /// vCard verisini cihaz seviyesinde dosya olarak indirir / açar.
  /// Başarısızlık durumunda otomatik olarak panoya kopyalama moduna düşer.
  Future<void> _downloadVCard(BuildContext context) async {
    final vCardText = _buildVCardFileContent();
    final uri = Uri.dataFromString(
      vCardText,
      mimeType: 'text/vcard',
      parameters: {'charset': 'utf-8'},
    );

    try {
      final didLaunch = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!didLaunch && context.mounted) {
        await _copyVCardToClipboard(context);
      }
    } catch (_) {
      if (context.mounted) {
        await _copyVCardToClipboard(context);
      }
    }
  }

  IconData _getPlatformIcon(String platform) {
    final p = platform.toLowerCase().trim();
    // E-ticaret platformları
    if (p == 'trendyol') return Icons.shopping_bag_rounded;
    if (p == 'hepsiburada') return Icons.shopping_cart_rounded;
    if (p == 'n11') return Icons.store_rounded;
    if (p == 'amazon') return Icons.cloud_done_rounded;
    if (p == 'shopier') return Icons.sell_rounded;
    if (p.contains('çiçeksepeti')) return Icons.local_florist_rounded;
    // Sosyal & harita
    if (p.contains('instagram')) return Icons.camera_alt_rounded;
    if (p.contains('whatsapp')) return Icons.chat_bubble_rounded;
    if (p.contains('google')) return Icons.verified_rounded;
    if (p.contains('youtube')) return Icons.play_circle_rounded;
    if (p.contains('facebook') || p.contains('meta')) {
      return Icons.people_alt_rounded;
    }
    if (p.contains('tiktok')) return Icons.music_note_rounded;
    if (p.contains('twitter') || p.contains('x.com')) {
      return Icons.alternate_email_rounded;
    }
    // İş kategorileri — Türkçe anahtar kelimeler
    if (p.contains('randevu')) return Icons.event_available_rounded;
    if (p.contains('menü') || p.contains('menu') || p.contains('günün')) {
      return Icons.local_dining_rounded;
    }
    if (p.contains('paket') || p.contains('teslimat') || p.contains('servis')) {
      return Icons.delivery_dining_rounded;
    }
    if (p.contains('teknik') || p.contains('onarım') || p.contains('tamir')) {
      return Icons.construction_rounded;
    }
    if (p.contains('hizmet') || p.contains('bakım')) return Icons.spa_rounded;
    if (p.contains('kataloğ') || p.contains('catalog') || p.contains('ürün')) {
      return Icons.auto_stories_rounded;
    }
    if (p.contains('konum') || p.contains('adres') || p.contains('harita')) {
      return Icons.location_on_rounded;
    }
    if (p.contains('web') || p.contains('site')) return Icons.language_rounded;
    if (p.contains('telefon') || p.contains('ara') || p.contains('call')) {
      return Icons.phone_rounded;
    }
    if (p.contains('e-posta') || p.contains('mail') || p.contains('e‑posta')) {
      return Icons.email_rounded;
    }
    return Icons.link_rounded;
  }

  Future<void> _openExternalUrl(BuildContext context, String? url) async {
    final trimmed = (url ?? '').trim();
    if (trimmed.isEmpty) return;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return;

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return;
    }

    try {
      final didLaunch = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!didLaunch) {
        if (context.mounted) {
          _showLinkError(context);
        }
      }
    } catch (_) {
      if (context.mounted) {
        _showLinkError(context);
      }
    }
  }

  void _showLinkError(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Bağlantı açılamadı. Lütfen tekrar deneyin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _normalizeExternalUrl(String value) {
    return VitrinView.normalizeExternalUrl(value);
  }

  static String normalizeExternalUrl(String value) {
    final text = value.trim();
    if (text.isEmpty) return '';

    final uri = Uri.tryParse(text);
    if (uri == null) return '';

    if (uri.hasScheme) {
      final scheme = uri.scheme.toLowerCase();
      if (scheme == 'http' || scheme == 'https') {
        return text;
      }
      return '';
    }

    if (!text.contains('.')) {
      return '';
    }
    return 'https://$text';
  }

  String _buildInstagramUrl(String value) {
    final text = value.trim();
    if (text.contains('instagram.com')) return _normalizeExternalUrl(text);

    final username = text.replaceFirst('@', '').replaceAll('/', '').trim();
    return 'https://instagram.com/$username';
  }

  String _buildMapsUrl(String address) {
    if (storeData.latitude != null && storeData.longitude != null) {
      return Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '${storeData.latitude},${storeData.longitude}',
      }).toString();
    }
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': address.trim(),
    }).toString();
  }

  Widget _buildShareButton(BuildContext context, VitrinThemePreset preset) {
    final slug = storeData.name.toLowerCase().replaceAll(
      RegExp(r'[^a-zA-Z0-9]'),
      '-',
    );
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
              onTap: () => _shareVitrin(context, shareUrl, preset),
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

  Future<void> _shareVitrin(
    BuildContext context,
    String shareUrl,
    VitrinThemePreset preset,
  ) async {
    final renderBox = context.findRenderObject() as RenderBox?;
    final shareOrigin =
        renderBox == null
            ? null
            : renderBox.localToGlobal(Offset.zero) & renderBox.size;
    final storeName = storeData.name.trim();
    final shareText =
        storeName.isEmpty
            ? 'VitrinX vitrini\n$shareUrl'
            : '$storeName vitrini\n$shareUrl';

    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          title: storeName.isEmpty ? 'VitrinX' : storeName,
          sharePositionOrigin: shareOrigin,
        ),
      );
      if (result.status != ShareResultStatus.unavailable) return;
    } catch (_) {
      // Desteklenmeyen cihazlarda bağlantı kopyalama yedeği kullanılır.
    }

    await Clipboard.setData(ClipboardData(text: shareUrl));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Paylaşım desteklenmedi, bağlantı kopyalandı.'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: preset.accent,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
class _ActionIconBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool compact;
  final bool emphasis;
  final VoidCallback? onTap;

  const _ActionIconBtn({
    required this.label,
    required this.icon,
    required this.color,
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
    final foregroundColor =
        emphasis && color.computeLuminance() > 0.42
            ? const Color(0xFF04151F)
            : emphasis
            ? Colors.white
            : color;
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
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 11 : 13,
                      fontWeight: FontWeight.w800,
                      color: foregroundColor,
                    ),
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

