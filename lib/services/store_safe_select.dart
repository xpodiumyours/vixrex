import 'package:vixrex/config/vitrin_alanlari.g.dart';

/// PostgREST `select()` wildcard'ı `edit_token` dahil tüm sütunları ister.
/// Token sütunu anon/authenticated için kapalı olduğundan güvenli liste kullanılır.
class StoreSafeSelect {
  const StoreSafeSelect._();

  /// `edit_token` hariç StoreData / public vitrin alanları.
  /// Not: Yeni sütunlar migration uygulanmadan buraya eklenmez;
  /// aksi halde Keşfet/select tüm vitrin listesini düşürür.
  ///
  /// `user_id` BİLEREK yok (2026-08-20 dersi): StoreData modelinde hiç
  /// karşılığı olmadığı hâlde burada duruyordu — hem anon'a sızıyordu
  /// (V-09'un önlemeye çalıştığı tam olarak buydu) hem de authenticated
  /// (anonim oturum dahil HERKES) için `stores.user_id` kolonunun SELECT'i
  /// kapatıldığından (V-09) TÜM Keşfet sorgusunu 42501 ile düşürüyordu.
  /// Sahiplik kontrolü zaten yerel slug eşleşmesiyle yapılıyor
  /// (bkz. `ExploreController.isOwnStore`) — bu sütuna hiç gerek yok.
  static const _systemColumns = <String>[
    'id',
    'slug',
    'theme',
    'status',
    'marketplace_links',
    'gallery_items',
    'products',
    'product_categories',
    'offerings',
    'catalog_link',
    'vcard_link',
    'is_published',
    'is_store',
    'is_demo',
    'storefront_kind',
    'faq_items',
    'about_values',
    'section_visibility',
    'product_storage_version',
    'created_at',
    'updated_at',
    'location_accuracy_meters',
    'location_consent_at',
    'location_source',
    'province_code',
    'district_code',
    'privacy_notice_acknowledged',
    'privacy_notice_acknowledged_at',
    'privacy_notice_version',
    'privacy_notice_hash',
    'terms_accepted',
    'terms_accepted_at',
    'terms_version',
    'terms_hash',
    'publication_consent_accepted',
    'publication_consent_accepted_at',
    'publication_consent_withdrawn_at',
    'publication_consent_version',
    'publication_consent_hash',
  ];

  static final String columns = {
    ..._systemColumns,
    ...vitrinAlanlari.map((field) => field.kolon),
  }.join(',');
}
