class LocalStorageKeys {
  const LocalStorageKeys._();

  static const vitrinData = 'vitrin_data';

  /// Vitrin verisinin yerele en son ne zaman yazildigi (ISO 8601).
  /// Buluttaki updated_at ile karsilastirilir: hangisi yeniyse o kazanir.
  /// Boylece tarayicidaki Vixrex Asistan duzenlemesi uygulamaya yansir,
  /// ama uygulamada yapilip henuz yayinlanmamis duzenleme de ezilmez.
  static const vitrinDataSavedAt = 'vitrin_data_saved_at';
  static const storeData = 'store_data';
  static const vitrinEditToken = 'vitrin_edit_token';
  static const storeEditToken = 'store_edit_token';

  // New keys for successfully published vitrin details:
  static const lastPublishedSlug = 'last_published_slug';
  static const lastPublishedLink = 'last_published_link';
  static const lastPublishedName = 'last_published_name';
  static const lastPublishedEditToken = 'last_published_edit_token';

  /// Hem eski hem yeni key'leri temizle
  static Future<void> clearAllEditTokens() async {
    // Bu method store_local_storage_service.dart tarafindan kullanilir
  }
}
