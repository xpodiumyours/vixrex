-- ============================================================================
-- "Bu vitrini kirala" denemelerinin otomatik temizliği
-- ============================================================================
-- NEDEN VAR
-- Casper (2026-08-14): "Kirala butonuna her tıklamada kalıcı bir kayıt
-- oluşuyor, hiç silinmiyor... reklamlar çıkmadan önce bunu halledelim.
-- 30 gün çok, 30 saat yeter."
--
-- clone_demo_store_as_draft ile oluşan taslaklar hangi demo'dan
-- kopyalandığını şimdiye kadar hiç işaretlemiyordu — bu yüzden onları
-- organik (gerçek esnafın kendi taslağı) satırlardan ayırt edip GÜVENLE
-- silmenin bir yolu yoktu. Önce işaretleniyor, sonra yalnız o işaretli
-- satırlar (ve hâlâ yayınlanmamışsa) temizleniyor.
--
-- NE YAPAR
-- 1) stores.cloned_from_slug: hangi demo'dan kopyalandığını kaydeder
--    (organik taslaklarda hep null kalır — onlara hiç dokunulmaz).
-- 2) clone_demo_store_as_draft artık bu alanı dolduruyor.
-- 3) cleanup_expired_trial_clones(): cloned_from_slug dolu VE hâlâ
--    is_published=false VE 30 saatten eski satırları siler.
--    Kullanıcı denemesini YAYINLARSA (is_published=true olur) bu satır
--    artık koşula girmez, asla silinmez — gerçek dönüşüm her zaman güvende.
-- 4) pg_cron ile saatte bir otomatik çalıştırılır.
-- ============================================================================

create extension if not exists pg_cron;

alter table public.stores
  add column if not exists cloned_from_slug text;

comment on column public.stores.cloned_from_slug is
  '"Bu vitrini kirala" ile kopyalandıysa kaynak demo''nun slug''ı; organik
   (esnafın kendi oluşturduğu) satırlarda her zaman null.';

-- clone_demo_store_as_draft'ı cloned_from_slug'ı da yazacak şekilde
-- güncelliyor — geri kalanı 20260814090000'dekiyle birebir aynı.
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
    slug, edit_token, user_id, cloned_from_slug,
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
    pg_catalog.btrim(p_source_slug),
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

-- Temizlik fonksiyonu — yalnız işaretli VE hâlâ taslak VE 30 saatten
-- eski satırları siler. anon/authenticated'e YETKİ VERİLMEZ (yalnız
-- cron/postgres çağırır) — dışarıdan tetiklenemez.
create or replace function public.cleanup_expired_trial_clones()
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
begin
  delete from public.stores
  where cloned_from_slug is not null
    and is_published = false
    and created_at < pg_catalog.now() - interval '30 hours';
end;
$$;

comment on function public.cleanup_expired_trial_clones() is
  '"Bu vitrini kirala" ile açılıp 30 saattir yayınlanmamış denemeleri
   siler. Yayınlanan (is_published=true) hiçbir satıra dokunmaz. Yalnız
   pg_cron çağırır, dışarıya (anon/authenticated) açık değildir.';

select cron.schedule(
  'cleanup-expired-trial-clones',
  '0 * * * *',
  $$select public.cleanup_expired_trial_clones();$$
);
