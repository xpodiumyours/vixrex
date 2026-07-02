import 'package:flutter/material.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/models/vitrin_gallery_preview_item.dart';
import 'package:vitrinx/theme/vitrin_theme_preset.dart';
import 'package:vitrinx/widgets/status_chip.dart';
import 'package:vitrinx/widgets/vitrin_view/vitrin_avatar_fallback.dart';
import 'package:vitrinx/widgets/vitrin_view/vitrin_cover_surface.dart';
import 'package:vitrinx/widgets/vitrin_view/vitrin_gallery_image.dart';
import 'package:vitrinx/widgets/vitrin_view/vitrin_share_button.dart';

class VitrinModernHeader extends StatelessWidget {
  final StoreData storeData;
  final VitrinThemePreset preset;
  final bool isEmbedded;
  final bool compactEmbeddedHeader;
  final bool publicMode;
  final double radius;
  final List<VitrinGalleryPreviewItem> galleryItems;
  final VoidCallback onShareTap;
  final String monogramText;

  const VitrinModernHeader({
    super.key,
    required this.storeData,
    required this.preset,
    required this.isEmbedded,
    required this.compactEmbeddedHeader,
    required this.publicMode,
    required this.radius,
    required this.galleryItems,
    required this.onShareTap,
    required this.monogramText,
  });

  @override
  Widget build(BuildContext context) {
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
    final overlayColors =
        hasHeroImage
            ? [
              Colors.black.withValues(alpha: 0.24),
              Colors.black.withValues(alpha: 0.36),
              Colors.black.withValues(alpha: 0.70),
            ]
            : [
              Colors.transparent,
              preset.background.withValues(alpha: preset.isDark ? 0.12 : 0.18),
              preset.background.withValues(alpha: preset.isDark ? 0.34 : 0.58),
            ];
    final monogram = VitrinVxMonogram(
      preset: preset,
      avatarRadius: monogramRadius,
      text: monogramText,
    );

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
          VitrinCoverSurface(
            preset: preset,
            overlayColors: overlayColors,
            heroChild:
                heroItem != null
                    ? VitrinGalleryImage(
                      item: heroItem,
                      errorBuilder:
                          (_, __, ___) => VitrinCoverSurface(
                            preset: preset,
                            overlayColors: overlayColors,
                            centeredChild: monogram,
                          ),
                    )
                    : null,
            centeredChild: hasHeroImage ? null : monogram,
          ),
          Positioned(
            top: isEmbedded ? 12 : 20,
            right: isEmbedded ? 12 : 20,
            child: VitrinShareButton(
              preset: preset,
              isEmbedded: isEmbedded,
              onTap: onShareTap,
            ),
          ),
        ],
      ),
    );
  }
}

class VitrinStoreIdentityBlock extends StatelessWidget {
  final StoreData storeData;
  final VitrinThemePreset preset;
  final bool isEmbedded;
  final bool compactEmbeddedHeader;
  final bool publicMode;

  const VitrinStoreIdentityBlock({
    super.key,
    required this.storeData,
    required this.preset,
    required this.isEmbedded,
    required this.compactEmbeddedHeader,
    required this.publicMode,
  });

  @override
  Widget build(BuildContext context) {
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
                      ),
                    ),
                  ),
                if (shouldShowStatus) StatusChip(status: status),
              ],
            ),
          ],
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
}
