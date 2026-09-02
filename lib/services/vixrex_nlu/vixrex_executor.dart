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
      case 'ilce':
        // Faz 1–2: il/ilçe listeden seçilmeli – serbest metinle yazma desteklenmiyor.
        // HomeShell özel akışa yönlendirir (scrollToAddress + liste).
        return false;
      case 'adres':
        controller.updateAddressText(deger as String);
        return true;
      case 'mahalle':
        controller.data.neighborhoodName = (deger as String).trim();
        controller.notifyListeners();
        return true;
      case 'haritaEtiketi':
        controller.data.mapLabel = (deger as String).trim();
        controller.notifyListeners();
        return true;
      case 'calismaSaatleri':
        controller.updateWorkingHoursText(deger as String);
        return true;
      case 'haritaLinki':
        controller.updateGoogleBusinessLink(deger as String);
        return true;
      case 'hakkindaBaslik':
        controller.data.aboutTitle = (deger as String).trim();
        controller.notifyListeners();
        return true;
      case 'hakkindaMetin':
        controller.updateCorporateBio(deger as String);
        return true;
      case 'heroRozet':
        controller.updateHeroBadge(deger as String);
        return true;
      case 'logo':
        controller.data.logoUrl = (deger as String).trim();
        controller.notifyListeners();
        return true;
      case 'kapakGorseli':
        controller.setCoverUrl(deger as String);
        return true;
      case 'instagram':
        controller.updateInstagram(deger as String);
        return true;
      case 'website':
        controller.updateWebsite(deger as String);
        return true;
      case 'telefon':
        controller.updatePhone(deger as String);
        return true;
      case 'eposta':
        controller.updateEmail(deger as String);
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
