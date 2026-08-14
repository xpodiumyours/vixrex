import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/theme/app_text_styles.dart';
import 'package:vixrex/widgets/common/app_tone.dart';

/// Ekran içi bilgi / uyarı / hata bandı.
///
/// `explore_screen.dart`'taki `_buildLoadWarning` (açık turuncu `#FFE8D9`
/// zemin + `#9A3412` metin) ve benzeri elle yazılmış bantların yerine geçer.
/// Koyu arayüzde açık pastel zemin bir ada gibi duruyordu; ton artık paletten
/// türetiliyor.
///
/// ```dart
/// AppBanner(
///   tone: AppTone.danger,
///   title: 'Vitrinler yüklenemedi',
///   message: 'Örnek vitrinler gösteriliyor.',
///   actionLabel: 'Tekrar dene',
///   onAction: _reload,
/// )
/// ```
class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.title,
    this.message,
    this.tone = AppTone.info,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
  });

  final String title;

  /// İkinci satır. Tek satırlık bantlarda null bırakılır.
  final String? message;

  final AppTone tone;

  /// Verilirse bandın altında hayalet aksiyon çizilir.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Verilirse sağ üstte kapatma düğmesi çizilir.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppColors.spacing16),
      decoration: BoxDecoration(
        color: tone.surface,
        borderRadius: BorderRadius.circular(AppColors.radius16),
        border: Border.all(color: tone.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(tone.icon, size: 18, color: tone.color),
          const SizedBox(width: AppColors.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.subTitle),
                if (message != null) ...[
                  const SizedBox(height: AppColors.spacing8),
                  Text(message!, style: AppTextStyles.caption),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: AppColors.spacing8),
                  InkWell(
                    onTap: onAction,
                    borderRadius: BorderRadius.circular(AppColors.radius12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 2,
                      ),
                      child: Text(
                        actionLabel!,
                        style: AppTextStyles.labelBold.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.mutedText,
              ),
            ),
        ],
      ),
    );
  }
}
