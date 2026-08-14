import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/theme/app_text_styles.dart';
import 'package:vixrex/widgets/vixrex_avatar.dart';

/// Sohbet başlık şeridi — TEK YERDE.
///
/// NEDEN VAR (Faz A): aynı şerit iki kez yazılıydı.
/// - onboarding `_buildTopBar`: avatar 40, isim 15/w700
/// - `VixRexHero`: avatar 34, isim 16/w900
/// Aynı Vixrex, iki farklı başlık. Ölçüler burada tek karara indi:
/// avatar 36, isim `subTitle` (16/w800), alt satır 11/w800 birincil renk.
class ChatTopBar extends StatelessWidget {
  const ChatTopBar({
    super.key,
    this.title = 'Vixrex',
    this.subtitle = 'Yanındayım',
    this.avatarSize = 36,
    this.halo = true,
    this.onTap,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppColors.spacing12,
      vertical: AppColors.spacing8,
    ),
  });

  final String title;

  /// Rol satırı. Boş verilirse satır hiç çizilmez.
  final String subtitle;

  final double avatarSize;

  /// Avatarın etrafındaki yumuşak işık. Şeritte açık, mesaj içinde kapalı.
  final bool halo;

  final VoidCallback? onTap;

  /// Sağ uçtaki aksiyon(lar) — kapat düğmesi, menü, durum çipi.
  final Widget? trailing;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: padding,
      child: Row(
        children: [
          VixrexAvatar(boyut: avatarSize, hale: halo),
          const SizedBox(width: AppColors.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppTextStyles.subTitle),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );

    if (onTap == null) return row;
    return Semantics(
      button: true,
      label: '$title ile sohbet alanına git',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radius24),
        child: row,
      ),
    );
  }
}
