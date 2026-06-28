import 'package:flutter/material.dart';

/// VitrinX uygulamasının merkezi renk paleti.
///
/// Tüm ekranlar ve widget'lar bu sınıftan renkleri almalıdır.
/// Doğrudan `Color(0xFF...)` literal kullanımından kaçınılmalıdır.
abstract final class AppColors {
  // ── Marka Renkleri (Turkuaz - Mavi) ───────────────────────────────────
  /// Ana turkuaz marka rengi.
  static const Color primary = Color(0xFF00E5FF);

  /// Koyu turuncu yerine koyu turkuaz tonu.
  static const Color primaryDark = Color(0xFF0891B2);

  /// İkincil marka rengi (mavi).
  static const Color secondary = Color(0xFF8B5CF6);

  /// Karşılama ve giriş ekranlarında kullanılan eski turuncu yerine turkuaz.
  static const Color brandOrange = Color(0xFFA855F7);

  /// Ana CTA gradient (soldan sağa: turkuaz → mavi).
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  // ── Arka Plan Renkleri ────────────────────────────────────────────────
  /// Sayfa arka planı (editör ve explore ekranlarında).
  static const Color bgEditor = Color(0xFF020617);

  /// Sayfa arka planı (setup ve landing ekranlarında, biraz daha beyaz).
  static const Color bgLight = Color(0xFF0F172A);

  /// Input alanı arka planı.
  static const Color inputBg = Color(0xFF0F172A);

  /// Açık turkuaz/mavi yüzeyler.
  static const Color surface = Color(0xFF111827);
  static const Color surfaceSoft = Color(0xFF1E293B);
  static const Color turquoiseSurface = Color(0xFF083344);
  static const Color blueSurface = Color(0xFF1E1B4B);

  // ── Metin Renkleri ────────────────────────────────────────────────────
  /// Başlık ve ana içerik metni (koyu lacivert/siyah).
  static const Color darkText = Color(0xFFF8FAFC);
  static const Color darkTextAlt = Color(0xFFE2E8F0);

  /// İkincil / yardımcı metin (muted).
  static const Color mutedText = Color(0xFF94A3B8);

  /// Orta ton metin (açıklama satırları).
  static const Color softText = Color(0xFFCBD5E1);

  // ── Kenarlık & Gölge ─────────────────────────────────────────────────
  /// Kart/kutu kenarlığı.
  static const Color border = Color(0xFF334155);
  static const Color focusedBorder = Color(0xFF00E5FF);
  static const Color cardBorderDark = Color(0xFF475569);
  static const Color cardBorderLight = Color(0xFF334155);

  // ── Durum Renkleri ───────────────────────────────────────────────────
  /// Başarı / yeşil.
  static const Color success = Color(0xFF22C55E);

  /// Bilgi / mavi.
  static const Color info = Color(0xFF38BDF8);

  /// Uyarı tonu.
  static const Color pinkAccent = Color(0xFFA855F7);

  /// Disabled / pasif rengi.
  static const Color disabled = Color(0xFF475569);
}
