import 'package:flutter/material.dart';

/// VitrinX uygulamasının merkezi tipografi stilleri.
///
/// Tüm ekranlar bu sınıftan text style almalıdır.
/// Doğrudan `TextStyle(...)` literal kullanımı yerine bu sabitler tercih edilmelidir.
abstract final class AppTextStyles {
  // ── Başlıklar ─────────────────────────────────────────────────────────

  /// Sayfa/kart ana başlığı — büyük ekranlarda.
  static const TextStyle displayTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: Color(0xFF0F172A),
    height: 1.2,
  );

  /// Bölüm başlığı — kart içi, adım başlığı.
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: Color(0xFF0F172A),
  );

  /// Alt bölüm başlığı.
  static const TextStyle subTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: Color(0xFF111827),
  );

  // ── Gövde Metni ───────────────────────────────────────────────────────

  /// Standart gövde metni.
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Color(0xFF334155),
    height: 1.5,
  );

  /// Küçük yardımcı metin (açıklamalar, ipuçları).
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Color(0xFF64748B),
    height: 1.4,
  );

  // ── Etiketler & Butonlar ──────────────────────────────────────────────

  /// Buton ve aksiyon etiketleri.
  static const TextStyle labelBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Color(0xFF0F172A),
  );

  /// Küçük etiket (chip, badge).
  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Color(0xFF64748B),
  );

  /// Birincil CTA buton metni (beyaz zemin üzerine).
  static const TextStyle ctaButton = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    letterSpacing: 0.3,
  );

  // ── Form Alanları ─────────────────────────────────────────────────────

  /// Form alanı etiketi (label).
  static const TextStyle formLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: Color(0xFF334155),
  );

  /// Hata mesajı.
  static const TextStyle errorText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.redAccent,
  );
}
