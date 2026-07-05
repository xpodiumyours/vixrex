import 'package:flutter/material.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/models/vitrin_gallery_preview_item.dart';
import 'package:vixrex/theme/vitrin_theme_preset.dart';
import 'package:vixrex/widgets/vitrin_view/vitrin_about_vcard.dart';
import 'package:vixrex/widgets/vitrin_view/vitrin_action_button_widgets.dart';
import 'package:vixrex/widgets/vitrin_view/vitrin_action_buttons.dart';
import 'package:vixrex/widgets/vitrin_view/vitrin_booking_cta.dart';
import 'package:vixrex/widgets/vitrin_view/vitrin_desktop_layout.dart';
import 'package:vixrex/widgets/vitrin_view/vitrin_footer.dart';
import 'package:vixrex/widgets/vitrin_view/vitrin_header_identity.dart';
import 'package:vixrex/widgets/vitrin_view/vitrin_links_hub.dart';
import 'package:vixrex/widgets/vitrin_view/vitrin_mobile_layout.dart';
import 'package:vixrex/widgets/vitrin_view/vitrin_premium_identity_card.dart';
import 'package:vixrex/widgets/vitrin_view/vitrin_products_catalog.dart';
import 'package:vixrex/widgets/vitrin_view/vitrin_profile_tools.dart';
import 'package:vixrex/widgets/vitrin_view/vitrin_public_hero.dart';
import 'package:vixrex/widgets/vitrin_view/vitrin_qr.dart';
import 'package:vixrex/widgets/vitrin_view/vitrin_shelf_gallery.dart';
import 'package:vixrex/widgets/vitrin_view/vitrin_view_actions.dart';
import 'package:vixrex/widgets/vitrin_view/vitrin_view_content.dart';

class VitrinDefaultContentSection extends StatelessWidget {
  final StoreData storeData;
  final VitrinThemePreset preset;
  final bool isEmbedded;
  final bool publicMode;
  final bool compactEmbeddedHeader;
  final String? publicLink;
  final double radius;
  final List<VitrinGalleryPreviewItem> galleryItems;

  const VitrinDefaultContentSection({
    super.key,
    required this.storeData,
    required this.preset,
    required this.isEmbedded,
    required this.publicMode,
    required this.compactEmbeddedHeader,
    required this.publicLink,
    required this.radius,
    required this.galleryItems,
  });

