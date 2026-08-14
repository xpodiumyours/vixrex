import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/theme/app_text_styles.dart';
import 'package:vixrex/widgets/common/app_button.dart';

/// Boş durum — ikon, başlık, açıklama, tek aksiyon.
///
/// `explore_screen.dart` (`_buildEmptyState`) ve `notifications_screen.dart`
/// bunu ayrı ayrı elle yazmıştı; ikisinde ikon boyutu, metin ağırlığı ve
/// boşluklar farklıydı.
///
/// ```dart
/// AppEmptyState(
///   icon: Icons.notifications_none_rounded,
///   title: 'Henüz bildirim yok',
///   message: 'Yeni randevu talepleri ve durum güncellemeleri burada görünür.',
///   actionLabel: 'Randevuları aç',
///   onAction: _openBookings,
/// )
/// ```
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppColors.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AppColors.surfaceSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: AppColors.secondary),
            ),
            const SizedBox(height: AppColors.spacing12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.subTitle,
            ),
            if (message != null) ...[
              const SizedBox(height: AppColors.spacing8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppColors.spacing20),
              AppButton.secondary(
                label: actionLabel!,
                onPressed: onAction,
                expanded: false,
                compact: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
