-- Dilim A tamamlayıcı: create_store_with_token phone/email/hero_badge alanlarını yazar.
-- Not: Uzakta apply_migration adı manual_panel_dilim_a_create_store_rpc olarak uygulandı.

CREATE OR REPLACE FUNCTION public.create_store_with_token(
  p_slug text,
  p_edit_token text,
  p_store jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_id uuid := auth.uid();
BEGIN
  IF p_slug IS NULL OR pg_catalog.length(pg_catalog.btrim(p_slug)) = 0 THEN
    RAISE EXCEPTION 'INVALID_SLUG';
  END IF;
  IF p_edit_token IS NULL OR pg_catalog.length(pg_catalog.btrim(p_edit_token)) < 24 THEN
    RAISE EXCEPTION 'INVALID_EDIT_TOKEN';
  END IF;

  INSERT INTO public.stores (
    slug,
    edit_token,
    user_id,
    name,
    business_type,
    description,
    corporate_bio,
    whatsapp,
    phone,
    email,
    hero_badge,
    instagram,
    website,
    address,
    theme,
    status,
    marketplace_links,
    gallery_items,
    products,
    product_categories,
    offerings,
    catalog_link,
    references_link,
    vcard_link,
    shelf_image_url,
    logo_url,
    working_hours,
    is_published,
    is_store,
    kategori,
    latitude,
    longitude,
    location_accuracy_meters,
    location_consent_at,
    location_source,
    province_code,
    province_name,
    district_code,
    district_name,
    google_business_link,
    privacy_notice_acknowledged,
    privacy_notice_version,
    privacy_notice_hash,
    terms_accepted,
    terms_version,
    terms_hash,
    publication_consent_accepted,
    publication_consent_version,
    publication_consent_hash,
    updated_at
  ) VALUES (
    pg_catalog.btrim(p_slug),
    pg_catalog.btrim(p_edit_token),
    v_user_id,
    coalesce(p_store->>'name', ''),
    coalesce(p_store->>'business_type', ''),
    coalesce(p_store->>'description', ''),
    coalesce(p_store->>'corporate_bio', ''),
    coalesce(p_store->>'whatsapp', ''),
    coalesce(p_store->>'phone', ''),
    coalesce(p_store->>'email', ''),
    coalesce(p_store->>'hero_badge', ''),
    coalesce(p_store->>'instagram', ''),
    coalesce(p_store->>'website', ''),
    coalesce(p_store->>'address', ''),
    coalesce(p_store->>'theme', ''),
    coalesce(p_store->>'status', ''),
    coalesce(p_store->'marketplace_links', '[]'::jsonb),
    coalesce(p_store->'gallery_items', '[]'::jsonb),
    coalesce(p_store->'products', '[]'::jsonb),
    coalesce(p_store->'product_categories', '[]'::jsonb),
    coalesce(p_store->'offerings', '[]'::jsonb),
    coalesce(p_store->>'catalog_link', ''),
    coalesce(p_store->>'references_link', ''),
    coalesce(p_store->>'vcard_link', ''),
    coalesce(p_store->>'shelf_image_url', ''),
    coalesce(p_store->>'logo_url', ''),
    coalesce(p_store->>'working_hours', ''),
    true,
    coalesce((p_store->>'is_store')::boolean, false),
    coalesce(p_store->>'kategori', ''),
    CASE WHEN p_store ? 'latitude' AND nullif(p_store->>'latitude', '') IS NOT NULL
      THEN (p_store->>'latitude')::float8 ELSE NULL END,
    CASE WHEN p_store ? 'longitude' AND nullif(p_store->>'longitude', '') IS NOT NULL
      THEN (p_store->>'longitude')::float8 ELSE NULL END,
    CASE WHEN p_store ? 'location_accuracy_meters'
      AND nullif(p_store->>'location_accuracy_meters', '') IS NOT NULL
      THEN (p_store->>'location_accuracy_meters')::float8 ELSE NULL END,
    CASE WHEN p_store ? 'location_consent_at'
      AND nullif(p_store->>'location_consent_at', '') IS NOT NULL
      THEN (p_store->>'location_consent_at')::timestamptz ELSE NULL END,
    p_store->>'location_source',
    coalesce(p_store->>'province_code', ''),
    coalesce(p_store->>'province_name', ''),
    coalesce(p_store->>'district_code', ''),
    coalesce(p_store->>'district_name', ''),
    coalesce(p_store->>'google_business_link', ''),
    coalesce((p_store->>'privacy_notice_acknowledged')::boolean, false),
    coalesce(p_store->>'privacy_notice_version', ''),
    coalesce(p_store->>'privacy_notice_hash', ''),
    coalesce((p_store->>'terms_accepted')::boolean, false),
    coalesce(p_store->>'terms_version', ''),
    coalesce(p_store->>'terms_hash', ''),
    coalesce((p_store->>'publication_consent_accepted')::boolean, false),
    coalesce(p_store->>'publication_consent_version', ''),
    coalesce(p_store->>'publication_consent_hash', ''),
    pg_catalog.now()
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.create_store_with_token(text, text, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_store_with_token(text, text, jsonb) TO anon, authenticated;

NOTIFY pgrst, 'reload schema';