  @override
  Widget build(BuildContext context) {
    final hasGalleryMedia = galleryItems.isNotEmpty;
    final aboutText = VitrinViewContent.aboutText(storeData);
    final shareUrl = VitrinViewContent.buildShareUrl(storeData, publicLink);
    final monogramText = VitrinViewContent.storeInitials(storeData);
    final hasBio = !publicMode;
    final hasAbout = publicMode && aboutText.isNotEmpty;
    final isBookingEnabled = storeData.bookingSettings?.isEnabled == true;
    final hasQrCard = publicLink?.isNotEmpty ?? false;
    final bookingCta = VitrinBookingCTA(
      storeData: storeData,
      preset: preset,
      isEmbedded: isEmbedded,
      publicMode: publicMode,
    );
    final actions = buildVitrinVisibleActions(
      context: context,
      storeData: storeData,
      publicMode: publicMode,
      isCompact: isEmbedded,
      publicLink: publicLink,
      actionColor: preset.accent,
      onOpenExternalUrl: VitrinViewActions.openExternalUrl,
    );

    final bioOrAbout =
        hasBio
            ? Column(
              children: [
                VitrinProfessionalBio(
                  storeData: storeData,
                  preset: preset,
                  isEmbedded: isEmbedded,
                ),
                SizedBox(height: isEmbedded ? 16 : 48),
              ],
            )
            : hasAbout
            ? Column(
              children: [
                VitrinAboutCard(
                  storeData: storeData,
                  preset: preset,
                  isEmbedded: isEmbedded,
                ),
                SizedBox(height: isEmbedded ? 16 : 30),
              ],
            )
            : const SizedBox();

    return VitrinDefaultLayout(
      header: VitrinModernHeader(
        storeData: storeData,
        preset: preset,
        isEmbedded: isEmbedded,
        compactEmbeddedHeader: compactEmbeddedHeader,
        publicMode: publicMode,
        radius: radius,
        galleryItems: galleryItems,
        onShareTap:
            () => VitrinViewActions.shareVitrin(
              context,
              storeData: storeData,
              shareUrl: shareUrl,
              preset: preset,
            ),
        monogramText: monogramText,
      ),
      identityBlock: VitrinStoreIdentityBlock(
        storeData: storeData,
        preset: preset,
        isEmbedded: isEmbedded,
        compactEmbeddedHeader: compactEmbeddedHeader,
        publicMode: publicMode,
      ),
      bookingCTA: bookingCta,
      premiumActionButtons: VitrinPremiumActionButtons(
        actions: actions,
        isEmbedded: isEmbedded,
      ),
      bioOrAbout: bioOrAbout,
      shelfImageCard: VitrinShelfGallery(
        preset: preset,
        galleryItems: galleryItems,
        isEmbedded: isEmbedded,
      ),
      productsCatalog: VitrinProductsCatalog(
        storeData: storeData,
        preset: preset,
        isEmbedded: isEmbedded,
        publicMode: publicMode,
        onOpenExternalUrl: VitrinViewActions.openExternalUrl,
      ),
      profileTools: VitrinProfileTools(
        storeData: storeData,
        preset: preset,
        isEmbedded: isEmbedded,
        publicLink: publicLink,
        hasVCardData: VitrinViewActions.hasVCardData(storeData),
        onDownloadVCard:
            (context) => VitrinViewActions.downloadVCard(context, storeData),
        onShareVitrin:
            (context, shareUrl, activePreset) => VitrinViewActions.shareVitrin(
              context,
              storeData: storeData,
              shareUrl: shareUrl,
              preset: activePreset,
            ),
        onOpenExternalUrl: VitrinViewActions.openExternalUrl,
        onNormalizeExternalUrl: VitrinViewActions.normalizeExternalUrl,
      ),
      linkHub: VitrinLinksHub(
        storeData: storeData,
        preset: preset,
        isEmbedded: isEmbedded,
        publicMode: publicMode,
        onGetPlatformIcon: VitrinViewActions.getPlatformIcon,
        onOpenExternalUrl: VitrinViewActions.openExternalUrl,
        onNormalizeExternalUrl: VitrinViewActions.normalizeExternalUrl,
      ),
      premiumIdentityCard: VitrinPremiumIdentityCard(
        storeData: storeData,
        preset: preset,
        isEmbedded: isEmbedded,
        onSharePressed:
            publicLink != null
                ? () => VitrinViewActions.shareVitrin(
                  context,
                  storeData: storeData,
                  shareUrl: publicLink!,
                  preset: preset,
                )
                : null,
        radius: radius,
      ),
      qrCard:
          publicLink != null
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
      isEmbedded: isEmbedded,
      isBookingEnabled: isBookingEnabled,
      hasVisibleActions: VitrinViewActions.hasVisibleActions(
        storeData,
        publicMode: publicMode,
        publicLink: publicLink,
      ),
      hasGalleryMedia: hasGalleryMedia,
      isStore: storeData.isStore,
      publicMode: publicMode,
      hasQrCard: publicMode && hasQrCard,
      showPremiumIdentityCard: !publicMode,
    );
  }
}

class VitrinPublicLayoutSection extends StatelessWidget {
  final StoreData storeData;
  final VitrinThemePreset preset;
  final bool isEmbedded;
  final String? publicLink;
  final List<VitrinGalleryPreviewItem> galleryItems;
  final bool isDesktop;

