-- Dilim A: manuel panel için telefon + kapak rozeti.
-- email sütunu 20260727 migration'da eklendi; burada yayın RPC'lerine bağlanır.

ALTER TABLE public.stores
  ADD COLUMN IF NOT EXISTS phone TEXT,
  ADD COLUMN IF NOT EXISTS hero_badge TEXT;

COMMENT ON COLUMN public.stores.phone IS
  'İşletme telefonu (WhatsApp’tan ayrı, isteğe bağlı).';
COMMENT ON COLUMN public.stores.hero_badge IS
  'Kapak üstü kısa etiket (örn. Atölye / Mağaza).';
COMMENT ON COLUMN public.stores.email IS
  'İşletme iletişim e-postası.';

-- Yeni sütunlar edit_token hariç SELECT iznine dahil edilsin.
REVOKE SELECT ON TABLE public.stores FROM anon, authenticated;
REVOKE SELECT (edit_token) ON TABLE public.stores FROM anon, authenticated;

DO $$
DECLARE
  safe_columns text;
BEGIN
  SELECT string_agg(quote_ident(attname), ', ' ORDER BY attnum)
  INTO safe_columns
  FROM pg_attribute
  WHERE attrelid = 'public.stores'::regclass
    AND attnum > 0
    AND NOT attisdropped
    AND attname <> 'edit_token';

  EXECUTE format(
    'GRANT SELECT (%s) ON TABLE public.stores TO anon, authenticated',
    safe_columns
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.update_store_with_token(
  p_slug text,
  p_edit_token text,
  p_store jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF p_slug IS NULL OR pg_catalog.length(pg_catalog.btrim(p_slug)) = 0 THEN
    RAISE EXCEPTION 'INVALID_SLUG';
  END IF;

  UPDATE public.stores
  SET
    name = coalesce(p_store->>'name', name),
    business_type = coalesce(p_store->>'business_type', business_type),
    description = coalesce(p_store->>'description', description),
    corporate_bio = coalesce(p_store->>'corporate_bio', corporate_bio),
    whatsapp = coalesce(p_store->>'whatsapp', whatsapp),
    phone = coalesce(p_store->>'phone', phone),
    email = coalesce(p_store->>'email', email),
    hero_badge = coalesce(p_store->>'hero_badge', hero_badge),
    instagram = coalesce(p_store->>'instagram', instagram),
    website = coalesce(p_store->>'website', website),
    address = coalesce(p_store->>'address', address),
    theme = coalesce(p_store->>'theme', theme),
    status = coalesce(p_store->>'status', status),
    marketplace_links = coalesce(p_store->'marketplace_links', marketplace_links),
    gallery_items = coalesce(p_store->'gallery_items', gallery_items),
    products = coalesce(p_store->'products', products),
    product_categories = coalesce(p_store->'product_categories', product_categories),
    offerings = coalesce(p_store->'offerings', offerings),
    catalog_link = coalesce(p_store->>'catalog_link', catalog_link),
    references_link = coalesce(p_store->>'references_link', references_link),
    vcard_link = coalesce(p_store->>'vcard_link', vcard_link),
    shelf_image_url = coalesce(nullif(p_store->>'shelf_image_url', ''), shelf_image_url),
    logo_url = coalesce(nullif(p_store->>'logo_url', ''), logo_url),
    working_hours = coalesce(p_store->>'working_hours', working_hours),
    is_published = true,
    is_store = coalesce((p_store->>'is_store')::boolean, is_store),
    kategori = coalesce(p_store->>'kategori', kategori),
    latitude = CASE WHEN p_store ? 'latitude' THEN (p_store->>'latitude')::float8 ELSE latitude END,
    longitude = CASE WHEN p_store ? 'longitude' THEN (p_store->>'longitude')::float8 ELSE longitude END,
    location_accuracy_meters = CASE WHEN p_store ? 'location_accuracy_meters' THEN (p_store->>'location_accuracy_meters')::float8 ELSE location_accuracy_meters END,
    location_consent_at = CASE WHEN p_store ? 'location_consent_at' THEN (p_store->>'location_consent_at')::timestamptz ELSE location_consent_at END,
    location_source = CASE WHEN p_store ? 'location_source' THEN p_store->>'location_source' ELSE location_source END,
    province_code = coalesce(p_store->>'province_code', province_code),
    province_name = coalesce(p_store->>'province_name', province_name),
    district_code = coalesce(p_store->>'district_code', district_code),
    district_name = coalesce(p_store->>'district_name', district_name),
    google_business_link = coalesce(p_store->>'google_business_link', google_business_link),
    privacy_notice_acknowledged = coalesce((p_store->>'privacy_notice_acknowledged')::boolean, privacy_notice_acknowledged),
    privacy_notice_version = coalesce(p_store->>'privacy_notice_version', privacy_notice_version),
    privacy_notice_hash = coalesce(p_store->>'privacy_notice_hash', privacy_notice_hash),
    terms_accepted = coalesce((p_store->>'terms_accepted')::boolean, terms_accepted),
    terms_version = coalesce(p_store->>'terms_version', terms_version),
    terms_hash = coalesce(p_store->>'terms_hash', terms_hash),
    publication_consent_accepted = coalesce((p_store->>'publication_consent_accepted')::boolean, publication_consent_accepted),
    publication_consent_version = coalesce(p_store->>'publication_consent_version', publication_consent_version),
    publication_consent_hash = coalesce(p_store->>'publication_consent_hash', publication_consent_hash),
    updated_at = pg_catalog.now()
  WHERE slug = pg_catalog.btrim(p_slug)
    AND (
      (
        pg_catalog.length(pg_catalog.btrim(coalesce(p_edit_token, ''))) >= 24
        AND edit_token = pg_catalog.btrim(p_edit_token)
      )
      OR (
        auth.uid() IS NOT NULL
        AND user_id = auth.uid()
      )
    );

  IF NOT FOUND THEN
    RAISE EXCEPTION 'STORE_UPDATE_NOT_ALLOWED' USING errcode = 'P0001';
  END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.update_store_with_token(text, text, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_store_with_token(text, text, jsonb) TO anon, authenticated;

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
