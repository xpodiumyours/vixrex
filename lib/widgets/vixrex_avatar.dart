import 'package:flutter/material.dart';

/// Vixrex'in yüzü — TEK YERDE.
///
/// NEDEN VAR (2026-08-07, tur bulgusu 16):
/// Maskot iki ayrı yerde ayrı ayrı çiziliyordu. Uygulama içi asistanda
/// her bot mesajının başında 28 piksellik bir avatar vardı; kurulum
/// sohbetinde hiç yoktu. Aynı Vixrex, iki farklı yüz.
///
/// Casper: "uygulama içinde her cümlesinin başında vixrex maskotu var,
/// diğer ekranda yok."
///
/// 6 Ağustos'ta "tek asistan" kararı verilip DİL birleştirilmişti
/// ("sen" kipi); görünüm birleştirilmemişti — karar yarım kalmıştı.
///
/// Görsel dosyası, çerçeve, hâle ve yedek görsel artık burada. İki
/// yüzey de bunu çağırır; biri değişince ikisi birden değişir.
class VixrexAvatar extends StatelessWidget {
  const VixrexAvatar({super.key, this.boyut = 28, this.hale = false});

  /// Dış çemberin çapı.
  final double boyut;

  /// Etrafında yumuşak bir ışık olsun mu. Başlıkta açık, mesajda kapalı:
  /// her satırda parlayan bir daire okumayı zorlaştırır.
  final bool hale;

  static const Color _cerceve = Color(0xFF0EA5E9);
  static const Color _zemin = Color(0xFF0E1B2E);

  @override
  Widget build(BuildContext context) {
    final icBoyut = boyut - 4;
    return Container(
      width: boyut,
      height: boyut,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _zemin,
        border: Border.all(
          color: _cerceve.withValues(alpha: 0.7),
          width: boyut >= 36 ? 1.5 : 1.2,
        ),
        boxShadow:
            hale
                ? [
                  BoxShadow(
                    color: _cerceve.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ]
                : null,
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/vixrex_v_crystal_mascot.png',
          width: icBoyut,
          height: icBoyut,
          fit: BoxFit.contain,
          // Ana görsel yüklenemezse eski maskot kullanılır; Vixrex'in
          // yüzü hiçbir koşulda boş kalmaz.
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/images/vixrex_mascot.webp',
              width: icBoyut,
              height: icBoyut,
              fit: BoxFit.contain,
            );
          },
        ),
      ),
    );
  }
}
