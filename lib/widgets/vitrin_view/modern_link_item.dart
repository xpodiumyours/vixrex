import 'package:flutter/material.dart';
import 'package:vitrinx/theme/vitrin_theme_preset.dart';

class ModernLinkItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final double radius;
  final bool compact;
  final VitrinThemePreset preset;
  final VoidCallback? onTap;

  const ModernLinkItem({
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

// ---------------------------------------------------------------------------
// _ProductCatalogBlock — extracted StatefulWidget for the products catalog
// ---------------------------------------------------------------------------
