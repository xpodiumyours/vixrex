/// Premium özellikleri için yapılandırma.
class PremiumConfig {
  const PremiumConfig._();

  /// Ücretsiz kullanıcılar için günlük OCR limiti.
  static const int freeOcrDailyLimit = 3;

  /// Premium özellikler.
  static const bool ocrEnabledForFree = true; // Sınırlı ücretsiz
  static const bool bulkUploadEnabledForFree = false;
  static const bool advancedAnalyticsEnabledForFree = false;

  /// Kullanıcının OCR kullanıp kullanamayacağını kontrol et.
  static bool canUseOcr(int dailyUsage) {
    return dailyUsage < freeOcrDailyLimit;
  }

  /// Kalan ücretsiz hakkını hesapla.
  static int remainingFreeOcr(int dailyUsage) {
    final remaining = freeOcrDailyLimit - dailyUsage;
    return remaining > 0 ? remaining : 0;
  }
}
