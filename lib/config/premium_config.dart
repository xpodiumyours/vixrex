/// Vitrin özellikleri için yapılandırma.
class PremiumConfig {
  const PremiumConfig._();

  /// Günlük OCR kullanım limiti.
  static const int freeOcrDailyLimit = 3;

  /// Özellik anahtarları.
  static const bool ocrEnabledForFree = true; // Sınırlı kullanım
  static const bool bulkUploadEnabledForFree = false;
  static const bool advancedAnalyticsEnabledForFree = false;

  /// Kullanıcının OCR kullanıp kullanamayacağını kontrol et.
  static bool canUseOcr(int dailyUsage) {
    return dailyUsage < freeOcrDailyLimit;
  }

  /// Kalan kullanım hakkını hesapla.
  static int remainingFreeOcr(int dailyUsage) {
    final remaining = freeOcrDailyLimit - dailyUsage;
    return remaining > 0 ? remaining : 0;
  }
}
