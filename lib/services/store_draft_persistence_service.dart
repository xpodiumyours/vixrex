import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/store_local_storage_service.dart';
import 'package:vixrex/utils/secure_token_generator.dart';

/// Vitrin taslağının cihaza kalıcı yazılması ve yayın öncesi edit
/// token yönetimi.
///
/// Controller cephe parçalama, Faz 7 (2026-08-13, gözden geçirilmiş
/// kapsam): `saveLocally`'nin gerçek depolama I/O'su ve
/// `ensureDraftEditToken` birebir buraya taşındı.
///
/// BİLEREK taşınmayanlar: `publish`, `openOwnerPreview`, `deleteVitrin`,
/// `withdrawPublicationConsent`. İncelemede görüldü ki bunlar
/// controller'ın diğer sorumluluklarına (medya mixin'i, yasal damgalama,
/// ürün katalog senkronu, `notifyListeners`) `this` üzerinden o kadar sıkı
/// bağlı ki ayrı bir sınıfa taşımak yalnız geri çağırma (callback) yığını
/// üretir — "silme testi": bu metotları buraya taşısak bile controller'da
/// hâlâ aynı miktarda koordinasyon kalır, sadece dolaylılık artar. Bu,
/// gerçek bir derinlik kazancı değil, kozmetik bir taşımadır — yapılmadı.
class StoreDraftPersistenceService {
  const StoreDraftPersistenceService({required this.storage});
  final StoreLocalStorageService storage;

  /// [data] ve varsa [publishedInfo]'yu cihaza yazar. Galeri senkronu
  /// (`activeGalleryItems` → `data.galleryItems`) çağıran tarafta kalır —
  /// o, editör medya state'ine (mixin) bağlı, bu servise ait değil.
  Future<void> persist(
    StoreData data,
    PublishedVitrinInfo? publishedInfo,
  ) async {
    await storage.saveVitrinData(data);
    if (publishedInfo != null) {
      await storage.savePublishedVitrinInfo(
        slug: publishedInfo.slug,
        publicLink: publishedInfo.publicLink,
        name: publishedInfo.name,
        editToken: publishedInfo.editToken,
      );
    }
  }

  /// Yayın öncesi taslak için cihaza özel edit token. Aynı token daha
  /// sonra yayınlanırken de kullanılır — böylece taslak satırı yeni bir
  /// satıra değil, doğrudan yayınlanan satıra dönüşür.
  Future<String> ensureDraftEditToken() async {
    final existing = (await storage.loadVitrinEditToken())?.trim() ?? '';
    if (existing.isNotEmpty) return existing;
    final token = SecureTokenGenerator.generateUuid();
    await storage.saveVitrinEditToken(token);
    return token;
  }
}
