import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/theme/app_text_styles.dart';
import 'package:vixrex/widgets/vixrex_avatar.dart';

/// Sohbet yüzeylerinin paylaştığı başlık içeriği — avatar + isim + rol metni.
///
/// Faz A (Tek Asistan planı): `VixRexHero` (Vixrex sekmesinin AppBar başlığı)
/// ve onboarding'in kendi `_buildTopBar()`'ı aynı satırı iki kez çiziyordu —
/// farklı avatar boyutu (34/40) ve farklı tipografiyle. Metin ve avatar
/// boyutu çağıran tarafa ait kalır (iki yüzeyin de kendi bağlamı var); ortak
/// olan yalnız düzen ve tipografi ölçeği.
class ChatTopBar extends StatelessWidget {
  const ChatTopBar({
    super.key,
    required this.avatarSize,
    required this.title,
    required this.subtitle,
    this.subtitleColor = AppColors.mutedText,
    this.onTap,
    this.semanticsLabel,
    this.trailing,
  });

  final double avatarSize;
  final String title;
  final String subtitle;
  final Color subtitleColor;
  final VoidCallback? onTap;
  final String? semanticsLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        VixrexAvatar(boyut: avatarSize, hale: true),
        const SizedBox(width: AppColors.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppTextStyles.subTitle),
              Text(
                subtitle,
                style: AppTextStyles.labelSmall.copyWith(
                  color: subtitleColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );

    if (onTap == null) return content;
    return Semantics(
      button: true,
      label: semanticsLabel ?? 'Vixrex ile sohbet alanına git',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radius24),
        child: content,
      ),
    );
  }
}
