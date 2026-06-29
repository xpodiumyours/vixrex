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

  /// Bilgi / mavi.
  static const Color info = Color(0xFF38BDF8);

  /// Hata / kırmızı.
  static const Color error = Color(0xFFEF4444);

  /// Uyarı / pembe-kırmızı.
  static const Color pinkAccent = Color(0xFFEC4899);

  // ── Özel Bileşen Renkleri ───────────────────────────────────────────
  static const Color bottomBarBg = Color(0xFF0D0E12);
  static const Color bottomBarActive = Color(0xFF00F0FF);
  static const Color bottomBarInactive = Color(0xFFA1A1AA);
  
  /// Şeffaf ve Cam efekti renkleri
  static const Color glassOverlay = Color(0x990D0E12);
  static const Color shadowColor = Color(0x66000000);
  
  static const Color disabled = Color(0xFF52525B);
}
