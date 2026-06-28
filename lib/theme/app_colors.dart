import 'package:flutter/material.dart';

/// VitrinX uygulamasÄ±nÄ±n merkezi renk paleti.
/// A-Kalite Premium Monokrom (Siyah/Beyaz/Gri) Tema.
abstract final class AppColors {
  // â”€â”€ Marka Renkleri (Monokrom Vurgular) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// Ana marka rengi (Saf Beyaz).
  static const Color primary = Color(0xFFFFFFFF);

  /// Koyu marka rengi (AÃ§Ä±k Gri / Zinc 300).
  static const Color primaryDark = Color(0xFFD4D4D8);

  /// Ä°kincil marka rengi (AÃ§Ä±k Gri / Zinc 400).
  static const Color secondary = Color(0xFFA1A1AA);

  /// Ana CTA gradient (Beyazdan AÃ§Ä±k Griye).
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFE4E4E7)],
  );

  // â”€â”€ Arka Plan Renkleri (Premium Dark Mode) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// Sayfa arka planÄ± (Tam Siyah - OLED SiyahÄ±).
  static const Color bgEditor = Color(0xFF000000);

  /// Sayfa arka planÄ± (Ã‡ok Koyu Gri).
  static const Color bgLight = Color(0xFF0A0A0A);

  /// Input alanÄ± arka planÄ±.
  static const Color inputBg = Color(0xFF111111);

  /// Standart yÃ¼zey rengi.
  static const Color surface = Color(0xFF0A0A0A);
  static const Color surfaceSoft = Color(0xFF111111);
  static const Color turquoiseSurface = Color(0xFF0A0A0A);
  static const Color blueSurface = Color(0xFF0A0A0A);

  // â”€â”€ Metin Renkleri (Premium Kontrast) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// BaÅŸlÄ±k ve ana iÃ§erik metni (KÄ±rÄ±k Beyaz - Okunabilir).
  static const Color darkText = Color(0xFFEDEDED);
  static const Color darkTextAlt = Color(0xFFD4D4D8);

  /// Ä°kincil / yardÄ±mcÄ± metin (Ä°kincil Gri).
  static const Color mutedText = Color(0xFFA1A1AA);

  /// Orta ton metin.
  static const Color softText = Color(0xFF71717A);

  // â”€â”€ KenarlÄ±k & GÃ¶lge (Metalik / Zinc) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// Standart kenarlÄ±k (Zinc 800).
  static const Color border = Color(0xFF27272A);
  
  /// OdaklanmÄ±ÅŸ kenarlÄ±k (Zinc 400 veya Beyaz).
  static const Color focusedBorder = Color(0xFFFFFFFF);
  
  static const Color cardBorderDark = Color(0xFF27272A);
  static const Color cardBorderLight = Color(0xFF3F3F46);

  // â”€â”€ Durum Renkleri â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// BaÅŸarÄ± / yeÅŸil (Hafif Soluk Premium YeÅŸil).
  static const Color success = Color(0xFF22C55E);

  /// Bilgi / mavi.
  static const Color info = Color(0xFF3B82F6);

  /// Hata / kÄ±rmÄ±zÄ± (Premium Mat KÄ±rmÄ±zÄ±).
  static const Color error = Color(0xFFEF4444);

  /// UyarÄ± / pembe-kÄ±rmÄ±zÄ±.
  static const Color pinkAccent = Color(0xFFEC4899);

  // â”€â”€ Ã–zel BileÅŸen Renkleri â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const Color bottomBarBg = Color(0xFF000000);
  static const Color bottomBarActive = Color(0xFFFFFFFF);
  static const Color bottomBarInactive = Color(0xFF71717A);
  
  /// Åeffaf ve Cam efekti renkleri
  static const Color glassOverlay = Color(0x80000000);
  static const Color shadowColor = Color(0x66000000);
  static const Color disabled = Color(0xFF52525B);
}
