import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';

/// VixRex uygulamasının merkezi tipografi stilleri.
///
/// Tüm ekranlar bu sınıftan text style almalıdır.
/// Doğrudan `TextStyle(...)` literal kullanımı yerine bu sabitler tercih edilmelidir.
abstract final class AppTextStyles {
  // ── Başlıklar ─────────────────────────────────────────────────────────

  /// Sayfa/kart ana başlığı — büyük ekranlarda.
  static const TextStyle displayTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: AppColors.darkText,
    height: 1.2,
  );

  /// Bölüm başlığı — kart içi, adım başlığı.
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: AppColors.darkText,
  );

  /// Alt bölüm başlığı.
  static const TextStyle subTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AppColors.darkText,
  );

  // ── Gövde Metni ───────────────────────────────────────────────────────

  /// Standart gövde metni.
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.darkTextAlt,
    height: 1.5,
  );

  /// Küçük yardımcı metin (açıklamalar, ipuçları).
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.mutedText,
    height: 1.4,
  );

  // ── Etiketler & Butonlar ──────────────────────────────────────────────

  /// Buton ve aksiyon etiketleri.
  static const TextStyle labelBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
  );

  /// Küçük etiket (chip, badge).
  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.mutedText,
  );

  /// Birincil CTA buton metni (elektrik mavisi zemin üzerine).
  static const TextStyle ctaButton = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: AppColors.onPrimary,
    letterSpacing: 0.3,
  );

  // ── Form Alanları ─────────────────────────────────────────────────────

  /// Form alanı etiketi (label).
  static const TextStyle formLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.darkTextAlt,
  );

  /// Hata mesajı.
  static const TextStyle errorText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.error,
  );
}
