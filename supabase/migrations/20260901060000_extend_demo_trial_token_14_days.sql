-- ============================================================================
-- Demo trial token suresini 24 saatten 14 gun cikar
-- ============================================================================
-- SORUN: Misafir kullanici 14 gunluk ucretsiz deneme vaadiyle geliyor ama
--   clone_demo_store_as_draft 24 saatlik token uretiyor. Kullanici ertesi
--   gun vitrine ulasamiyor. "14 gun ucretsiz dene" vaadi eclişiyor.
--
-- COZUM: clone_demo_store_as_draft icindeki edit_token_expires_at'i
--   24 hours -> 14 days olarak degistir. rent_demo_for_account zaten
--   kalici hesaplarda 1 yil'a cekiyor - o akis etkilenmez.
-- ============================================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.clone_demo_store_as_draft(
  p_source_slug text,
  p_new_slug text,
  p_edit_token text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, extensions
AS $$
BEGIN
  IF p_new_slug IS NULL OR pg_catalog.length(pg_catalog.btrim(p_new_slug)) = 0 THEN
    RAISE EXCEPTION 'INVALID_SLUG';
  END IF;
  IF p_edit_token IS NULL OR pg_catalog.length(pg_catalog.btrim(p_edit_token)) < 24 THEN
    RAISE EXCEPTION 'INVALID_EDIT_TOKEN';
  END IF;

  INSERT INTO public.stores (
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
    edit_token_expires_at
  )
  SELECT
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
    now() + interval '14 days'
  FROM public.stores
  WHERE slug = pg_catalog.btrim(p_source_slug)
    AND is_demo = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'SOURCE_NOT_FOUND';
  END IF;
END;
$$;

COMMENT ON FUNCTION public.clone_demo_store_as_draft(text, text, text) IS
  'Demo vitrini taslak olarak klonlar. edit_token 14 gun gecerli (deneme suresi). '
  'Kalici hesaplarda rent_demo_for_account bunu 1 yila ceker.';

COMMIT;
