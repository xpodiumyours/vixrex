import 'package:flutter/material.dart';

/// VitrinX uygulamasının merkezi renk paleti.
///
/// Tüm ekranlar ve widget'lar bu sınıftan renkleri almalıdır.
/// Doğrudan `Color(0xFF...)` literal kullanımından kaçınılmalıdır.
abstract final class AppColors {
  // ── Marka Renkleri ────────────────────────────────────────────────────
  /// Ana turuncu gradient başlangıcı. Buton, vurgu, aktif göstergeler.
  static const Color primary = Color(0xFFFF4D00);

  /// Gradient bitiş moru. CTA gradient'inde primary ile birlikte kullanılır.
  static const Color secondary = Color(0xFFB200FF);

  /// Turuncu marka rengi (landing ve auth ekranlarında kullanılır).
  static const Color brandOrange = Color(0xFFFF5A1F);

  /// Ana CTA gradient (soldan sağa: primary → secondary).
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  // ── Arka Plan Renkleri ────────────────────────────────────────────────
  /// Sayfa arka planı (editör ve kurulum ekranlarında).
  static const Color bgEditor = Color(0xFFF6F8FC);

  /// Sayfa arka planı (setup ve landing ekranlarında, biraz daha beyaz).
  static const Color bgLight = Color(0xFFF8FAFC);

  /// Input alanı arka planı.
  static const Color inputBg = Color(0xFFF1F5F9);

  // ── Metin Renkleri ────────────────────────────────────────────────────
  /// Başlık ve ana içerik metni (koyu).
  static const Color darkText = Color(0xFF111827);

  /// Başlık ve ana içerik metni (biraz daha koyu, setup ekranı versiyonu).
  static const Color darkTextAlt = Color(0xFF0F172A);

  /// İkincil / yardımcı metin (muted).
  static const Color mutedText = Color(0xFF64748B);

  /// Orta ton metin (açıklama satırları).
  static const Color softText = Color(0xFF334155);

  // ── Kenarlık & Gölge ─────────────────────────────────────────────────
  /// Kart/kutu kenarlığı (editör ve explore ekranları).
  static const Color cardBorderDark = Color.fromRGBO(15, 23, 42, 0.10);

  /// Kart/kutu kenarlığı (setup ekranı, biraz daha hafif).
  static const Color cardBorderLight = Color.fromRGBO(15, 23, 42, 0.08);

  // ── Durum Renkleri ───────────────────────────────────────────────────
  /// Başarı / yeşil (landing, rozet renkleri).
  static const Color success = Color(0xFF10B981);

  /// Bilgi / mavi.
  static const Color info = Color(0xFF2563EB);

  /// Pembe / uyarı tonu.
  static const Color pinkAccent = Color(0xFFFB7185);
}
