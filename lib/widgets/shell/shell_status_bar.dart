import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/theme/app_text_styles.dart';
import 'package:vixrex/widgets/common/app_button.dart';
import 'package:vixrex/widgets/common/app_tone.dart';

/// Masaüstü kabuğunun yayın durumu ve paylaşım aksiyonları.
class ShellStatusBar extends StatelessWidget {
  const ShellStatusBar({
    super.key,
    required this.isPublished,
    this.publicLink,
    this.onCopyLink,
    this.onShowQr,
    this.onOpenVitrin,
    this.onPublish,
  });

  final bool isPublished;
  final String? publicLink;
  final VoidCallback? onCopyLink;
  final VoidCallback? onShowQr;
  final VoidCallback? onOpenVitrin;
  final VoidCallback? onPublish;

  @override
  Widget build(BuildContext context) {
    final tone = isPublished ? AppTone.success : AppTone.neutral;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.spacing20,
        vertical: AppColors.spacing12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgLight,
        border: Border(bottom: BorderSide(color: AppColors.blueSurface)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: tone.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: tone.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: tone.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isPublished ? 'Yayında' : 'Yayında değil',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: tone.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppColors.spacing12),
          Expanded(
            child: Text(
              publicLink ?? 'Vitrininiz henüz yayınlanmadı',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall,
            ),
          ),
          const SizedBox(width: AppColors.spacing12),
          if (isPublished) ...[
            AppButton.secondary(
              label: 'Kopyala',
              icon: Icons.copy_rounded,
              onPressed: onCopyLink,
              expanded: false,
              compact: true,
            ),
            const SizedBox(width: AppColors.spacing8),
            AppButton.secondary(
              label: 'QR',
              icon: Icons.qr_code_2_rounded,
              onPressed: onShowQr,
              expanded: false,
              compact: true,
            ),
            const SizedBox(width: AppColors.spacing8),
            AppButton.primary(
              label: 'Vitrini aç',
              onPressed: onOpenVitrin,
              expanded: false,
              compact: true,
            ),
          ] else
            AppButton.primary(
              label: 'Vitrini yayınla',
              onPressed: onPublish,
              expanded: false,
              compact: true,
            ),
        ],
      ),
    );
  }
}
