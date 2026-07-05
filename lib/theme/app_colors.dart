import 'package:flutter/material.dart';

/// VitrinX uygulamasının merkezi renk paleti.
/// Elektrik Mavisi & Koyu Karbon Arka Planlar (Cyber Dragon Teması).
abstract final class AppColors {
  // ── Marka Renkleri (Elektrik Mavisi & Cyan) ─────────────────────────────
  /// Ana marka rengi (Elektrik Mavisi).
  static const Color primary = Color(0xFF00F0FF);

  /// Koyu marka rengi (Koyu Siber Mavi).
  static const Color primaryDark = Color(0xFF008D99);

  /// İkincil marka rengi (Neon Turkuaz).
  static const Color secondary = Color(0xFF00E5FF);

  /// Marka turuncusunun kaldırılmasıyla birleşen elektrik mavisi.
  static const Color brandOrange = Color(0xFF00F0FF);

  /// Landing ekranı için ortak marka renkleri.
  static const Color landingBrandOrange = Color(0xFFFF5A1F);
  static const Color landingDarkAccent = Color(0xFF0F172A);
  static const Color landingLightBg = Color(0xFFF8FAFC);
  static const Color landingMint = Color(0xFF10B981);
  static const Color landingBlueAccent = Color(0xFF2563EB);
  static const Color landingPinkAccent = Color(0xFFFB7185);

  /// Genel boşluk ve yuvarlaklık sabitleri.
  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing30 = 30;
  static const double spacing32 = 32;
  static const double spacing40 = 40;
  static const double spacing60 = 60;
  static const double spacing80 = 80;
  static const double spacing100 = 100;
  static const double spacing120 = 120;

  static const double radius12 = 12;
  static const double radius16 = 16;
  static const double radius20 = 20;
  static const double radius24 = 24;
  static const double radius30 = 30;
  static const double radius40 = 40;

  /// Ana CTA gradient (soldan sağa: Elektrik Mavisi → Neon Turkuaz).
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  // ── Arka Plan Renkleri (OLED Koyu Karbon) ───────────────────────────────────
  /// Sayfa arka planı (Kömür Siyahı / OLED Arka Plan).
  static const Color bgEditor = Color(0xFF0D0E12);

  /// Sayfa arka planı (Çok Koyu Karbon Gri).
  static const Color bgLight = Color(0xFF13151A);

  /// Input alanı arka planı (Koyu Karbon).
  static const Color inputBg = Color(0xFF1E222B);

  /// Standart yüzey rengi.
  static const Color surface = Color(0xFF13151A);
  static const Color surfaceSoft = Color(0xFF1E222B);
  static const Color turquoiseSurface = Color(0xFF083344);
  static const Color blueSurface = Color(0xFF1E1B4B);

  // ── Metin Renkleri (Siber Işıklar) ────────────────────────────────────────
  /// Başlık ve ana içerik metni (Okunabilir Kırık Beyaz).
  static const Color darkText = Color(0xFFEDEDED);
  static const Color darkTextAlt = Color(0xFFD4D4D8);

  /// İkincil / yardımcı metin (Yardımcı Gri).
  static const Color mutedText = Color(0xFFA1A1AA);

  /// Orta ton metin.
  static const Color softText = Color(0xFF71717A);

  // ── Kenarlık & Gölge (Mat Siber Çizgiler) ───────────────────────────────────
  /// Standart kenarlık (Siber Mat Çizgi).
  static const Color border = Color(0xFF2B313E);

  /// Odaklanmış kenarlık (Elektrik Mavisi).
  static const Color focusedBorder = Color(0xFF00F0FF);

  static const Color cardBorderDark = Color(0xFF2B313E);
  static const Color cardBorderLight = Color(0xFF3F3F46);

  // ── Durum Renkleri ───────────────────────────────────────────────────
  /// Başarı / yeşil.
  static const Color success = Color(0xFF10B981);

  /// Hata / kırmızı.
  static const Color error = Color(0xFFEF4444);

  // ── Özel Bileşen Renkleri ───────────────────────────────────────────
  static const Color bottomBarActive = Color(0xFF00F0FF);
  static const Color bottomBarInactive = Color(0xFFA1A1AA);

  /// Şeffaf ve Cam efekti renkleri
  static const Color glassOverlay = Color(0x990D0E12);
  static const Color shadowColor = Color(0x66000000);

  static const Color disabled = Color(0xFF52525B);
}
