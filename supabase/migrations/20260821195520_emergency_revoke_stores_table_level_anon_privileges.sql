-- ACİL (2026-08-21, canlıda bulundu, kritik): anon rolünün public.stores
-- üzerinde TABLO SEVİYESİNDE SELECT/INSERT/UPDATE/DELETE/TRUNCATE/TRIGGER/
-- MAINTAIN/REFERENCES yetkisi olduğu tespit edildi (aclexplode ile
-- doğrulandı). Bu, sütun bazlı REVOKE'lerin (edit_token/user_id dahil)
-- neden işe yaramadığını açıklıyor — tablo seviyesi yetki sütun seviyesini
-- geçersiz kılıyor. TRUNCATE RLS'ten muaftır: bu hâliyle herkese açık
-- anon anahtarla TÜM stores tablosu boşaltılabilirdi.
--
-- Kaynağı ayrı bir soruşturma konusu (muhtemelen 5 Ağustos temel şemasında
-- veya sonraki bir migration'da yanlışlıkla tablo seviyesinde GRANT
-- kullanılmış). Bu migration yalnız acil kapatma yapar.

revoke insert, update, delete, truncate, trigger, maintain, references
  on table public.stores from anon;
revoke select on table public.stores from anon;

-- Şimdi anon'un stores'ta HİÇBİR tablo-seviyesi yetkisi yok. Sadece
-- güvenli, herkese açık sütunlar için tek tek SELECT açılır.
grant select (
  "id","slug","theme","status","marketplace_links","gallery_items","products",
  "product_categories","offerings","catalog_link","vcard_link","is_published",
  "is_store","is_demo","faq_items","about_values","section_visibility",
  "product_storage_version","created_at","updated_at","location_accuracy_meters",
  "location_consent_at","location_source","province_code","district_code",
  "privacy_notice_acknowledged","privacy_notice_acknowledged_at","privacy_notice_version",
  "privacy_notice_hash","terms_accepted","terms_accepted_at","terms_version","terms_hash",
  "publication_consent_accepted","publication_consent_accepted_at",
  "publication_consent_withdrawn_at","publication_consent_version","publication_consent_hash",
  "name","hero_badge","description","hero_location_text","kategori","business_type",
  "logo_url","shelf_image_url","whatsapp","phone","email","address","province_name",
  "district_name","neighborhood_name","map_label","working_hours","instagram","website",
  "google_business_link","latitude","longitude","category_section_title",
  "product_section_title","featured_banner_label","featured_banner_title",
  "featured_banner_description","featured_banner_image_url","featured_banner_price_text",
  "about_kicker","about_title","corporate_bio","about_image_url","about_image_caption",
  "gallery_section_kicker","gallery_section_title","gallery_action_label",
  "gallery_action_href","blog_section_kicker","blog_section_title","faq_section_kicker",
  "faq_section_title","faq_section_description","show_storefront_rating",
  "show_directions_link","references_link","consent_accepted_at","explicit_consent_given",
  "rating_score","review_count","booking_is_enabled","theme_preset","publish_hash",
  "publish_version"
) on table public.stores to anon;

notify pgrst, 'reload schema';
