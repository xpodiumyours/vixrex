import 'package:vixrex/models/store_data.dart';

/// Store (vitrin/mağaza) veri erişim operasyonları için repository arayüzü.
abstract class StoreRepository {
  /// Kullanıcının kendi vitrinini getirir.
  Future<StoreData?> getStoreForCurrentUser();

  /// Edit token ile vitrin getirir.
  Future<StoreData?> getStoreByToken(String editToken);

  /// Slug ile vitrin getirir.
  Future<StoreData?> getStoreBySlug(String slug);

  /// Yeni vitrin oluşturur.
  Future<void> insertStore(Map<String, dynamic> payload);

  /// Edit token ile vitrin günceller (RPC).
  Future<void> updateStoreWithToken({
    required String slug,
    required String editToken,
    required Map<String, dynamic> storeData,
  });

  /// Yayınlama rızasını geri çeker.
  Future<void> withdrawPublicationConsent({
    required String slug,
    required String editToken,
  });

  /// Tüm yayınlanmış vitrinleri getirir.
  Future<List<StoreData>> fetchPublishedStores();
}
