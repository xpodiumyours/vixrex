/// PostgREST `select()` wildcard'ı `edit_token` dahil tüm sütunları ister.
/// Token sütunu anon/authenticated için kapalı olduğundan güvenli liste kullanılır.
class StoreSafeSelect {
  const StoreSafeSelect._();

  /// `edit_token` hariç StoreData / public vitrin alanları.
  static const columns =
      'id,slug,name,business_type,description,corporate_bio,whatsapp,instagram,'
      'website,address,theme,status,marketplace_links,gallery_items,products,'
      'product_categories,offerings,catalog_link,references_link,vcard_link,'
      'shelf_image_url,logo_url,working_hours,is_published,is_store,kategori,'
      'latitude,longitude,location_accuracy_meters,location_consent_at,'
      'location_source,province_code,province_name,district_code,district_name,'
      'google_business_link,privacy_notice_acknowledged,privacy_notice_acknowledged_at,'
      'privacy_notice_version,privacy_notice_hash,terms_accepted,terms_accepted_at,'
      'terms_version,terms_hash,publication_consent_accepted,'
      'publication_consent_accepted_at,publication_consent_withdrawn_at,'
      'publication_consent_version,publication_consent_hash,user_id,updated_at,'
      'created_at,product_storage_version';
}
