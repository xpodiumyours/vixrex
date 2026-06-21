import 'package:flutter/material.dart';

/// VitrinX uygulamasının merkezi renk paleti.
///
/// Tüm ekranlar ve widget'lar bu sınıftan renkleri almalıdır.
/// Doğrudan `Color(0xFF...)` literal kullanımından kaçınılmalıdır.
abstract final class AppColors {
  // ── Marka Renkleri (Turkuaz - Mavi) ───────────────────────────────────
  /// Ana turkuaz marka rengi.
  static const Color primary = Color(0xFF10D8D8);

  /// Koyu turuncu yerine koyu turkuaz tonu.
  static const Color primaryDark = Color(0xFF0EA8B0);

  /// İkincil marka rengi (mavi).
  static const Color secondary = Color(0xFF38A0E4);

  /// Karşılama ve giriş ekranlarında kullanılan eski turuncu yerine turkuaz.
  static const Color brandOrange = Color(0xFF10D8D8);

  /// Ana CTA gradient (soldan sağa: turkuaz → mavi).
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  // ── Arka Plan Renkleri ────────────────────────────────────────────────
  /// Sayfa arka planı (editör ve explore ekranlarında).
  static const Color bgEditor = Color(0xFFF4F5F8);

  /// Sayfa arka planı (setup ve landing ekranlarında, biraz daha beyaz).
  static const Color bgLight = Color(0xFFF4F5F8);

  /// Input alanı arka planı.
  static const Color inputBg = Color(0xFFF1F5F9);

  /// Açık turkuaz/mavi yüzeyler.
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF0F8F8);
  static const Color turquoiseSurface = Color(0xFFC8F4F4);
  static const Color blueSurface = Color(0xFFC0E4F4);

  // ── Metin Renkleri ────────────────────────────────────────────────────
  /// Başlık ve ana içerik metni (koyu lacivert/siyah).
  static const Color darkText = Color(0xFF182028);
  static const Color darkTextAlt = Color(0xFF182028);

  /// İkincil / yardımcı metin (muted).
  static const Color mutedText = Color(0xFF64748B);

  /// Orta ton metin (açıklama satırları).
  static const Color softText = Color(0xFF475569);

  // ── Kenarlık & Gölge ─────────────────────────────────────────────────
  /// Kart/kutu kenarlığı.
  static const Color border = Color(0xFFD0E4E8);
  static const Color focusedBorder = Color(0xFFA0D8D8);
  static const Color cardBorderDark = Color(0xFFD0E4E8);
  static const Color cardBorderLight = Color(0xFFD0E4E8);

  // ── Durum Renkleri ───────────────────────────────────────────────────
  /// Başarı / yeşil.
  static const Color success = Color(0xFF10B981);

  /// Bilgi / mavi.
  static const Color info = Color(0xFF2563EB);

  /// Uyarı tonu.
  static const Color pinkAccent = Color(0xFFFB7185);

  /// Disabled / pasif rengi.
  static const Color disabled = Color(0xFFCBD5E1);
}
