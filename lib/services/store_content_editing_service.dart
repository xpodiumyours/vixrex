import 'package:vixrex/models/store_data.dart';

/// Vitrin içerik alanlarını `StoreData`'ya yazan tek cephe.
///
/// Controller parçalama, Faz 6 (2026-08-13): `StoreEditorController`'daki
/// `updateField` switch'i ve üç çoklu-alan setter'ı (`updateAboutSection`,
/// `updateGallerySectionMeta`, `updateFeaturedCampaign`) birebir buraya
/// taşındı. Davranış aynı — yalnız `StoreData` mutasyonu, `notifyListeners`
/// çağıran tarafta (controller) kalıyor, bu servis state/notify bilmiyor.
///
/// [writeField] şemadaki (`lib/config/vitrin_alanlari.g.dart` →
/// `vitrinAlanlari`, Next.js `vitrinFieldSchema.ts` ile aynı kaynaktan
/// üretilir) basit, tek-alanlı yazılabilir alanları TEK giriş noktasından
/// yazar — Next.js'teki `update_working_draft_field` ile aynı ilke
/// (ADR 0001: iki istemci aynı çekirdek yazma mantığını iki kere yazmaz).
///
/// Kapsam dışı BİLEREK: kategori/işletme türü (yan etkili senkron),
/// booking (ensure mantığı), yasal onay (koşullu damgalama), durum
/// (`selectStatus`, şemada yok — operasyonel), SSS listesi
/// (`updateFaqItems`, yapısal liste, şemada yok) ve bölüm görünürlüğü
/// (`updateSectionVisibility`, harita mantığı taşıyor). Bunlar
/// `StoreEditorController`'da kalıyor.
class StoreContentEditingService {
  const StoreContentEditingService();

  /// [deger], alanın `tip`ine göre `String` ya da `bool` olmalı.
  ///
  /// NOT: trim() davranışı alan alan FARKLIDIR (ör. işletme adı
  /// trim'lenmez, telefon trim'lenir) — bu, taşımadan ÖNCE de böyleydi;
  /// burada düzeltilmedi, birebir korundu.
  void writeField(StoreData data, String anahtar, Object? deger) {
    switch (anahtar) {
      case 'isletmeAdi':
        data.name = deger as String;
      case 'kisaTanitim':
        data.description = deger as String;
      case 'whatsapp':
        data.whatsapp = deger as String;
      case 'telefon':
        data.phone = (deger as String).trim();
      case 'eposta':
        data.email = (deger as String).trim();
      case 'heroRozet':
        data.heroBadge = (deger as String).trim();
      case 'hakkindaMetin':
        data.corporateBio = deger as String;
      case 'kategoriBolumBaslik':
        data.categorySectionTitle = (deger as String).trim();
      case 'urunBolumBaslik':
        data.productSectionTitle = (deger as String).trim();
      case 'galeriAksiyonMetni':
        data.galleryActionLabel = (deger as String).trim();
      case 'galeriAksiyonLinki':
        data.galleryActionHref = (deger as String).trim();
      case 'blogUstBaslik':
        data.blogSectionKicker = (deger as String).trim();
      case 'blogBaslik':
        data.blogSectionTitle = (deger as String).trim();
      case 'sssUstBaslik':
        data.faqSectionKicker = (deger as String).trim();
      case 'sssBaslik':
        data.faqSectionTitle = (deger as String).trim();
      case 'sssAciklama':
        data.faqSectionDescription = (deger as String).trim();
      case 'puanGoster':
        data.showStorefrontRating = deger as bool;
      case 'yolTarifiGoster':
        data.showDirectionsLink = deger as bool;
      case 'calismaSaatleri':
        data.workingHours = (deger as String).trim();
      case 'instagram':
        data.instagram = (deger as String).trim();
      case 'website':
        data.website = (deger as String).trim();
      case 'haritaLinki':
        data.googleBusinessLink = deger as String;
      case 'referansLinki':
        data.referencesLink = deger as String;
      case 'adres':
        data.address = deger as String;
      default:
        throw ArgumentError(
          'writeField: bilinmeyen veya bu yoldan desteklenmeyen anahtar: $anahtar',
        );
    }
  }

  void writeAboutSection(
    StoreData data, {
    required String kicker,
    required String title,
    required String body,
    required String imageUrl,
    required String imageCaption,
    required List<StoreAboutValue> values,
  }) {
    data.aboutKicker = kicker.trim();
    data.aboutTitle = title.trim();
    data.corporateBio = body;
    data.aboutImageUrl = imageUrl.trim();
    data.aboutImageCaption = imageCaption.trim();
    data.aboutValues = List.of(values.take(3));
  }

  void writeGallerySectionMeta(
    StoreData data, {
    required String kicker,
    required String title,
  }) {
    data.gallerySectionKicker = kicker.trim();
    data.gallerySectionTitle = title.trim();
  }

  void writeFeaturedCampaign(
    StoreData data, {
    required String label,
    required String title,
    required String description,
    required String priceText,
    required String imageUrl,
  }) {
    data.featuredBannerLabel = label.trim();
    data.featuredBannerTitle = title.trim();
    data.featuredBannerDescription = description.trim();
    data.featuredBannerPriceText = priceText.trim();
    data.featuredBannerImageUrl = imageUrl.trim();
  }
}
