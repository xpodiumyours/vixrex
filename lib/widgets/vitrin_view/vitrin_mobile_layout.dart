import 'package:flutter/material.dart';

class VitrinMobileLayout extends StatelessWidget {
  final Widget hero;
  final Widget bookingCTA;
  final Widget productsCatalog;
  final Widget profileTools;
  final Widget aboutCard;
  final Widget linkHub;
  final Widget shelfImageCard;
  final Widget qrCard;
  final Widget footer;

  final bool isBookingEnabled;
  final bool isStore;
  final bool hasAboutText;
  final bool hasMarketplaceLinks;
  final bool hasGalleryMedia;
  final bool hasQrCard;

  const VitrinMobileLayout({
    super.key,
    required this.hero,
    required this.bookingCTA,
    required this.productsCatalog,
    required this.profileTools,
    required this.aboutCard,
    required this.linkHub,
    required this.shelfImageCard,
    required this.qrCard,
    required this.footer,
    required this.isBookingEnabled,
    required this.isStore,
    required this.hasAboutText,
    required this.hasMarketplaceLinks,
    required this.hasGalleryMedia,
    required this.hasQrCard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        hero,
        const SizedBox(height: 14),
        bookingCTA,
        if (isBookingEnabled) const SizedBox(height: 16),
        if (isStore) ...[
          productsCatalog,
          const SizedBox(height: 14),
        ],
        profileTools,
        const SizedBox(height: 14),
        if (hasAboutText) ...[
          aboutCard,
          const SizedBox(height: 18),
        ],
        linkHub,
        if (hasMarketplaceLinks) const SizedBox(height: 18),
        if (hasGalleryMedia) ...[
          shelfImageCard,
          const SizedBox(height: 18),
        ],
        if (hasQrCard) ...[
          qrCard,
          const SizedBox(height: 22),
        ],
        footer,
        const SizedBox(height: 48),
      ],
    );
  }
}

class VitrinDefaultLayout extends StatelessWidget {
  final Widget header;
  final Widget identityBlock;
  final Widget bookingCTA;
  final Widget premiumActionButtons;
  final Widget bioOrAbout;
  final Widget shelfImageCard;
  final Widget productsCatalog;
  final Widget profileTools;
  final Widget linkHub;
  final Widget premiumIdentityCard;
  final Widget qrCard;
  final Widget footer;

  final bool isEmbedded;
  final bool isBookingEnabled;
  final bool hasVisibleActions;
  final bool hasGalleryMedia;
  final bool isStore;
  final bool publicMode;
  final bool hasQrCard;
  final bool showPremiumIdentityCard;

  const VitrinDefaultLayout({
    super.key,
    required this.header,
    required this.identityBlock,
    required this.bookingCTA,
    required this.premiumActionButtons,
    required this.bioOrAbout,
    required this.shelfImageCard,
    required this.productsCatalog,
    required this.profileTools,
    required this.linkHub,
    required this.premiumIdentityCard,
    required this.qrCard,
    required this.footer,
    required this.isEmbedded,
    required this.isBookingEnabled,
    required this.hasVisibleActions,
    required this.hasGalleryMedia,
    required this.isStore,
    required this.publicMode,
    required this.hasQrCard,
    required this.showPremiumIdentityCard,
  });

  @override
  Widget build(BuildContext context) {
    final children = [
      header,
      SizedBox(height: isEmbedded ? 16 : 24),
      identityBlock,
      SizedBox(height: isEmbedded ? 16 : 30),
      bookingCTA,
      if (isBookingEnabled) SizedBox(height: isEmbedded ? 16 : 30),
      if (hasVisibleActions) ...[
        premiumActionButtons,
        SizedBox(height: isEmbedded ? 16 : 30),
      ],
      bioOrAbout,
      if (hasGalleryMedia) ...[
        shelfImageCard,
        SizedBox(height: isEmbedded ? 16 : 30),
      ],
      if (isStore) ...[
        productsCatalog,
        SizedBox(height: isEmbedded ? 16 : 30),
      ],
      if (publicMode) ...[
        profileTools,
        SizedBox(height: isEmbedded ? 16 : 24),
      ],
      linkHub,
      SizedBox(height: isEmbedded ? 18 : 64),
      if (showPremiumIdentityCard) ...[
        premiumIdentityCard,
        SizedBox(height: isEmbedded ? 18 : 64),
      ],
      if (hasQrCard) ...[
        qrCard,
        SizedBox(height: isEmbedded ? 18 : 24),
      ],
      footer,
      SizedBox(height: isEmbedded ? 36 : 120),
    ];

    return isEmbedded
        ? ListView(
            padding: EdgeInsets.zero,
            physics: const ClampingScrollPhysics(),
            children: children,
          )
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(children: children),
          );
  }
}
