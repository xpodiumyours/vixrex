/// Metin normalizasyonu için yardımcı fonksiyonlar.
class TextUtils {
  const TextUtils._();

  /// Türkçe karakterleri ASCII karşılıklarına dönüştürür.
  /// Büyük/küçük harf duyarlı: önce toLowerCase, sonra replaceAll.
  static String normalizeTurkish(String text) {
    return text
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }
}
