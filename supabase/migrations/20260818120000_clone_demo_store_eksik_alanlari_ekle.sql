-- ============================================================================
-- clone_demo_store_as_draft fonksiyonunu güncelle
-- Eksik bölüm başlıklarını da kopyala: about_section_title, blog_*, faq_*
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
    show_storefront_rating, show_directions_link,
    -- Yeni eklenen bölüm başlıkları (teknofix kalitesi için)
    about_section_title, blog_section_kicker, blog_section_title,
    faq_section_kicker, faq_section_title, faq_section_description
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
    show_storefront_rating, show_directions_link,
    -- Yeni eklenenler
    about_section_title, blog_section_kicker, blog_section_title,
    faq_section_kicker, faq_section_title, faq_section_description
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
  'Demo vitrini taslak olarak kopyalar — teknofix kalitesinde tüm alanlar dahil.';
