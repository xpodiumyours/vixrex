import 'package:flutter/material.dart';

class VitrinPremiumActionButtons extends StatelessWidget {
  final List<Widget> actions;
  final bool isEmbedded;

  const VitrinPremiumActionButtons({
    super.key,
    required this.actions,
    required this.isEmbedded,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = isEmbedded ? 8.0 : 12.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isEmbedded ? 18 : 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth =
              constraints.hasBoundedWidth ? constraints.maxWidth : 360.0;
          final itemWidth =
              actions.length == 1
                  ? availableWidth
                  : (availableWidth - spacing) / 2;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            alignment: WrapAlignment.center,
            children:
                actions
                    .map(
                      (action) => SizedBox(
                        width:
                            itemWidth.clamp(112.0, availableWidth).toDouble(),
                        child: action,
                      ),
                    )
                    .toList(),
          );
        },
      ),
    );
  }
}

class VitrinActionIconButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool compact;
  final bool emphasis;
  final VoidCallback? onTap;

  const VitrinActionIconButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
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
