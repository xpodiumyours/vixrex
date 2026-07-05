import 'package:flutter/material.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/models/vitrin_gallery_preview_item.dart';
import 'package:vixrex/theme/vitrin_theme_preset.dart';
import 'package:vixrex/widgets/status_chip.dart';
import 'package:vixrex/widgets/vitrin_view/vitrin_avatar_fallback.dart';
import 'package:vixrex/widgets/vitrin_view/vitrin_cover_surface.dart';
import 'package:vixrex/widgets/vitrin_view/vitrin_gallery_image.dart';
import 'package:vixrex/widgets/vitrin_view/vitrin_share_button.dart';
import 'package:vixrex/widgets/vitrin_view/vitrin_view_content.dart';

class VitrinPublicHero extends StatelessWidget {
  final StoreData storeData;
  final VitrinThemePreset preset;
  final List<VitrinGalleryPreviewItem> galleryItems;
  final List<Widget> actions;
  final bool isEmbedded;
  final bool desktop;
  final VoidCallback onShareTap;

  const VitrinPublicHero({
    super.key,
    required this.storeData,
    required this.preset,
    required this.galleryItems,
    required this.actions,
    required this.isEmbedded,
    required this.desktop,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    final heroItem = galleryItems.isEmpty ? null : galleryItems.first;
    final heroHeight = desktop ? 376.0 : 168.0;
    final avatarSize = desktop ? 116.0 : 92.0;
    final description = VitrinViewContent.publicHeroDescription(storeData);
    final avatar = VitrinStoreAvatar(
      preset: preset,
      size: avatarSize,
      logoUrl: storeData.logoUrl,
      monogramText: VitrinViewContent.storeInitials(storeData),
    );
    final cover = VitrinCoverSurface(
      preset: preset,
      begin: desktop ? Alignment.centerLeft : Alignment.topCenter,
      end: desktop ? Alignment.centerRight : Alignment.bottomCenter,
      overlayColors: [
        Colors.black.withValues(alpha: desktop ? 0.62 : 0.10),
        Colors.black.withValues(alpha: desktop ? 0.34 : 0.24),
        preset.background.withValues(alpha: desktop ? 0.72 : 0.66),
      ],
      heroChild:
          heroItem != null
              ? VitrinGalleryImage(
                item: heroItem,
                errorBuilder:
                    (_, __, ___) => VitrinHeaderFallbackSurface(preset: preset),
              )
              : null,
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
              child: VitrinShareButton(
                preset: preset,
                isEmbedded: isEmbedded,
                onTap: onShareTap,
              ),
            ),
            Positioned(
              left: 38,
              right: 38,
              bottom: 34,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  avatar,
                  const SizedBox(width: 22),
                  Expanded(
                    child: _VitrinPublicHeroText(
                      storeData: storeData,
                      preset: preset,
                      description: description,
                      desktop: true,
                    ),
                  ),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(width: 28),
                    SizedBox(
                      width: 360,
                      child: _VitrinPublicHeroActionGrid(actions: actions),
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
                child: VitrinShareButton(
                  preset: preset,
                  isEmbedded: isEmbedded,
                  onTap: onShareTap,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: -avatarSize / 2,
                child: Center(child: avatar),
              ),
            ],
          ),
          SizedBox(height: avatarSize / 2 + 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: _VitrinPublicHeroText(
              storeData: storeData,
              preset: preset,
              description: description,
              desktop: false,
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: _VitrinPublicHeroActionGrid(actions: actions),
            ),
          ],
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}

class _VitrinPublicHeroText extends StatelessWidget {
  final StoreData storeData;
  final VitrinThemePreset preset;
  final String description;
  final bool desktop;

  const _VitrinPublicHeroText({
    required this.storeData,
    required this.preset,
    required this.description,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
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
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _VitrinPublicHeroActionGrid extends StatelessWidget {
  final List<Widget> actions;

  const _VitrinPublicHeroActionGrid({required this.actions});

  @override
  Widget build(BuildContext context) {
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
}
