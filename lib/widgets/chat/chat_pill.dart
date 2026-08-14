import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/theme/app_text_styles.dart';

/// Sohbet yüzeylerinin paylaştığı hap düğme — hızlı yanıt, karşılama
/// aksiyonu.
///
/// Faz A (Tek Asistan planı): onboarding'in karşılama düğmeleri 42px,
/// `VixRexQuickReplies`'in hapları 36px'ti; ikisi de kendi `#0E1B2E` /
/// `#38A0E4` ikincil rengini taşıyordu. Yükseklik 44px'te birleşti,
/// ikincil hap artık palet renklerini (`inputBg` + `border`) kullanıyor.
class ChatPill extends StatelessWidget {
  const ChatPill({
    super.key,
    required this.label,
    required this.primary,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool primary;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = primary ? Colors.white : AppColors.mutedText;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            height: 44,
            padding: const EdgeInsets.symmetric(
              horizontal: AppColors.spacing16,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: primary ? AppColors.ctaGradient : null,
              color: primary ? null : AppColors.inputBg,
              border: primary ? null : Border.all(color: AppColors.border),
              boxShadow:
                  primary
                      ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.27),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                      : null,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 14, color: foreground),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: AppTextStyles.labelBold.copyWith(
                      color: foreground,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
