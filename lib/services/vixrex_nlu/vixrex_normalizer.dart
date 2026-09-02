/// Türkçe normalize – tek kaynak.
/// Mevcut ChatbotService._normalize ve Next.js assistantConversation normalize ile aynı kural.
/// Değişirse iki tarafta da aynı anda değişmeli (parity).
class VixrexNormalizer {
  const VixrexNormalizer._();

  /// Küçük harf + Türkçe karakter sadeleştirme + NFD benzeri sadeleştirme.
  /// Not: Dart'ta NFD yok, elle liste yeterli – Next.js tarafı NFD+tr-TR yapar, sonuç eşdeğer olmalı.
  static String normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('İ', 'i')
        .replaceAll('Ğ', 'g')
        .replaceAll('Ü', 'u')
        .replaceAll('Ş', 's')
        .replaceAll('Ö', 'o')
        .replaceAll('Ç', 'c');
  }

  /// Normalize edilmiş metinde `keyword` var mı?
  static bool containsNormalized(String haystack, String keyword) {
    return normalize(haystack).contains(normalize(keyword));
  }
}
