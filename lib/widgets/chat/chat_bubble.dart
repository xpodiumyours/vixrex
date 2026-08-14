import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/theme/app_text_styles.dart';
import 'package:vixrex/widgets/vixrex_avatar.dart';

/// Sohbet balonlarının paylaştığı kabuk — zemin, kenarlık, yuvarlaklık ve
/// (bot ise) avatar yerleşimi buradan gelir. İçerik çağırana ait kalır;
/// bu bileşen davranışı veya metni değiştirmez, yalnız çizimi ortaklaştırır.
///
/// Faz A (Tek Asistan planı): üç ayrı balon çizimi vardı — companion
/// sohbetindeki `VixRexBotMessage`/`VixRexUserMessage` ve onboarding'in
/// kendi `_ChatBubble`'ı. Kullanıcı balonu artık marka gradyanı almıyor
/// (`ctaGradient` yalnız yayınlama aksiyonuna ait kalır); üçü de aynı
/// `surfaceSoft` + kenarlık kabuğunu paylaşıyor.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.isBot, required this.child});

  final bool isBot;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: AppColors.spacing12,
      ),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.86,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppColors.radius16),
          topRight: const Radius.circular(AppColors.radius16),
          bottomLeft: Radius.circular(isBot ? 4 : AppColors.radius16),
          bottomRight: Radius.circular(isBot ? AppColors.radius16 : 4),
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: DefaultTextStyle.merge(style: AppTextStyles.body, child: child),
    );

    if (!isBot) {
      return Align(alignment: Alignment.centerRight, child: bubble);
    }

    // Bot mesajının solunda Vixrex'in yüzü. Kullanıcının kendi cümlesinde
    // yoktur — o konuşan Vixrex değil.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2, right: 8),
          child: VixrexAvatar(boyut: 28),
        ),
        Flexible(child: bubble),
      ],
    );
  }
}
