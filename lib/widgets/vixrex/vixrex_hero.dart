import 'package:flutter/material.dart';
import 'package:vixrex/widgets/vixrex_avatar.dart';
import 'package:vixrex/theme/app_colors.dart';

/// Kompakt başlık şeridi: küçük mascot + isim + rol rozeti.
/// Not: Eskiden büyük ortalanmış hero + açıklama paragrafı vardı; paragraf
/// kaldırıldı çünkü aynı bilgi zaten sohbet/öneri kartında tekrarlanıyordu.
class VixRexHero extends StatelessWidget {
  final double mascotSize;
  final VoidCallback? onTap;

  const VixRexHero({super.key, required this.mascotSize, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: 'Vixrex ile sohbet alanına git',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Row(
          children: [
            // Vixrex'in yüzü tek yerden gelir — bkz. VixrexAvatar.
            VixrexAvatar(boyut: mascotSize, hale: true),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Vixrex',
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Yanındayım',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
