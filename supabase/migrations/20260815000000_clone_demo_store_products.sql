-- ============================================================================
-- "Bu vitrini kirala" — gerçek ürün kataloğunu da kopyala
-- ============================================================================
-- NEDEN VAR
-- Casper (2026-08-14): "kirala ile açılan vitrinlerde kategori ve ürünler
-- gelmiyor." Araştırınca görüldü: çoğu demo vitrinin (kiralik-butik,
-- kiralik-kafe, kiralik-kuafor, kiralik-teknik, demo-teknofix) GERÇEKTEN
-- 6-8 ürünü var — ama clone_demo_store_as_draft onları hiç kopyalamıyordu.
-- Sebep: ürünler stores.products (JSONB, kullanılmayan/boş bir sütun)
-- DEĞİL, ayrı bir ilişkisel `products` tablosunda duruyor (store_id ile
-- bağlı). Aynı şekilde ürün kategorileri de ayrı `product_categories`
-- tablosunda. Önceki migration yalnız stores satırını kopyalıyordu, bu
-- iki tabloya hiç dokunmuyordu.
--
-- NE YAPAR
-- clone_demo_store_as_draft'ı üç adıma çıkarır:
--   1) stores satırını kopyala (önceki davranış, değişmedi).
--   2) product_categories'i kopyala — yeni id'ler üretilir, eski→yeni
--      eşleme geçici bir tabloda tutulur (aynı fonksiyon çağrısı içinde,
--      commit'te otomatik silinir).
--   3) products'ı kopyala — category_id varsa yeni kategori id'sine
--      eşlenir; yoksa (kategorisiz ürün) null kalır.
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
declare
  v_source_id uuid;
  v_new_id uuid;
begin
  if p_new_slug is null or pg_catalog.length(pg_catalog.btrim(p_new_slug)) = 0 then
    raise exception 'INVALID_SLUG';
  end if;
  if p_edit_token is null or pg_catalog.length(pg_catalog.btrim(p_edit_token)) < 24 then
    raise exception 'INVALID_EDIT_TOKEN';
  end if;

  select id into v_source_id
  from public.stores
  where slug = pg_catalog.btrim(p_source_slug)
    and is_demo = true
    and is_published = true;

  if v_source_id is null then
    raise exception 'SOURCE_NOT_FOUND';
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
  where id = v_source_id
  returning id into v_new_id;

  -- Ürün kategorilerini kopyala; eski→yeni id eşlemesi geçici tabloda
  -- (yalnız bu fonksiyon çağrısı içinde yaşar, commit'te silinir).
  create temporary table _kategori_esleme (
    eski_id uuid primary key,
    yeni_id uuid not null
  ) on commit drop;

  insert into _kategori_esleme (eski_id, yeni_id)
  select id, gen_random_uuid()
  from public.product_categories
  where store_id = v_source_id;

  insert into public.product_categories (
    id, store_id, name, slug, sort_order, is_active
  )
  select e.yeni_id, v_new_id, k.name, k.slug, k.sort_order, k.is_active
  from public.product_categories k
  join _kategori_esleme e on e.eski_id = k.id
  where k.store_id = v_source_id;

  -- Ürünleri kopyala; category_id varsa yeni kategori id'sine eşlenir,
  -- yoksa (kategorisiz ürün) null kalır.
  insert into public.products (
    id, store_id, category_id, source_type, external_product_id,
    name, slug, description, price_amount, price_text, currency,
    stock_quantity, stock_status, image_urls, metadata,
    seo_title, seo_description, is_visible, is_active, sort_order,
    brand, barcode, vat_rate, variants, old_price_amount, badge_tag,
    fulfillment_region
  )
  select
    gen_random_uuid(), v_new_id, e.yeni_id, p.source_type,
    p.external_product_id,
    p.name, p.slug, p.description, p.price_amount, p.price_text, p.currency,
    p.stock_quantity, p.stock_status, p.image_urls, p.metadata,
    p.seo_title, p.seo_description, p.is_visible, p.is_active, p.sort_order,
    p.brand, p.barcode, p.vat_rate, p.variants, p.old_price_amount,
    p.badge_tag, p.fulfillment_region
  from public.products p
  left join _kategori_esleme e on e.eski_id = p.category_id
  where p.store_id = v_source_id;
end;
$$;
