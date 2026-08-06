/// İşletme adresi için tek doğrulama kaynağı.
///
/// NEDEN VAR
/// Adres eskiden yalnız "boş değil" diye kontrol ediliyordu; "asd" yazan
/// esnaf vitrinini öyle yayınlayabiliyordu. Vitrinin işi müşteriyi dükkâna
/// getirmek — yarım adres, adres olmamasından beterdir çünkü müşteri yola
/// çıkar ve bulamaz.
///
/// Kural bilerek DAR tutuldu: esnafı yormayacak ama boş sallamayı da
/// engelleyecek kadar. İl ve ilçe zaten resmi listeden seçiliyor; burada
/// yalnız sokak/cadde ve kapı numarası aranıyor.
class AddressValidator {
  const AddressValidator._();

  /// Adresin en az bu kadar karakter olması beklenir.
  /// "Atatürk Cad. No:24" 18 karakter — eşik bunun altında tutuldu.
  static const int minUzunluk = 10;

  /// Sokak/cadde/mahalle belirten yaygın Türkçe kısaltmalar.
  static const List<String> _yerBelirteclari = [
    'cad',
    'sok',
    'mah',
    'bulv',
    'blv',
    'apt',
    'blok',
    'sit',
    'plaza',
    'çarşı',
    'carsi',
    'pasaj',
    'sanayi',
    'osb',
    'küme',
    'kume',
  ];

  /// Adres kabul edilebilir mi? Değilse [hataMesaji] sebebini söyler.
  static bool gecerliMi(String? adres) => hataMesaji(adres) == null;

  /// Adres kabul edilebilirse `null`, değilse kullanıcıya gösterilecek
  /// mesaj döner. Mesaj ne yapılacağını söyler, yalnız "hatalı" demez.
  static String? hataMesaji(String? adres) {
    final metin = (adres ?? '').trim();

    if (metin.isEmpty) {
      return 'Adres gerekli. Örnek: Atatürk Cad. No:24';
    }

    if (metin.length < minUzunluk) {
      return 'Adres çok kısa. Müşterinin seni bulabilmesi için sokak/cadde '
          've kapı numarası yaz. Örnek: Atatürk Cad. No:24';
    }

    final kucuk = metin.toLowerCase();
    final rakamVar = RegExp(r'\d').hasMatch(metin);
    final yerBelirteciVar = _yerBelirteclari.any(kucuk.contains);

    // İkisinden en az biri olmalı: ya kapı numarası, ya sokak/cadde adı.
    // İkisini birden zorunlu tutmak köy ve sanayi adreslerini dışarıda
    // bırakırdı.
    if (!rakamVar && !yerBelirteciVar) {
      return 'Adres eksik görünüyor. Sokak/cadde adı veya kapı numarası '
          'ekle. Örnek: Atatürk Cad. No:24';
    }

    return null;
  }
}
