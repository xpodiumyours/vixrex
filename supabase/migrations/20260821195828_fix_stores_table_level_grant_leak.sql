-- ACİL DÜZELTME (2026-08-21, canlıda bulundu ve canlıda kapatıldı — bu
-- migration o düzeltmenin dosyaya yazılmış hâlidir, uygulanınca no-op olur).
--
-- BULGU 1 (kritik sızıntı): `anon` rolünün public.stores üzerinde TABLO
-- SEVİYESİNDE (sütun bazlı değil) SELECT/INSERT/UPDATE/DELETE/TRUNCATE/
-- TRIGGER/MAINTAIN/REFERENCES yetkisi olduğu tespit edildi (aclexplode ile
-- doğrulandı). Bu, edit_token/user_id gibi sütunlara yönelik önceki
-- sütun-bazlı REVOKE'lerin (V-09, 20260818050000) neden `anon` için hiç
-- işe yaramadığını açıklıyor — tablo seviyesi yetki sütun seviyesini
-- geçersiz kılıyor. Canlıda doğrulandı: sade `anon` anahtarıyla
-- `?select=slug,edit_token,user_id` 200 döndü, gerçek edit_token
-- değerlerini içeriyordu. TRUNCATE RLS'ten muaftır — bu hâliyle herkese
-- açık anon anahtarla tüm stores tablosu boşaltılabilirdi. Tespit anında
-- 0 gerçek (is_demo=false) yayınlı mağaza vardı, yalnız 9 demo etkilendi.
--
-- BULGU 2 (fonksiyonel, aynı kök sebep): 13 sıradan vitrin alanı (bölüm
-- başlıkları, mahalle adı vb.) sonradan eklenen migration'larda yalnız
-- `anon`'a grant edilmiş, `authenticated`'e unutulmuş. Uygulama her
-- ziyaretçiye otomatik anonim oturum açtığı için (main.dart
-- `_oturumuGuvenceyeAl`) TÜM ziyaretçiler `authenticated` rolünde sorgu
-- atıyor — StoreSafeSelect.columns bu 13 alanı istediği için TÜM Keşfet
-- sorgusu 42501 ile düşüyordu ("Vitrinler yüklenemedi").
--
-- BULGU 3: `authenticated` rolünde de aynı taşma var — TRUNCATE/MAINTAIN/
-- REFERENCES/TRIGGER tablo seviyesinde açıktı, hiçbir uygulama kodu
-- kullanmıyor. SELECT/INSERT/UPDATE/DELETE'e dokunulmadı: SELECT zaten
-- sütun bazlı kısıtlı, UPDATE gerçekten kullanılıyor
-- (auto_fill_service.dart) ve RLS ile "auth.uid() = user_id" doğru
-- kısıtlanmış, DELETE aynı şekilde RLS korumalı, INSERT için hiç RLS
-- politikası yok (varsayılan red — RLS enabled, forcerowsecurity hariç).
--
-- KÖK SEBEP: sütun-bazlı GRANT modeli — her yeni/hassas sütun için iki
-- rolde ayrı ayrı hatırlanması gerekiyor, insan hafızasına bağımlı ve
-- tekrar eden bir hata sınıfı üretiyor (2026-08-05'ten bu yana en az 3
-- ayrı olayda: V-09, Keşfet 403, bu). Kalıcı mimari düzeltme (varsayılan
-- açık + küçük hassas liste kapalı, TEK tablo seviyesinde) ayrı bir işte
-- ele alınacak — bu migration yalnız acil deliği kapatır ve tespit edilen
-- eksik authenticated grant'larını tamamlar.

-- ── anon: tablo seviyesindeki her şeyi kaldır, yalnız güvenli sütunları
-- tek tek geri aç ─────────────────────────────────────────────────────
revoke insert, update, delete, truncate, trigger, maintain, references
  on table public.stores from anon;
revoke select on table public.stores from anon;

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

-- ── authenticated: eksik 13 sütuna GRANT ekle (BULGU 2), fazla
-- tablo-seviyesi yetkileri kaldır (BULGU 3) ─────────────────────────────
grant select (
  "blog_section_kicker", "blog_section_title", "category_section_title",
  "faq_section_description", "faq_section_kicker", "faq_section_title",
  "gallery_action_href", "gallery_action_label", "hero_location_text",
  "map_label", "neighborhood_name", "product_section_title", "section_visibility"
) on table public.stores to authenticated;

-- edit_token/user_id/cloned_from_slug/premium_expires_at/
-- premium_reminder_sent_for/version zaten authenticated'ten kapalıydı
-- (V-09 ve sonrası); burada yalnız anon'dan da açıkça kapatılıyor
-- (idempotent — zaten kapalıysa no-op).
revoke select ("edit_token") on table public.stores from anon, authenticated;
revoke select ("user_id") on table public.stores from anon, authenticated;
revoke select ("cloned_from_slug") on table public.stores from anon, authenticated;
revoke select ("premium_expires_at") on table public.stores from anon, authenticated;
revoke select ("premium_reminder_sent_for") on table public.stores from anon, authenticated;
revoke select ("version") on table public.stores from anon, authenticated;

revoke truncate, maintain, references, trigger
  on table public.stores from authenticated;

notify pgrst, 'reload schema';
