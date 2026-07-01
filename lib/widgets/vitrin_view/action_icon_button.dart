import 'package:flutter/material.dart';

class ActionIconButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double radius;
  final bool compact;
  final bool emphasis;
  final VoidCallback? onTap;

  const ActionIconButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.radius,
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
