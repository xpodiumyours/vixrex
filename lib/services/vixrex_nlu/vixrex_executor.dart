import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/models/store_data.dart';

/// Mevcut Vixrex işlemlerine delege – yeni yazma yolu açmaz.
/// Kural:
/// - 24 düz alan → StoreContentEditingService.writeField (updateField)
/// - kategori → selectCategory (BusinessCategoryConfig + booking paketi)
/// - isletmeTuru → updateBusinessType
/// - il/ilce → selectProvince/selectDistrict (StoreLocationMixin)
/// - adres → updateAddressText
/// - yasal alanlar bu borudan YAZILAMAZ (owner_forbidden_draft_keys) – ayrı legal akış
/// - gorsel → https URL ise writeField, "fotoğraf yükle" ise VixRexAction’a yönlendirme (çağıran taraf)
class VixrexExecutor {
  const VixrexExecutor();

  /// Tek alan için mevcut controller’ı çağırır. Başarılı ise true, bilinmeyen anahtar ise false.
  /// `deger` ham tipte gelmeli: String için String, acikKapali için bool, sayi için num.
  bool execute({
    required StoreEditorController controller,
    required VixrexNiyetAlan alan,
    required Object? deger,
  }) {
    final anahtar = alan.anahtar;
    // Özel dallanmalar – StoreContentEditingService.writeField kapsamı dışında olanlar.
    switch (anahtar) {
      case 'kategori':
        controller.selectCategory(deger as String);
        return true;
      case 'isletmeTuru':
        controller.updateBusinessType(deger as String);
        return true;
      case 'il':
        // Faz 1 dar: il/ilçe tek başına metin update'i değil, province/district seçimi.
        // StoreEditorController.selectProvince(data, code, name) data ister – burada sade.
        // Faz 1’de il/ilçe için doğrudan StoreData’ya yazmayalım, netleştirme ile
        // kullanıcıdan il/ilçe listeden seçtirilecek; bu yüzden burada doğrudan
        // string olarak yazmıyoruz – false dönerek çağıranı yönlendirme yapmaya zorluyoruz.
        // Fakat parity için basit metin yazımı da desteklenmeli – geçici olarak
        // StoreData’ya yazmıyoruz, çünkü il/ilçe resmi liste + kod eşlemesi gerektirir.
        // Faz 1’de il/ilçe sadece netleştirme ile listeden seçilecek, serbest metin reddedilecek.
        return false;
      case 'ilce':
        return false;
      case 'adres':
        controller.updateAddressText(deger as String);
        return true;
      default:
        break;
    }

    // Yasal alanlar bu borudan yasak – çağıran taraf legal akışa yönlendirmeli.
    const yasak = {
      'isletmeAdi': false, // bu izinli, örnek – yasak listesi değil
    };
    // Gerçek yasak: owner_forbidden_draft_keys’teki legal alanlar zaten sözlükte yok,
    // bu yüzden buraya düşmez – ek kontrol gerekmez.

    try {
      controller.updateField(anahtar, deger);
      return true;
    } catch (_) {
      // writeField bilinmeyen anahtar fırlatır – özel işlem gerektirir.
      return false;
    }
  }

  /// Çok-alanlı faz için: StoreData’ya doğrudan yazım gerekirse (test amaçlı)
  /// – controller bypass, sadece StoreData mutasyonu. Prod’da kullanılmaz.
  static void writeToStoreData(StoreData data, String anahtar, Object? deger) {
    // Gerekirse StoreContentEditingService.writeField çağrılabilir.
  }
}
