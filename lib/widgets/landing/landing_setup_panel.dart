import 'package:flutter/material.dart';
import 'package:vitrinx/theme/app_colors.dart';

class LandingSetupPanel extends StatelessWidget {
  final String label;
  final List<(IconData, String)> items;
  final String footer;
  final bool highlighted;

  const LandingSetupPanel({
    super.key,
    required this.label,
    required this.items,
    required this.footer,
    required this.highlighted,
  });

  static const Color brandBlue = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: highlighted ? null : AppColors.surface,
        gradient:
            highlighted
                ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.surface, AppColors.turquoiseSurface],
                )
                : null,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color:
              highlighted
                  ? AppColors.primary.withValues(alpha: 0.38)
                  : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color:
                highlighted
                    ? AppColors.primary.withValues(alpha: 0.14)
                    : Colors.black.withValues(alpha: 0.2),
            blurRadius: highlighted ? 34 : 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlighted ? brandBlue : AppColors.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 22),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color:
                          highlighted
                              ? Colors.white.withValues(alpha: 0.1)
                              : AppColors.bgEditor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      highlighted ? Icons.check_rounded : item.$1,
                      size: 19,
                      color:
                          highlighted
                              ? const Color(0xFF65E7E7)
                              : AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: TextStyle(
                        color:
                            highlighted ? Colors.white : AppColors.darkTextAlt,
                        fontSize: 14,
                        height: 1.35,
                        fontWeight:
                            highlighted ? FontWeight.w800 : FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            decoration: BoxDecoration(
              color:
                  highlighted
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    highlighted
                        ? Colors.white.withValues(alpha: 0.12)
                        : AppColors.border,
              ),
            ),
            child: Text(
              footer,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    highlighted ? const Color(0xFFBFF7F7) : AppColors.mutedText,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
