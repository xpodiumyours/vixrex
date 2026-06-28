import 'package:flutter/material.dart';

/// VitrinX uygulamasının merkezi renk paleti.
///
/// Tüm ekranlar ve widget'lar bu sınıftan renkleri almalıdır.
/// Doğrudan `Color(0xFF...)` literal kullanımından kaçınılmalıdır.
abstract final class AppColors {
  // ── Marka Renkleri (Neon Mor - Cyan) ───────────────────────────────────
  /// Ana marka rengi (Neon Mor).
  static const Color primary = Color(0xFF8B5CF6);

  /// Koyu marka rengi (Derin Mor).
  static const Color primaryDark = Color(0xFF4C1D95);

  /// İkincil marka rengi (Neon Cyan).
  static const Color secondary = Color(0xFF06B6D4);

  /// Uyarı ve vurgular için sıcak ton (Amber/Orange).
  static const Color brandOrange = Color(0xFFF59E0B);

  /// Ana CTA gradient (soldan sağa: turkuaz → mavi).
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  // ── Arka Plan Renkleri (Deep Space) ───────────────────────────────────
  /// Sayfa arka planı (Derin Uzay Mavisi/Siyahı).
  static const Color bgEditor = Color(0xFF040914);

  /// Sayfa arka planı (Bir tık aydınlık yüzey).
  static const Color bgLight = Color(0xFF0B1325);

  /// Input alanı arka planı.
  static const Color inputBg = Color(0xFF111C33);

  /// Standart yüzey rengi.
  static const Color surface = Color(0xFF0B1325);
  static const Color surfaceSoft = Color(0xFF111C33);
  static const Color turquoiseSurface = Color(0xFF083344);
  static const Color blueSurface = Color(0xFF1E1B4B);

  // ── Metin Renkleri (Starlight) ────────────────────────────────────────
  /// Başlık ve ana içerik metni (Yıldız beyazı).
  static const Color darkText = Color(0xFFF8FAFC);
  static const Color darkTextAlt = Color(0xFFE2E8F0);

  /// İkincil / yardımcı metin (Uzay grisi).
  static const Color mutedText = Color(0xFF94A3B8);

  /// Orta ton metin.
  static const Color softText = Color(0xFFCBD5E1);

  // ── Kenarlık & Gölge (Metalik) ────────────────────────────────────────
  /// Standart kenarlık.
  static const Color border = Color(0xFF1E293B);
  
  /// Odaklanmış kenarlık (Neon Mor).
  static const Color focusedBorder = Color(0xFF8B5CF6);
  
  static const Color cardBorderDark = Color(0xFF334155);
  static const Color cardBorderLight = Color(0xFF1E293B);

  // ── Durum Renkleri ───────────────────────────────────────────────────
  /// Başarı / yeşil.
  static const Color success = Color(0xFF10B981);

  /// Bilgi / mavi.
  static const Color info = Color(0xFF38BDF8);

  /// Hata / kırmızı.
  static const Color error = Color(0xFFEF4444);

  /// Uyarı / pembe-kırmızı.
  static const Color pinkAccent = Color(0xFFF43F5E);

  /// Disabled / pasif rengi.
  static const Color disabled = Color(0xFF475569);
}
