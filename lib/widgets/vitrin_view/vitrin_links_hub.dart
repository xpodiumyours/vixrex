import 'package:flutter/material.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/theme/vitrin_theme_preset.dart';

class VitrinLinksHub extends StatelessWidget {
  final StoreData storeData;
  final VitrinThemePreset preset;
  final bool isEmbedded;
  final bool publicMode;
  final IconData Function(String) onGetPlatformIcon;
  final Future<void> Function(BuildContext, String) onOpenExternalUrl;
  final String Function(String) onNormalizeExternalUrl;

  const VitrinLinksHub({
    super.key,
    required this.storeData,
    required this.preset,
    required this.isEmbedded,
    required this.publicMode,
    required this.onGetPlatformIcon,
    required this.onOpenExternalUrl,
    required this.onNormalizeExternalUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = isEmbedded;
    final visibleMarketplaceLinks = publicMode
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
              icon: onGetPlatformIcon(link.platform),
              title: link.platform,
              subtitle: link.subtitle.trim().isNotEmpty
                  ? link.subtitle.trim()
                  : link.url.isEmpty
                      ? 'Bağlantıyı ziyaret et'
                      : link.url,
              color: preset.accent,
              compact: isCompact,
              preset: preset,
              onTap: () {
                if (!publicMode) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Müşteriler bu bağlantıya bastığında '${link.platform}' sayfasına yönlendirilir.",
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                onOpenExternalUrl(context, onNormalizeExternalUrl(link.url));
              },
            ),
          ),
          if (!publicMode && storeData.marketplaceLinks.isEmpty)
            _ModernLinkItem(
              icon: Icons.auto_stories_rounded,
              title: 'Dijital Katalog',
              subtitle: 'Geniş ürün ve hizmet yelpazesi',
              color: Colors.blueGrey,
              compact: isCompact,
              preset: preset,
            ),
          if (!publicMode) ...[
            _ModernLinkItem(
              icon: Icons.verified_rounded,
              title: 'Referanslarımız',
              subtitle: 'Güçlü çözüm ortaklıklarımız',
              color: Colors.indigo.shade400,
              compact: isCompact,
              preset: preset,
            ),
            _ModernLinkItem(
              icon: Icons.contact_page_rounded,
              title: 'Kişilerime Ekle',
              subtitle:
                  'Tek dokunuşla tüm iletişim bilgilerini rehberine kaydet',
              color: Colors.teal.shade500,
              compact: isCompact,
              preset: preset,
            ),
          ],
        ],
      ),
    );
  }
}

class _ModernLinkItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool compact;
  final VitrinThemePreset preset;
  final VoidCallback? onTap;

  const _ModernLinkItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.preset,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = preset.isDark && color.computeLuminance() < 0.35
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
