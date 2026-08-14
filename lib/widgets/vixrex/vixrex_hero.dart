import 'package:flutter/material.dart';
import 'package:vixrex/widgets/chat/chat_top_bar.dart';

/// Kompakt başlık şeridi: küçük mascot + isim + rol rozeti.
/// Not: Eskiden büyük ortalanmış hero + açıklama paragrafı vardı; paragraf
/// kaldırıldı çünkü aynı bilgi zaten sohbet/öneri kartında tekrarlanıyordu.
///
/// Çizimi [ChatTopBar] ile paylaşır — bkz. Faz A (Tek Asistan planı).
class VixRexHero extends StatelessWidget {
  final double mascotSize;
  final VoidCallback? onTap;

  const VixRexHero({super.key, required this.mascotSize, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChatTopBar(avatarSize: mascotSize, onTap: onTap);
  }
}