  const VitrinPublicLayoutSection({
    super.key,
    required this.storeData,
    required this.preset,
    required this.isEmbedded,
    required this.publicLink,
    required this.galleryItems,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final hasAboutText = VitrinViewContent.aboutText(storeData).isNotEmpty;
    final shareUrl = VitrinViewContent.buildShareUrl(storeData, publicLink);
    final hero = VitrinPublicHero(
      storeData: storeData,
      preset: preset,
      galleryItems: galleryItems,
      actions: buildVitrinVisibleActions(
        context: context,
        storeData: storeData,
        publicMode: true,
        isCompact: true,
        publicLink: publicLink,
        actionColor: preset.accent,
        onOpenExternalUrl: VitrinViewActions.openExternalUrl,
      ),
      isEmbedded: isEmbedded,
      desktop: isDesktop,
      onShareTap:
          () => VitrinViewActions.shareVitrin(
            context,
            storeData: storeData,
            shareUrl: shareUrl,
            preset: preset,
          ),
    );

    final bookingCta = VitrinBookingCTA(
      storeData: storeData,
      preset: preset,
      isEmbedded: isEmbedded,
      publicMode: true,
    );
    final productsCatalog = VitrinProductsCatalog(
      storeData: storeData,
      preset: preset,
      isEmbedded: isEmbedded,
      publicMode: true,
      onOpenExternalUrl: VitrinViewActions.openExternalUrl,
    );
    final profileTools = VitrinProfileTools(
      storeData: storeData,
      preset: preset,
      isEmbedded: isEmbedded,
      publicLink: publicLink,
      hasVCardData: VitrinViewActions.hasVCardData(storeData),
      onDownloadVCard:
          (context) => VitrinViewActions.downloadVCard(context, storeData),
      onShareVitrin:
          (context, shareUrl, activePreset) => VitrinViewActions.shareVitrin(
            context,
            storeData: storeData,
            shareUrl: shareUrl,
            preset: activePreset,
          ),
      onOpenExternalUrl: VitrinViewActions.openExternalUrl,
      onNormalizeExternalUrl: VitrinViewActions.normalizeExternalUrl,
    );
    final aboutCard = VitrinAboutCard(
      storeData: storeData,
      preset: preset,
      isEmbedded: isEmbedded,
    );
    final linkHub = VitrinLinksHub(
      storeData: storeData,
      preset: preset,
      isEmbedded: isEmbedded,
      publicMode: true,
      onGetPlatformIcon: VitrinViewActions.getPlatformIcon,
      onOpenExternalUrl: VitrinViewActions.openExternalUrl,
      onNormalizeExternalUrl: VitrinViewActions.normalizeExternalUrl,
    );
    final shelfGallery = VitrinShelfGallery(
      preset: preset,
      galleryItems: galleryItems,
      isEmbedded: isEmbedded,
    );
    final qrCard =
        publicLink != null
            ? VitrinQrCard(url: publicLink!, preset: preset, isEmbedded: isEmbedded)
            : const SizedBox();
    final footer = VitrinFooter(
      storeData: storeData,
      preset: preset,
      publicMode: true,
    );
    final isBookingEnabled = storeData.bookingSettings?.isEnabled == true;
    final hasMarketplaceLinks = storeData.marketplaceLinks.any(
      (link) => link.url.trim().isNotEmpty,
    );
    final hasQrCard = publicLink?.isNotEmpty ?? false;

    return isDesktop
        ? VitrinDesktopLayout(
          hero: hero,
          bookingCTA: bookingCta,
          productsCatalog: productsCatalog,
          aboutCard: aboutCard,
          profileTools: profileTools,
          qrCard: qrCard,
          linkHub: linkHub,
          shelfImageCard: shelfGallery,
          footer: footer,
          hasSideLinks: hasMarketplaceLinks,
          hasGalleryMedia: galleryItems.isNotEmpty,
          isBookingEnabled: isBookingEnabled,
          isStore: storeData.isStore,
          hasAboutText: hasAboutText,
          hasQrCard: hasQrCard,
        )
        : VitrinMobileLayout(
          hero: hero,
          bookingCTA: bookingCta,
          productsCatalog: productsCatalog,
          profileTools: profileTools,
          aboutCard: aboutCard,
          linkHub: linkHub,
          shelfImageCard: shelfGallery,
          qrCard: qrCard,
          footer: footer,
          isBookingEnabled: isBookingEnabled,
          isStore: storeData.isStore,
          hasAboutText: hasAboutText,
          hasMarketplaceLinks: hasMarketplaceLinks,
          hasGalleryMedia: galleryItems.isNotEmpty,
          hasQrCard: hasQrCard,
        );
  }
}
