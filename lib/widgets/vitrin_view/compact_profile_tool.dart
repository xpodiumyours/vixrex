import 'package:flutter/material.dart';
import 'package:vitrinx/theme/vitrin_theme_preset.dart';

class CompactProfileToolData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const CompactProfileToolData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });
}

class CompactProfileTool extends StatelessWidget {
  final CompactProfileToolData data;
  final VitrinThemePreset preset;
  final bool dense;

  const CompactProfileTool({
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
          child:
              dense
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
