import 'package:flutter/material.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/theme/vitrin_theme_preset.dart';

class VitrinProfileTools extends StatelessWidget {
  final StoreData storeData;
  final VitrinThemePreset preset;
  final bool isEmbedded;
  final String? publicLink;
  final bool hasVCardData;
  final Future<void> Function(BuildContext) onDownloadVCard;
  final Future<void> Function(BuildContext, String, VitrinThemePreset) onShareVitrin;
  final Future<void> Function(BuildContext, String) onOpenExternalUrl;
  final String Function(String) onNormalizeExternalUrl;

  const VitrinProfileTools({
    super.key,
    required this.storeData,
    required this.preset,
    required this.isEmbedded,
    this.publicLink,
    required this.hasVCardData,
    required this.onDownloadVCard,
    required this.onShareVitrin,
    required this.onOpenExternalUrl,
    required this.onNormalizeExternalUrl,
  });

  @override
  Widget build(BuildContext context) {
    final tools = <_CompactProfileToolData>[
      if (storeData.products.isNotEmpty)
        _CompactProfileToolData(
          icon: Icons.auto_stories_rounded,
          title: 'Katalog',
          subtitle: '${storeData.products.length} ürün',
          color: preset.accent,
          onTap: () {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Katalog ürünleri bu sayfada görüntüleniyor.'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      if (hasVCardData)
        _CompactProfileToolData(
          icon: Icons.contact_page_rounded,
          title: 'vCard',
          subtitle: 'Rehbere kaydet',
          color: preset.accent,
          onTap: () => onDownloadVCard(context),
        ),
      if (storeData.referencesLink.trim().isNotEmpty)
        _CompactProfileToolData(
          icon: Icons.verified_rounded,
          title: 'Referanslar',
          subtitle: 'Yorumları gör',
          color: preset.accent,
          onTap: () => onOpenExternalUrl(
            context,
            onNormalizeExternalUrl(storeData.referencesLink.trim()),
          ),
        ),
      if (publicLink?.isNotEmpty ?? false)
        _CompactProfileToolData(
          icon: Icons.qr_code_2_rounded,
          title: 'QR Paylaş',
          subtitle: 'Linki gönder',
          color: preset.accent,
          onTap: () => onShareVitrin(context, publicLink!, preset),
        ),
    ];

    if (tools.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isEmbedded ? 18 : 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: preset.surface.withValues(alpha: preset.isDark ? 0.72 : 0.98),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: preset.border.withValues(alpha: preset.isDark ? 0.72 : 0.72),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxColumns = constraints.maxWidth < 360 ? 3 : 4;
            final columns =
                tools.length < maxColumns ? tools.length : maxColumns;
            final spacing = constraints.maxWidth < 360 ? 6.0 : 8.0;
            final itemWidth =
                columns <= 1
                    ? constraints.maxWidth
                    : (constraints.maxWidth - (spacing * (columns - 1))) /
                        columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: tools
                  .map(
                    (tool) => SizedBox(
                      width: itemWidth
                          .clamp(76.0, constraints.maxWidth)
                          .toDouble(),
                      child: _CompactProfileTool(
                        data: tool,
                        preset: preset,
                        dense: true,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}

class _CompactProfileToolData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _CompactProfileToolData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });
}

class _CompactProfileTool extends StatelessWidget {
  final _CompactProfileToolData data;
  final VitrinThemePreset preset;
  final bool dense;

  const _CompactProfileTool({
    required this.data,
    required this.preset,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(dense ? 12 : 14),
        child: Ink(
          height: dense ? 70 : null,
          padding: EdgeInsets.all(dense ? 8 : 10),
          decoration: BoxDecoration(
            color: data.color.withValues(alpha: preset.isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(dense ? 12 : 14),
            border: Border.all(
              color: data.color.withValues(alpha: preset.isDark ? 0.26 : 0.18),
            ),
          ),
          child: dense
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: data.color.withValues(
                          alpha: preset.isDark ? 0.18 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(data.icon, color: data.color, size: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: preset.textPrimary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: data.color.withValues(
                          alpha: preset.isDark ? 0.18 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(data.icon, color: data.color, size: 18),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: preset.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: preset.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
