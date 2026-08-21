import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';

/// Hızlı yanıt hapı — TEK YERDE.
///
/// NEDEN VAR (Faz A): üç ayrı yükseklik vardı — quick replies 36px,
/// onboarding karşılama butonları 42px. Dokunma hedefi ikisinde de küçüktü;
/// 44px'e çıktı (mobil erişilebilirlik alt sınırı).
///
/// İkincil hap artık `inputBg` + `border`. Silinen palet dışı çift:
/// `#0E1B2E` zemin ve `#38A0E4` kenarlık.
class ChatPill extends StatelessWidget {
  const ChatPill({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;

  /// Birincil hap: `ctaGradient` zemin. Listede yalnız ilki birincil olur.
  final bool primary;

  final IconData? icon;

  static const double height = 44;
  static const double _radius = height / 2;

  @override
  Widget build(BuildContext context) {
    final fg = primary ? AppColors.onPrimary : AppColors.darkTextAlt;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_radius),
          child: Ink(
            height: height,
            padding: const EdgeInsets.symmetric(
              horizontal: AppColors.spacing16,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radius),
              gradient: primary ? AppColors.ctaGradient : null,
              color: primary ? null : AppColors.inputBg,
              border: primary ? null : Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: fg),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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

/// Hapların ortalanmış şeridi. Başlık metni ("Devam") isteğe bağlı.
class ChatPillRow extends StatelessWidget {
  const ChatPillRow({
    super.key,
    required this.children,
    this.caption,
    this.padding = const EdgeInsets.fromLTRB(12, 4, 12, 6),
  });

  final List<Widget> children;
  final String? caption;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: Column(
        children: [
          if (caption != null) ...[
            Text(
              caption!,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: AppColors.spacing8),
          ],
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppColors.spacing8,
            runSpacing: AppColors.spacing8,
            children: children,
          ),
        ],
      ),
    );
  }
}
