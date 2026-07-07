import 'package:flutter/material.dart';

class VitrinDesktopLayout extends StatelessWidget {
  final Widget hero;
  final Widget bookingCTA;
  final Widget productsCatalog;
  final Widget aboutCard;
  final Widget profileTools;
  final Widget qrCard;
  final Widget linkHub;
  final Widget shelfImageCard;
  final Widget footer;
  final bool hasSideLinks;
  final bool hasGalleryMedia;
  final bool isBookingEnabled;
  final bool hasProducts;
  final bool hasAboutText;
  final bool hasQrCard;

  const VitrinDesktopLayout({
    super.key,
    required this.hero,
    required this.bookingCTA,
    required this.productsCatalog,
    required this.aboutCard,
    required this.profileTools,
    required this.qrCard,
    required this.linkHub,
    required this.shelfImageCard,
    required this.footer,
    required this.hasSideLinks,
    required this.hasGalleryMedia,
    required this.isBookingEnabled,
    required this.hasProducts,
    required this.hasAboutText,
    required this.hasQrCard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: hero,
        ),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: Column(
                  children: [
                    bookingCTA,
                    if (isBookingEnabled) const SizedBox(height: 18),
                    if (hasProducts) ...[
                      productsCatalog,
                      const SizedBox(height: 22),
                    ],
                    if (hasAboutText) aboutCard,
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 360,
                child: Column(
                  children: [
                    profileTools,
                    if (hasQrCard) ...[
                      const SizedBox(height: 16),
                      qrCard,
                    ],
                    if (hasSideLinks) ...[
                      const SizedBox(height: 16),
                      linkHub,
                    ],
                    if (hasGalleryMedia) ...[
                      const SizedBox(height: 16),
                      shelfImageCard,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        footer,
        const SizedBox(height: 56),
      ],
    );
  }
}
