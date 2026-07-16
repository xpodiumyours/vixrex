import 'package:flutter/material.dart';

/// Vixrex uygulamasının merkezi renk paleti.
///
/// Uygulama yüzeyleri için tek kaynak elektrik mavisi ve koyu lacivert
/// sözleşmesidir. Başarı, hata ve üçüncü taraf marka renkleri ayrıdır.
abstract final class AppColors {
  // ── Marka renkleri ──────────────────────────────────────────────────────
  /// Ana marka rengi (Elektrik Mavisi).
  static const Color primary = Color(0xFF147DFF);

  /// Basılı/yoğun marka aksiyonu.
  static const Color primaryDark = Color(0xFF0B5FD7);

  /// Vurgu, odak halkası ve küçük parıltılar için açık mavi.
  static const Color secondary = Color(0xFF57B7FF);
  static const Color brandGlow = Color(0xFF28E3FF);
  static const Color onPrimary = Color(0xFF06152F);

  /// Geriye uyumluluk için eski ad; yeni kod [primary] kullanmalıdır.
  static const Color brandOrange = primary;

  /// Landing ekranının da kullandığı ortak marka yüzeyleri.
  static const Color landingBrandOrange = primary;
  static const Color landingDarkAccent = Color(0xFF08132D);
  static const Color landingLightBg = Color(0xFF050B1A);
  static const Color landingMint = Color(0xFF10B981);
  static const Color landingBlueAccent = secondary;
  static const Color landingPinkAccent = Color(0xFF8B5CF6);

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

  // ── Uygulama yüzeyleri ─────────────────────────────────────────────────
  /// En koyu uygulama zemini.
  static const Color bgEditor = Color(0xFF050B1A);

  /// Normal sayfa zemini.
  static const Color bgLight = Color(0xFF08132D);

  /// Form alanı zemini.
  static const Color inputBg = Color(0xFF0D1C38);

  /// Kart ve modal zemini.
  static const Color surface = Color(0xFF0B1730);
  static const Color surfaceSoft = Color(0xFF112448);
  static const Color turquoiseSurface = Color(0xFF102B59);
  static const Color blueSurface = Color(0xFF182E5B);

  // ── Metin Renkleri (Siber Işıklar) ────────────────────────────────────────
  /// Başlık ve ana içerik metni.
  static const Color darkText = Color(0xFFF7FBFF);
  static const Color darkTextAlt = Color(0xFFD9E7FF);

  /// İkincil / yardımcı metin (Yardımcı Gri).
  static const Color mutedText = Color(0xFFA9BBDA);

  /// Orta ton metin.
  static const Color softText = Color(0xFF738AB3);

  // ── Kenarlık & Gölge (Mat Siber Çizgiler) ───────────────────────────────────
  /// Standart kenarlık.
  static const Color border = Color(0xFF294D88);

  /// Odaklanmış kenarlık (Elektrik Mavisi).
  static const Color focusedBorder = secondary;

  static const Color cardBorderDark = border;
  static const Color cardBorderLight = Color(0xFF4169A7);

  // ── Durum Renkleri ───────────────────────────────────────────────────
  /// Başarı / yeşil.
  static const Color success = Color(0xFF10B981);

  /// Hata / kırmızı.
  static const Color error = Color(0xFFEF4444);

  // ── Özel Bileşen Renkleri ───────────────────────────────────────────
  static const Color bottomBarActive = primary;
  static const Color bottomBarInactive = Color(0xFFA1A1AA);

  /// Şeffaf ve Cam efekti renkleri
  static const Color glassOverlay = Color(0x990D0E12);
  static const Color shadowColor = Color(0x66000000);

  static const Color disabled = Color(0xFF52525B);
}
