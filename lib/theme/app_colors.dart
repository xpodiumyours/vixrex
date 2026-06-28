import 'package:flutter/material.dart';

/// VitrinX uygulamasının merkezi renk paleti.
/// Neon Mor & Cyan Vurguları, OLED Siyah Arka Plan Üzerinde (Uzay Teknolojisi Teması).
abstract final class AppColors {
  // ── Marka Renkleri (Neon Mor - Cyan) ───────────────────────────────────
  /// Ana marka rengi (Neon Mor).
  static const Color primary = Color(0xFF8B5CF6);

  /// Koyu marka rengi (Derin Mor).
  static const Color primaryDark = Color(0xFF4C1D95);

  /// İkincil marka rengi (Neon Cyan).
  static const Color secondary = Color(0xFF06B6D4);

  /// Turuncu yerine kullanılacak nötr/mor geçiş (Turuncu/Sarı tamamen kaldırıldı).
  static const Color brandOrange = Color(0xFF8B5CF6);

  /// Ana CTA gradient (soldan sağa: Neon Mor → Neon Cyan).
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  // ── Arka Plan Renkleri (OLED Deep Space) ───────────────────────────────────
  /// Sayfa arka planı (OLED Siyahı).
  static const Color bgEditor = Color(0xFF000000);

  /// Sayfa arka planı (Çok Koyu Gri).
  static const Color bgLight = Color(0xFF0A0A0A);

  /// Input alanı arka planı.
  static const Color inputBg = Color(0xFF0F172A);

  /// Standart yüzey rengi.
  static const Color surface = Color(0xFF0A0A0A);
  static const Color surfaceSoft = Color(0xFF0F172A);
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
  static const Color pinkAccent = Color(0xFFEC4899);

  // ── Özel Bileşen Renkleri ───────────────────────────────────────────
  static const Color bottomBarBg = Color(0xFF000000);
  static const Color bottomBarActive = Color(0xFF8B5CF6);
  static const Color bottomBarInactive = Color(0xFF94A3B8);
  
  /// Şeffaf ve Cam efekti renkleri
  static const Color glassOverlay = Color(0x80000000);
  static const Color shadowColor = Color(0x66000000);
  
  static const Color disabled = Color(0xFF52525B);
}
