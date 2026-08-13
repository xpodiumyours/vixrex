-- ============================================================================
-- Demo vitrini "kirala" — zengin içeriği koruyan taslak kopya
-- ============================================================================
-- NEDEN VAR
-- Keşfet ekranındaki "Bu vitrini kirala" butonu bir demo vitrini (is_demo=
-- true) kopyalayıp ziyaretçiye kendi taslağı olarak Vixrex Asistan'da açmak
-- istiyor. Mevcut save_store_draft_with_token yalnız basit alanları (isim,
-- açıklama, whatsapp...) yazıyor — ürünler, Hakkımızda, SSS, kampanya
-- banner'ı gibi demoyu asıl zengin yapan alanları YOK SAYIYOR (aynı boşluk
-- daha önce about_title/faq_items'ta iki kez bulunmuştu, create_store_with_
-- token ve update_store_with_token'daki yorumlara bakın). O yolu kullanırsak
-- kiralayan kişi boşaltılmış bir vitrin görür, gördüğü demoyu değil.
--
-- create_store_with_token / update_store_with_token zengin alanları yazıyor
-- ama ikisi de is_published'i ZORLA true yapıyor — kopya taslak kalmalı,
-- kullanıcı Asistan'da deneyip kendi isteğiyle yayınlamalı.
--
-- NE YAPAR
-- Kaynak satırı (yalnız is_demo=true VE is_published=true olan) doğrudan
-- veritabanı içinde satır olarak kopyalar (INSERT ... SELECT) — Dart/SQL
-- arasında dördüncü bir alan listesi bakımı gerektirmez, yeni bir sütun
-- eklenirse (deny-list'te değilse) otomatik kopyalanır.
--
-- BİLEREK KOPYALANMAYAN (deny-list, SELECT listesinde yok):
--   id, edit_token, user_id, created_at, updated_at, published_at,
--   is_demo, is_published (draft olarak sabitlenir), publish_version,
--   publish_hash, rating_score, review_count (varsayılan değer alır),
--   privacy_notice_*, terms_*, publication_consent_*, explicit_consent_given,
--   consent_accepted_at, location_consent_at
--     → Hukuki onay bilgileri KOPYALANMAZ: yeni kullanıcı hiçbir şeyi
--       kabul etmedi, demo satırındaki sahte/eski onay damgasını
--       miras almamalı.
--
-- Yalnız `is_demo = true` satırlardan kopyalanabilir — rastgele başka bir
-- kullanıcının özel vitrinini klonlamak için kullanılamaz.
-- ============================================================================

create or replace function public.clone_demo_store_as_draft(
  p_source_slug text,
  p_new_slug text,
  p_edit_token text
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
begin
  if p_new_slug is null or pg_catalog.length(pg_catalog.btrim(p_new_slug)) = 0 then
    raise exception 'INVALID_SLUG';
  end if;
  if p_edit_token is null or pg_catalog.length(pg_catalog.btrim(p_edit_token)) < 24 then
    raise exception 'INVALID_EDIT_TOKEN';
  end if;

  insert into public.stores (
    slug, edit_token, user_id,
    name, business_type, description, corporate_bio,
    whatsapp, phone, email, hero_badge, instagram, website, address,
    theme, theme_preset, status,
    marketplace_links, gallery_items, products, product_categories, offerings,
    catalog_link, references_link, vcard_link, shelf_image_url, logo_url,
    working_hours, is_published, is_store, kategori,
    latitude, longitude, location_accuracy_meters, location_source,
    province_code, province_name, district_code, district_name,
    google_business_link,
    featured_banner_label, featured_banner_title, featured_banner_description,
    featured_banner_image_url, featured_banner_price_text,
    faq_items, about_kicker, about_title, about_image_url, about_image_caption,
    about_values, gallery_section_kicker, gallery_section_title,
    show_storefront_rating, show_directions_link
  )
  select
    pg_catalog.btrim(p_new_slug), pg_catalog.btrim(p_edit_token), null,
    name, business_type, description, corporate_bio,
    whatsapp, phone, email, hero_badge, instagram, website, address,
    theme, theme_preset, 'draft',
    marketplace_links, gallery_items, products, product_categories, offerings,
    catalog_link, references_link, vcard_link, shelf_image_url, logo_url,
    working_hours, false, is_store, kategori,
    latitude, longitude, location_accuracy_meters, location_source,
    province_code, province_name, district_code, district_name,
    google_business_link,
    featured_banner_label, featured_banner_title, featured_banner_description,
    featured_banner_image_url, featured_banner_price_text,
    faq_items, about_kicker, about_title, about_image_url, about_image_caption,
    about_values, gallery_section_kicker, gallery_section_title,
    show_storefront_rating, show_directions_link
  from public.stores
  where slug = pg_catalog.btrim(p_source_slug)
    and is_demo = true
    and is_published = true;

  if not found then
    raise exception 'SOURCE_NOT_FOUND';
  end if;
end;
$$;

comment on function public.clone_demo_store_as_draft(text, text, text) is
  '"Bu vitrini kirala" — bir demo vitrini (is_demo=true) taslak olarak
   kopyalar. Yalnız demo kaynaklardan kopyalanabilir; hukuki onay/kimlik
   alanları bilerek taşınmaz.';

revoke execute on function public.clone_demo_store_as_draft(text, text, text)
  from public;
grant execute on function public.clone_demo_store_as_draft(text, text, text)
  to anon, authenticated;
